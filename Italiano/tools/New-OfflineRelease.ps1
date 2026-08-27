#requires -version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$CandidateDirectory,
    [Parameter(Mandatory=$true)][string]$BaselineInstallerZip,
    [string]$OutputDirectory = (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'dist')
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$candidatePath = Join-Path $CandidateDirectory 'QTTabBar.dll'
$candidateHash = (Get-FileHash -LiteralPath $candidatePath -Algorithm SHA256).Hash.ToUpperInvariant()
if ($candidateHash -cne '77F1351E8672FD5C8EBDC49C9A28E4D66EA267BC7FF8B2BF872AADD62EBA7B36') {
    throw "RC1 non valida: $candidateHash."
}

$zipHash = (Get-FileHash -LiteralPath $BaselineInstallerZip -Algorithm SHA256).Hash.ToUpperInvariant()
if ($zipHash -cne '913A3F36B47251CD4B7D70EB94D2B05DCAC703269104483E1CA1502ABB5D40C3') {
    throw "Archivio installer baseline non valido: $zipHash."
}

$stage = Join-Path $env:TEMP ("QTTabBar-Italiano-v0.4.0_" + [Guid]::NewGuid().ToString('N'))
$package = Join-Path $stage 'QTTabBar-Italiano-Windows10-v0.4.0'
$payload = Join-Path $package 'Payload'
New-Item -ItemType Directory -Path $payload,$OutputDirectory -Force | Out-Null

try {
    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'Italiano\installer\Common.ps1') -Destination $package
    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'Italiano\installer\Install-QTTabBarItaliano.ps1') -Destination $package
    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'Italiano\installer\Restore-QTTabBarOriginale.ps1') -Destination $package
    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'Italiano\installer\INSTALLA_QTTABBAR_ITALIANO.cmd') -Destination $package
    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'Italiano\installer\RIPRISTINA_QTTABBAR_ORIGINALE.cmd') -Destination $package
    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'Italiano\release\RELEASE_NOTES_v0.4.0.md') -Destination $package
    Copy-Item -LiteralPath $candidatePath -Destination $payload

    $extract = Join-Path $stage 'baseline'
    Expand-Archive -LiteralPath $BaselineInstallerZip -DestinationPath $extract
    $msi = @(Get-ChildItem -LiteralPath $extract -Filter '*.msi' -File -Recurse)
    if ($msi.Count -ne 1) { throw "Atteso un MSI nella baseline; rilevati $($msi.Count)." }
    $msiHash = (Get-FileHash -LiteralPath $msi[0].FullName -Algorithm SHA256).Hash.ToUpperInvariant()
    if ($msiHash -cne 'AAE4F2BEC2F4CA0EDE488638B9F31543B7CFCBFC90F1C6DDB74F5FB47B890287') {
        throw "MSI baseline non valido: $msiHash."
    }
    Copy-Item -LiteralPath $msi[0].FullName -Destination (Join-Path $payload 'QTTabBar.Setup_v1.5.6-beta.1_en.2024.msi')

    $hashLines = foreach ($file in @(Get-ChildItem -LiteralPath $package -File -Recurse | Sort-Object FullName)) {
        $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToUpperInvariant()
        $relative = $file.FullName.Substring($package.Length + 1)
        "$hash  $relative"
    }
    [IO.File]::WriteAllText((Join-Path $package 'SHA256SUMS.txt'),(($hashLines -join [Environment]::NewLine) + [Environment]::NewLine),(New-Object Text.UTF8Encoding($false)))

    $outputZip = Join-Path $OutputDirectory 'QTTabBar-Italiano-Windows10-v0.4.0.zip'
    $temporaryZip = Join-Path $OutputDirectory ("QTTabBar-Italiano-Windows10-v0.4.0_" + [Guid]::NewGuid().ToString('N') + '.tmp.zip')
    Compress-Archive -LiteralPath $package -DestinationPath $temporaryZip -CompressionLevel Optimal
    if (Test-Path -LiteralPath $outputZip) {
        [IO.File]::Copy($temporaryZip,$outputZip,$true)
        Remove-Item -LiteralPath $temporaryZip -Force
    }
    else {
        [IO.File]::Move($temporaryZip,$outputZip)
    }
    $outputHash = (Get-FileHash -LiteralPath $outputZip -Algorithm SHA256).Hash.ToUpperInvariant()
    Write-Host "Release creata: $outputZip" -ForegroundColor Green
    Write-Host "SHA-256: $outputHash" -ForegroundColor Green
}
finally {
    if (Test-Path -LiteralPath $stage) {
        $resolvedTemp = (Resolve-Path -LiteralPath $env:TEMP).Path.TrimEnd('\')
        $resolvedStage = (Resolve-Path -LiteralPath $stage).Path
        if (-not $resolvedStage.StartsWith($resolvedTemp + '\',[StringComparison]::OrdinalIgnoreCase)) {
            throw "Directory temporanea non sicura: $resolvedStage"
        }
        Remove-Item -LiteralPath $resolvedStage -Recurse -Force
    }
}
