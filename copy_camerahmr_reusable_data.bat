@echo off
setlocal EnableExtensions DisableDelayedExpansion

if /I "%~1"=="--help" goto :help
if /I "%~1"=="-h" goto :help

cd /d "%~dp0"

set "SOURCE_DATA_DIR=%~1"
if not defined SOURCE_DATA_DIR set "SOURCE_DATA_DIR=D:\SMPL-project\CameraHMR\data"

echo.
echo Copying cleanly reusable CameraHMR files into this Phy-SIC checkout.
echo Source: %SOURCE_DATA_DIR%
echo Target: %CD%\data
echo.
echo This script intentionally does NOT copy SMPL-X locked-head files.
echo.

if not exist "%SOURCE_DATA_DIR%\" (
    echo ERROR: Source data directory was not found:
    echo   %SOURCE_DATA_DIR%
    goto :error
)

call :copy_required "%SOURCE_DATA_DIR%\smpl_mean_params.npz" "data\smpl_mean_params.npz" || goto :error

call :copy_required "%SOURCE_DATA_DIR%\pretrained-models\cam_model_cleaned.ckpt" "data\pretrained-models\cam_model_cleaned.ckpt" || goto :error
call :copy_required "%SOURCE_DATA_DIR%\pretrained-models\camerahmr_checkpoint_cleaned.ckpt" "data\pretrained-models\camerahmr_checkpoint_cleaned.ckpt" || goto :error
call :copy_required "%SOURCE_DATA_DIR%\pretrained-models\model_final_f05665.pkl" "data\pretrained-models\model_final_f05665.pkl" || goto :error

call :copy_required "%SOURCE_DATA_DIR%\models\SMPL\SMPL_NEUTRAL.pkl" "data\body_models\smpl\SMPL_NEUTRAL.pkl" || goto :error
call :copy_required "%SOURCE_DATA_DIR%\models\SMPL\SMPL_NEUTRAL.pkl" "data\models\SMPL\SMPL_NEUTRAL.pkl" || goto :error

echo.
echo Reusable CameraHMR files copied successfully.
goto :success

:copy_required
if not exist "%~1" (
    echo ERROR: Required source file was not found:
    echo   %~1
    exit /b 1
)
for %%I in ("%~2") do mkdir "%%~dpI" 2>nul
echo Copying %~2
copy /Y "%~1" "%~2" >nul
exit /b %ERRORLEVEL%

:help
echo Copies only the cleanly reusable CameraHMR model files into this Phy-SIC checkout.
echo.
echo Usage:
echo   copy_camerahmr_reusable_data.bat [CameraHMR data dir]
echo.
echo Default source:
echo   D:\SMPL-project\CameraHMR\data
echo.
echo Copied files:
echo   data\smpl_mean_params.npz
echo   data\pretrained-models\cam_model_cleaned.ckpt
echo   data\pretrained-models\camerahmr_checkpoint_cleaned.ckpt
echo   data\pretrained-models\model_final_f05665.pkl
echo   data\body_models\smpl\SMPL_NEUTRAL.pkl
echo   data\models\SMPL\SMPL_NEUTRAL.pkl
echo.
echo Not copied:
echo   SMPL-X locked-head files, AGORA kid templates, DECO, Depth Pro, MMPose.
goto :success

:error
echo.
echo copy_camerahmr_reusable_data.bat failed. Check the message above.
pause
exit /b 1

:success
echo.
pause
exit /b 0
