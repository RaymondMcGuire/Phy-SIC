### PhySIC: Install Instructions

#### Hardware Requirements
This project requires a GPU with atleast 40GB of VRAM since we use OmniEraser based on FLUX.

#### Docker setup
The maintained setup is CUDA 12.8 + PyTorch 2.7.1 through uv:

```sh
git submodule update --init --recursive
cp .env.example .env
docker compose build physic
docker compose run --rm physic
```

To pre-download runtime Hugging Face models into the mounted data cache on Windows, accept/request access for `black-forest-labs/FLUX.1-dev` and `theSure/Omnieraser`, set `HF_TOKEN` in `.env`, and run:

```bat
fetch_hf_data.bat
```

This downloads into the local `data/huggingface/` cache, including public runtime repos such as MoGe, GroundingDINO, and WiLoR-mini. Docker then reads it through the `PHYSIC_DATA_DIR` volume mapping. Docker runtime is forced offline for Hugging Face and does not receive `HF_TOKEN`.

By default, compose mounts `data/`, `images/`, and `outputs/` from the compose checkout into the container. Edit `.env` if the model data lives elsewhere. For example, if you run Compose from WSL `~/project/Phy-SIC` but downloaded data on Windows under `D:\SMPL-project\Phy-SIC\data`, set:

```env
PHYSIC_DATA_DIR=/mnt/d/SMPL-project/Phy-SIC/data
PHYSIC_IMAGES_DIR=/mnt/d/SMPL-project/Phy-SIC/images
PHYSIC_OUTPUTS_DIR=/mnt/d/SMPL-project/Phy-SIC/outputs
```

PowerShell can also override a single run:

```powershell
$env:PHYSIC_DATA_DIR="D:\SMPL-project\Phy-SIC\data"
docker compose run --rm physic
```

Inside WSL, use the mounted Linux path form instead, for example `/mnt/d/SMPL-project/Phy-SIC/data`.

If the build stalls or the machine runs out of memory, lower the build/download concurrency before building:

```powershell
$env:PHYSIC_BUILD_JOBS="1"
$env:UV_CONCURRENT_DOWNLOADS="1"
$env:UV_CONCURRENT_BUILDS="1"
$env:UV_CONCURRENT_INSTALLS="1"
docker compose build physic --progress=plain
```

The compose file also defaults the runtime container to `PHYSIC_CPUS=8` and `PHYSIC_MEM_LIMIT=32g`. These limits do not fully cap Docker BuildKit during image build; for build-time memory pressure, also set Docker Desktop or WSL resource limits.

#### Local uv setup
If you want a local Linux/WSL environment instead of Docker, install uv first and then run:

```sh
git submodule update --init --recursive
bash install.sh
```

The old conda/CUDA 12.1 path is no longer the source of truth for this checkout.
