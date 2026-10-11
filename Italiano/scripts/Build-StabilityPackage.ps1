#requires -version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$UpstreamInstaller,
    [Parameter(Mandatory=$true)][string]$WixDirectory,
    [Parameter(Mandatory=$true)][string]$RollbackMsi,
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '..\dist'),
    [string]$BuildDirectory = (Join-Path $PSScriptRoot '..\build')
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$expected = '2F91AD5B04DE7518C9BDE708768E88BE4EBF8EB92AA3649B1FEED1B3DF239FDF'
if ((Get-FileHash -LiteralPath $UpstreamInstaller -Algorithm SHA256).Hash -ne $expected) {
    throw 'Installer upstream 1.6.3 non corrispondente allo SHA-256 ufficiale.'
}
New-Item -ItemType Directory -Path $BuildDirectory,$OutputDirectory -Force | Out-Null
$BuildDirectory = (Resolve-Path $BuildDirectory).Path
$OutputDirectory = (Resolve-Path $OutputDirectory).Path
$extract = Join-Path $BuildDirectory 'upstream'
& (Join-Path $WixDirectory 'dark.exe') $UpstreamInstaller -x $extract -nologo
if ($LASTEXITCODE -ne 0) { throw 'Estrazione bootstrapper non riuscita.' }
$upstreamMsi = Get-ChildItem $extract -Filter '*.msi' -Recurse | Select-Object -First 1
if (!$upstreamMsi) { throw 'MSI upstream assente.' }
$files = Join-Path $BuildDirectory 'files'
$decompiled = Join-Path $BuildDirectory 'upstream.wxs'
& (Join-Path $WixDirectory 'dark.exe') $upstreamMsi.FullName -x $files -o $decompiled -nologo
if ($LASTEXITCODE -ne 0) { throw 'Estrazione MSI non riuscita.' }
$payload = Join-Path $BuildDirectory 'payload'
New-Item -ItemType Directory -Path $payload -Force | Out-Null
[xml]$upstream = Get-Content $decompiled -Raw
$ns = New-Object Xml.XmlNamespaceManager($upstream.NameTable)
$ns.AddNamespace('w','http://schemas.microsoft.com/wix/2006/wi')
foreach ($file in $upstream.SelectNodes('//w:File',$ns)) {
    Copy-Item -LiteralPath (Join-Path $files ('File\' + $file.Id)) -Destination (Join-Path $payload $file.Name) -Force
}
$candidate = Join-Path $root 'QTTabBar\bin\Release\QTTabBar.dll'
if ([Reflection.AssemblyName]::GetAssemblyName($candidate).Version.ToString() -ne '1.6.3.0') {
    throw 'Identita assembly inattesa: compilare il ramo italiano senza modificare AssemblyVersion.'
}
Copy-Item -LiteralPath $candidate -Destination (Join-Path $payload 'QTTabBar.dll') -Force

# Reuse upstream's COM registration and component GUIDs, but use a standard
# transactional major upgrade and do not delete shared Explorer registry keys.
$source = New-Object Xml.XmlDocument
$source.PreserveWhitespace = $true
$source.Load((Join-Path $root 'Installer\Installer.wxs'))
$ns = New-Object Xml.XmlNamespaceManager($source.NameTable)
$ns.AddNamespace('w','http://schemas.microsoft.com/wix/2006/wi')
$directory = $source.SelectSingleNode('/w:Wix/w:Product/w:Directory',$ns)
foreach ($comment in @($directory.SelectNodes('.//comment()'))) { [void]$comment.ParentNode.RemoveChild($comment) }
foreach ($nativeImage in @($directory.SelectNodes('.//*[local-name()="NativeImage"]'))) { [void]$nativeImage.ParentNode.RemoveChild($nativeImage) }
foreach ($file in $directory.SelectNodes('.//w:File',$ns)) {
    $file.Source = '$(var.PayloadRoot)\' + $file.Name
}
foreach ($key in $directory.SelectNodes('.//w:RegistryKey',$ns)) {
    if ($key.Key -eq 'Software\Microsoft\Internet Explorer\Toolbar') {
        $key.RemoveAttribute('ForceDeleteOnUninstall')
        $key.RemoveAttribute('ForceCreateOnInstall')
    }
}
$directoryXml = $directory.OuterXml.Replace('!(loc.STANDARD_BUTTONS)','Pulsanti QTTabBar').Replace('!(loc.DESKTOP_TOOL)','Strumenti desktop QTTabBar').Replace('!(loc.QTTABBAR_ATUOLOADER)','QTTabBar Autoloader')
$feature = $source.SelectSingleNode('/w:Wix/w:Product/w:Feature',$ns)
foreach ($comment in @($feature.SelectNodes('.//comment()'))) { [void]$comment.ParentNode.RemoveChild($comment) }
$featureXml = $feature.OuterXml
$wxs = @'
<?xml version="1.0" encoding="utf-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
 <?define SkuName="QTTabBar"?>
 <?define ProductVersion="1.6.3.0"?>
 <?define StrongName="QTTabBar, Version=1.6.3.0, Culture=neutral, PublicKeyToken=973461f1cd23d8eb"?>
 <Product Id="{540B7E57-F7A0-4AA5-A362-736892574234}" Name="QTTabBar Italiano 0.6.0 (base 1.6.3)" Language="1040" Version="1.6.5" Manufacturer="QTTabBar - edizione italiana" UpgradeCode="{EC9BAFF7-58FB-40CB-9F67-1C438A7524A5}">
  <Package InstallerVersion="500" Compressed="yes" InstallScope="perMachine" Platform="x64" />
  <MediaTemplate EmbedCab="yes" />
  <!-- No Language filter: the previous MSI is English, this one is Italian. -->
  <Upgrade Id="{EC9BAFF7-58FB-40CB-9F67-1C438A7524A5}">
   <UpgradeVersion Minimum="0.0.0" IncludeMinimum="yes" Maximum="1.6.5" IncludeMaximum="no" MigrateFeatures="yes" Property="OLDQTTABBAR" />
   <UpgradeVersion Minimum="1.6.5" IncludeMinimum="no" OnlyDetect="yes" Property="NEWQTTABBAR" />
  </Upgrade>
  <Condition Message="E gia installata una versione piu recente di QTTabBar.">Installed OR NOT NEWQTTABBAR</Condition>
  <InstallExecuteSequence><RemoveExistingProducts After="InstallInitialize">OLDQTTABBAR</RemoveExistingProducts></InstallExecuteSequence>
  <Property Id="NETFRAMEWORK48"><RegistrySearch Id="NetFx48" Root="HKLM" Key="SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" Name="Release" Type="raw" Win64="yes" /></Property>
  <Condition Message="E richiesto Windows 10 x64 con .NET Framework 4.8.">Installed OR (VersionNT64 AND NETFRAMEWORK48 &gt;= "#528040")</Condition>
  <Property Id="ARPHELPLINK" Value="https://github.com/mattia-di-chiara-5/QTTabBar-Italiano-Windows10" />
  <Property Id="ARPNOREPAIR" Value="1" />
  <!-- Explorer is restarted explicitly by the per-user wrapper, never from MSI. -->
  __DIRECTORY__
  __FEATURE__
 </Product>
</Wix>
'@
$wxs = $wxs.Replace('__DIRECTORY__',$directoryXml).Replace('__FEATURE__',$featureXml)
$sourceFile = Join-Path $BuildDirectory 'Italiano.wxs'
[IO.File]::WriteAllText($sourceFile,$wxs,[Text.UTF8Encoding]::new($false))
$object = Join-Path $BuildDirectory 'Italiano.wixobj'
& (Join-Path $WixDirectory 'candle.exe') -nologo "-dPayloadRoot=$payload" -out $object $sourceFile
if ($LASTEXITCODE -ne 0) { throw 'Compilazione WiX non riuscita.' }
$package = Join-Path $OutputDirectory 'QTTabBar-Italiano-v0.6.0'
New-Item -ItemType Directory -Path $package -Force | Out-Null
$msi = Join-Path $package 'QTTabBar-Italiano-v0.6.0.msi'
& (Join-Path $WixDirectory 'light.exe') -nologo -sice:ICE03 -out $msi $object
if ($LASTEXITCODE -ne 0) { throw 'Creazione MSI non riuscita.' }
foreach ($name in @('Installa-Stabilita.ps1','Ripristina-VersionePrecedente.ps1')) {
    Copy-Item -LiteralPath (Join-Path $root "Italiano\installer\$name") -Destination $package -Force
}
$rollbackDirectory = Join-Path $package 'Rollback'
New-Item -ItemType Directory -Path $rollbackDirectory -Force | Out-Null
if ((Get-FileHash $RollbackMsi).Hash -ne '675C49C0681304CC537D3626AF5794BAA035610DA321A8CC9934A2A67332522E') { throw 'MSI originale per rollback non valido.' }
Copy-Item -LiteralPath $RollbackMsi -Destination (Join-Path $rollbackDirectory 'QTTabBar-Italiano-v0.5.0.msi') -Force
Copy-Item -LiteralPath (Join-Path $root 'Italiano\INSTALLA_STABILITA.cmd') -Destination $package -Force
Copy-Item -LiteralPath (Join-Path $root 'Italiano\RIPRISTINA_VERSIONE_PRECEDENTE.cmd') -Destination $package -Force
Copy-Item -LiteralPath (Join-Path $root 'LICENSE.txt') -Destination $package -Force
Copy-Item -LiteralPath (Join-Path $root 'README_IT.md') -Destination $package -Force
$auditDirectory = Join-Path $package 'Italiano\docs'
New-Item -ItemType Directory -Path $auditDirectory -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'Italiano\docs\AUDIT_PRESTAZIONI_0.6.0.md') -Destination $auditDirectory -Force
$msiHash = (Get-FileHash $msi -Algorithm SHA256).Hash
$scriptPath = Join-Path $package 'Installa-Stabilita.ps1'
$scriptText = [IO.File]::ReadAllText($scriptPath).Replace('__MSI_SHA256__',$msiHash).Replace('__DLL_SHA256__',(Get-FileHash $candidate).Hash)
[IO.File]::WriteAllText($scriptPath,$scriptText,[Text.UTF8Encoding]::new($true))
[IO.File]::WriteAllText((Join-Path $package 'MSI_SHA256.txt'),$msiHash,[Text.UTF8Encoding]::new($false))
$zip = Join-Path $OutputDirectory 'QTTabBar-Italiano-Windows10-v0.6.0.zip'
Compress-Archive -Path (Join-Path $package '*') -DestinationPath $zip -Force
Get-FileHash -LiteralPath $zip,$msi -Algorithm SHA256
