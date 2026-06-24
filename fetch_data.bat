@echo off
setlocal EnableExtensions DisableDelayedExpansion

if /I "%~1"=="--help" goto :help
if /I "%~1"=="-h" goto :help

cd /d "%~dp0"

where curl.exe >nul 2>nul || (
    echo ERROR: curl.exe was not found. Install curl or use a recent Windows 10/11 build.
    exit /b 1
)
where tar.exe >nul 2>nul || (
    echo ERROR: tar.exe was not found. Install bsdtar/libarchive or use a recent Windows 10/11 build.
    exit /b 1
)
where powershell.exe >nul 2>nul || (
    echo ERROR: powershell.exe was not found.
    exit /b 1
)

echo.
echo This script downloads the same data as fetch_data.sh into the local data\ folder.
echo Some downloads require SMPL, SMPL-X, AGORA, and CameraHMR accounts.
echo.

call :prompt_credentials "SMPL" "https://smpl.is.tue.mpg.de" || goto :error

mkdir "data\body_models\smpl" 2>nul
call :download_post "https://download.is.tue.mpg.de/download.php?domain=smpl&sfile=SMPL_python_v.1.1.0.zip" "data\body_models\smpl\SMPL_python_v.1.1.0.zip" || goto :error
call :expand_zip "data\body_models\smpl\SMPL_python_v.1.1.0.zip" "data\body_models\smpl" || goto :error
if not exist "data\body_models\smpl\SMPL_python_v.1.1.0\smpl\models" (
    echo ERROR: Expected SMPL models folder was not found after extraction.
    goto :error
)
move /Y "data\body_models\smpl\SMPL_python_v.1.1.0\smpl\models\*" "data\body_models\smpl\" >nul || goto :error
rmdir /S /Q "data\body_models\smpl\SMPL_python_v.1.1.0" 2>nul
del /Q "data\body_models\smpl\SMPL_python_v.1.1.0.zip" 2>nul
if not exist "data\body_models\smpl\basicmodel_neutral_lbs_10_207_0_v1.1.0.pkl" (
    echo ERROR: Expected neutral SMPL model was not found.
    goto :error
)
copy /Y "data\body_models\smpl\basicmodel_neutral_lbs_10_207_0_v1.1.0.pkl" "data\body_models\smpl\SMPL_NEUTRAL.pkl" >nul || goto :error

call :prompt_credentials "SMPL-X" "https://smpl-x.is.tue.mpg.de" || goto :error

mkdir "data\body_models\smplx" 2>nul
call :download_post "https://download.is.tue.mpg.de/download.php?domain=smplx&sfile=models_smplx_v1_1.zip" "data\body_models\smplx\models_smplx_v1_1.zip" || goto :error
call :expand_zip "data\body_models\smplx\models_smplx_v1_1.zip" "data\body_models\smplx" || goto :error
if not exist "data\body_models\smplx\models\smplx" (
    echo ERROR: Expected SMPL-X models folder was not found after extraction.
    goto :error
)
move /Y "data\body_models\smplx\models\smplx\*" "data\body_models\smplx\" >nul || goto :error
rmdir /S /Q "data\body_models\smplx\models" 2>nul
del /Q "data\body_models\smplx\models_smplx_v1_1.zip" 2>nul

call :download_post "https://download.is.tue.mpg.de/download.php?domain=smplx&sfile=model_transfer.zip" "data\body_models\transfer.zip" || goto :error
call :extract_zip_entry "data\body_models\transfer.zip" "smpl2smplx_deftrafo_setup.pkl" "data\body_models" || goto :error
del /Q "data\body_models\transfer.zip" 2>nul

call :prompt_credentials "AGORA" "https://agora.is.tue.mpg.de" || goto :error

call :download_post "https://download.is.tue.mpg.de/download.php?domain=agora&resume=1&sfile=smpl_kid_template.npy" "data\body_models\smpl\kid_template.npy" || goto :error
call :download_post "https://download.is.tue.mpg.de/download.php?domain=agora&resume=1&sfile=smplx_kid_template.npy" "data\body_models\smplx\kid_template.npy" || goto :error

call :prompt_credentials "CameraHMR" "https://camerahmr.is.tue.mpg.de" || goto :error

