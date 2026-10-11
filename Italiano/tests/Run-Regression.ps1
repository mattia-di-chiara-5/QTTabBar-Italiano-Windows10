#requires -version 5.1
param([string]$Dll = (Join-Path $PSScriptRoot '..\..\QTTabBar\bin\Release\QTTabBar.dll'))
$ErrorActionPreference = 'Stop'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$output = Join-Path ([IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($Dll))) 'StabilityRegression.exe'
& $compiler /nologo /r:System.Drawing.dll /r:System.Windows.Forms.dll "/out:$output" (Join-Path $PSScriptRoot 'StabilityRegression.cs')
if ($LASTEXITCODE -ne 0) { throw 'Compilazione test non riuscita.' }
& $output $Dll
if ($LASTEXITCODE -ne 0) { throw 'Regressione rilevata.' }
