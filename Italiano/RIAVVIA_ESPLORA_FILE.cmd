@echo off
chcp 65001 >nul
cd /d "%~dp0"
title QTTabBar Italiano - Riavvio Esplora file
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer\Riavvia-Explorer.ps1"
