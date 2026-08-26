#requires -version 5.1
$ErrorActionPreference = 'SilentlyContinue'
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptRoot
$Root = $ProjectRoot
. (Join-Path $ScriptRoot 'Common.ps1')
Write-Host 'Riavvio di Esplora file...' -ForegroundColor Cyan
Restart-ExplorerSafely
Write-Host 'Esplora file riavviato.' -ForegroundColor Green
Start-Sleep -Seconds 2
