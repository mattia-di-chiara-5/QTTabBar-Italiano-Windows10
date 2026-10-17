#requires -version 5.1
param([string]$PackageDirectory=$PSScriptRoot,[switch]$DesktopShortcut)
$ErrorActionPreference='Stop'
$package=(Resolve-Path -LiteralPath $PackageDirectory).Path
if((Get-Item -LiteralPath (Join-Path $package 'SHA256SUMS.json')).Length -gt 32768){throw 'Manifest troppo grande.'}
$manifest=@(Get-Content -LiteralPath (Join-Path $package 'SHA256SUMS.json') -Raw|ConvertFrom-Json)
$allowed=@('Explorer++.exe','Explorer++IT.dll','config.xml','PROFILO-RAPIDO.xml','ORIGINE.json','traduzione.json','ResourceLocalizer.cs','LICENZA-Explorer++.txt','LEGGIMI-Explorer++.txt','CRONOLOGIA-Explorer++.txt','SORGENTI-ExplorerPlusPlus-adf72c76.zip','LEGGIMI.md','SICUREZZA.md','RICERCA_OSINT.md','INSTALLA.ps1')
if($manifest.Count -ne $allowed.Count){throw 'Manifest non valido.'}
foreach($name in $allowed){
 $entry=@($manifest|Where-Object {$_.Name -ceq $name})
 if($entry.Count -ne 1 -or $entry[0].SHA256 -notmatch '^[A-Fa-f0-9]{64}$'){throw 'Voce manifest non valida.'}
 if($name -ne 'config.xml' -and (Get-FileHash -LiteralPath (Join-Path $package $name)).Hash -ne $entry[0].SHA256){throw ('Hash non corrispondente: '+$name)}
}
if((Get-FileHash -LiteralPath (Join-Path $package 'Explorer++.exe')).Hash -ne 'BB1FD439010C97FEFA78A121524A1828765B9B7050181A567A80603CC785A967'){throw 'Core ufficiale non corrispondente.'}
$destination=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'Programs\EsploraItalia\0.1.0-preview'
# Preflight all immutable destinations before copying anything.
foreach($name in $allowed){
 $target=Join-Path $destination $name
 if($name -ne 'config.xml' -and (Test-Path -LiteralPath $target)){
  $expected=($manifest|Where-Object {$_.Name -ceq $name}).SHA256
  if((Get-FileHash -LiteralPath $target).Hash -ne $expected){throw ('Installazione esistente differente: '+$name)}
 }
}
New-Item -ItemType Directory -Path $destination -Force|Out-Null
foreach($name in $allowed){
 $target=Join-Path $destination $name
 if(Test-Path -LiteralPath $target){continue}
 if($name -eq 'config.xml'){
  $settings=New-Object Xml.XmlReaderSettings;$settings.DtdProcessing=[Xml.DtdProcessing]::Prohibit;$settings.XmlResolver=$null;$settings.MaxCharactersInDocument=32768
  $reader=[Xml.XmlReader]::Create((Join-Path $package 'PROFILO-RAPIDO.xml'),$settings)
  try{$xml=New-Object Xml.XmlDocument;$xml.XmlResolver=$null;$xml.Load($reader)}finally{$reader.Dispose()}
  $node=$xml.SelectSingleNode('/ExplorerPlusPlus/Settings/Setting[@name="NewTabDirectory"]')
  if(!$node){throw 'Profilo non valido.'}
  $node.InnerText=[Environment]::GetFolderPath('UserProfile');$xml.Save($target)
 }else{Copy-Item -LiteralPath (Join-Path $package $name) -Destination $target}
}
foreach($name in $allowed|Where-Object {$_ -ne 'config.xml'}){
 if((Get-FileHash -LiteralPath (Join-Path $destination $name)).Hash -ne ($manifest|Where-Object {$_.Name -ceq $name}).SHA256){throw 'Verifica dopo la copia fallita.'}
}
$shell=New-Object -ComObject WScript.Shell
$links=@((Join-Path ([Environment]::GetFolderPath('Programs')) 'Esplora Italia.lnk'))
if($DesktopShortcut){$links+=(Join-Path ([Environment]::GetFolderPath('DesktopDirectory')) 'Esplora Italia.lnk')}
foreach($link in $links){
 if(Test-Path -LiteralPath $link){Copy-Item -LiteralPath $link -Destination ($link+'.precedente-'+(Get-Date -Format yyyyMMddHHmmss))}
 $shortcut=$shell.CreateShortcut($link);$shortcut.TargetPath=Join-Path $destination 'Explorer++.exe';$shortcut.Arguments='--language IT';$shortcut.WorkingDirectory=$destination;$shortcut.Description='Esplora Italia - Explorer++ con profilo rapido italiano';$shortcut.Save()
}
[pscustomobject]@{InstalledPath=$destination;Version='0.1.0-preview';CoreVersion='1.5.0.2844';Shortcuts=$links}