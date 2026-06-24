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

By default, compose mounts `data/`, `images/`, and `outputs/` from the host into the container.

#### Local uv setup
If you want a local Linux/WSL environment instead of Docker, install uv first and then run:

```sh
git submodule update --init --recursive
bash install.sh
```

The old conda/CUDA 12.1 path is no longer the source of truth for this checkout.
