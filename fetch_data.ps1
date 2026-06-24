param(
  [string]$DataDir = "data",
  [switch]$Force,
  [switch]$Help
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

if ($Help) {
  Write-Host "Downloads Phy-SIC model/data files on Windows."
  Write-Host ""
  Write-Host "Usage:"
  Write-Host "  fetch_data.bat"
  Write-Host "  fetch_data.bat -DataDir data"
  Write-Host "  fetch_data.bat -DataDir data -Force"
  Write-Host ""
  Write-Host "Environment:"
  Write-Host "  FORCE_DOWNLOAD=1   Redownload complete files."
  Write-Host ""
  Write-Host "Accounts required when files are missing:"
  Write-Host "  SMPL, SMPL-X, AGORA, CameraHMR"
  exit 0
}

if ($env:FORCE_DOWNLOAD -eq "1") {
  $Force = $true
}

Set-Location $PSScriptRoot

function Resolve-FullPath($Path) {
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $Path))
}

$DataRoot = Resolve-FullPath $DataDir
$Accounts = @{}

function New-Directory($Path) {
  if ($Path) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }
}

function Join-DataPath([string[]]$Parts) {
  $path = $DataRoot
  foreach ($part in $Parts) {
    $path = Join-Path $path $part
  }
  return $path
}

function Test-FileMinimum($Path, [int64]$MinBytes = 1) {
  if (-not (Test-Path -LiteralPath $Path)) {
    return $false
  }
  return ((Get-Item -LiteralPath $Path).Length -ge $MinBytes)
}

function Test-AllFiles([object[]]$Specs) {
  foreach ($spec in $Specs) {
    if (-not (Test-FileMinimum $spec.OutFile $spec.MinBytes)) {
      return $false
    }
  }
  return $true
}

function Show-Skip($Name) {
  Write-Host "[skip] $Name is already complete."
}

function Read-PlainPassword($Prompt) {
  $secure = Read-Host -Prompt $Prompt -AsSecureString
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try {
    [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  }
  finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  }
}

function Get-Account($Key, $RegistrationUrl) {
  if ($Accounts.ContainsKey($Key)) {
    return $Accounts[$Key]
  }

  Write-Host ""
  Write-Host "Please register at $RegistrationUrl"
  $username = Read-Host -Prompt "Username"
  $password = Read-PlainPassword "Password"
  $account = @{ username = $username; password = $password }
  $Accounts[$Key] = $account
  return $account
}

function New-PostSpec($Domain, $SFile, $OutFile, [int64]$MinBytes) {
  @{
    Domain = $Domain
    SFile = $SFile
    OutFile = $OutFile
    MinBytes = $MinBytes
  }
}

function New-GetSpec($Url, $OutFile, [int64]$MinBytes) {
  @{
    Url = $Url
    OutFile = $OutFile
    MinBytes = $MinBytes
  }
}

function Show-TextPreview($Path) {
  Write-Host "---- file preview: $Path ----"
  try {
    Get-Content -LiteralPath $Path -TotalCount 8 -ErrorAction SilentlyContinue | ForEach-Object {
      Write-Host $_
    }
  }
  catch {
  }
  Write-Host "---- end preview ----"
}

function Assert-DownloadedFile($Path, [int64]$MinBytes, $Destination) {
  if (-not (Test-Path -LiteralPath $Path)) {
    throw "Downloaded temp file does not exist: $Path"
  }

  $downloadedBytes = (Get-Item -LiteralPath $Path).Length
  Write-Host ("[saved] {0:N0} bytes" -f $downloadedBytes)
  if ($downloadedBytes -lt $MinBytes) {
    Show-TextPreview $Path
    Remove-Item -Force -LiteralPath $Path -ErrorAction SilentlyContinue
    throw "Downloaded file is smaller than expected minimum $MinBytes bytes. This usually means an authentication, license, or server error page was downloaded instead of the real file: $Destination"
  }
}

