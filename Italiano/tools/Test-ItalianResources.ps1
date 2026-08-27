#requires -version 5.1
[CmdletBinding()]
param([string]$RepositoryRoot)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
    $RepositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}
$basePath = Join-Path $RepositoryRoot 'QTTabBar\Resources_String.resx'
$italianPath = Join-Path $RepositoryRoot 'QTTabBar\Resources_String_it_IT.resx'
$sourcePath = Join-Path $RepositoryRoot 'QTTabBar\Resources_String_it_IT.cs'
$projectPath = Join-Path $RepositoryRoot 'QTTabBar\QTTabBar.csproj'

[xml]$base = Get-Content -LiteralPath $basePath -Raw
[xml]$italian = Get-Content -LiteralPath $italianPath -Raw
$baseMap = @{}
$italianMap = @{}
foreach ($node in $base.root.data) { $baseMap[[string]$node.name] = [string]$node.value }
foreach ($node in $italian.root.data) { $italianMap[[string]$node.name] = [string]$node.value }

if ($baseMap.Count -ne 42 -or $italianMap.Count -ne 42) {
    throw "Numero chiavi inatteso: base=$($baseMap.Count), italiano=$($italianMap.Count)."
}
$missing = @($baseMap.Keys | Where-Object { -not $italianMap.ContainsKey($_) })
$extra = @($italianMap.Keys | Where-Object { -not $baseMap.ContainsKey($_) })
if ($missing.Count -or $extra.Count) {
    throw "Contratto chiavi non rispettato. Mancanti=$($missing -join ','); extra=$($extra -join ',')."
}

$segments = 0
foreach ($key in $baseMap.Keys) {
    $baseSegments = @([regex]::Split($baseMap[$key],';'))
    $italianSegments = @([regex]::Split($italianMap[$key],';'))
    $segments += $baseSegments.Count
    if ($baseSegments.Count -ne $italianSegments.Count) {
        throw "Cardinalità non valida per ${key}: $($baseSegments.Count)/$($italianSegments.Count)."
    }
    for ($i = 0; $i -lt $baseSegments.Count; $i++) {
        $basePlaceholders = @([regex]::Matches($baseSegments[$i],'\{\d+\}') | ForEach-Object Value | Sort-Object -Unique)
        $itPlaceholders = @([regex]::Matches($italianSegments[$i],'\{\d+\}') | ForEach-Object Value | Sort-Object -Unique)
        if (($basePlaceholders -join ',') -cne ($itPlaceholders -join ',')) {
            throw "Placeholder non validi per $key segmento $i."
        }
        if ([string]::IsNullOrEmpty($baseSegments[$i]) -ne [string]::IsNullOrEmpty($italianSegments[$i])) {
            throw "Segmento vuoto non allineato per $key segmento $i."
        }
    }
}
if ($segments -ne 489) { throw "Numero segmenti inatteso: $segments." }

$source = Get-Content -LiteralPath $sourcePath -Raw
$properties = @([regex]::Matches($source,'internal static string\s+([A-Za-z0-9_]+)\s*\{') | ForEach-Object {
    $_.Groups[1].Value
} | Sort-Object -Unique)
if ($properties.Count -ne 42) { throw "Proprietà C# italiane inattese: $($properties.Count)." }
if ($properties -contains 'Language' -or $properties -notcontains 'Version_LangFile') {
    throw 'Contratto proprietà C# non valido.'
}

$project = Get-Content -LiteralPath $projectPath -Raw
foreach ($marker in @('Resources_String_it_IT.cs','Resources_String_it_IT.resx')) {
    if ($project -notmatch [regex]::Escape($marker)) { throw "Riferimento progetto assente: $marker." }
}

$hash = (Get-FileHash -LiteralPath $italianPath -Algorithm SHA256).Hash.ToUpperInvariant()
if ($hash -cne 'C0AB7A24941DD212015C5E60CF8AD870F69C4BBF686F789AEDF899CE3070D393') {
    throw "Hash RESX italiano inatteso: $hash."
}
Write-Host "PASS: 42 chiavi, 489 segmenti, placeholder/empty parity, SHA-256 $hash" -ForegroundColor Green
