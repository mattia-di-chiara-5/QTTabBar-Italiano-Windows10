@echo off
chcp 65001 >nul
cd /d "%~dp0"
title QTTabBar Italiano - Installazione o riparazione
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer\Installa-O-Ripara-QTTabBarItaliano.ps1"
if errorlevel 1 pause
