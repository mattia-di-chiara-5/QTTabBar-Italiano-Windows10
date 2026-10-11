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
