#requires -version 5.1
[CmdletBinding()]
param(
    [string]$CandidatePath = "$env:LOCALAPPDATA\QTTabBar-Italiano\Candidates\v0.4.0-RC1_20260826_125021\QTTabBar.dll",
    [string]$OutputRoot = "$env:LOCALAPPDATA\QTTabBar-Italiano\Snapshots"
)

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'installer\Common.ps1')

$candidate = Get-FileRecord -Path $CandidatePath
if ($candidate.SHA256 -cne $script:QtExpectedCandidateHash) {
    throw "Hash RC1 non valido: $($candidate.SHA256)."
}

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$snapshot = Join-Path $OutputRoot "Stage4.0.2_$stamp"
$files = Join-Path $snapshot 'files'
$registry = Join-Path $snapshot 'registry'
New-Item -ItemType Directory -Path $files,$registry -Force | Out-Null

$gacRecords = @()
foreach ($gac in @(Get-QTTabBarGacFiles | Sort-Object FullName -Unique)) {
    $record = Get-FileRecord -Path $gac.FullName
    $copy = Join-Path $files ("GAC_" + $gac.Directory.Name + "_QTTabBar.dll")
    Copy-Item -LiteralPath $gac.FullName -Destination $copy -Force
    $gacRecords += $record
}

$languageKey = 'HKCU:\Software\QTTabBar\Config\Lang'
$language = $null
if (Test-Path -LiteralPath $languageKey) {
    $language = Get-ItemProperty -LiteralPath $languageKey
    [void](Export-RegistryKey -NativePath 'HKCU\Software\QTTabBar\Config\Lang' -Destination (Join-Path $registry 'HKCU_QTTabBar_Config_Lang.reg'))
}

$uninstall = foreach ($entry in @(Get-QTTabBarEntries)) {
    [pscustomobject]@{
        DisplayName = [string](Get-SafePropertyValue $entry 'DisplayName' '')
        DisplayVersion = [string](Get-SafePropertyValue $entry 'DisplayVersion' '')
        Publisher = [string](Get-SafePropertyValue $entry 'Publisher' '')
        UninstallString = [string](Get-SafePropertyValue $entry 'UninstallString' '')
        RegistryPath = [string](Get-SafePropertyValue $entry 'PSPath' '')
    }
}

$clsids = @(
    '{D2BF470E-ED1C-487F-A333-2BD8835EB6CE}',
    '{D2BF470E-ED1C-487F-A666-2BD8835EB6CE}',
    '{D2BF470E-ED1C-487F-A555-2BD8835EB6CE}',
    '{D2BF470E-ED1C-487F-A777-2BD8835EB6CE}'
)
$com = foreach ($clsid in $clsids) {
    $path = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\$clsid\InprocServer32"
    if (Test-Path -LiteralPath $path) {
        $item = Get-ItemProperty -LiteralPath $path
        [pscustomobject]@{
            CLSID = $clsid
            Class = [string](Get-SafePropertyValue $item 'Class' '')
            Assembly = [string](Get-SafePropertyValue $item 'Assembly' '')
            RuntimeVersion = [string](Get-SafePropertyValue $item 'RuntimeVersion' '')
        }
    }
}

$report = [ordered]@{
    Stage = '4.0.2'
    Created = (Get-Date).ToString('o')
    Candidate = $candidate
    Gac = $gacRecords
    ExplorerPids = @(Get-Process explorer -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)
    LanguageKeyExisted = (Test-Path -LiteralPath $languageKey)
    Language = $(if ($null -eq $language) { $null } else {
        [ordered]@{
            UseLangFile = Get-SafePropertyValue $language 'UseLangFile'
            LangFile = Get-SafePropertyValue $language 'LangFile'
            BuiltInLang = Get-SafePropertyValue $language 'BuiltInLang'
            BuiltInLangSelectedIndex = Get-SafePropertyValue $language 'BuiltInLangSelectedIndex'
        }
    })
    Uninstall = @($uninstall)
    Com = @($com)
}
Write-Utf8NoBom -Path (Join-Path $snapshot 'snapshot.json') -Text ($report | ConvertTo-Json -Depth 8)

$hashLines = foreach ($file in @(Get-ChildItem -LiteralPath $snapshot -File -Recurse | Sort-Object FullName)) {
    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToUpperInvariant()
    $relative = $file.FullName.Substring($snapshot.Length + 1)
    "$hash  $relative"
}
Write-Utf8NoBom -Path (Join-Path $snapshot 'SHA256SUMS.txt') -Text (($hashLines -join [Environment]::NewLine) + [Environment]::NewLine)
Write-Utf8NoBom -Path (Join-Path $snapshot 'COMPLETE') -Text ('Stage 4.0.2 snapshot complete' + [Environment]::NewLine)

Write-Host 'STAGE 4.0.2 SNAPSHOT: SUPERATO' -ForegroundColor Green
Write-Host $snapshot -ForegroundColor Green