function Invoke-CurlPostDownload($Url, $OutFile, $Account) {
  $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
  if (-not $curl) {
    throw "curl.exe was not found. Invoke-WebRequest failed and curl fallback is unavailable."
  }

  & $curl.Source `
    -L `
    -k `
    --fail `
    --retry 3 `
    --user-agent "Wget/1.21.4" `
    --output $OutFile `
    --data-urlencode "username=$($Account.username)" `
    --data-urlencode "password=$($Account.password)" `
    $Url

  if ($LASTEXITCODE -ne 0) {
    throw "curl.exe failed with exit code $LASTEXITCODE for $Url"
  }
}

function Invoke-PostDownload($Spec, $Account) {
  if (-not $Force -and (Test-FileMinimum $Spec.OutFile $Spec.MinBytes)) {
    $len = (Get-Item -LiteralPath $Spec.OutFile).Length
    Write-Host ("[skip] {0} ({1:N0} bytes)" -f $Spec.OutFile, $len)
    return
  }

  if (Test-Path -LiteralPath $Spec.OutFile) {
    $len = (Get-Item -LiteralPath $Spec.OutFile).Length
    if ($Force) {
      Write-Host ("[replace] Force enabled; replacing {0} ({1:N0} bytes)." -f $Spec.OutFile, $len)
    }
    else {
      Write-Host ("[replace] {0} is only {1:N0} bytes; downloading again." -f $Spec.OutFile, $len)
    }
    Remove-Item -Force -LiteralPath $Spec.OutFile
  }

  New-Directory (Split-Path $Spec.OutFile -Parent)
  $url = "https://download.is.tue.mpg.de/download.php?domain=$($Spec.Domain)&sfile=$($Spec.SFile)"
  $partFile = "$($Spec.OutFile).part"
  Remove-Item -Force -LiteralPath $partFile -ErrorAction SilentlyContinue

  Write-Host "[download] $($Spec.SFile)"
  Write-Host "           -> $($Spec.OutFile)"
  try {
    Invoke-WebRequest `
      -Uri $url `
      -Method Post `
      -Body @{ username = $Account.username; password = $Account.password } `
      -ContentType "application/x-www-form-urlencoded" `
      -OutFile $partFile `
      -MaximumRedirection 10 `
      -UserAgent "Wget/1.21.4" `
      -UseBasicParsing
  }
  catch {
    Write-Host "[warn] Invoke-WebRequest failed: $($_.Exception.Message)"
    Write-Host "[warn] Retrying with curl.exe..."
    Remove-Item -Force -LiteralPath $partFile -ErrorAction SilentlyContinue
    Invoke-CurlPostDownload $url $partFile $Account
  }

  Assert-DownloadedFile $partFile $Spec.MinBytes $Spec.OutFile
  Move-Item -Force -LiteralPath $partFile -Destination $Spec.OutFile
}

function Invoke-GetDownload($Spec) {
  if (-not $Force -and (Test-FileMinimum $Spec.OutFile $Spec.MinBytes)) {
    $len = (Get-Item -LiteralPath $Spec.OutFile).Length
    Write-Host ("[skip] {0} ({1:N0} bytes)" -f $Spec.OutFile, $len)
    return
  }

  if (Test-Path -LiteralPath $Spec.OutFile) {
    Remove-Item -Force -LiteralPath $Spec.OutFile
  }

  New-Directory (Split-Path $Spec.OutFile -Parent)
  $partFile = "$($Spec.OutFile).part"
  Remove-Item -Force -LiteralPath $partFile -ErrorAction SilentlyContinue

  Write-Host "[download] $($Spec.Url)"
  Write-Host "           -> $($Spec.OutFile)"
  try {
    Invoke-WebRequest `
      -Uri $Spec.Url `
      -OutFile $partFile `
      -MaximumRedirection 10 `
      -UserAgent "Wget/1.21.4" `
      -UseBasicParsing
  }
  catch {
    Write-Host "[warn] Invoke-WebRequest failed: $($_.Exception.Message)"
    Write-Host "[warn] Retrying with curl.exe..."
    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if (-not $curl) {
      throw "curl.exe was not found. Invoke-WebRequest failed and curl fallback is unavailable."
    }
    & $curl.Source -L -k --fail --retry 3 --user-agent "Wget/1.21.4" --output $partFile $Spec.Url
    if ($LASTEXITCODE -ne 0) {
      throw "curl.exe failed with exit code $LASTEXITCODE for $($Spec.Url)"
    }
  }

  Assert-DownloadedFile $partFile $Spec.MinBytes $Spec.OutFile
  Move-Item -Force -LiteralPath $partFile -Destination $Spec.OutFile
}

