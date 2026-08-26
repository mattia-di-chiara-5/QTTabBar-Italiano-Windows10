#requires -version 5.1
$ErrorActionPreference = 'Stop'
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptRoot
$ForkRoot = Split-Path -Parent $ProjectRoot
$Root = $ProjectRoot
. (Join-Path $ScriptRoot 'Common.ps1')

try {
    Write-Section 'QTTabBar Italiano - riparazione della lingua v0.3.0'

    $entries = @(Get-QTTabBarEntries)
    if ($entries.Count -eq 0) {
        throw 'QTTabBar non risulta installato. Esegui INSTALLA_O_RIPARA_QTTABBAR_ITALIANO.cmd.'
    }

    foreach ($entry in $entries) {
        $name = [string](Get-SafePropertyValue -InputObject $entry -Name 'DisplayName')
        $version = [string](Get-SafePropertyValue -InputObject $entry -Name 'DisplayVersion')
        Write-Host ("Rilevato: $name $version").TrimEnd() -ForegroundColor Green
    }

    $source = Join-Path $ForkRoot 'I18N\Lng_QTTabBar_it_IT.xml'
    $result = Copy-ItalianLanguageFile -Source $source -OpenFolder

    Write-Host ''
    Write-Host 'File italiano validato e copiato correttamente.' -ForegroundColor Green
    Write-Host "Percorso: $($result.Target)" -ForegroundColor White
    Write-Host "SHA-256: $($result.SHA256)"
    Write-Host 'Il percorso e stato copiato negli appunti.' -ForegroundColor Green
    Write-Host ''
    Write-Host 'Ora completa questi passaggi in Esplora file:' -ForegroundColor Yellow
    Write-Host '1. Visualizza > Opzioni > QTTabBar, se la barra non e ancora visibile.'
    Write-Host '2. Clic destro sulla barra delle schede > QTTabBar Options.'
    Write-Host '3. Language > Use language file.'
    Write-Host '4. Incolla il percorso dagli appunti oppure scegli il file evidenziato.'
    Write-Host '5. Apply > OK.'
    Write-Host '6. Se non cambia subito, esegui RIAVVIA_ESPLORA_FILE.cmd.'
    Read-Host 'Premi INVIO per chiudere'
}
catch {
    Write-Host "ERRORE: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host 'Premi INVIO per chiudere'
    exit 1
}
