#requires -version 5.1
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptRoot
$Root = $ProjectRoot
. (Join-Path $ScriptRoot 'Common.ps1')

function Restart-Elevated {
    $powershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    Start-Process -FilePath $powershell -Verb RunAs `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" | Out-Null
}

function Invoke-UninstallEntry {
    param([Parameter(Mandatory=$true)][object]$Entry)

    $name = [string](Get-SafePropertyValue -InputObject $Entry -Name 'DisplayName')
    $command = [string](Get-SafePropertyValue -InputObject $Entry -Name 'QuietUninstallString')
    if ([string]::IsNullOrWhiteSpace($command)) {
        $command = [string](Get-SafePropertyValue -InputObject $Entry -Name 'UninstallString')
    }
    if ([string]::IsNullOrWhiteSpace($command)) {
        throw "Comando di disinstallazione assente per $name."
    }

    if ($command -match '\{[0-9A-Fa-f-]{36}\}') {
        $productCode = $Matches[0]
        $process = Start-Process msiexec.exe `
            -ArgumentList @('/x',$productCode,'/passive','/norestart') `
            -Wait -PassThru
    }
    else {
        $parts = $command -split ' ',2
        $arguments = if ($parts.Count -gt 1) { $parts[1] } else { '' }
        $process = Start-Process $parts[0].Trim('"') -ArgumentList $arguments -Wait -PassThru
    }

    if ($process.ExitCode -notin @(0,1605,1641,3010)) {
        throw "Disinstallazione non riuscita. Codice $($process.ExitCode)."
    }
}

if (-not (Test-Administrator)) {
    Restart-Elevated
    exit 0
}

try {
    Write-Section 'Disinstallazione QTTabBar Italiano'
    Get-Process explorer -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    $entries = @(Get-QTTabBarEntries)
    if ($entries.Count -eq 0) {
        Write-Host 'QTTabBar non risulta installato.' -ForegroundColor Yellow
    }
    else {
        foreach ($entry in $entries) {
            $name = [string](Get-SafePropertyValue -InputObject $entry -Name 'DisplayName')
            $version = [string](Get-SafePropertyValue -InputObject $entry -Name 'DisplayVersion')
            Write-Host ("Rimozione: $name $version").TrimEnd()
            Invoke-UninstallEntry -Entry $entry
        }
        Write-Host 'QTTabBar disinstallato.' -ForegroundColor Green
    }

    Remove-Item (Join-Path $env:LOCALAPPDATA 'QTTabBar-Italiano') `
        -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item 'HKCU:\Software\QTTabBar-Italiano' `
        -Recurse -Force -ErrorAction SilentlyContinue

    Start-Process (Join-Path $env:WINDIR 'explorer.exe')
    Read-Host 'Premi INVIO per chiudere'
}
catch {
    Start-Process (Join-Path $env:WINDIR 'explorer.exe') -ErrorAction SilentlyContinue
    Write-Host "ERRORE: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host 'Premi INVIO per chiudere'
    exit 1
}
