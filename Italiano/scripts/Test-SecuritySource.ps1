#requires -version 5.1
param()
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$source=Get-ChildItem $root -Recurse -Filter *.cs -File | Where-Object { $_.FullName -notmatch '\\(bin|obj|packages|build|dist)\\' }
$bad=@($source|Select-String -Pattern '\b(BinaryFormatter|NetDataContractSerializer|LosFormatter|ObjectStateFormatter)\b')
if($bad.Count){throw ('Forbidden object deserializer returned: '+($bad|Out-String))}
$ipc=[IO.File]::ReadAllText((Join-Path $root 'QTTabBar\InstanceManager.cs'))
if($ipc.Contains('SecurityMode.None') -or $ipc.Contains('DelToByte') -or $ipc.Contains('ready.Wait(')){throw 'Legacy IPC path or UI initialization wait returned.'}
Get-ChildItem (Join-Path $root 'Italiano') -Recurse -Filter *.ps1 -File | Where-Object { $_.FullName -notmatch '\\(build|dist)\\' } | ForEach-Object {
    $tokens=$null;$errors=$null
    [void][Management.Automation.Language.Parser]::ParseFile($_.FullName,[ref]$tokens,[ref]$errors)
    if($errors.Count){throw ($errors|Out-String)}
}
Write-Output ('PASS: '+$source.Count+' C# sources checked for retired object deserializers; IPC and PowerShell source gates passed')
