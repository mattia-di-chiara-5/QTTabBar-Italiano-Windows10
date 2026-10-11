#requires -version 5.1
[CmdletBinding()]
param([switch]$Elevated, [string]$UserSid, [switch]$MantieniAnteprimeAutomatiche)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
if (!$UserSid) { $UserSid = $identity.User.Value }
if ($UserSid -ne $identity.User.Value) { throw 'Eseguire l aggiornamento con lo stesso account Windows.' }
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (!$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if ($Elevated) { throw 'Elevazione amministrativa non riuscita.' }
    $ps = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -Elevated -UserSid "{1}"' -f $PSCommandPath,$UserSid
    if ($MantieniAnteprimeAutomatiche) { $arguments += ' -MantieniAnteprimeAutomatiche' }
    $p = Start-Process $ps -Verb RunAs -ArgumentList $arguments -Wait -PassThru
    exit $p.ExitCode
}
$mutex = New-Object Threading.Mutex($false,'Global\QTTabBarItaliano_Maintenance')
$locked = $false
$transcript = $false
try {
    try { $locked = $mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $locked = $true }
    if (!$locked) { throw 'Un altra manutenzione di QTTabBar e gia in corso.' }
    $windows = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    if (![Environment]::Is64BitOperatingSystem -or ![Environment]::Is64BitProcess -or [int]$windows.CurrentBuild -lt 10240 -or [int]$windows.CurrentBuild -ge 22000) { throw 'Richiesto Windows 10 x64 e PowerShell a 64 bit.' }
    $msi = Join-Path $PSScriptRoot 'QTTabBar-Italiano-v0.6.0.msi'
    $expected = '__MSI_SHA256__'
    if ($expected -notmatch '^[A-F0-9]{64}$' -or (Get-FileHash $msi -Algorithm SHA256).Hash -ne $expected) { throw 'SHA-256 MSI non valido. Usare il pacchetto compilato della release.' }
    $entries = @(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue | Where-Object { $_.PSObject.Properties['DisplayName'] -and $_.DisplayName -match 'QTTabBar' })
    $releaseRoot = Join-Path $env:ProgramData 'QTTabBar-Italiano\v0.6.0'
    if ($entries.Count -eq 1 -and $entries[0].PSChildName -eq '{540B7E57-F7A0-4AA5-A362-736892574234}') {
        $installedDll = Join-Path $env:WINDIR 'Microsoft.NET\assembly\GAC_MSIL\QTTabBar\v4.0_1.6.3.0__973461f1cd23d8eb\QTTabBar.dll'
        if (!(Test-Path $installedDll) -or (Get-FileHash $installedDll).Hash -ne '__DLL_SHA256__') { throw 'DLL installata alterata o assente: riparare l MSI prima di proseguire.' }
        Write-Host 'QTTabBar Italiano 0.6.0 e gia installato. Nessuna reinstallazione.'
        exit 0
    }
    if ($entries.Count -gt 1 -or ($entries.Count -eq 1 -and $entries[0].PSChildName -ne '{43662BD1-B726-4830-B411-00AD2BC51F50}')) { throw 'La migrazione automatica supporta solo l edizione italiana 0.5.0 verificata o una nuova installazione.' }
    New-Item -ItemType Directory -Path $releaseRoot -Force | Out-Null
    if ((Get-Item $releaseRoot).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Directory di stato non valida.' }
    $acl = New-Object Security.AccessControl.DirectorySecurity
    $acl.SetAccessRuleProtection($true,$false)
    foreach ($sid in @('S-1-5-32-544','S-1-5-18')) {
        $account = New-Object Security.Principal.SecurityIdentifier($sid)
        $rule = New-Object Security.AccessControl.FileSystemAccessRule($account,'FullControl','ContainerInherit,ObjectInherit','None','Allow')
        [void]$acl.AddAccessRule($rule)
    }
    $acl.SetOwner((New-Object Security.Principal.SecurityIdentifier('S-1-5-32-544')))
    Set-Acl $releaseRoot $acl
    $stateRoot = Join-Path $releaseRoot ((Get-Date -Format 'yyyyMMdd_HHmmss') + '_' + [Guid]::NewGuid().ToString('N').Substring(0,8))
    New-Item -ItemType Directory -Path $stateRoot | Out-Null
    Start-Transcript -Path (Join-Path $stateRoot 'install.log') | Out-Null
    $transcript = $true
    $protectedMsi = Join-Path $stateRoot 'QTTabBar-Italiano-v0.6.0.msi'
    Copy-Item -LiteralPath $msi -Destination $protectedMsi
    if ((Get-FileHash $protectedMsi).Hash -ne $expected) { throw 'Copia protetta MSI non valida.' }
    $oldDll = Join-Path $env:WINDIR 'Microsoft.NET\assembly\GAC_MSIL\QTTabBar\v4.0_1.6.3.0__973461f1cd23d8eb\QTTabBar.dll'
    $state = [ordered]@{ Version='0.6.0'; UserSid=$UserSid; PreviousInstalled=($entries.Count -eq 1); ConfigExisted=(Test-Path 'HKCU:\Software\QTTabBar'); MsiHash=$expected; Date=(Get-Date).ToString('o'); Status='Prepared' }
    # The OLD uninstaller may delete the shared Toolbar key. Preserve both views.
    $toolbarKeys = @('HKLM\SOFTWARE\Microsoft\Internet Explorer\Toolbar','HKLM\SOFTWARE\WOW6432Node\Microsoft\Internet Explorer\Toolbar')
    for ($i=0; $i -lt $toolbarKeys.Count; $i++) {
        if (Test-Path ('Registry::' + $toolbarKeys[$i].Replace('HKLM','HKEY_LOCAL_MACHINE'))) {
            & reg.exe export $toolbarKeys[$i] (Join-Path $stateRoot "toolbar-$i.reg") /y | Out-Null
            if ($LASTEXITCODE -ne 0) { throw 'Backup barre condivise non riuscito.' }
        }
    }
    if ($state.ConfigExisted) {
        & reg.exe export 'HKCU\Software\QTTabBar' (Join-Path $stateRoot 'config.reg') /y | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Backup configurazione non riuscito.' }
        $state.ConfigHash = (Get-FileHash (Join-Path $stateRoot 'config.reg')).Hash
    }
    if ($state.PreviousInstalled) {
        $hash = (Get-FileHash $oldDll).Hash
        if ($hash -notin @('06840BA8902DD7CE7416956AD69F0EA535A6773C1754DE3358DB36724F35B9B1')) { throw 'DLL precedente non riconosciuta: aggiornamento interrotto.' }
        Copy-Item -LiteralPath $oldDll -Destination (Join-Path $stateRoot 'QTTabBar.before.dll')
        $state.PreviousDllHash = $hash
        $rollbackMsi = Join-Path $PSScriptRoot 'Rollback\QTTabBar-Italiano-v0.5.0.msi'
        if ((Get-FileHash $rollbackMsi).Hash -ne '675C49C0681304CC537D3626AF5794BAA035610DA321A8CC9934A2A67332522E') { throw 'MSI di ripristino assente o non valido.' }
        Copy-Item -LiteralPath $rollbackMsi -Destination (Join-Path $stateRoot 'QTTabBar-Italiano-v0.5.0.msi')
        $runtime = Join-Path $env:ProgramData 'QTTabBar'
        if (Test-Path $runtime) {
            if (@(Get-Item $runtime; Get-ChildItem $runtime -Recurse -Force) | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }) { throw 'Il percorso dei plugin contiene collegamenti: backup manuale necessario.' }
            Copy-Item -LiteralPath $runtime -Destination (Join-Path $stateRoot 'runtime-before') -Recurse
        }
    }
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Ripristina-VersionePrecedente.ps1') -Destination $stateRoot
    $state | ConvertTo-Json | Set-Content (Join-Path $stateRoot 'state.json') -Encoding UTF8
    $stateRoot | Set-Content (Join-Path $releaseRoot 'latest-state.txt') -Encoding UTF8
    Write-Host 'Backup completato. Aggiornamento di QTTabBar e riavvio di Esplora file...'
    $session = (Get-Process -Id $PID).SessionId
    Get-Process explorer -ErrorAction SilentlyContinue | Where-Object SessionId -eq $session | Stop-Process -Force -ErrorAction Stop
    try {
        $log = Join-Path $stateRoot 'msi.log'
        $p = Start-Process msiexec.exe -ArgumentList ('/i "{0}" /qn /norestart REBOOT=ReallySuppress /l*v "{1}"' -f $protectedMsi,$log) -Wait -PassThru -WindowStyle Hidden
        if ($p.ExitCode -notin @(0,3010)) { throw "MSI non riuscito: $($p.ExitCode)" }
        for ($i=0; $i -lt $toolbarKeys.Count; $i++) {
            $toolbarBackup = Join-Path $stateRoot "toolbar-$i.reg"
            if (Test-Path $toolbarBackup) {
                & reg.exe import $toolbarBackup | Out-Null
                if ($LASTEXITCODE -ne 0) { throw 'Ripristino barre condivise non riuscito.' }
            }
        }
        $gac = Join-Path $env:WINDIR 'Microsoft.NET\assembly\GAC_MSIL\QTTabBar\v4.0_1.6.3.0__973461f1cd23d8eb\QTTabBar.dll'
        if (!(Test-Path $gac) -or (Get-FileHash $gac).Hash -ne '__DLL_SHA256__') { throw 'DLL installata non corrispondente alla release.' }
        $lang = 'HKCU:\Software\QTTabBar\Config\Lang'
        New-Item $lang -Force | Out-Null
        New-ItemProperty $lang -Name UseLangFile -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty $lang -Name BuiltInLangSelectedIndex -Value 8 -PropertyType DWord -Force | Out-Null
        New-ItemProperty $lang -Name BuiltInLang -Value Italiano -PropertyType String -Force | Out-Null
        if (!$MantieniAnteprimeAutomatiche) {
            $tips = 'HKCU:\Software\QTTabBar\Config\Tips'
            New-Item $tips -Force | Out-Null
            New-ItemProperty $tips -Name SubDirTipsWithShift -Value 1 -PropertyType DWord -Force | Out-Null
            New-ItemProperty $tips -Name ShowPreviewsWithShift -Value 1 -PropertyType DWord -Force | Out-Null
            Write-Host 'Profilo veloce: tenere premuto Maiusc (Shift) per anteprime e menu sottocartelle.'
        }
        $state.Status = 'Installed'
        $state | ConvertTo-Json | Set-Content (Join-Path $stateRoot 'state.json') -Encoding UTF8
        Write-Host "Installazione verificata. Backup: $stateRoot"
        if ($p.ExitCode -eq 3010) { Write-Warning 'Windows richiede un riavvio per completare l aggiornamento.' }
    } catch {
        $failure = $_
        Write-Warning 'Aggiornamento non riuscito: avvio del ripristino.'
        & (Join-Path $stateRoot 'Ripristina-VersionePrecedente.ps1') -StateDirectory $stateRoot -Elevated -UserSid $UserSid
        throw $failure
    } finally {
        Get-Process explorer -ErrorAction SilentlyContinue | Where-Object SessionId -eq $session | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        if (!(Get-Process explorer -ErrorAction SilentlyContinue | Where-Object SessionId -eq $session)) { Start-Process (Join-Path $env:WINDIR 'explorer.exe') }
    }
} finally {
    if ($transcript) { Stop-Transcript | Out-Null }
    if ($locked) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
}
