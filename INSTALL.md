### PhySIC: Docker + uv Install Instructions

#### Hardware Requirements

PhySIC is GPU-heavy. The original release expects a large NVIDIA GPU because
OmniEraser uses FLUX. This setup fixes the project environment inside an Ubuntu
22.04 CUDA 12.1 container and uses uv for Python dependency management.

#### Host Requirements

Use Windows + WSL2 + Docker Desktop:

1. Install WSL2 with Ubuntu 22.04.
2. Install Docker Desktop and enable the WSL2 backend.
3. Enable Docker Desktop integration for your Ubuntu 22.04 distro.
4. Confirm Docker can see the GPU:

```bash
docker run --rm --gpus all nvidia/cuda:12.1.1-base-ubuntu22.04 nvidia-smi
```

The `nvidia/cuda:12.1.1-base-ubuntu22.04` image is only a GPU smoke-test image.
It is not the PhySIC runtime image and can be removed later if you want to save
disk space.

#### Project Layout

For best build performance, keep the source code in the WSL/Linux filesystem:

```bash
mkdir -p ~/projects
cd ~/projects
git clone <your-physic-repo-url> Phy-SIC
cd Phy-SIC
```

Large data can remain on Windows and be mounted into the container. Copy the
example environment file and edit paths if needed:

```bash
cp .env.example .env
```

Defaults:

```text
PHYSIC_DATA_DIR=/mnt/d/SMPL-project/Phy-SIC/data
PHYSIC_IMAGES_DIR=/mnt/d/SMPL-project/Phy-SIC/images
PHYSIC_OUTPUT_DIR=/mnt/d/SMPL-project/Phy-SIC/outputs
CUDA_VISIBLE_DEVICES=all
```

#### Build the Docker Environment

```bash
docker compose build
```

Enter the container:

```bash
docker compose run --rm physic bash
```

Check GPU access:

```bash
docker compose run --rm physic nvidia-smi
```

Check Python dependencies and data:

```bash
docker compose run --rm physic uv run python scripts/check-env.py
docker compose run --rm physic uv run python scripts/check-env.py --data-only
```

#### Download Data

From Windows, run the PowerShell downloader:

```bat
scripts\fetch-data-win.bat
```

The downloader writes into `data/`, skips complete data groups that already
exist, and only asks for credentials for missing restricted assets. The same
`data/` directory is mounted into Docker through `PHYSIC_DATA_DIR`.

#### Run PhySIC

Place input images in the mounted `images/` directory, then run:

```bash
docker compose run --rm physic uv run python run_optimizer.py
```

To use only one physical GPU:

```bash
CUDA_VISIBLE_DEVICES=1 docker compose run --rm physic uv run python run_optimizer.py
```
