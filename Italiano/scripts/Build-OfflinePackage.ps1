#requires -version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$UpstreamZip,
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '..\dist')
)

$ErrorActionPreference = 'Stop'
$expectedArchiveHash = '913A3F36B47251CD4B7D70EB94D2B05DCAC703269104483E1CA1502ABB5D40C3'
$expectedMsiHash = 'AAE4F2BEC2F4CA0EDE488638B9F31543B7CFCBFC90F1C6DDB74F5FB47B890287'

$archiveHash = (Get-FileHash -LiteralPath $UpstreamZip -Algorithm SHA256).Hash
if ($archiveHash -cne $expectedArchiveHash) {
    throw "Hash archivio non valido: $archiveHash"
}

Write-Host "Archivio upstream verificato." -ForegroundColor Green
Write-Host "SHA-256 archivio: $archiveHash"
Write-Host "SHA-256 MSI atteso: $expectedMsiHash"
Write-Host "Per la v0.3.0 usare come release asset il pacchetto offline già validato."
