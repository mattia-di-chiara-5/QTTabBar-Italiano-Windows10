#requires -version 5.1
param([Parameter(Mandatory=$true)][string]$PackageDirectory,[Parameter(Mandatory=$true)][string]$Localizer)
$ErrorActionPreference='Stop'
$package=(Resolve-Path -LiteralPath $PackageDirectory).Path
$manifest=ConvertFrom-Json -InputObject (Get-Content -LiteralPath (Join-Path $package 'SHA256SUMS.json') -Raw)
if($manifest.Count -ne 19 -or @($manifest.Name|Sort-Object -Unique).Count -ne 19){throw 'Manifest incompleto o duplicato.'}
foreach($entry in $manifest){
 if($entry.Name -notmatch '^[A-Za-z0-9+._-]+$'){throw 'Percorso non valido nel manifest.'}
 if((Get-FileHash -LiteralPath (Join-Path $package $entry.Name)).Hash -ne $entry.SHA256){throw ('Hash pacchetto: '+$entry.Name)}
}
$core=Join-Path $package 'Explorer++.exe'
if((Get-FileHash -LiteralPath $core).Hash -ne '60DB6409C66282B6545DD83B115A37AEDDA43C16EF77809377C78F96E569E1BB'){throw 'Core diverso da quello attestato.'}
if([Diagnostics.FileVersionInfo]::GetVersionInfo($core).FileVersion -ne '1.5.0.2844'){throw 'Versione core non prevista.'}
& $Localizer verify (Join-Path $package 'Explorer++IT.dll') (Join-Path $package 'traduzione.json')
if($LASTEXITCODE){throw 'Risorse italiane non corrispondenti.'}
$settings=New-Object Xml.XmlReaderSettings;$settings.DtdProcessing=[Xml.DtdProcessing]::Prohibit;$settings.XmlResolver=$null;$settings.MaxCharactersInDocument=32768
$reader=[Xml.XmlReader]::Create((Join-Path $package 'config.xml'),$settings)
try{$xml=New-Object Xml.XmlDocument;$xml.XmlResolver=$null;$xml.Load($reader)}finally{$reader.Dispose()}
$testSettings=New-Object Xml.XmlReaderSettings;$testSettings.DtdProcessing=[Xml.DtdProcessing]::Prohibit;$testSettings.XmlResolver=$null;$testSettings.MaxCharactersInDocument=4194304
$testReader=[Xml.XmlReader]::Create((Join-Path $package 'TEST-NATIVI.xml'),$testSettings)
try{$testXml=New-Object Xml.XmlDocument;$testXml.XmlResolver=$null;$testXml.Load($testReader)}finally{$testReader.Dispose()}
$summary=$testXml.DocumentElement
if($summary.LocalName -ne 'testsuites' -or $summary.GetAttribute('tests') -ne '864' -or $summary.GetAttribute('failures') -ne '0' -or $summary.GetAttribute('errors') -ne '0'){throw 'Risultati test nativi non corrispondenti.'}
if(!$testXml.SelectSingleNode('/testsuites/testsuite[@name="ComStaThreadPoolExecutorTest"]/testcase[@name="RepeatedConstructionRunsTasksAndStops"]')){throw 'Stress test nativo assente.'}
$required=@{Language='16';Theme='2';IconTheme='2';ShowFilePreviews='no';ShowFolderSizes='no';DisableFolderSizesNetworkRemovable='yes';ReplaceExplorerMode='0';StartupMode='2';ShowInfoTips='no';HandleZipFiles='yes'}
foreach($name in $required.Keys){$nodes=$xml.SelectNodes('/ExplorerPlusPlus/Settings/Setting[@name="'+$name+'"]');if($nodes.Count -ne 1 -or $nodes[0].InnerText -cne $required[$name]){throw ('Profilo non conforme alla configurazione dichiarata: '+$name)}}
Get-ChildItem (Split-Path $PSScriptRoot -Parent) -Recurse -Filter *.ps1 -File|ForEach-Object {
 $tokens=$null;$errors=$null;[void][Management.Automation.Language.Parser]::ParseFile($_.FullName,[ref]$tokens,[ref]$errors)
 if($errors.Count){throw ($errors|Out-String)}
}
[pscustomobject]@{PackageIntegrity=$true;AttestedFixedCore=$true;NativeTests864=$true;ItalianResources=$true;SafeProfile=$true;PowerShellSyntax=$true}