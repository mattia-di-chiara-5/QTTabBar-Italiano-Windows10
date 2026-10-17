#requires -version 5.1
param([Parameter(Mandatory=$true)][string]$Localizer,[Parameter(Mandatory=$true)][string]$OriginalDll)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$temp=Join-Path ([IO.Path]::GetTempPath()) ('EsploraItalia-security-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp|Out-Null
try{
 $mapping=Join-Path $root 'traduzione.json'
 $output=Join-Path $temp 'translated.dll'
 $before=(Get-FileHash -LiteralPath $OriginalDll).Hash
 & $Localizer patch $OriginalDll $output $mapping
 if($LASTEXITCODE){throw 'Traduzione valida rifiutata.'}
 & $Localizer verify $output $mapping
 if($LASTEXITCODE){throw 'Rilettura non riuscita.'}
 $map=ConvertFrom-Json -InputObject (Get-Content -LiteralPath $mapping -Raw)
 $map[0].Original+=' INPUT INCOMPATIBILE'
 $bad=Join-Path $temp 'wrong-original.json'
 [IO.File]::WriteAllText($bad,($map|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
 & $Localizer patch $OriginalDll (Join-Path $temp 'must-not-exist.dll') $bad
 if($LASTEXITCODE -eq 0 -or (Test-Path -LiteralPath (Join-Path $temp 'must-not-exist.dll'))){throw 'Testo originale non verificato prima della copia.'}
 $duplicate=Join-Path $temp 'duplicate.json'
 [IO.File]::WriteAllText($duplicate,(@($map[0],$map[0])|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
 & $Localizer patch $OriginalDll (Join-Path $temp 'duplicate.dll') $duplicate
 if($LASTEXITCODE -eq 0){throw 'Identificatori duplicati accettati.'}
 & $Localizer patch $OriginalDll $OriginalDll $mapping
 if($LASTEXITCODE -eq 0 -or (Get-FileHash -LiteralPath $OriginalDll).Hash -ne $before){throw 'La sorgente e stata sovrascritta.'}
 $truncated=Join-Path $temp 'truncated.dll'
 [IO.File]::WriteAllBytes($truncated,[byte[]]@(0x4D,0x5A))
 & $Localizer patch $truncated (Join-Path $temp 'truncated-out.dll') $mapping
 if($LASTEXITCODE -eq 0){throw 'Immagine troncata accettata.'}
 [pscustomobject]@{ValidRoundTrip=$true;WrongOriginalRejected=$true;DuplicateIdsRejected=$true;SourcePreserved=$true;TruncatedImageRejected=$true}
}finally{
 # Only remove this test's freshly created, fixed-prefix temporary directory.
 $resolved=[IO.Path]::GetFullPath($temp)
 $parent=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
 if($resolved.StartsWith($parent,[StringComparison]::OrdinalIgnoreCase) -and (Split-Path $resolved -Leaf) -match '^EsploraItalia-security-[a-f0-9]{32}$'){
  Remove-Item -LiteralPath $resolved -Recurse -Force
 }
}