@echo off
chcp 65001 >nul
cd /d "%~dp0"
title QTTabBar Italiano - Diagnostica
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer\Diagnostica-QTTabBarItaliano.ps1"
