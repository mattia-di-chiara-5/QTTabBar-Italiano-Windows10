@echo off
chcp 65001 >nul
cd /d "%~dp0"
title QTTabBar Italiano - Disinstallazione
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer\Disinstalla-QTTabBarItaliano.ps1"
if errorlevel 1 pause
