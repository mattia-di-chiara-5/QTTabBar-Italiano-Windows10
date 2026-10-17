#requires -version 5.1
param([Parameter(Mandatory=$true)][string]$PackageDirectory,[Parameter(Mandatory=$true)][string]$Localizer)
$ErrorActionPreference='Stop'
$package=(Resolve-Path -LiteralPath $PackageDirectory).Path
$manifest=@(Get-Content -LiteralPath (Join-Path $package 'SHA256SUMS.json') -Raw|ConvertFrom-Json)
if($manifest.Count -ne 15 -or @($manifest.Name|Sort-Object -Unique).Count -ne 15){throw 'Manifest incompleto o duplicato.'}
foreach($entry in $manifest){
 if($entry.Name -notmatch '^[A-Za-z0-9+._-]+$'){throw 'Percorso non valido nel manifest.'}
 if((Get-FileHash -LiteralPath (Join-Path $package $entry.Name)).Hash -ne $entry.SHA256){throw ('Hash pacchetto: '+$entry.Name)}
}
$core=Join-Path $package 'Explorer++.exe'
if((Get-FileHash -LiteralPath $core).Hash -ne 'BB1FD439010C97FEFA78A121524A1828765B9B7050181A567A80603CC785A967'){throw 'Core diverso da quello attestato.'}
if([Diagnostics.FileVersionInfo]::GetVersionInfo($core).FileVersion -ne '1.5.0.2844'){throw 'Versione core non prevista.'}
& $Localizer verify (Join-Path $package 'Explorer++IT.dll') (Join-Path $package 'traduzione.json')
if($LASTEXITCODE){throw 'Risorse italiane non corrispondenti.'}
$settings=New-Object Xml.XmlReaderSettings;$settings.DtdProcessing=[Xml.DtdProcessing]::Prohibit;$settings.XmlResolver=$null;$settings.MaxCharactersInDocument=32768
$reader=[Xml.XmlReader]::Create((Join-Path $package 'config.xml'),$settings)
try{$xml=New-Object Xml.XmlDocument;$xml.XmlResolver=$null;$xml.Load($reader)}finally{$reader.Dispose()}
$required=@{Language='16';Theme='2';IconTheme='2';ShowFilePreviews='no';ShowFolderSizes='no';DisableFolderSizesNetworkRemovable='yes';ReplaceExplorerMode='0';StartupMode='2';ShowInfoTips='no';HandleZipFiles='yes'}
foreach($name in $required.Keys){$nodes=$xml.SelectNodes('/ExplorerPlusPlus/Settings/Setting[@name="'+$name+'"]');if($nodes.Count -ne 1 -or $nodes[0].InnerText -cne $required[$name]){throw ('Profilo non conforme alla configurazione dichiarata: '+$name)}}
Get-ChildItem (Split-Path $PSScriptRoot -Parent) -Recurse -Filter *.ps1 -File|ForEach-Object {
 $tokens=$null;$errors=$null;[void][Management.Automation.Language.Parser]::ParseFile($_.FullName,[ref]$tokens,[ref]$errors)
 if($errors.Count){throw ($errors|Out-String)}
}
[pscustomobject]@{PackageIntegrity=$true;AttestedCoreUnchanged=$true;ItalianResources=$true;SafeProfile=$true;PowerShellSyntax=$true}