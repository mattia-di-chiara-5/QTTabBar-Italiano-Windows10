@echo off
chcp 65001 >nul
cd /d "%~dp0"
title QTTabBar Italiano - Percorso lingua
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer\Copia-Percorso-Lingua.ps1"
if errorlevel 1 pause
