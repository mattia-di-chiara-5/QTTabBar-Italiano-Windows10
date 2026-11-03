#requires -version 5.1
function Start-ExplorerAsInteractiveUser([string]$UserSid) {
    if ($UserSid -ne [Security.Principal.WindowsIdentity]::GetCurrent().User.Value) { throw 'Account del desktop non corrispondente.' }
    $session=(Get-Process -Id $PID).SessionId
    $existing=@(Get-Process explorer -ErrorAction SilentlyContinue|Where-Object SessionId -eq $session)
    $uac=Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA
    if ($uac.EnableLUA -eq 0) {
        # No split token exists in this OS mode. Do not change the user's UAC policy.
        if (!$existing.Count) { Start-Process (Join-Path $env:WINDIR 'explorer.exe') }
        Write-Warning 'UAC disattivato: Windows non offre un token limitato. IPC QTTabBar elevato resta disabilitato.'
        return
    }
    if (!('QtExplorerToken' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
public static class QtExplorerToken {
 [DllImport("kernel32.dll",SetLastError=true)] static extern IntPtr OpenProcess(uint access,bool inherit,int id);
 [DllImport("advapi32.dll",SetLastError=true)] static extern bool OpenProcessToken(IntPtr process,uint access,out IntPtr token);
 [DllImport("advapi32.dll",SetLastError=true)] static extern bool GetTokenInformation(IntPtr token,int info,out int value,int length,out int returned);
 [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr handle);
 public static bool Elevated(int id) {
  IntPtr p=OpenProcess(0x1000,false,id),t=IntPtr.Zero;
  if(p==IntPtr.Zero)throw new Win32Exception(Marshal.GetLastWin32Error());
  try {if(!OpenProcessToken(p,8,out t))throw new Win32Exception(Marshal.GetLastWin32Error());int value,n;if(!GetTokenInformation(t,20,out value,4,out n))throw new Win32Exception(Marshal.GetLastWin32Error());return value!=0;}
  finally {if(t!=IntPtr.Zero)CloseHandle(t);CloseHandle(p);}
 }
}
'@
    }
    if ($existing.Count -and !@($existing|Where-Object {[QtExplorerToken]::Elevated($_.Id)}).Count) { return }
    $existing|Stop-Process -Force -ErrorAction Stop
    $scheduler=New-Object -ComObject Schedule.Service
    $scheduler.Connect()
    $folder=$scheduler.GetFolder('\')
    $definition=$scheduler.NewTask(0)
    $definition.Principal.UserId=$UserSid
    $definition.Principal.LogonType=3 # Existing interactive token; no password.
    $definition.Principal.RunLevel=0 # Limited token, never inherit the installer elevation.
    $definition.Settings.AllowDemandStart=$true
    $definition.Settings.Enabled=$true
    $definition.Settings.DisallowStartIfOnBatteries=$false
    $definition.Settings.StopIfGoingOnBatteries=$false
    $definition.Settings.ExecutionTimeLimit='PT0S'
    $action=$definition.Actions.Create(0)
    $action.Path=Join-Path $env:WINDIR 'explorer.exe'
    $name='QTTabBarItaliano-Restart-'+[Guid]::NewGuid().ToString('N')
    $registered=$false
    try {
        $task=$folder.RegisterTaskDefinition($name,$definition,6,$UserSid,$null,3)
        $registered=$true
        [void]$task.RunEx($null,4,$session,$null) # TASK_RUN_USE_SESSION_ID
        for($i=0;$i -lt 100;$i++) {
            Start-Sleep -Milliseconds 100
            $running=@(Get-Process explorer -ErrorAction SilentlyContinue|Where-Object SessionId -eq $session)
            if($running.Count -and !@($running|Where-Object {[QtExplorerToken]::Elevated($_.Id)}).Count) { return }
        }
        throw 'Explorer non risulta avviato con token utente normale.'
    } finally {
        if($registered) { $folder.DeleteTask($name,0) }
    }
}