function Assert-Zip($Path) {
  try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($Path)
    $zip.Dispose()
  }
  catch {
    Show-TextPreview $Path
    throw "File is not a valid zip archive: $Path. $($_.Exception.Message)"
  }
}

function Expand-Zip($Archive, $Destination) {
  Assert-Zip $Archive
  New-Directory $Destination
  Write-Host "[extract] $Archive"
  Expand-Archive -Force -LiteralPath $Archive -DestinationPath $Destination
}

function Invoke-TarExtract($Archive, $Destination) {
  $tar = Get-Command tar.exe -ErrorAction SilentlyContinue
  if (-not $tar) {
    throw "tar.exe was not found. Use a recent Windows 10/11 build or install bsdtar/libarchive."
  }
  New-Directory $Destination
  Write-Host "[extract] $Archive"
  & $tar.Source -xzf $Archive -C $Destination
  if ($LASTEXITCODE -ne 0) {
    throw "tar.exe failed with exit code $LASTEXITCODE for $Archive"
  }
}

function Invoke-AccountDownloads($Key, $RegistrationUrl, $Name, [object[]]$Specs) {
  if (Test-AllFiles $Specs) {
    Show-Skip $Name
    return
  }

  $account = Get-Account $Key $RegistrationUrl
  foreach ($spec in $Specs) {
    Invoke-PostDownload $spec $account
  }
}

function Copy-IfExists($Source, $Destination) {
  if (-not (Test-Path -LiteralPath $Source)) {
    throw "Expected file was not found: $Source"
  }
  New-Directory (Split-Path $Destination -Parent)
  Copy-Item -Force -LiteralPath $Source -Destination $Destination
}

function Ensure-Smpl {
  $smplDir = Join-DataPath @("body_models", "smpl")
  $modelsDir = Join-DataPath @("models", "SMPL")
  New-Directory $smplDir
  New-Directory $modelsDir

  $basic = Join-DataPath @("body_models", "smpl", "basicmodel_neutral_lbs_10_207_0_v1.1.0.pkl")
  $neutral = Join-DataPath @("body_models", "smpl", "SMPL_NEUTRAL.pkl")
  $cameraNeutral = Join-DataPath @("models", "SMPL", "SMPL_NEUTRAL.pkl")

  if ((-not (Test-Path -LiteralPath $basic)) -and (Test-Path -LiteralPath $neutral)) {
    Write-Host "[copy] Creating SMPL official filename for smplfitter."
    Copy-Item -Force -LiteralPath $neutral -Destination $basic
  }
  if ((-not (Test-Path -LiteralPath $cameraNeutral)) -and (Test-Path -LiteralPath $neutral)) {
    Copy-Item -Force -LiteralPath $neutral -Destination $cameraNeutral
  }

  $specs = @(
    @{ OutFile = $basic; MinBytes = 1000000 },
    @{ OutFile = $neutral; MinBytes = 1000000 },
    @{ OutFile = $cameraNeutral; MinBytes = 1000000 }
  )
  if (Test-AllFiles $specs) {
    Show-Skip "SMPL body model"
    return
  }

  $archive = Join-DataPath @("body_models", "smpl", "SMPL_python_v.1.1.0.zip")
  $account = Get-Account "smpl" "https://smpl.is.tue.mpg.de"
  Invoke-PostDownload (New-PostSpec "smpl" "SMPL_python_v.1.1.0.zip" $archive 1000000) $account

  $tmp = Join-DataPath @("body_models", "smpl", "SMPL_python_v.1.1.0_tmp")
  Remove-Item -Recurse -Force -LiteralPath $tmp -ErrorAction SilentlyContinue
  Expand-Zip $archive $tmp
  $sourceModels = Join-Path $tmp "SMPL_python_v.1.1.0\smpl\models"
  if (-not (Test-Path -LiteralPath $sourceModels)) {
    throw "Expected SMPL models folder was not found after extraction: $sourceModels"
  }
  Get-ChildItem -LiteralPath $sourceModels -File | ForEach-Object {
    Copy-Item -Force -LiteralPath $_.FullName -Destination $smplDir
  }
  Remove-Item -Recurse -Force -LiteralPath $tmp -ErrorAction SilentlyContinue
  Remove-Item -Force -LiteralPath $archive -ErrorAction SilentlyContinue

  Copy-IfExists $basic $neutral
  Copy-IfExists $neutral $cameraNeutral
}

