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

echo Phy-SIC data downloader
echo.
echo Press Enter to use the default repository data directory:
echo   %CD%\data
echo.
set /p "DATA_DIR=Data directory [data]: "
if "%DATA_DIR%"=="" set "DATA_DIR=data"

echo.
set /p "FORCE=Force re-download existing complete files? [y/N]: "
if /I "%FORCE%"=="y" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0fetch_data.ps1" -DataDir "%DATA_DIR%" -Force
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0fetch_data.ps1" -DataDir "%DATA_DIR%"
)
goto :Finish

:RunWithArgs
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0fetch_data.ps1" %*
goto :Finish

:Help
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0fetch_data.ps1" -Help
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
