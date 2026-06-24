param(
  [string]$DataDir = "data",
  [string]$Token = "",
  [switch]$SkipGated,
  [switch]$Help,
  [switch]$ReinstallTools
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Set-Location $PSScriptRoot

if ($Help) {
  Write-Host "Downloads Phy-SIC Hugging Face runtime models on Windows."
  Write-Host ""
  Write-Host "Usage:"
  Write-Host "  fetch_hf_data.bat"
  Write-Host "  fetch_hf_data.bat -DataDir data"
  Write-Host "  fetch_hf_data.bat -DataDir data -SkipGated"
  Write-Host "  fetch_hf_data.bat -DataDir D:\SMPL-project\Phy-SIC\data"
  Write-Host ""
  Write-Host "Before downloading gated models:"
  Write-Host "  1. Accept access on https://huggingface.co/black-forest-labs/FLUX.1-dev"
  Write-Host "  2. Accept/request access on https://huggingface.co/theSure/Omnieraser"
  Write-Host "  3. Put HF_TOKEN=hf_xxx in .env, pass -Token hf_xxx, or paste it when prompted"
  Write-Host ""
  Write-Host "Also downloads public runtime repos such as MoGe, GroundingDINO, and WiLoR-mini."
  Write-Host "This script creates .hf-download-venv with only huggingface_hub tools."
  exit 0
}

function Resolve-FullPath($Path) {
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $Path))
}

function Read-DotEnv($Path) {
  $values = @{}
  if (-not (Test-Path -LiteralPath $Path)) {
    return $values
  }

  Get-Content -LiteralPath $Path | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq "" -or $line.StartsWith("#")) {
      return
    }
    if ($line -match "^\s*([^=\s]+)\s*=\s*(.*)\s*$") {
      $key = $matches[1]
      $value = $matches[2].Trim()
      if (
        ($value.StartsWith('"') -and $value.EndsWith('"')) -or
        ($value.StartsWith("'") -and $value.EndsWith("'"))
      ) {
        $value = $value.Substring(1, $value.Length - 2)
      }
      $values[$key] = $value
    }
  }
  return $values
}

function Get-PythonCommand {
  $py = Get-Command py.exe -ErrorAction SilentlyContinue
  if ($py) {
    return @($py.Source, "-3")
  }

  $python = Get-Command python.exe -ErrorAction SilentlyContinue
  if ($python) {
    return @($python.Source)
  }

  throw "Python was not found. Install Python 3.10+ on Windows before running fetch_hf_data.bat."
}

function Invoke-Python($PythonCommand, [string[]]$Arguments) {
  $exe = $PythonCommand[0]
  $prefixArgs = @()
  if ($PythonCommand.Count -gt 1) {
    $prefixArgs = $PythonCommand[1..($PythonCommand.Count - 1)]
  }
  & $exe @prefixArgs @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Python command failed with exit code $LASTEXITCODE."
  }
}

$envValues = Read-DotEnv (Join-Path $PSScriptRoot ".env")
if (-not $Token) {
  if ($env:HF_TOKEN) {
    $Token = $env:HF_TOKEN
  }
  elseif ($env:HUGGING_FACE_HUB_TOKEN) {
    $Token = $env:HUGGING_FACE_HUB_TOKEN
  }
  elseif ($envValues["HF_TOKEN"]) {
    $Token = $envValues["HF_TOKEN"]
  }
  elseif ($envValues["HUGGING_FACE_HUB_TOKEN"]) {
    $Token = $envValues["HUGGING_FACE_HUB_TOKEN"]
  }
}

if (-not $Token -and -not $SkipGated) {
  Write-Host ""
  Write-Host "[hf] HF_TOKEN was not found in .env or environment variables."
  Write-Host "[hf] Paste a Hugging Face read token for FLUX.1-dev and Omnieraser. Input is hidden."
  $secure = Read-Host -Prompt "HF token" -AsSecureString
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try {
    $Token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  }
  finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  }
  if ([string]::IsNullOrWhiteSpace($Token)) {
    throw "HF token is required to download gated Hugging Face repos."
  }
}

$DataRoot = Resolve-FullPath $DataDir
$VenvDir = Join-Path $PSScriptRoot ".hf-download-venv"
$VenvPython = Join-Path $VenvDir "Scripts\python.exe"

Write-Host "[hf] Windows download mode"
Write-Host "[hf] Data directory: $DataRoot"
Write-Host "[hf] HF cache: $(Join-Path $DataRoot 'huggingface')"
Write-Host "[hf] Torch cache: $(Join-Path $DataRoot 'torch')"

$pythonCommand = Get-PythonCommand
if ($ReinstallTools -and (Test-Path -LiteralPath $VenvDir)) {
  Remove-Item -Recurse -Force -LiteralPath $VenvDir
}
if (-not (Test-Path -LiteralPath $VenvPython)) {
  Write-Host "[hf] Creating lightweight downloader venv: $VenvDir"
  Invoke-Python $pythonCommand @("-m", "venv", $VenvDir)
}

Write-Host "[hf] Ensuring huggingface_hub downloader tools..."
& $VenvPython -m pip install --upgrade pip "huggingface_hub[hf_xet]>=0.26"
if ($LASTEXITCODE -ne 0) {
  throw "Failed to install huggingface_hub in $VenvDir."
}

$args = @("fetch_hf_data.py", "--data-dir", $DataRoot)
if ($Token) {
  $args += @("--token", $Token)
}
if ($SkipGated) {
  $args += "--skip-gated"
}

& $VenvPython @args
if ($LASTEXITCODE -ne 0) {
  throw "Hugging Face data download failed with exit code $LASTEXITCODE."
}
