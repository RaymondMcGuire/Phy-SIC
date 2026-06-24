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

echo Existing destination files are skipped only after a minimum-size check.
echo Set FORCE_DOWNLOAD=1 to redownload complete files too.

mkdir "data\body_models\smpl" 2>nul
mkdir "data\models\SMPL" 2>nul
if exist "data\body_models\smpl\SMPL_NEUTRAL.pkl" if exist "data\models\SMPL\SMPL_NEUTRAL.pkl" (
    echo SKIP SMPL body model: data\body_models\smpl\SMPL_NEUTRAL.pkl already exists.
    goto :after_smpl
)

call :prompt_credentials "SMPL" "https://smpl.is.tue.mpg.de" || goto :error
call :download_post "https://download.is.tue.mpg.de/download.php?domain=smpl&sfile=SMPL_python_v.1.1.0.zip" "data\body_models\smpl\SMPL_python_v.1.1.0.zip" 1000000 || goto :error
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
copy /Y "data\body_models\smpl\SMPL_NEUTRAL.pkl" "data\models\SMPL\SMPL_NEUTRAL.pkl" >nul || goto :error
:after_smpl

mkdir "data\body_models\smplx" 2>nul
mkdir "data\models\SMPLX" 2>nul
if exist "data\body_models\smplx\SMPLX_NEUTRAL.npz" if exist "data\models\SMPLX\SMPLX_NEUTRAL.npz" (
    echo SKIP SMPL-X body model: data\body_models\smplx\SMPLX_NEUTRAL.npz already exists.
    goto :after_smplx
)

call :prompt_credentials "SMPL-X" "https://smpl-x.is.tue.mpg.de" || goto :error
call :download_post "https://download.is.tue.mpg.de/download.php?domain=smplx&sfile=models_smplx_v1_1.zip" "data\body_models\smplx\models_smplx_v1_1.zip" 1000000 || goto :error
call :expand_zip "data\body_models\smplx\models_smplx_v1_1.zip" "data\body_models\smplx" || goto :error
if not exist "data\body_models\smplx\models\smplx" (
    echo ERROR: Expected SMPL-X models folder was not found after extraction.
    goto :error
)
move /Y "data\body_models\smplx\models\smplx\*" "data\body_models\smplx\" >nul || goto :error
rmdir /S /Q "data\body_models\smplx\models" 2>nul
del /Q "data\body_models\smplx\models_smplx_v1_1.zip" 2>nul
copy /Y "data\body_models\smplx\SMPLX_NEUTRAL.npz" "data\models\SMPLX\SMPLX_NEUTRAL.npz" >nul || goto :error
:after_smplx

if exist "data\body_models\smpl\kid_template.npy" if exist "data\body_models\smplx\kid_template.npy" (
    echo SKIP AGORA kid templates: files already exist.
    goto :after_agora
)

call :prompt_credentials "AGORA" "https://agora.is.tue.mpg.de" || goto :error
call :download_post "https://download.is.tue.mpg.de/download.php?domain=agora&resume=1&sfile=smpl_kid_template.npy" "data\body_models\smpl\kid_template.npy" 1000 || goto :error
call :download_post "https://download.is.tue.mpg.de/download.php?domain=agora&resume=1&sfile=smplx_kid_template.npy" "data\body_models\smplx\kid_template.npy" 1000 || goto :error
:after_agora

mkdir "data\pretrained-models" 2>nul
if exist "data\pretrained-models\cam_model_cleaned.ckpt" if exist "data\pretrained-models\camerahmr_checkpoint_cleaned.ckpt" if exist "data\pretrained-models\model_final_f05665.pkl" if exist "data\smpl_mean_params.npz" (
    echo SKIP CameraHMR checkpoints: files already exist.
    goto :after_camerahmr
)

call :prompt_credentials "CameraHMR" "https://camerahmr.is.tue.mpg.de" || goto :error
call :download_post "https://download.is.tue.mpg.de/download.php?domain=camerahmr&sfile=cam_model_cleaned.ckpt" "data\pretrained-models\cam_model_cleaned.ckpt" 1000000 || goto :error
call :download_post "https://download.is.tue.mpg.de/download.php?domain=camerahmr&sfile=camerahmr_checkpoint_cleaned.ckpt" "data\pretrained-models\camerahmr_checkpoint_cleaned.ckpt" 10000000 || goto :error
call :download_post "https://download.is.tue.mpg.de/download.php?domain=camerahmr&sfile=model_final_f05665.pkl" "data\pretrained-models\model_final_f05665.pkl" 10000000 || goto :error
call :download_post "https://download.is.tue.mpg.de/download.php?domain=camerahmr&sfile=smpl_mean_params.npz" "data\smpl_mean_params.npz" 1000 || goto :error
:after_camerahmr

