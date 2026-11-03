#requires -version 5.1
$ErrorActionPreference='Stop'
# Isolated scheduler/process doubles: never start, stop or schedule a real desktop.
Add-Type @'
using System;
public static class QtExplorerToken { public static bool Elevated(int id) {return id==22;} }
public static class SessionFixture {
 public static bool Uac=true, Ran, Stopped, Deleted, FailRun, Timeout;
 public static int Session=123;
 public static string Sid=System.Security.Principal.WindowsIdentity.GetCurrent().User.Value;
 public static void Reset() {Uac=true;Ran=Stopped=Deleted=FailRun=Timeout=false;}
}
public class SessionPrincipal { public string UserId; public int LogonType,RunLevel; }
public class SessionSettings { public bool AllowDemandStart,Enabled,DisallowStartIfOnBatteries,StopIfGoingOnBatteries; public string ExecutionTimeLimit; }
public class SessionAction { public string Path; }
public class SessionActions {public SessionAction Create(int type){return new SessionAction();}}
public class SessionDefinition {public SessionPrincipal Principal=new SessionPrincipal();public SessionSettings Settings=new SessionSettings();public SessionActions Actions=new SessionActions();}
public class SessionTask {
 public void RunEx(object args,int flags,int session,object user) {
  if(flags!=4||session!=SessionFixture.Session||user!=null)throw new Exception("Wrong interactive session");
  if(SessionFixture.FailRun)throw new Exception("Injected scheduler failure");SessionFixture.Ran=true;
 }
}
public class SessionFolder {
 public SessionTask RegisterTaskDefinition(string name,SessionDefinition d,int flags,string sid,object password,int logon) {
  if(!name.StartsWith("QTTabBarItaliano-Restart-")||d.Principal.RunLevel!=0||d.Principal.LogonType!=3||sid!=SessionFixture.Sid||d.Principal.UserId!=sid||password!=null||logon!=3)throw new Exception("Unsafe task identity");
  if(d.Settings.ExecutionTimeLimit!="PT0S"||!d.Settings.Enabled||!d.Settings.AllowDemandStart||d.Settings.StopIfGoingOnBatteries||d.Settings.DisallowStartIfOnBatteries)throw new Exception("Unsafe desktop lifetime");
  return new SessionTask();
 }
 public void DeleteTask(string name,int flags){SessionFixture.Deleted=true;}
}
public class SessionScheduler {public void Connect(){}public SessionFolder GetFolder(string path){return new SessionFolder();}public SessionDefinition NewTask(int flags){return new SessionDefinition();}}
'@
function Get-Process {
    [CmdletBinding()]param([Parameter(Position=0)][string]$Name,[int]$Id)
    if($Id){return [pscustomobject]@{Id=$Id;SessionId=[SessionFixture]::Session}}
    $normal=[SessionFixture]::Ran -and ![SessionFixture]::Timeout
    [pscustomobject]@{Id=$(if($normal){33}else{22});SessionId=[SessionFixture]::Session}
}
function Get-ItemProperty {param([string]$Path,[string]$Name) [pscustomobject]@{EnableLUA=[int][SessionFixture]::Uac}}
function Stop-Process {[CmdletBinding()]param([Parameter(ValueFromPipeline=$true)]$InputObject,[switch]$Force) process{[SessionFixture]::Stopped=$true}}
function Start-Sleep {param([int]$Milliseconds)}
function New-Object {param([string]$ComObject) if($ComObject -ne 'Schedule.Service'){throw 'Unexpected COM server'};[SessionScheduler]::new()}
. (Join-Path $PSScriptRoot '..\installer\ExplorerSession.ps1')
[SessionFixture]::Reset()
Start-ExplorerAsInteractiveUser ([SessionFixture]::Sid)
if(![SessionFixture]::Stopped -or ![SessionFixture]::Ran -or ![SessionFixture]::Deleted){throw 'Normal launch/cleanup failed'}
foreach($scenario in @('FailRun','Timeout')) {
    [SessionFixture]::Reset()
    if($scenario -eq 'FailRun'){[SessionFixture]::FailRun=$true}else{[SessionFixture]::Timeout=$true}
    $rejected=$false
    try{Start-ExplorerAsInteractiveUser ([SessionFixture]::Sid)}catch{$rejected=$true}
    if(!$rejected -or ![SessionFixture]::Deleted){throw ('Failure cleanup missing: '+$scenario)}
}
[SessionFixture]::Reset();[SessionFixture]::Uac=$false
Start-ExplorerAsInteractiveUser ([SessionFixture]::Sid)
if([SessionFixture]::Stopped -or [SessionFixture]::Ran){throw 'Disabled-UAC mode changed the existing desktop'}
$rejected=$false
try{Start-ExplorerAsInteractiveUser 'S-1-0-0'}catch{$rejected=$true}
if(!$rejected){throw 'Wrong user accepted'}
Write-Host 'PASS: limited interactive token/session, no password, unlimited desktop lifetime, task cleanup on success/failure/timeout, UAC-disabled preservation and wrong-user rejection'
