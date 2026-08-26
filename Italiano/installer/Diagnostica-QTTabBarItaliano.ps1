#requires -version 5.1
$ErrorActionPreference = 'SilentlyContinue'
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptRoot
$Root = $ProjectRoot
. (Join-Path $ScriptRoot 'Common.ps1')

Write-Section 'Diagnostica QTTabBar Italiano v0.3.0'
$windows = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$entries = @(Get-QTTabBarEntries)
$language = Join-Path $env:LOCALAPPDATA 'QTTabBar-Italiano\I18N\Lng_QTTabBar_it_IT.xml'

Write-Host "Sistema: $([string](Get-SafePropertyValue -InputObject $windows -Name 'ProductName')) $([string](Get-SafePropertyValue -InputObject $windows -Name 'DisplayVersion'))"
Write-Host "Build: $([string](Get-SafePropertyValue -InputObject $windows -Name 'CurrentBuildNumber'))"
Write-Host "Architettura x64: $([Environment]::Is64BitOperatingSystem)"
Write-Host "QTTabBar installato: $($entries.Count -gt 0)"
foreach ($entry in $entries) {
    $name = [string](Get-SafePropertyValue -InputObject $entry -Name 'DisplayName')
    $version = [string](Get-SafePropertyValue -InputObject $entry -Name 'DisplayVersion')
    Write-Host ("  - $name $version").TrimEnd()
}
Write-Host "File italiano presente: $(Test-Path -LiteralPath $language)"
Write-Host "Percorso lingua: $language"

if (Test-Path -LiteralPath $language) {
    try {
        $result = Test-QTLanguageFile -Path $language
        Write-Host "XML italiano valido: True" -ForegroundColor Green
        Write-Host "Sezioni XML: $($result.Sections)"
        Write-Host "SHA-256: $($result.SHA256)"
    }
    catch {
        Write-Host "XML italiano valido: False" -ForegroundColor Red
        Write-Host $_.Exception.Message
    }
}

Write-Host ''
Write-Host 'Nota: l attivazione della lingua viene salvata internamente da QTTabBar' -ForegroundColor Yellow
Write-Host 'quando si preme Apply nelle sue Opzioni; non viene forzata con chiavi non documentate.'
Write-Host "Log eccezioni QTTabBar: $(Join-Path $env:APPDATA 'QTTabBar\QTTabBarException.log')"
Read-Host 'Premi INVIO per chiudere'
