$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Set-Location (Join-Path $PSScriptRoot "..")

function New-Directory($Path) {
  if ($Path) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }
}

function Test-AllFiles($Paths) {
  foreach ($path in $Paths) {
    if (-not (Test-Path -LiteralPath $path)) {
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

function Read-Account($Name) {
  Write-Host "Please register at $Name before continuing."
  $username = Read-Host -Prompt "Username"
  $password = Read-PlainPassword "Password"
  @{ username = $username; password = $password }
}

function Invoke-PostDownload($Url, $OutFile, $Account) {
  New-Directory (Split-Path $OutFile -Parent)
  Write-Host "[download] $OutFile"
  Invoke-WebRequest `
    -Uri $Url `
    -Method Post `
    -Body @{ username = $Account.username; password = $Account.password } `
    -OutFile $OutFile `
    -MaximumRedirection 10 `
    -UseBasicParsing
}

function Invoke-Download($Url, $OutFile) {
  if (Test-Path -LiteralPath $OutFile) {
    Write-Host "[skip] $OutFile"
    return
  }

  New-Directory (Split-Path $OutFile -Parent)
  Write-Host "[download] $OutFile"
  Invoke-WebRequest `
    -Uri $Url `
    -OutFile $OutFile `
    -MaximumRedirection 10 `
    -UseBasicParsing
}

function Expand-TarGz($Archive, $Destination) {
  New-Directory $Destination
  tar -xzf $Archive -C $Destination
  if ($LASTEXITCODE -ne 0) {
    throw "tar failed for $Archive"
  }
}

function Remove-IfExists($Paths) {
  foreach ($path in $Paths) {
    if (Test-Path -LiteralPath $path) {
      Remove-Item -Recurse -Force -LiteralPath $path
    }
  }
}

function Ensure-SMPL {
  $targets = @(
    "data/body_models/smpl/SMPL_NEUTRAL.pkl",
    "data/body_models/smpl/basicmodel_neutral_lbs_10_207_0_v1.1.0.pkl"
  )
  if (Test-AllFiles $targets) {
    Show-Skip "SMPL body model"
    return
  }

  $account = Read-Account "https://smpl.is.tue.mpg.de"
  New-Directory "data/body_models/smpl"
  Invoke-PostDownload `
    "https://download.is.tue.mpg.de/download.php?domain=smpl&sfile=SMPL_python_v.1.1.0.zip" `
    "data/body_models/smpl/SMPL_python_v.1.1.0.zip" `
    $account
  Expand-Archive -Force "data/body_models/smpl/SMPL_python_v.1.1.0.zip" "data/body_models/smpl"
  Move-Item -Force "data/body_models/smpl/SMPL_python_v.1.1.0/smpl/models/*" "data/body_models/smpl"
  Copy-Item -Force "data/body_models/smpl/basicmodel_neutral_lbs_10_207_0_v1.1.0.pkl" "data/body_models/smpl/SMPL_NEUTRAL.pkl"
  Remove-IfExists @("data/body_models/smpl/SMPL_python_v.1.1.0", "data/body_models/smpl/SMPL_python_v.1.1.0.zip")
}

function Ensure-SMPLX {
  $targets = @(
    "data/body_models/smplx/SMPLX_NEUTRAL.npz",
    "data/body_models/smpl2smplx_deftrafo_setup.pkl"
  )
  if (Test-AllFiles $targets) {
    Show-Skip "SMPL-X body model and transfer data"
    return
  }

  $account = Read-Account "https://smpl-x.is.tue.mpg.de"
  New-Directory "data/body_models/smplx"

  if (-not (Test-Path -LiteralPath "data/body_models/smplx/SMPLX_NEUTRAL.npz")) {
    Invoke-PostDownload `
      "https://download.is.tue.mpg.de/download.php?domain=smplx&sfile=models_smplx_v1_1.zip" `
      "data/body_models/smplx/models_smplx_v1_1.zip" `
      $account
    Expand-Archive -Force "data/body_models/smplx/models_smplx_v1_1.zip" "data/body_models/smplx"
    Move-Item -Force "data/body_models/smplx/models/smplx/*" "data/body_models/smplx"
    Remove-IfExists @("data/body_models/smplx/models", "data/body_models/smplx/models_smplx_v1_1.zip")
  }

  if (-not (Test-Path -LiteralPath "data/body_models/smpl2smplx_deftrafo_setup.pkl")) {
    Invoke-PostDownload `
      "https://download.is.tue.mpg.de/download.php?domain=smplx&sfile=model_transfer.zip" `
      "data/body_models/transfer.zip" `
      $account
    Expand-Archive -Force "data/body_models/transfer.zip" "data/body_models/transfer"
    Move-Item -Force "data/body_models/transfer/smpl2smplx_deftrafo_setup.pkl" "data/body_models/smpl2smplx_deftrafo_setup.pkl"
    Remove-IfExists @("data/body_models/transfer", "data/body_models/transfer.zip")
  }
}

function Ensure-AgoraTemplates {
  $targets = @(
    "data/body_models/smpl/kid_template.npy",
    "data/body_models/smplx/kid_template.npy"
  )
  if (Test-AllFiles $targets) {
    Show-Skip "AGORA kid templates"
    return
  }

  $account = Read-Account "https://agora.is.tue.mpg.de"
  if (-not (Test-Path -LiteralPath "data/body_models/smpl/kid_template.npy")) {
    Invoke-PostDownload `
      "https://download.is.tue.mpg.de/download.php?domain=agora&resume=1&sfile=smpl_kid_template.npy" `
      "data/body_models/smpl/kid_template.npy" `
      $account
  }
  if (-not (Test-Path -LiteralPath "data/body_models/smplx/kid_template.npy")) {
    Invoke-PostDownload `
      "https://download.is.tue.mpg.de/download.php?domain=agora&resume=1&sfile=smplx_kid_template.npy" `
      "data/body_models/smplx/kid_template.npy" `
      $account
  }
}

function Ensure-CameraHMR {
  $targets = @(
    "data/chmr/cam_model_cleaned.ckpt",
    "data/chmr/camerahmr_checkpoint_cleaned.ckpt",
    "data/chmr/model_final_f05665.pkl",
    "data/chmr/smpl_mean_params.npz"
  )
  if (Test-AllFiles $targets) {
    Show-Skip "CameraHMR checkpoints"
    return
  }

  $account = Read-Account "https://camerahmr.is.tue.mpg.de"
  New-Directory "data/chmr"
  if (-not (Test-Path -LiteralPath "data/chmr/cam_model_cleaned.ckpt")) {
    Invoke-PostDownload "https://download.is.tue.mpg.de/download.php?domain=camerahmr&sfile=cam_model_cleaned.ckpt" "data/chmr/cam_model_cleaned.ckpt" $account
  }
  if (-not (Test-Path -LiteralPath "data/chmr/camerahmr_checkpoint_cleaned.ckpt")) {
    Invoke-PostDownload "https://download.is.tue.mpg.de/download.php?domain=camerahmr&sfile=camerahmr_checkpoint_cleaned.ckpt" "data/chmr/camerahmr_checkpoint_cleaned.ckpt" $account
  }
  if (-not (Test-Path -LiteralPath "data/chmr/model_final_f05665.pkl")) {
    Invoke-PostDownload "https://download.is.tue.mpg.de/download.php?domain=camerahmr&sfile=model_final_f05665.pkl" "data/chmr/model_final_f05665.pkl" $account
  }
  if (-not (Test-Path -LiteralPath "data/chmr/smpl_mean_params.npz")) {
    Invoke-PostDownload "https://download.is.tue.mpg.de/download.php?domain=camerahmr&sfile=smpl_mean_params.npz" "data/chmr/smpl_mean_params.npz" $account
  }
}

function Ensure-PublicModels {
  Invoke-Download "https://huggingface.co/JunkyByte/easy_ViTPose/resolve/main/torch/wholebody/vitpose-h-wholebody.pth" "data/vitpose_huge_wholebody.pth"
  Invoke-Download "https://ml-site.cdn-apple.com/models/depth-pro/depth_pro.pt" "data/depth_pro.pt"
}

function Ensure-DecoCheckpoint {
  $targets = @("data/deco/deco_best.pth")
  if (Test-AllFiles $targets) {
    Show-Skip "DECO checkpoint"
    return
  }

  New-Directory "data/deco"
  Invoke-Download "https://keeper.mpdl.mpg.de/f/6f2e2258558f46ceb269/?dl=1" "data/deco/Release_Checkpoint.tar.gz"
  Expand-TarGz "data/deco/Release_Checkpoint.tar.gz" "data/deco"
  Move-Item -Force "data/deco/Release_Checkpoint/*" "data/deco"
  Remove-IfExists @("data/deco/Release_Checkpoint", "data/deco/Release_Checkpoint.tar.gz")
}

function Ensure-DecoData {
  $targets = @(
    "data/conversions/smpl_to_smplx.pkl",
    "data/conversions/smplx_to_smpl.pkl",
    "data/body_models/smplx/smplx_vert_segmentation.json",
    "data/deco/pose_hrnet_w32_256x192.pth",
    "data/body_models/smplx/smplx_neutral_tpose.ply",
    "data/body_models/smpl/smpl_neutral_tpose.ply"
  )
  if (Test-AllFiles $targets) {
    Show-Skip "DECO data package"
    return
  }

  New-Directory "data/deco"
  Invoke-Download "https://keeper.mpdl.mpg.de/f/50cf65320b824391854b/?dl=1" "data/deco/data.tar.gz"
  Expand-TarGz "data/deco/data.tar.gz" "data/deco"
  Remove-IfExists @(
    "data/conversions",
    "data/body_models/smplx/smplx_vert_segmentation.json",
    "data/deco/pose_hrnet_w32_256x192.pth",
    "data/body_models/smplx/smplx_neutral_tpose.ply",
    "data/body_models/smpl/smpl_neutral_tpose.ply"
  )
  Move-Item -Force "data/deco/data/conversions" "data/conversions"
  Move-Item -Force "data/deco/data/smplx_vert_segmentation.json" "data/body_models/smplx/smplx_vert_segmentation.json"
  Move-Item -Force "data/deco/data/weights/pose_hrnet_w32_256x192.pth" "data/deco/pose_hrnet_w32_256x192.pth"
  Move-Item -Force "data/deco/data/smplx/smplx_neutral_tpose.ply" "data/body_models/smplx/smplx_neutral_tpose.ply"
  Move-Item -Force "data/deco/data/smpl/smpl_neutral_tpose.ply" "data/body_models/smpl/smpl_neutral_tpose.ply"
  Remove-IfExists @("data/deco/data", "data/deco/data.tar.gz")
}

Write-Host "[fetch] Downloading PhySIC data into ./data"
Ensure-SMPL
Ensure-SMPLX
Ensure-AgoraTemplates
Ensure-CameraHMR
Ensure-PublicModels
Ensure-DecoCheckpoint
Ensure-DecoData
Write-Host "[fetch] Done. In Docker, verify with: docker compose run --rm physic uv run python scripts/check-env.py --data-only"