function Ensure-Smplx {
  $smplxDir = Join-DataPath @("body_models", "smplx")
  $modelsDir = Join-DataPath @("models", "SMPLX")
  New-Directory $smplxDir
  New-Directory $modelsDir

  $neutral = Join-DataPath @("body_models", "smplx", "SMPLX_NEUTRAL.npz")
  $cameraNeutral = Join-DataPath @("models", "SMPLX", "SMPLX_NEUTRAL.npz")
  $specs = @(
    @{ OutFile = $neutral; MinBytes = 1000000 },
    @{ OutFile = $cameraNeutral; MinBytes = 1000000 }
  )
  if (Test-AllFiles $specs) {
    Show-Skip "SMPL-X body model"
  }
  else {
    $archive = Join-DataPath @("body_models", "smplx", "models_smplx_v1_1.zip")
    $account = Get-Account "smplx" "https://smpl-x.is.tue.mpg.de"
    Invoke-PostDownload (New-PostSpec "smplx" "models_smplx_v1_1.zip" $archive 1000000) $account

    $tmp = Join-DataPath @("body_models", "smplx", "models_smplx_v1_1_tmp")
    Remove-Item -Recurse -Force -LiteralPath $tmp -ErrorAction SilentlyContinue
    Expand-Zip $archive $tmp
    $sourceModels = Join-Path $tmp "models\smplx"
    if (-not (Test-Path -LiteralPath $sourceModels)) {
      throw "Expected SMPL-X models folder was not found after extraction: $sourceModels"
    }
    Get-ChildItem -LiteralPath $sourceModels -File | ForEach-Object {
      Copy-Item -Force -LiteralPath $_.FullName -Destination $smplxDir
    }
    Remove-Item -Recurse -Force -LiteralPath $tmp -ErrorAction SilentlyContinue
    Remove-Item -Force -LiteralPath $archive -ErrorAction SilentlyContinue
    Copy-IfExists $neutral $cameraNeutral
  }
}

function Ensure-SmplxTransfer {
  $smpl2smplx = Join-DataPath @("body_models", "smpl2smplx_deftrafo_setup.pkl")
  $smplx2smpl = Join-DataPath @("body_models", "smplx2smpl_deftrafo_setup.pkl")
  $specs = @(
    @{ OutFile = $smpl2smplx; MinBytes = 1000 },
    @{ OutFile = $smplx2smpl; MinBytes = 1000 }
  )
  if (Test-AllFiles $specs) {
    Show-Skip "SMPL/SMPL-X transfer files"
    return
  }

  $archive = Join-DataPath @("body_models", "model_transfer.zip")
  $account = Get-Account "smplx" "https://smpl-x.is.tue.mpg.de"
  Invoke-PostDownload (New-PostSpec "smplx" "model_transfer.zip" $archive 100000) $account

  $tmp = Join-DataPath @("body_models", "model_transfer_tmp")
  Remove-Item -Recurse -Force -LiteralPath $tmp -ErrorAction SilentlyContinue
  Expand-Zip $archive $tmp
  Get-ChildItem -LiteralPath $tmp -Recurse -Filter "*deftrafo_setup.pkl" | ForEach-Object {
    Copy-Item -Force -LiteralPath $_.FullName -Destination (Join-DataPath @("body_models", $_.Name))
  }
  Remove-Item -Recurse -Force -LiteralPath $tmp -ErrorAction SilentlyContinue
  Remove-Item -Force -LiteralPath $archive -ErrorAction SilentlyContinue

  if (-not (Test-Path -LiteralPath $smpl2smplx)) {
    throw "Expected smpl2smplx_deftrafo_setup.pkl was not found in model_transfer.zip."
  }
  if (-not (Test-Path -LiteralPath $smplx2smpl)) {
    throw "Expected smplx2smpl_deftrafo_setup.pkl was not found in model_transfer.zip."
  }
}