mkdir "data" 2>nul
mkdir "data\mmpose\configs\wholebody_2d_keypoint\rtmpose\coco-wholebody" 2>nul
mkdir "data\mmpose\configs\_base_" 2>nul
call :download_get "https://raw.githubusercontent.com/open-mmlab/mmpose/v1.3.2/configs/wholebody_2d_keypoint/rtmpose/coco-wholebody/rtmpose-l_8xb64-270e_coco-wholebody-256x192.py" "data\mmpose\configs\wholebody_2d_keypoint\rtmpose\coco-wholebody\rtmpose-l_8xb64-270e_coco-wholebody-256x192.py" 1000 || goto :error
call :download_get "https://raw.githubusercontent.com/open-mmlab/mmpose/v1.3.2/configs/_base_/default_runtime.py" "data\mmpose\configs\_base_\default_runtime.py" 100 || goto :error
call :download_get "https://download.openmmlab.com/mmpose/v1/projects/rtmposev1/rtmpose-l_simcc-coco-wholebody_pt-aic-coco_270e-256x192-6f206314_20230124.pth" "data\mmpose\rtmpose-l_simcc-coco-wholebody_pt-aic-coco_270e-256x192-6f206314_20230124.pth" 10000000 || goto :error
call :download_get "https://ml-site.cdn-apple.com/models/depth-pro/depth_pro.pt" "data\depth_pro.pt" 10000000 || goto :error

mkdir "data\deco" 2>nul
if exist "data\deco\deco_best.pth" (
    echo SKIP DECO checkpoint: data\deco\deco_best.pth already exists.
) else (
    call :download_get "https://keeper.mpdl.mpg.de/f/6f2e2258558f46ceb269/?dl=1" "data\deco\Release_Checkpoint.tar.gz" 1000000 || goto :error
    tar.exe -xzf "data\deco\Release_Checkpoint.tar.gz" -C "data\deco" || goto :error
    del /Q "data\deco\Release_Checkpoint.tar.gz" 2>nul
    if exist "data\deco\Release_Checkpoint" (
        move /Y "data\deco\Release_Checkpoint\*" "data\deco\" >nul || goto :error
        rmdir /S /Q "data\deco\Release_Checkpoint" 2>nul
    ) else (
        echo ERROR: Expected DECO Release_Checkpoint folder was not found after extraction.
        goto :error
    )
)

if exist "data\conversions\smpl_to_smplx.pkl" if exist "data\body_models\smplx\smplx_vert_segmentation.json" if exist "data\deco\pose_hrnet_w32_256x192.pth" if exist "data\body_models\smplx\smplx_neutral_tpose.ply" if exist "data\body_models\smpl\smpl_neutral_tpose.ply" (
    echo SKIP DECO support data: files already exist.
    goto :after_deco_data
)

call :download_get "https://keeper.mpdl.mpg.de/f/50cf65320b824391854b/?dl=1" "data\deco\data.tar.gz" 1000000 || goto :error
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
:after_deco_data

echo.
echo Data download complete.
goto :success

:prompt_credentials
echo.
echo Please register at %~2
set "AUTH_USERNAME="
set "AUTH_PASSWORD="
set /P "AUTH_USERNAME=Username (%~1 account): "
for /F "usebackq delims=" %%P in (`powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$secure = Read-Host -Prompt 'Password (%~1 account)' -AsSecureString; $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure); try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }"`) do set "AUTH_PASSWORD=%%P"
exit /b 0

:download_post
set "MIN_BYTES=%~3"
if "%MIN_BYTES%"=="" set "MIN_BYTES=1"
if /I not "%FORCE_DOWNLOAD%"=="1" (
    call :file_complete "%~2" "%MIN_BYTES%"
    if not errorlevel 1 (
        echo SKIP existing %~2
        exit /b 0
    )
)
if exist "%~2" (
    echo Replacing incomplete or invalid %~2
    del /Q "%~2" 2>nul
)
echo Downloading %~2
call :download_post_powershell "%~1" "%~2.part" || goto :download_post_curl
goto :download_post_validate