mkdir "data\chmr" 2>nul
call :download_post "https://download.is.tue.mpg.de/download.php?domain=camerahmr&sfile=cam_model_cleaned.ckpt" "data\chmr\cam_model_cleaned.ckpt" || goto :error
call :download_post "https://download.is.tue.mpg.de/download.php?domain=camerahmr&sfile=camerahmr_checkpoint_cleaned.ckpt" "data\chmr\camerahmr_checkpoint_cleaned.ckpt" || goto :error
call :download_post "https://download.is.tue.mpg.de/download.php?domain=camerahmr&sfile=model_final_f05665.pkl" "data\chmr\model_final_f05665.pkl" || goto :error
call :download_post "https://download.is.tue.mpg.de/download.php?domain=camerahmr&sfile=smpl_mean_params.npz" "data\chmr\smpl_mean_params.npz" || goto :error

mkdir "data" 2>nul
call :download_get "https://huggingface.co/JunkyByte/easy_ViTPose/resolve/main/torch/wholebody/vitpose-h-wholebody.pth" "data\vitpose_huge_wholebody.pth" || goto :error
call :download_get "https://ml-site.cdn-apple.com/models/depth-pro/depth_pro.pt" "data\depth_pro.pt" || goto :error

mkdir "data\deco" 2>nul
call :download_get "https://keeper.mpdl.mpg.de/f/6f2e2258558f46ceb269/?dl=1" "data\deco\Release_Checkpoint.tar.gz" || goto :error
tar.exe -xzf "data\deco\Release_Checkpoint.tar.gz" -C "data\deco" || goto :error
del /Q "data\deco\Release_Checkpoint.tar.gz" 2>nul
if exist "data\deco\Release_Checkpoint" (
    move /Y "data\deco\Release_Checkpoint\*" "data\deco\" >nul || goto :error
    rmdir /S /Q "data\deco\Release_Checkpoint" 2>nul
) else (
    echo ERROR: Expected DECO Release_Checkpoint folder was not found after extraction.
    goto :error
)

call :download_get "https://keeper.mpdl.mpg.de/f/50cf65320b824391854b/?dl=1" "data\deco\data.tar.gz" || goto :error
tar.exe -xzf "data\deco\data.tar.gz" -C "data\deco" || goto :error
del /Q "data\deco\data.tar.gz" 2>nul
if not exist "data\deco\data" (
    echo ERROR: Expected DECO data folder was not found after extraction.
    goto :error
)

robocopy "data\deco\data\conversions" "data\conversions" /E >nul
if %ERRORLEVEL% GEQ 8 goto :error
move /Y "data\deco\data\smplx_vert_segmentation.json" "data\body_models\smplx\" >nul || goto :error
move /Y "data\deco\data\weights\pose_hrnet_w32_256x192.pth" "data\deco\" >nul || goto :error
move /Y "data\deco\data\smplx\smplx_neutral_tpose.ply" "data\body_models\smplx\" >nul || goto :error
move /Y "data\deco\data\smpl\smpl_neutral_tpose.ply" "data\body_models\smpl\" >nul || goto :error
rmdir /S /Q "data\deco\data" 2>nul

echo.
echo Data download complete.
exit /b 0

:prompt_credentials
echo.
echo Please register at %~2
set "AUTH_USERNAME="
set "AUTH_PASSWORD="
set /P "AUTH_USERNAME=Username (%~1 account): "
set /P "AUTH_PASSWORD=Password (%~1 account): "
exit /b 0

:download_post
echo Downloading %~2
curl.exe -L -k --retry 3 -C - --data-urlencode "username=%AUTH_USERNAME%" --data-urlencode "password=%AUTH_PASSWORD%" -o "%~2" "%~1"
exit /b %ERRORLEVEL%

:download_get
echo Downloading %~2
curl.exe -L -k --retry 3 -C - -o "%~2" "%~1"
exit /b %ERRORLEVEL%

:expand_zip
echo Extracting %~1
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Force -LiteralPath '%~1' -DestinationPath '%~2'"
exit /b %ERRORLEVEL%

:extract_zip_entry
echo Extracting %~2 from %~1
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; $zip='%~1'; $entry='%~2'; $dest='%~3'; $archive=[IO.Compression.ZipFile]::OpenRead($zip); try { $match=$archive.Entries | Where-Object { $_.FullName -eq $entry } | Select-Object -First 1; if (-not $match) { throw ('Entry not found: ' + $entry) }; $target=Join-Path $dest $match.Name; [IO.Compression.ZipFileExtensions]::ExtractToFile($match, $target, $true) } finally { $archive.Dispose() }"
exit /b %ERRORLEVEL%

:help
echo Downloads PhySIC model/data files on Windows.
echo.
echo Usage:
echo   fetch_data.bat
echo.
echo Requirements:
echo   curl.exe, tar.exe, powershell.exe
echo.
echo Accounts required:
echo   SMPL, SMPL-X, AGORA, CameraHMR
exit /b 0

:error
echo.
echo fetch_data.bat failed. Check the message above and rerun the script.
exit /b 1