function Ensure-AgoraKidTemplates {
  $specs = @(
    New-PostSpec "agora" "smpl_kid_template.npy" (Join-DataPath @("body_models", "smpl", "kid_template.npy")) 1000
    New-PostSpec "agora" "smplx_kid_template.npy" (Join-DataPath @("body_models", "smplx", "kid_template.npy")) 1000
  )
  Invoke-AccountDownloads "agora" "https://agora.is.tue.mpg.de" "AGORA kid templates" $specs
}

function Ensure-CameraHmr {
  $specs = @(
    New-PostSpec "camerahmr" "cam_model_cleaned.ckpt" (Join-DataPath @("pretrained-models", "cam_model_cleaned.ckpt")) 1000000
    New-PostSpec "camerahmr" "camerahmr_checkpoint_cleaned.ckpt" (Join-DataPath @("pretrained-models", "camerahmr_checkpoint_cleaned.ckpt")) 10000000
    New-PostSpec "camerahmr" "model_final_f05665.pkl" (Join-DataPath @("pretrained-models", "model_final_f05665.pkl")) 10000000
    New-PostSpec "camerahmr" "smpl_mean_params.npz" (Join-DataPath @("smpl_mean_params.npz")) 1000
  )
  Invoke-AccountDownloads "camerahmr" "https://camerahmr.is.tue.mpg.de" "CameraHMR checkpoints" $specs
}

function Ensure-MmposeAndDepthPro {
  $specs = @(
    New-GetSpec "https://raw.githubusercontent.com/open-mmlab/mmpose/v1.3.2/configs/wholebody_2d_keypoint/rtmpose/coco-wholebody/rtmpose-l_8xb64-270e_coco-wholebody-256x192.py" (Join-DataPath @("mmpose", "configs", "wholebody_2d_keypoint", "rtmpose", "coco-wholebody", "rtmpose-l_8xb64-270e_coco-wholebody-256x192.py")) 1000
    New-GetSpec "https://raw.githubusercontent.com/open-mmlab/mmpose/v1.3.2/configs/_base_/default_runtime.py" (Join-DataPath @("mmpose", "configs", "_base_", "default_runtime.py")) 100
    New-GetSpec "https://download.openmmlab.com/mmpose/v1/projects/rtmposev1/rtmpose-l_simcc-coco-wholebody_pt-aic-coco_270e-256x192-6f206314_20230124.pth" (Join-DataPath @("mmpose", "rtmpose-l_simcc-coco-wholebody_pt-aic-coco_270e-256x192-6f206314_20230124.pth")) 10000000
    New-GetSpec "https://ml-site.cdn-apple.com/models/depth-pro/depth_pro.pt" (Join-DataPath @("depth_pro.pt")) 10000000
  )
  foreach ($spec in $specs) {
    Invoke-GetDownload $spec
  }
}

function Ensure-TorchHubModels {
  $specs = @(
    New-GetSpec "https://dl.fbaipublicfiles.com/segment_anything_2/092824/sam2.1_hiera_large.pt" (Join-DataPath @("torch", "hub", "checkpoints", "sam2.1_hiera_large.pt")) 100000000
  )
  foreach ($spec in $specs) {
    Invoke-GetDownload $spec
  }
}

