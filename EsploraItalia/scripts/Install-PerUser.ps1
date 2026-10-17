#requires -version 5.1
param([string]$PackageDirectory=$PSScriptRoot,[switch]$DesktopShortcut)
$ErrorActionPreference='Stop'
$package=(Resolve-Path -LiteralPath $PackageDirectory).Path
if((Get-Item -LiteralPath (Join-Path $package 'SHA256SUMS.json')).Length -gt 32768){throw 'Manifest troppo grande.'}
$manifest=ConvertFrom-Json -InputObject (Get-Content -LiteralPath (Join-Path $package 'SHA256SUMS.json') -Raw)
$allowed=@('Explorer++.exe','Explorer++IT.dll','config.xml','PROFILO-RAPIDO.xml','ORIGINE.json','traduzione.json','ResourceLocalizer.cs','LICENZA-Explorer++.txt','LEGGIMI-Explorer++.txt','CRONOLOGIA-Explorer++.txt','SORGENTI-ExplorerPlusPlus-adf72c76.zip','LEGGIMI.md','SICUREZZA.md','RICERCA_OSINT.md','DIPENDENZE.md','COLLAUDO.md','CORE-FIXES.patch','TEST-NATIVI.xml','INSTALLA.ps1')
if($manifest.Count -ne $allowed.Count){throw 'Manifest non valido.'}
foreach($name in $allowed){
 $entry=@($manifest|Where-Object {$_.Name -ceq $name})
 if($entry.Count -ne 1 -or $entry[0].SHA256 -notmatch '^[A-Fa-f0-9]{64}$'){throw 'Voce manifest non valida.'}
 if($name -ne 'config.xml' -and (Get-FileHash -LiteralPath (Join-Path $package $name)).Hash -ne $entry[0].SHA256){throw ('Hash non corrispondente: '+$name)}
}
if((Get-FileHash -LiteralPath (Join-Path $package 'Explorer++.exe')).Hash -ne '60DB6409C66282B6545DD83B115A37AEDDA43C16EF77809377C78F96E569E1BB'){throw 'Core corretto non corrispondente.'}
$destination=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'Programs\EsploraItalia\0.2.0-preview'
# Refuse redirected installation directories, particularly when called from an elevated shell.
$ancestor=$destination
while($ancestor){
 if(Test-Path -LiteralPath $ancestor){
  $item=Get-Item -LiteralPath $ancestor -Force
  if(!$item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'Destinazione non sicura: cartella reindirizzata o non valida.'}
 }
 $parent=Split-Path $ancestor -Parent
 if($parent -eq $ancestor){break}
 $ancestor=$parent
}
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
Copy-Item -LiteralPath (Join-Path $package 'SHA256SUMS.json') -Destination (Join-Path $destination 'SHA256SUMS.json') -Force
$shell=New-Object -ComObject WScript.Shell
$links=@((Join-Path ([Environment]::GetFolderPath('Programs')) 'Esplora Italia.lnk'))
if($DesktopShortcut){$links+=(Join-Path ([Environment]::GetFolderPath('DesktopDirectory')) 'Esplora Italia.lnk')}
foreach($link in $links){
 if(Test-Path -LiteralPath $link){Copy-Item -LiteralPath $link -Destination ($link+'.precedente-'+(Get-Date -Format yyyyMMddHHmmss))}
 $shortcut=$shell.CreateShortcut($link);$shortcut.TargetPath=Join-Path $destination 'Explorer++.exe';$shortcut.Arguments='--language IT';$shortcut.WorkingDirectory=$destination;$shortcut.Description='Esplora Italia - Explorer++ con profilo rapido italiano';$shortcut.Save()
}
[pscustomobject]@{InstalledPath=$destination;Version='0.2.0-preview';CoreVersion='1.5.0.2844';Shortcuts=$links}