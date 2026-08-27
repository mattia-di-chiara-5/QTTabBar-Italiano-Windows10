@echo off
setlocal
powershell.exe -NoProfile -Command "$p=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent()); if($p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){exit 0}else{exit 1}" >nul 2>&1
if errorlevel 1 (
  echo Richiesta autorizzazione amministratore...
  set "QT_LAUNCHER=%~f0"
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath $env:QT_LAUNCHER -Verb RunAs"
  if errorlevel 1 (
    echo Impossibile aprire la richiesta UAC.
    pause
    exit /b 1
  )
  exit /b 0
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-QTTabBarItaliano.ps1"
set "QT_EXIT=%ERRORLEVEL%"
echo.
if not "%QT_EXIT%"=="0" echo Installazione non completata. Codice %QT_EXIT%.
if not "%QT_EXIT%"=="0" echo Controlla i log in %%LOCALAPPDATA%%\QTTabBar-Italiano\Logs.
pause
exit /b %QT_EXIT%
