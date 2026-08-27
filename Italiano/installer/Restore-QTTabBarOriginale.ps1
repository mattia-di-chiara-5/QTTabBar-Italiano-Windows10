#requires -version 5.1
[CmdletBinding()]
param(
    [string]$StateDirectory,
    [switch]$NonRiavviareExplorer,
    [switch]$Elevated
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

function Restart-Elevated {
    $powershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -Elevated' -f $PSCommandPath
    if (-not [string]::IsNullOrWhiteSpace($StateDirectory)) {
        $arguments += (' -StateDirectory "{0}"' -f $StateDirectory)
    }
    if ($NonRiavviareExplorer) { $arguments += ' -NonRiavviareExplorer' }
    $process = Start-Process -FilePath $powershell -Verb RunAs -ArgumentList $arguments -Wait -PassThru
    exit $process.ExitCode
}

if (-not (Test-Administrator)) {
    if ($Elevated) {
        throw 'Elevazione amministrativa non riuscita. Nessuna modifica è stata applicata.'
    }
    Restart-Elevated
}

$maintenanceMutex = Enter-QTTabBarMaintenance
try {
    $allowedRoot = Join-Path $env:ProgramData 'QTTabBar-Italiano\v0.4.0'
    if ([string]::IsNullOrWhiteSpace($StateDirectory)) {
        $latest = Join-Path $allowedRoot 'latest-state.txt'
        if (-not (Test-Path -LiteralPath $latest)) { throw 'Nessuno stato v0.4.0 da ripristinare.' }
        $StateDirectory = [IO.File]::ReadAllText($latest).Trim()
    }

    $resolvedRoot = (Resolve-Path -LiteralPath $allowedRoot).Path.TrimEnd('\')
    $resolvedState = (Resolve-Path -LiteralPath $StateDirectory).Path.TrimEnd('\')
    if (-not $resolvedState.StartsWith($resolvedRoot + '\',[StringComparison]::OrdinalIgnoreCase)) {
        throw "Directory di stato non consentita: $resolvedState"
    }
    if ((Get-Item -LiteralPath $resolvedState).Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw "La directory di stato non può essere un collegamento: $resolvedState"
    }
    if (-not (Test-AdministratorDirectory -Path $resolvedRoot) -or
        -not (Test-AdministratorDirectory -Path $resolvedState)) {
        throw 'Le ACL dello stato di ripristino non sono sicure.'
    }

    $statePath = Join-Path $resolvedState 'install-state.json'
    if (-not (Test-Path -LiteralPath $statePath)) { throw "Stato non trovato: $statePath" }
    $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json

    $backup = [string]$state.PreviousGacBackup
    if (-not (Test-Path -LiteralPath $backup)) { throw "Backup DLL non trovato: $backup" }
    $resolvedBackup = (Resolve-Path -LiteralPath $backup).Path
    $allowedBackupRoot = (Join-Path $resolvedState 'backup').TrimEnd('\') + '\'
    if (-not $resolvedBackup.StartsWith($allowedBackupRoot,[StringComparison]::OrdinalIgnoreCase)) {
        throw "Percorso del backup non consentito: $resolvedBackup"
    }
    if ((Get-Item -LiteralPath $resolvedBackup).Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw "Il backup DLL non può essere un collegamento: $resolvedBackup"
    }
    $backupHash = (Get-FileHash -LiteralPath $resolvedBackup -Algorithm SHA256).Hash.ToUpperInvariant()
    if ($backupHash -cne [string]$state.PreviousGacHash) { throw 'Hash del backup DLL non valido.' }
    if ($backupHash -cne $script:QtExpectedBaselineHash) {
        throw "Il backup DLL non coincide con la baseline sicura attesa: $backupHash"
    }

    $resolvedLanguageBackup = $null
    if ([bool]$state.LanguageKeyExisted) {
        $languageBackup = [string]$state.LanguageBackup
        if (-not (Test-Path -LiteralPath $languageBackup)) {
            throw "Backup lingua non trovato: $languageBackup"
        }
        $resolvedLanguageBackup = (Resolve-Path -LiteralPath $languageBackup).Path
        if (-not $resolvedLanguageBackup.StartsWith($allowedBackupRoot,[StringComparison]::OrdinalIgnoreCase)) {
            throw "Percorso del backup lingua non consentito: $resolvedLanguageBackup"
        }
        $languageBackupHash = (Get-FileHash -LiteralPath $resolvedLanguageBackup -Algorithm SHA256).Hash.ToUpperInvariant()
        if ($languageBackupHash -cne [string]$state.LanguageBackupHash) {
            throw 'Hash del backup lingua non valido.'
        }
        if (-not (Test-LanguageRegistryBackup -Path $resolvedLanguageBackup)) {
            throw 'Il backup lingua contiene chiavi non consentite.'
        }
    }

    Install-GacAssembly -Path $resolvedBackup
    Restore-LanguageRegistry -Existed ([bool]$state.LanguageKeyExisted) -BackupFile $resolvedLanguageBackup
    if (-not $NonRiavviareExplorer) { Restart-ExplorerSafely }

    $restored = Get-FileRecord -Path (Get-QTTabBarGacFile).FullName
    if ($restored.SHA256 -cne $backupHash) {
        throw "Ripristino GAC non verificato: $($restored.SHA256)."
    }
    Write-Host "Ripristino completato. SHA-256: $($restored.SHA256)" -ForegroundColor Green
}
finally {
    Exit-QTTabBarMaintenance -Mutex $maintenanceMutex
}
