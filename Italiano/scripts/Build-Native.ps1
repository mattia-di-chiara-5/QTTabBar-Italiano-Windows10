#requires -version 5.1
param([string]$Toolset='v143')
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
foreach($platform in @('Win32','x64')) {
    $properties=@('/p:Configuration=Release',('/p:Platform='+$platform),('/p:PlatformToolset='+$Toolset),'/p:WindowsTargetPlatformVersion=10.0','/p:PostBuildEventUseInBuild=false','/nologo','/v:minimal')
    & msbuild (Join-Path $root 'MinHook\libMinHook.vcxproj') @properties
    if($LASTEXITCODE){throw ('MinHook build failed: '+$platform)}
    & msbuild (Join-Path $root 'QTHookLib\QTHookLib.vcxproj') @properties /p:BuildProjectReferences=false
    if($LASTEXITCODE){throw ('QTHookLib build failed: '+$platform)}
    $architecture=if($platform -eq 'Win32'){'x86'}else{'x64'}
    $bits=if($platform -eq 'Win32'){'32'}else{'64'}
    $dll=Join-Path $root ('QTHookLib\bin\Release\QTHookLib'+$bits+'.dll')
    if(!(Test-Path -LiteralPath $dll)){throw ('Native DLL missing: '+$dll)}
    $compiler=Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
    $test=Join-Path (Split-Path $dll -Parent) ('NativeLoadTest-'+[char]0xE8+'-'+$architecture+'.exe')
    & $compiler /nologo ('/platform:'+$architecture) ('/out:'+$test) (Join-Path $root 'Italiano\tests\NativeLoadTest.cs')
    if($LASTEXITCODE){throw 'Native load test compilation failed.'}
    & $test $dll
    if($LASTEXITCODE){throw ('Native load test failed: '+$platform)}
}
