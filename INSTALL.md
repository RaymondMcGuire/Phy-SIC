### PhySIC: Install Instructions

#### Hardware Requirements
This project requires a GPU with atleast 40GB of VRAM since we use OmniEraser based on FLUX.

#### Docker setup
The maintained setup is CUDA 12.8 + PyTorch 2.7.1 through uv:

```sh
git submodule update --init --recursive
docker compose build physic
docker compose run --rm physic
```

By default, compose mounts `data/`, `images/`, and `outputs/` from the host into the container. If you download model data on Windows into another folder, point Compose at it before running:

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
