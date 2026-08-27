#requires -version 5.1
[CmdletBinding()]
param(
    [string]$CandidatePath = (Join-Path $PSScriptRoot 'Payload\QTTabBar.dll'),
    [string]$MsiPath = (Join-Path $PSScriptRoot 'Payload\QTTabBar.Setup_v1.5.6-beta.1_en.2024.msi'),
    [switch]$NonRiavviareExplorer,
    [switch]$Elevated
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

$script:BootstrapTranscriptStarted = $false
$script:MaintenanceMutex = $null
$bootstrapLog = $null
trap {
    Write-Host ''
    Write-Host "ERRORE INIZIALE: $($_.Exception.Message)" -ForegroundColor Red
    if (-not [string]::IsNullOrWhiteSpace($bootstrapLog)) {
        Write-Host "Log diagnostico: $bootstrapLog" -ForegroundColor Yellow
    }
    if ($script:BootstrapTranscriptStarted) {
        try { Stop-Transcript | Out-Null } catch {}
    }
    if ($null -ne $script:MaintenanceMutex) {
        Exit-QTTabBarMaintenance -Mutex $script:MaintenanceMutex
        $script:MaintenanceMutex = $null
    }
    exit 1
}

function Restart-Elevated {
    $powershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -CandidatePath "{1}" -MsiPath "{2}" -Elevated' -f $PSCommandPath,$CandidatePath,$MsiPath
    if ($NonRiavviareExplorer) { $arguments += ' -NonRiavviareExplorer' }
    $process = Start-Process -FilePath $powershell -Verb RunAs -ArgumentList $arguments -Wait -PassThru
    exit $process.ExitCode
}

$isAdministrator = Test-Administrator
if ($Elevated -or $isAdministrator) {
    $bootstrapDirectory = Join-Path $env:LOCALAPPDATA 'QTTabBar-Italiano\Logs'
    New-Item -ItemType Directory -Path $bootstrapDirectory -Force | Out-Null
    $bootstrapLog = Join-Path $bootstrapDirectory ("install_v0.4.0_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.log')
    Start-Transcript -LiteralPath $bootstrapLog -Force | Out-Null
    $script:BootstrapTranscriptStarted = $true
}

if (-not $isAdministrator) {
    if ($Elevated) {
        throw 'Elevazione amministrativa non riuscita. Nessuna modifica è stata applicata.'
    }
    Restart-Elevated
}

$script:MaintenanceMutex = Enter-QTTabBarMaintenance

$candidate = Get-FileRecord -Path $CandidatePath
if ($candidate.SHA256 -cne $script:QtExpectedCandidateHash) {
    throw "DLL candidata non valida. Atteso $script:QtExpectedCandidateHash; rilevato $($candidate.SHA256)."
}

$windows = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$build = [int](Get-SafePropertyValue -InputObject $windows -Name 'CurrentBuildNumber' -Default 0)
if ($build -lt 10240 -or $build -ge 22000) {
    throw "Questa release è validata solo per Windows 10 x64. Build rilevata: $build."
}
if (-not [Environment]::Is64BitOperatingSystem) {
    throw 'Questa release richiede Windows 10 x64.'
}

$releaseStateRoot = Join-Path $env:ProgramData 'QTTabBar-Italiano\v0.4.0'
if (-not (Test-Path -LiteralPath $releaseStateRoot)) {
    New-Item -ItemType Directory -Path $releaseStateRoot | Out-Null
}
Protect-AdministratorDirectory -Path $releaseStateRoot
if (-not (Test-AdministratorDirectory -Path $releaseStateRoot)) {
    throw "ACL non sicura sulla directory di stato: $releaseStateRoot"
}

$activeGacFiles = @(Get-QTTabBarGacFiles | Sort-Object FullName -Unique)
if ($activeGacFiles.Count -gt 1) {
    throw "Attesa al massimo una QTTabBar.dll nella GAC; rilevate $($activeGacFiles.Count)."
}
if ($activeGacFiles.Count -eq 1) {
    $activeGac = Get-FileRecord -Path $activeGacFiles[0].FullName
}
if ($activeGacFiles.Count -eq 1 -and $activeGac.SHA256 -ceq $script:QtExpectedCandidateHash) {
    $existingLatest = Join-Path $releaseStateRoot 'latest-state.txt'
    if (-not (Test-Path -LiteralPath $existingLatest)) {
        throw 'La DLL italiana è già attiva, ma manca uno stato di rollback verificabile.'
    }
    $existingStateRoot = [IO.File]::ReadAllText($existingLatest).Trim()
    $resolvedReleaseRoot = (Resolve-Path -LiteralPath $releaseStateRoot).Path.TrimEnd('\')
    $resolvedExistingState = (Resolve-Path -LiteralPath $existingStateRoot).Path.TrimEnd('\')
    if (-not $resolvedExistingState.StartsWith($resolvedReleaseRoot + '\',[StringComparison]::OrdinalIgnoreCase)) {
        throw "Stato precedente non consentito: $resolvedExistingState"
    }
    Protect-AdministratorDirectory -Path $resolvedExistingState
    $existingStatePath = Join-Path $resolvedExistingState 'install-state.json'
    $existingState = Get-Content -LiteralPath $existingStatePath -Raw | ConvertFrom-Json
    $existingBackup = (Resolve-Path -LiteralPath ([string]$existingState.PreviousGacBackup)).Path
    $existingBackupRoot = (Join-Path $resolvedExistingState 'backup').TrimEnd('\') + '\'
    if (-not $existingBackup.StartsWith($existingBackupRoot,[StringComparison]::OrdinalIgnoreCase)) {
        throw "Backup precedente non consentito: $existingBackup"
    }
    $existingBackupHash = (Get-FileHash -LiteralPath $existingBackup -Algorithm SHA256).Hash.ToUpperInvariant()
    if ($existingBackupHash -cne $script:QtExpectedBaselineHash) {
        throw "Il rollback precedente non contiene la baseline sicura: $existingBackupHash"
    }
    if ([bool]$existingState.LanguageKeyExisted) {
        $existingLanguageBackup = (Resolve-Path -LiteralPath ([string]$existingState.LanguageBackup)).Path
        if (-not $existingLanguageBackup.StartsWith($existingBackupRoot,[StringComparison]::OrdinalIgnoreCase) -or
            -not (Test-LanguageRegistryBackup -Path $existingLanguageBackup)) {
            throw 'Il backup lingua precedente non è sicuro.'
        }
        $existingLanguageHash = (Get-FileHash -LiteralPath $existingLanguageBackup -Algorithm SHA256).Hash.ToUpperInvariant()
        $existingState | Add-Member -NotePropertyName LanguageBackupHash -NotePropertyValue $existingLanguageHash -Force
    }
    $existingState | Add-Member -NotePropertyName SecurityHardened -NotePropertyValue $true -Force
    $existingStateTemporary = $existingStatePath + '.tmp'
    Write-Utf8NoBom -Path $existingStateTemporary -Text ($existingState | ConvertTo-Json -Depth 6)
    [IO.File]::Copy($existingStateTemporary,$existingStatePath,$true)
    Remove-Item -LiteralPath $existingStateTemporary -Force
    Set-BuiltInItalian
    if (-not $NonRiavviareExplorer) { Restart-ExplorerSafely }
    Write-Section 'Installazione già presente e verificata'
    Write-Host 'Stato di rollback protetto e lingua italiana integrata selezionata.' -ForegroundColor Green
    Exit-QTTabBarMaintenance -Mutex $script:MaintenanceMutex
    $script:MaintenanceMutex = $null
    if ($script:BootstrapTranscriptStarted) {
        Stop-Transcript | Out-Null
        $script:BootstrapTranscriptStarted = $false
    }
    exit 0
}
if ($activeGacFiles.Count -eq 1 -and $activeGac.SHA256 -cne $script:QtExpectedBaselineHash) {
    throw "La DLL installata non coincide con la baseline sicura attesa: $($activeGac.SHA256)."
}

$stamp = (Get-Date -Format 'yyyyMMdd_HHmmss') + '_' + [Guid]::NewGuid().ToString('N').Substring(0,8)
$stateRoot = Join-Path $releaseStateRoot $stamp
$backupRoot = Join-Path $stateRoot 'backup'
$stagingRoot = Join-Path $stateRoot 'staging'
New-Item -ItemType Directory -Path $stateRoot | Out-Null
Protect-AdministratorDirectory -Path $stateRoot
New-Item -ItemType Directory -Path $backupRoot,$stagingRoot | Out-Null
$log = $bootstrapLog

$protectedCandidatePath = Join-Path $stagingRoot 'QTTabBar.dll'
Copy-Item -LiteralPath $candidate.Path -Destination $protectedCandidatePath
$protectedCandidate = Get-FileRecord -Path $protectedCandidatePath
if ($protectedCandidate.SHA256 -cne $script:QtExpectedCandidateHash) {
    throw "Copia protetta della DLL non valida: $($protectedCandidate.SHA256)."
}

$languageKey = 'HKCU:\Software\QTTabBar\Config\Lang'
$languageExisted = Test-Path -LiteralPath $languageKey
$languageBackup = Join-Path $backupRoot 'HKCU_QTTabBar_Config_Lang.reg'
$oldGacBackup = Join-Path $backupRoot 'QTTabBar.before.dll'
$installedMsiThisRun = $false

try {
    Write-Section 'QTTabBar Italiano v0.4.0'
    Write-Host "RC1: $($candidate.Path)"
    Write-Host "SHA-256: $($candidate.SHA256)"

    if ($languageExisted) {
        if (-not (Export-RegistryKey -NativePath 'HKCU\Software\QTTabBar\Config\Lang' -Destination $languageBackup)) {
            throw 'Backup della configurazione lingua non riuscito.'
        }
        if (-not (Test-LanguageRegistryBackup -Path $languageBackup)) {
            throw 'Il backup della configurazione lingua contiene chiavi non consentite.'
        }
        $languageBackupHash = (Get-FileHash -LiteralPath $languageBackup -Algorithm SHA256).Hash.ToUpperInvariant()
    }

    $entries = @(Get-QTTabBarEntries)
    if ($entries.Count -eq 0) {
        $msi = Get-FileRecord -Path $MsiPath
        if ($msi.SHA256 -cne $script:QtExpectedMsiHash) {
            throw "MSI baseline non valido. Atteso $script:QtExpectedMsiHash; rilevato $($msi.SHA256)."
        }
        $protectedMsiPath = Join-Path $stagingRoot 'QTTabBar.Setup_v1.5.6-beta.1_en.2024.msi'
        Copy-Item -LiteralPath $msi.Path -Destination $protectedMsiPath
        $protectedMsi = Get-FileRecord -Path $protectedMsiPath
        if ($protectedMsi.SHA256 -cne $script:QtExpectedMsiHash) {
            throw "Copia protetta dell'MSI non valida: $($protectedMsi.SHA256)."
        }
        Write-Host 'Installazione della baseline QTTabBar 1.5.6.1...'
        $quotedMsi = '"{0}"' -f $protectedMsi.Path
        $process = Start-Process msiexec.exe -ArgumentList @('/i',$quotedMsi,'/passive','/norestart') -Wait -PassThru
        if ($process.ExitCode -notin @(0,1641,3010)) {
            throw "Installazione MSI non riuscita. Codice $($process.ExitCode)."
        }
        $installedMsiThisRun = $true
    }
    else {
        $compatible = @($entries | Where-Object {
            ([string](Get-SafePropertyValue -InputObject $_ -Name 'DisplayVersion' -Default '')) -like '1.5.6*'
        })
        if ($compatible.Count -eq 0) {
            throw 'È installata una versione QTTabBar diversa da 1.5.6.x; aggiornamento interrotto.'
        }
    }

    $oldGac = Get-QTTabBarGacFile
    Copy-Item -LiteralPath $oldGac.FullName -Destination $oldGacBackup -Force
    $oldGacHash = (Get-FileHash -LiteralPath $oldGacBackup -Algorithm SHA256).Hash.ToUpperInvariant()
    if ($oldGacHash -cne $script:QtExpectedBaselineHash) {
        throw "La DLL installata non coincide con la baseline sicura attesa: $oldGacHash."
    }
    Write-Host "Backup DLL corrente: $oldGacBackup"
    Write-Host "Hash precedente: $oldGacHash"

    Install-GacAssembly -Path $protectedCandidate.Path
    $newGac = Get-FileRecord -Path (Get-QTTabBarGacFile).FullName
    if ($newGac.SHA256 -cne $script:QtExpectedCandidateHash) {
        throw "La GAC non contiene la RC1 attesa dopo l'installazione: $($newGac.SHA256)."
    }

    Set-BuiltInItalian
    if (-not $NonRiavviareExplorer) { Restart-ExplorerSafely }

    $state = [ordered]@{
        Version = '0.4.0'
        Date = (Get-Date).ToString('o')
        WindowsBuild = $build
        SourceCandidate = $candidate
        ProtectedCandidate = $protectedCandidate
        InstalledGac = $newGac
        PreviousGacHash = $oldGacHash
        PreviousGacBackup = $oldGacBackup
        LanguageKeyExisted = $languageExisted
        LanguageBackup = $(if ($languageExisted) { $languageBackup } else { $null })
        LanguageBackupHash = $(if ($languageExisted) { $languageBackupHash } else { $null })
        InstalledMsiThisRun = $installedMsiThisRun
        Log = $log
    }
    Write-Utf8NoBom -Path (Join-Path $stateRoot 'install-state.json') -Text ($state | ConvertTo-Json -Depth 6)
    $latestState = Join-Path $releaseStateRoot 'latest-state.txt'
    $latestStateTemporary = $latestState + '.tmp'
    Write-Utf8NoBom -Path $latestStateTemporary -Text $stateRoot
    Move-Item -LiteralPath $latestStateTemporary -Destination $latestState -Force

    Write-Section 'Installazione completata'
    Write-Host 'La DLL italiana built-in è nella GAC e la lingua integrata è selezionata.' -ForegroundColor Green
    Write-Host "Stato/rollback: $stateRoot"
    exit 0
}
catch {
    Write-Host "ERRORE: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Avvio rollback automatico...' -ForegroundColor Yellow
    try {
        if (Test-Path -LiteralPath $oldGacBackup) { Install-GacAssembly -Path $oldGacBackup }
        Restore-LanguageRegistry -Existed $languageExisted -BackupFile $languageBackup
        if (-not $NonRiavviareExplorer) { Restart-ExplorerSafely }
        Write-Host 'Rollback completato.' -ForegroundColor Green
    }
    catch {
        Write-Host "ROLLBACK NON COMPLETO: $($_.Exception.Message)" -ForegroundColor Red
    }
    exit 1
}
finally {
    if ($null -ne $script:MaintenanceMutex) {
        Exit-QTTabBarMaintenance -Mutex $script:MaintenanceMutex
        $script:MaintenanceMutex = $null
    }
    if ($script:BootstrapTranscriptStarted) {
        try { Stop-Transcript | Out-Null } catch {}
        $script:BootstrapTranscriptStarted = $false
    }
}
