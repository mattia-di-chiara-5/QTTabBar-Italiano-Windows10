#requires -version 5.1
[CmdletBinding()]
param([switch]$NonRiavviareExplorer)

$ErrorActionPreference = 'Stop'
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptRoot
$ForkRoot = Split-Path -Parent $ProjectRoot
$Root = $ProjectRoot
. (Join-Path $ScriptRoot 'Common.ps1')

function Restart-Elevated {
    $powershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($NonRiavviareExplorer) { $arguments += ' -NonRiavviareExplorer' }
    Start-Process -FilePath $powershell -Verb RunAs -ArgumentList $arguments | Out-Null
}

if (-not (Test-Administrator)) {
    Restart-Elevated
    exit 0
}

$DataRoot = Join-Path $env:ProgramData 'QTTabBar-Italiano'
$LogDirectory = Join-Path $DataRoot 'Logs'
$BackupDirectory = Join-Path $DataRoot 'Backup'
New-Item -Path $LogDirectory,$BackupDirectory -ItemType Directory -Force | Out-Null
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$log = Join-Path $LogDirectory "install_or_repair_$timestamp.log"
Start-Transcript -Path $log -Force | Out-Null

try {
    Write-Section 'QTTabBar Italiano - installazione o riparazione offline v0.3.0'

    $windows = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $build = [int]$windows.CurrentBuildNumber
    $product = [string](Get-SafePropertyValue -InputObject $windows -Name 'ProductName')
    $displayVersion = [string](Get-SafePropertyValue -InputObject $windows -Name 'DisplayVersion')
    Write-Host "Sistema: $product $displayVersion (build $build)"
    Write-Host "Architettura: $(if ([Environment]::Is64BitOperatingSystem) { 'x64' } else { 'x86' })"

    if ($build -lt 10240 -or $build -ge 22000) {
        throw 'Il pacchetto e destinato esclusivamente a Windows 10.'
    }
    if (-not [Environment]::Is64BitOperatingSystem) {
        throw 'Il pacchetto supporta esclusivamente Windows 10 x64.'
    }

    Write-Section '.NET Framework 3.5'
    $netfx = Get-WindowsOptionalFeature -Online -FeatureName NetFx3
    if ($netfx.State -ne 'Enabled') {
        Write-Host 'Abilitazione di .NET Framework 3.5...' -ForegroundColor Yellow
        Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -NoRestart | Out-Null
    }
    else {
        Write-Host '.NET Framework 3.5 e gia abilitato.' -ForegroundColor Green
    }

    $entries = @(Get-QTTabBarEntries)
    $installedNow = $false

    if ($entries.Count -gt 0) {
        Write-Section 'QTTabBar gia installato'
        foreach ($entry in $entries) {
            $name = [string](Get-SafePropertyValue -InputObject $entry -Name 'DisplayName')
            $version = [string](Get-SafePropertyValue -InputObject $entry -Name 'DisplayVersion')
            Write-Host ("Rilevato: $name $version").TrimEnd() -ForegroundColor Green
        }
        $compatible = @($entries | Where-Object {
            $version = [string](Get-SafePropertyValue -InputObject $_ -Name 'DisplayVersion')
            -not [string]::IsNullOrWhiteSpace($version) -and $version -like '1.5.6*'
        })
        if ($compatible.Count -eq 0) {
            throw 'E presente una versione QTTabBar diversa da 1.5.6.x. Non viene sovrascritta automaticamente.'
        }
        Write-Host 'Nessuna reinstallazione: viene riparata soltanto la localizzazione.' -ForegroundColor Green
    }
    else {
        Write-Section 'Backup e installazione offline'

        try {
            Checkpoint-Computer -Description "Prima di QTTabBar Italiano $timestamp" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
            Write-Host 'Punto di ripristino creato.' -ForegroundColor Green
        }
        catch {
            Write-Warning "Punto di ripristino non creato: $($_.Exception.Message)"
        }

        $regPath = 'Registry::HKEY_CURRENT_USER\Software\QTTabBar'
        if (Test-Path -LiteralPath $regPath) {
            $backup = Join-Path $BackupDirectory "HKCU_QTTabBar_$timestamp.reg"
            $reg = Join-Path $env:SystemRoot 'System32\reg.exe'
            $process = Start-Process -FilePath $reg -ArgumentList @('export','HKCU\Software\QTTabBar',"`"$backup`"",'/y') -Wait -PassThru
            if ($process.ExitCode -ne 0) {
                throw "Backup del Registro non riuscito. Codice $($process.ExitCode)."
            }
            Write-Host "Backup Registro: $backup" -ForegroundColor DarkGray
        }

        $msiCandidates = @(
            (Join-Path $ProjectRoot 'Payload\QTTabBar.Setup_v1.5.6-beta.1_en.2024.msi'),
            (Join-Path $ForkRoot 'Payload\QTTabBar.Setup_v1.5.6-beta.1_en.2024.msi')
        )
        $msi = $msiCandidates |
            Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
            Select-Object -First 1

        if ([string]::IsNullOrWhiteSpace([string]$msi)) {
            throw ('Payload MSI non presente nel clone Git. Per una nuova installazione ' +
                'usa il pacchetto ZIP della GitHub Release v0.3.0. ' +
                'Il clone sorgente puo comunque riparare la lingua se QTTabBar e gia installato.')
        }
        if (-not (Test-MsiCompoundFile -Path $msi)) {
            throw 'Il payload MSI non e presente oppure non ha una struttura MSI valida.'
        }

        $expectedHash = 'AAE4F2BEC2F4CA0EDE488638B9F31543B7CFCBFC90F1C6DDB74F5FB47B890287'
        $actualHash = (Get-FileHash -LiteralPath $msi -Algorithm SHA256).Hash
        if ($actualHash -cne $expectedHash) {
            throw "Hash MSI non valido. Atteso $expectedHash; rilevato $actualHash."
        }

        $productName = Get-MsiProperty -Path $msi -PropertyName 'ProductName'
        $productVersion = Get-MsiProperty -Path $msi -PropertyName 'ProductVersion'
        if ([string]::IsNullOrWhiteSpace($productName) -or $productName -notmatch 'QTTabBar') {
            throw "ProductName MSI non valido: $productName"
        }

        Write-Host "Prodotto: $productName"
        Write-Host "Versione: $productVersion"
        Write-Host "SHA-256: $actualHash"
        Write-Host 'Origine: archivio beta caricato dall utente, incorporato nel pacchetto offline.'

        $installer = Start-Process -FilePath 'msiexec.exe' `
            -ArgumentList @('/i',"`"$msi`"",'/passive','/norestart') `
            -Wait -PassThru
        if ($installer.ExitCode -notin @(0,1641,3010)) {
            throw "Installazione MSI non riuscita. Codice $($installer.ExitCode)."
        }
        $installedNow = $true
        Write-Host 'QTTabBar installato.' -ForegroundColor Green
    }

    Write-Section 'Preparazione della lingua italiana'
    $sourceLanguage = Join-Path $ForkRoot 'I18N\Lng_QTTabBar_it_IT.xml'
    $language = Copy-ItalianLanguageFile -Source $sourceLanguage -OpenFolder

    Write-Host "File lingua verificato: $($language.Sections) sezioni XML." -ForegroundColor Green
    Write-Host "SHA-256 lingua: $($language.SHA256)"
    Write-Host "Percorso: $($language.Target)" -ForegroundColor White
    Write-Host 'Il percorso e stato copiato negli appunti.' -ForegroundColor Green

    $state = [ordered]@{
        PackageVersion = '0.3.0'
        QTTabBarVersion = '1.5.6-beta.1'
        WindowsBuild = $build
        InstalledByThisRun = $installedNow
        LanguageFile = $language.Target
        LanguageSHA256 = $language.SHA256
        MSI_SHA256 = 'AAE4F2BEC2F4CA0EDE488638B9F31543B7CFCBFC90F1C6DDB74F5FB47B890287'
        SourceArchiveSHA256 = '913A3F36B47251CD4B7D70EB94D2B05DCAC703269104483E1CA1502ABB5D40C3'
        Date = (Get-Date).ToString('o')
        Log = $log
    }
    $state | ConvertTo-Json -Depth 4 |
        Set-Content -LiteralPath (Join-Path $DataRoot 'install-state.json') -Encoding UTF8

    if (-not $NonRiavviareExplorer) {
        Write-Section 'Riavvio di Esplora file'
        Restart-ExplorerSafely
    }

    Write-Section 'Operazione completata'
    Write-Host 'QTTabBar e installato e il file italiano e pronto.' -ForegroundColor Green
    Write-Host ''
    Write-Host 'Per attivarlo una sola volta:' -ForegroundColor Yellow
    Write-Host '1. Esplora file > Visualizza > Opzioni > QTTabBar.'
    Write-Host '2. Clic destro sulla barra delle schede > QTTabBar Options.'
    Write-Host '3. Apri Language e seleziona Use language file.'
    Write-Host '4. Incolla il percorso gia presente negli appunti oppure seleziona il file aperto.'
    Write-Host '5. Premi Apply e OK. Se necessario esegui RIAVVIA_ESPLORA_FILE.cmd.'
    Write-Host ''
    Write-Host "Log: $log" -ForegroundColor DarkGray
    Read-Host 'Premi INVIO per chiudere'
}
catch {
    Write-Host ''
    Write-Host "ERRORE: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Log: $log" -ForegroundColor Yellow
    Read-Host 'Premi INVIO per chiudere'
    exit 1
}
finally {
    try { Stop-Transcript | Out-Null } catch {}
}
