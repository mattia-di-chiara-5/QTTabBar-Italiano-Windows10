@echo off
chcp 65001 >nul
cd /d "%~dp0"
title QTTabBar Italiano - Riparazione lingua
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer\Applica-Lingua-Italiana.ps1"
if errorlevel 1 pause
