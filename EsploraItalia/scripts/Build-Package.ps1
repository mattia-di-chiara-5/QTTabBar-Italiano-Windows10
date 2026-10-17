#requires -version 5.1
param([string]$InputDirectory,[string]$OutputDirectory=(Join-Path $PSScriptRoot '..\dist'),[string]$Verifier='gh')
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$origin=Get-Content -LiteralPath (Join-Path $root 'origine.lock.json') -Raw|ConvertFrom-Json
$out=[IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $out -Force|Out-Null
if(!$InputDirectory){$InputDirectory=Join-Path $out '.inputs';New-Item -ItemType Directory -Path $InputDirectory -Force|Out-Null}
$inputs=[IO.Path]::GetFullPath($InputDirectory)
function Get-PinnedFile($name,$url,$expected){
 $file=Join-Path $inputs $name
 if(!(Test-Path -LiteralPath $file)){Invoke-WebRequest -Uri $url -OutFile $file -Headers @{'User-Agent'='EsploraItalia-package'}}
 if((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ne $expected){throw ('Input non corrispondente: '+$name)}
 return $file
}
$binary=Get-PinnedFile 'binary.zip' $origin.BinaryUrl $origin.BinarySHA256
$translation=Get-PinnedFile 'translations.zip' $origin.TranslationUrl $origin.TranslationSHA256
$source=Get-PinnedFile 'source.zip' $origin.SourceUrl $origin.SourceSHA256
foreach($file in @($binary,$translation)){
 $verified=& $Verifier attestation verify $file --repo derceg/explorerplusplus --signer-workflow derceg/explorerplusplus/.github/workflows/build.yml --source-digest $origin.SourceCommit --deny-self-hosted-runners --format json
 if($LASTEXITCODE){throw 'Attestazione crittografica non valida.'}
 if(!($verified -join "`n"|ConvertFrom-Json)){throw 'Esito attestazione assente.'}
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Copy-Entry($archive,$entryName,$destination){
 $zip=[IO.Compression.ZipFile]::OpenRead($archive)
 try{
  $entries=@($zip.Entries|Where-Object {$_.FullName -ceq $entryName})
  if($entries.Count -ne 1 -or $entries[0].Length -gt 32MB){throw ('Voce archivio non valida: '+$entryName)}
  $stream=$entries[0].Open()
  try{$target=[IO.File]::Create($destination);try{$stream.CopyTo($target)}finally{$target.Dispose()}}finally{$stream.Dispose()}
 }finally{$zip.Dispose()}
}
Copy-Entry $binary 'Explorer++.exe' (Join-Path $out 'Explorer++.exe')
if((Get-FileHash (Join-Path $out 'Explorer++.exe')).Hash -ne $origin.ExecutableSHA256){throw 'Eseguibile inatteso.'}
Copy-Entry $binary 'License.txt' (Join-Path $out 'LICENZA-Explorer++.txt')
Copy-Entry $binary 'Readme.txt' (Join-Path $out 'LEGGIMI-Explorer++.txt')
Copy-Entry $binary 'History.txt' (Join-Path $out 'CRONOLOGIA-Explorer++.txt')
$original=Join-Path $inputs 'Explorer++IT-originale.dll'
Copy-Entry $translation 'Explorer++IT.dll' $original
if((Get-FileHash $original).Hash -ne $origin.OriginalItalianSHA256){throw 'Traduzione originale inattesa.'}
$compiler=Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$localizer=Join-Path $inputs 'ResourceLocalizer.exe'
& $compiler /nologo /target:exe /platform:x64 /optimize+ /checked+ /warnaserror+ /r:System.Core.dll /r:System.Runtime.Serialization.dll ('/out:'+$localizer) (Join-Path $root 'src\ResourceLocalizer.cs')
if($LASTEXITCODE){throw 'Compilazione localizzatore fallita.'}
$localized=Join-Path $inputs ('Explorer++IT-'+[Guid]::NewGuid().ToString('N')+'.dll')
& $localizer patch $original $localized (Join-Path $root 'traduzione.json')
if($LASTEXITCODE){throw 'Localizzazione fallita.'}
Move-Item -LiteralPath $localized -Destination (Join-Path $out 'Explorer++IT.dll') -Force
foreach($name in @('config.xml','traduzione.json')){Copy-Item -LiteralPath (Join-Path $root $name) -Destination (Join-Path $out $name) -Force}
Copy-Item -LiteralPath (Join-Path $root 'config.xml') -Destination (Join-Path $out 'PROFILO-RAPIDO.xml') -Force
Copy-Item -LiteralPath (Join-Path $root 'origine.lock.json') -Destination (Join-Path $out 'ORIGINE.json') -Force
Copy-Item -LiteralPath $source -Destination (Join-Path $out 'SORGENTI-ExplorerPlusPlus-adf72c76.zip') -Force
Copy-Item -LiteralPath (Join-Path $root 'src\ResourceLocalizer.cs') -Destination (Join-Path $out 'ResourceLocalizer.cs') -Force
foreach($name in @('SICUREZZA.md','RICERCA_OSINT.md')){Copy-Item -LiteralPath (Join-Path $root ('docs\'+$name)) -Destination (Join-Path $out $name) -Force}
Copy-Item -LiteralPath (Join-Path $root 'README.md') -Destination (Join-Path $out 'LEGGIMI.md') -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Install-PerUser.ps1') -Destination (Join-Path $out 'INSTALLA.ps1') -Force
$files=@('Explorer++.exe','Explorer++IT.dll','config.xml','PROFILO-RAPIDO.xml','ORIGINE.json','traduzione.json','ResourceLocalizer.cs','LICENZA-Explorer++.txt','LEGGIMI-Explorer++.txt','CRONOLOGIA-Explorer++.txt','SORGENTI-ExplorerPlusPlus-adf72c76.zip','LEGGIMI.md','SICUREZZA.md','RICERCA_OSINT.md','INSTALLA.ps1')
$manifest=@(foreach($name in $files){[pscustomobject]@{Name=$name;SHA256=(Get-FileHash -LiteralPath (Join-Path $out $name)).Hash}})
$manifest|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $out 'SHA256SUMS.json') -Encoding UTF8
& (Join-Path $root 'tests\Test-Package.ps1') -PackageDirectory $out -Localizer $localizer
$zip=Join-Path $out 'EsploraItalia-Windows10-x64-v0.1.0-preview.zip'
$paths=@($files|ForEach-Object {Join-Path $out $_})+@((Join-Path $out 'SHA256SUMS.json'))
Compress-Archive -LiteralPath $paths -DestinationPath $zip -Force
Get-FileHash -LiteralPath $zip