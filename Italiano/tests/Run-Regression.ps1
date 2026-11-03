#requires -version 5.1
param([string]$Dll = (Join-Path $PSScriptRoot '..\..\QTTabBar\bin\Release\QTTabBar.dll'))
$ErrorActionPreference = 'Stop'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$directory = [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($Dll))
$isolated = Join-Path $directory ('stability-test-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $isolated | Out-Null
foreach ($file in @('QTTabBar.dll','QTPluginLib.dll','BandObjectLib.dll','Interop.SHDocVw.dll')) {
    Copy-Item -LiteralPath (Join-Path $directory $file) -Destination $isolated
}
$output = Join-Path $isolated 'StabilityRegression.exe'
& $compiler /nologo /r:System.Drawing.dll /r:System.Windows.Forms.dll "/out:$output" (Join-Path $PSScriptRoot 'StabilityRegression.cs')
if ($LASTEXITCODE -ne 0) { throw 'Compilazione test non riuscita.' }
$devConfig = '<configuration><runtime><developmentMode developerInstallation="true" /></runtime></configuration>'
[IO.File]::WriteAllText(($output + '.config'), $devConfig)
$previousDevPath = $env:DEVPATH
$env:DEVPATH = $isolated
try { & $output (Join-Path $isolated 'QTTabBar.dll') }
finally { $env:DEVPATH = $previousDevPath }
if ($LASTEXITCODE -ne 0) { throw 'Regressione rilevata.' }
$performance = Join-Path $isolated 'PerformanceRegression.exe'
& $compiler /nologo /debug:full /r:System.Drawing.dll /r:System.Windows.Forms.dll /r:System.Core.dll "/out:$performance" (Join-Path $PSScriptRoot 'PerformanceRegression.cs') (Join-Path $PSScriptRoot '..\..\QTTabBar\CoalescedQuery.cs')
if ($LASTEXITCODE -ne 0) { throw 'Compilazione test prestazioni non riuscita.' }
[IO.File]::WriteAllText(($performance + '.config'), $devConfig)
$env:DEVPATH = $isolated
try { & $performance (Join-Path $isolated 'QTTabBar.dll') }
finally { $env:DEVPATH = $previousDevPath }
if ($LASTEXITCODE -ne 0) { throw 'Regressione prestazioni rilevata.' }

$security = Join-Path $isolated 'SecurityRegression.exe'
& $compiler /nologo /r:System.Drawing.dll /r:System.Core.dll /r:System.Xml.dll /r:System.Runtime.Serialization.dll /r:System.ServiceModel.dll ("/out:"+$security) (Join-Path $PSScriptRoot 'SecurityRegression.cs') (Join-Path $PSScriptRoot '..\..\QTTabBar\IpcCommand.cs') (Join-Path $PSScriptRoot '..\..\QTTabBar\IpcTransport.cs') (Join-Path $PSScriptRoot '..\..\QTTabBar\IpcAuthorization.cs') (Join-Path $PSScriptRoot '..\..\Plugins\Memo\MemoPersistence.cs')
if ($LASTEXITCODE) { throw 'Compilazione test sicurezza non riuscita.' }
[IO.File]::WriteAllText(($security + '.config'), $devConfig)
$env:DEVPATH = $isolated
try { & $security (Join-Path $isolated 'QTTabBar.dll') $isolated }
finally { $env:DEVPATH = $previousDevPath }
if ($LASTEXITCODE) { throw 'Regressione sicurezza rilevata.' }