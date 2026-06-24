@echo off
setlocal EnableExtensions DisableDelayedExpansion

cd /d "%~dp0"

if /I "%~1"=="--help" goto :Help
if /I "%~1"=="-h" goto :Help

where powershell.exe >nul 2>nul || (
  echo ERROR: powershell.exe was not found.
  goto :Error
)

if not "%~1"=="" goto :RunWithArgs

echo Phy-SIC Hugging Face runtime model downloader
echo.
echo This downloads model caches on Windows into the local data\huggingface folder.
echo Docker can then read them through the PHYSIC_DATA_DIR volume mapping.
echo Gated models FLUX.1-dev and Omnieraser will be downloaded too.
echo They require HF_TOKEN in .env and accepted Hugging Face access.
echo.
echo Press Enter to use the default repository data directory:
echo   %CD%\data
echo.
set /p "DATA_DIR=Data directory [data]: "
if "%DATA_DIR%"=="" set "DATA_DIR=data"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0fetch_hf_data_windows.ps1" -DataDir "%DATA_DIR%"
goto :Finish

:RunWithArgs
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0fetch_hf_data_windows.ps1" %*
goto :Finish

:Help
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0fetch_hf_data_windows.ps1" -Help
goto :Finish

:Error
set "SCRIPT_EXIT_CODE=1"
goto :PauseAndExit

:Finish
set "SCRIPT_EXIT_CODE=%ERRORLEVEL%"

:PauseAndExit
echo.
pause
exit /b %SCRIPT_EXIT_CODE%