function Ensure-Deco {
  $decoDir = Join-DataPath @("deco")
  New-Directory $decoDir

  $decoBest = Join-DataPath @("deco", "deco_best.pth")
  if (Test-FileMinimum $decoBest 1000000) {
    Show-Skip "DECO checkpoint"
  }
  else {
    $archive = Join-DataPath @("deco", "Release_Checkpoint.tar.gz")
    Invoke-GetDownload (New-GetSpec "https://keeper.mpdl.mpg.de/f/6f2e2258558f46ceb269/?dl=1" $archive 1000000)
    Invoke-TarExtract $archive $decoDir
    Remove-Item -Force -LiteralPath $archive -ErrorAction SilentlyContinue
    $releaseDir = Join-DataPath @("deco", "Release_Checkpoint")
    if (-not (Test-Path -LiteralPath $releaseDir)) {
      throw "Expected DECO Release_Checkpoint folder was not found after extraction."
    }
    Get-ChildItem -LiteralPath $releaseDir | ForEach-Object {
      Move-Item -Force -LiteralPath $_.FullName -Destination $decoDir
    }
    Remove-Item -Recurse -Force -LiteralPath $releaseDir -ErrorAction SilentlyContinue
  }

  $supportSpecs = @(
    @{ OutFile = (Join-DataPath @("conversions", "smpl_to_smplx.pkl")); MinBytes = 1000000 },
    @{ OutFile = (Join-DataPath @("conversions", "smplx_to_smpl.pkl")); MinBytes = 1000000 },
    @{ OutFile = (Join-DataPath @("body_models", "smplx", "smplx_vert_segmentation.json")); MinBytes = 1000 },
    @{ OutFile = (Join-DataPath @("deco", "pose_hrnet_w32_256x192.pth")); MinBytes = 1000000 },
    @{ OutFile = (Join-DataPath @("body_models", "smplx", "smplx_neutral_tpose.ply")); MinBytes = 1000 },
    @{ OutFile = (Join-DataPath @("body_models", "smpl", "smpl_neutral_tpose.ply")); MinBytes = 1000 }
  )
  if (Test-AllFiles $supportSpecs) {
    Show-Skip "DECO support data"
    return
  }

  $archive = Join-DataPath @("deco", "data.tar.gz")
  Invoke-GetDownload (New-GetSpec "https://keeper.mpdl.mpg.de/f/50cf65320b824391854b/?dl=1" $archive 1000000)
  Invoke-TarExtract $archive $decoDir
  Remove-Item -Force -LiteralPath $archive -ErrorAction SilentlyContinue
  $dataDir = Join-DataPath @("deco", "data")
  if (-not (Test-Path -LiteralPath $dataDir)) {
    throw "Expected DECO data folder was not found after extraction."
  }

  New-Directory (Join-DataPath @("conversions"))
  Copy-Item -Recurse -Force -Path (Join-Path $dataDir "conversions\*") -Destination (Join-DataPath @("conversions"))
  Copy-IfExists (Join-Path $dataDir "smplx_vert_segmentation.json") (Join-DataPath @("body_models", "smplx", "smplx_vert_segmentation.json"))
  Copy-IfExists (Join-Path $dataDir "weights\pose_hrnet_w32_256x192.pth") (Join-DataPath @("deco", "pose_hrnet_w32_256x192.pth"))
  Copy-IfExists (Join-Path $dataDir "smplx\smplx_neutral_tpose.ply") (Join-DataPath @("body_models", "smplx", "smplx_neutral_tpose.ply"))
  Copy-IfExists (Join-Path $dataDir "smpl\smpl_neutral_tpose.ply") (Join-DataPath @("body_models", "smpl", "smpl_neutral_tpose.ply"))
  Remove-Item -Recurse -Force -LiteralPath $dataDir -ErrorAction SilentlyContinue
}

Write-Host "[fetch] Downloading Phy-SIC data"
Write-Host "[fetch] Data directory: $DataRoot"
if ($Force) {
  Write-Host "[fetch] Force: enabled"
}

Ensure-Smpl
Ensure-Smplx
Ensure-SmplxTransfer
Ensure-AgoraKidTemplates
Ensure-CameraHmr
Ensure-MmposeAndDepthPro
Ensure-TorchHubModels
Ensure-Deco

Write-Host ""
Write-Host "[fetch] Data download complete."
Write-Host "[fetch] Data directory: $DataRoot"
