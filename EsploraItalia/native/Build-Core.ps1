#requires -version 5.1
param([Parameter(Mandatory=$true)][string]$SourceDirectory,[Parameter(Mandatory=$true)][string]$OutputDirectory)
$ErrorActionPreference='Stop'
$commit='adf72c76b883271427ba16c39f9d6f5011488a42'
if(Test-Path -LiteralPath $SourceDirectory){throw 'Usare una directory sorgente nuova.'}
git clone --depth 1 https://github.com/derceg/explorerplusplus.git $SourceDirectory
if($LASTEXITCODE){throw 'Clone upstream non riuscito.'}
git -C $SourceDirectory fetch --depth 1 origin $commit
if($LASTEXITCODE){throw 'Fetch del commit non riuscito.'}
git -C $SourceDirectory checkout --detach $commit
if($LASTEXITCODE -or (git -C $SourceDirectory rev-parse HEAD).Trim() -ne $commit){throw 'Commit non corrispondente.'}
git -C $SourceDirectory -c protocol.file.allow=never submodule update --init
if($LASTEXITCODE){throw 'Submodule vcpkg non disponibile.'}
& (Join-Path $PSScriptRoot 'Apply-Fixes.ps1') -SourceDirectory $SourceDirectory
Push-Location $SourceDirectory
try{
 & .\Explorer++\ThirdParty\vcpkg\bootstrap-vcpkg.bat -disableMetrics
 if($LASTEXITCODE){throw 'Bootstrap vcpkg fallito.'}
 $solutionDirectory=(Join-Path $SourceDirectory 'Explorer++')+'\'
 $props=@('/m','/p:Configuration=Release','/p:Platform=x64','/p:ExplorerPlusPlusBuildVersion=2844',('/p:SolutionDir='+$solutionDirectory),'/v:minimal')
 & msbuild .\Explorer++\Explorer++\Explorer++.vcxproj @props
 if($LASTEXITCODE){throw 'Build core C++ fallita.'}
 & msbuild .\Explorer++\TestExplorer++\TestExplorer++.vcxproj @props
 if($LASTEXITCODE){throw 'Build test C++ fallita.'}
 New-Item -ItemType Directory -Path $OutputDirectory -Force|Out-Null
 & .\Explorer++\TestExplorer++\x64\Release\TestExplorer++.exe ('--gtest_output=xml:'+(Join-Path $OutputDirectory 'native-tests.xml'))
 if($LASTEXITCODE){throw 'Test nativi non superati.'}
 Copy-Item -LiteralPath .\Explorer++\Explorer++\x64\Release\Explorer++.exe -Destination (Join-Path $OutputDirectory 'Explorer++.exe')
 git diff --binary | Set-Content -LiteralPath (Join-Path $OutputDirectory 'core-fixes.patch') -Encoding utf8
 Get-FileHash (Join-Path $OutputDirectory 'Explorer++.exe')
}finally{Pop-Location}