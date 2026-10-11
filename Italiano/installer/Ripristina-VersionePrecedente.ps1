#requires -version 5.1
[CmdletBinding()]
param([string]$StateDirectory, [switch]$Elevated, [string]$UserSid)
$ErrorActionPreference = 'Stop'
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
if (!$UserSid) { $UserSid = $identity.User.Value }
if ($identity.User.Value -ne $UserSid) { throw 'Usare lo stesso account Windows dell installazione.' }
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (!$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if ($Elevated) { throw 'Elevazione non riuscita.' }
    $arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -Elevated -UserSid "{1}"' -f $PSCommandPath,$UserSid
    if ($StateDirectory) { $arguments += ' -StateDirectory "{0}"' -f $StateDirectory }
    $p = Start-Process (Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe') -Verb RunAs -ArgumentList $arguments -Wait -PassThru
    exit $p.ExitCode
}
$mutex = New-Object Threading.Mutex($false,'Global\QTTabBarItaliano_Maintenance')
$locked = $false
try {
try { $locked = $mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $locked = $true }
if (!$locked) { throw 'Un altra manutenzione di QTTabBar e gia in corso.' }
$root = Join-Path $env:ProgramData 'QTTabBar-Italiano\v0.5.0'
if (!$StateDirectory) { $StateDirectory = (Get-Content (Join-Path $root 'latest-state.txt') -Raw).Trim() }
$StateDirectory = (Resolve-Path -LiteralPath $StateDirectory).Path
if (!(($StateDirectory + '\').StartsWith($root.TrimEnd('\') + '\',[StringComparison]::OrdinalIgnoreCase))) { throw 'Percorso di ripristino non consentito.' }
if ((Get-Item $StateDirectory).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Directory di ripristino non valida.' }
$state = Get-Content (Join-Path $StateDirectory 'state.json') -Raw | ConvertFrom-Json
if ($state.UserSid -ne $UserSid -or $state.Version -ne '0.5.0') { throw 'Stato di ripristino non compatibile.' }
if ($state.PreviousInstalled) {
    $oldMsi = Join-Path $StateDirectory 'QTTabBar-1.5.6.1.msi'
    $oldDll = Join-Path $StateDirectory 'QTTabBar.before.dll'
    if ((Get-FileHash $oldMsi).Hash -ne 'AAE4F2BEC2F4CA0EDE488638B9F31543B7CFCBFC90F1C6DDB74F5FB47B890287' -or (Get-FileHash $oldDll).Hash -ne $state.PreviousDllHash) { throw 'Backup binari non valido.' }
}
if ($state.ConfigExisted) {
    $config = Join-Path $StateDirectory 'config.reg'
    if ((Get-FileHash $config).Hash -ne $state.ConfigHash) { throw 'Backup configurazione non valido.' }
    foreach ($line in Get-Content $config) {
        if ($line -match '^\[' -and $line -notmatch '^\[HKEY_CURRENT_USER\\Software\\QTTabBar(?:\\[^\]]*)?\]$') { throw 'Il backup contiene chiavi non consentite.' }
    }
}
$session = (Get-Process -Id $PID).SessionId
Get-Process explorer -ErrorAction SilentlyContinue | Where-Object SessionId -eq $session | Stop-Process -Force -ErrorAction Stop
try {
    $p = Start-Process msiexec.exe -ArgumentList '/x {43662BD1-B726-4830-B411-00AD2BC51F50} /qn /norestart REBOOT=ReallySuppress' -Wait -PassThru -WindowStyle Hidden
    if ($p.ExitCode -notin @(0,1605,3010)) { throw "Disinstallazione nuova versione non riuscita: $($p.ExitCode)" }
    if ($state.PreviousInstalled) {
        $p = Start-Process msiexec.exe -ArgumentList ('/i "{0}" /qn /norestart REBOOT=ReallySuppress' -f $oldMsi) -Wait -PassThru -WindowStyle Hidden
        if ($p.ExitCode -notin @(0,3010)) { throw "Ripristino MSI non riuscito: $($p.ExitCode)" }
        Add-Type -AssemblyName System.EnterpriseServices
        (New-Object System.EnterpriseServices.Internal.Publish).GacInstall($oldDll)
        $gac = Join-Path $env:WINDIR 'assembly\GAC_MSIL\QTTabBar\1.5.6.1__973461f1cd23d8eb\QTTabBar.dll'
        if ((Get-FileHash $gac).Hash -ne $state.PreviousDllHash) { throw 'DLL precedente non ripristinata correttamente.' }
        $runtime = Join-Path $StateDirectory 'runtime-before'
        if (Test-Path $runtime) { Copy-Item -Path (Join-Path $runtime '*') -Destination (Join-Path $env:ProgramData 'QTTabBar') -Recurse -Force }
    }
    if (Test-Path 'HKCU:\Software\QTTabBar') { Remove-Item 'HKCU:\Software\QTTabBar' -Recurse -Force }
    if ($state.ConfigExisted) {
        & reg.exe import $config | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Ripristino configurazione non riuscito.' }
    }
    foreach ($toolbarBackup in @(Get-ChildItem $StateDirectory -Filter 'toolbar-*.reg')) {
        & reg.exe import $toolbarBackup.FullName | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Ripristino barre condivise non riuscito.' }
    }
    $state.Status = 'Restored'
    $state | ConvertTo-Json | Set-Content (Join-Path $StateDirectory 'state.json') -Encoding UTF8
    Write-Host 'Versione precedente e configurazione ripristinate.'
} finally {
    Get-Process explorer -ErrorAction SilentlyContinue | Where-Object SessionId -eq $session | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    if (!(Get-Process explorer -ErrorAction SilentlyContinue | Where-Object SessionId -eq $session)) { Start-Process (Join-Path $env:WINDIR 'explorer.exe') }
}
} finally {
    if ($locked) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
}
