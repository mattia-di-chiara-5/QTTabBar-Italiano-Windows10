@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Installa-Stabilita.ps1"
if errorlevel 1 pause
