@echo off
setlocal

cd /d "%~dp0\.."
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0fetch-data-win.ps1"
pause
