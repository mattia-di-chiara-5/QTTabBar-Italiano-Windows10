#requires -version 5.1
$ErrorActionPreference = 'Stop'
$language = Join-Path $env:LOCALAPPDATA 'QTTabBar-Italiano\I18N\Lng_QTTabBar_it_IT.xml'
if (-not (Test-Path -LiteralPath $language)) {
    throw 'File lingua non trovato. Esegui RIPARA_SOLO_LINGUA_ITALIANA.cmd.'
}
try { Set-Clipboard -Value $language } catch { $language | clip.exe }
Start-Process explorer.exe -ArgumentList "/select,`"$language`""
Write-Host 'Percorso copiato negli appunti:' -ForegroundColor Green
Write-Host $language
Read-Host 'Premi INVIO per chiudere'