:download_post_curl
echo Retrying %~2 with curl.exe
curl.exe -L -k --fail --retry 3 --user-agent "Wget/1.21.4" --data-urlencode "username=%AUTH_USERNAME%" --data-urlencode "password=%AUTH_PASSWORD%" -o "%~2.part" "%~1"
if errorlevel 1 exit /b %ERRORLEVEL%

:download_post_validate
call :file_complete "%~2.part" "%MIN_BYTES%" || (
    echo ERROR: Downloaded file is smaller than expected. This usually means login, license, or server error HTML was downloaded instead of the real file.
    call :show_text_preview "%~2.part"
    del /Q "%~2.part" 2>nul
    exit /b 1
)
move /Y "%~2.part" "%~2" >nul
exit /b %ERRORLEVEL%

:download_get
set "MIN_BYTES=%~3"
if "%MIN_BYTES%"=="" set "MIN_BYTES=1"
if /I not "%FORCE_DOWNLOAD%"=="1" (
    call :file_complete "%~2" "%MIN_BYTES%"
    if not errorlevel 1 (
        echo SKIP existing %~2
        exit /b 0
    )
)
if exist "%~2" (
    echo Replacing incomplete or invalid %~2
    del /Q "%~2" 2>nul
)
echo Downloading %~2
curl.exe -L -k --fail --retry 3 --user-agent "Wget/1.21.4" -o "%~2.part" "%~1"
if errorlevel 1 exit /b %ERRORLEVEL%
call :file_complete "%~2.part" "%MIN_BYTES%" || (
    echo ERROR: Downloaded file is smaller than expected.
    call :show_text_preview "%~2.part"
    del /Q "%~2.part" 2>nul
    exit /b 1
)
move /Y "%~2.part" "%~2" >nul
exit /b %ERRORLEVEL%

:expand_zip
echo Extracting %~1
call :assert_zip "%~1" || exit /b 1
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& { param($archive, $destination) Expand-Archive -Force -LiteralPath $archive -DestinationPath $destination }" "%~1" "%~2"
exit /b %ERRORLEVEL%

:download_post_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& { param($url, $outFile, $username, $password) $ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri $url -Method Post -Body @{ username=$username; password=$password } -OutFile $outFile -MaximumRedirection 10 -UserAgent 'Wget/1.21.4' -UseBasicParsing; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 } }" "%~1" "%~2" "%AUTH_USERNAME%" "%AUTH_PASSWORD%"
exit /b %ERRORLEVEL%

:file_complete
if not exist "%~1" exit /b 1
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& { param($path, $minBytes) if ((Get-Item -LiteralPath $path).Length -ge [int64]$minBytes) { exit 0 } else { exit 1 } }" "%~1" "%~2"
exit /b %ERRORLEVEL%

:assert_zip
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& { param($path) try { Add-Type -AssemblyName System.IO.Compression.FileSystem; $zip = [System.IO.Compression.ZipFile]::OpenRead($path); $zip.Dispose(); exit 0 } catch { Write-Host 'ERROR: File is not a valid zip archive:' $path; Write-Host $_.Exception.Message; exit 1 } }" "%~1"
if errorlevel 1 (
    call :show_text_preview "%~1"
    exit /b 1
)
exit /b 0

:show_text_preview
echo ---- file preview: %~1 ----
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& { param($path) if (Test-Path -LiteralPath $path) { Get-Content -LiteralPath $path -TotalCount 8 -ErrorAction SilentlyContinue } }" "%~1"
echo ---- end preview ----
exit /b 0

:help
echo Downloads PhySIC model/data files on Windows.
echo.
echo Usage:
echo   fetch_data.bat
echo.
echo Requirements:
echo   curl.exe, tar.exe, powershell.exe
echo.
echo Reuse/skip behavior:
echo   Existing destination files are skipped only after a minimum-size check.
echo   Set FORCE_DOWNLOAD=1 to redownload complete files too.
echo.
echo Accounts required:
echo   SMPL, SMPL-X, AGORA, CameraHMR
goto :success

:error
echo.
echo fetch_data.bat failed. Check the message above and rerun the script.
pause
exit /b 1

:success
echo.
pause
exit /b 0
