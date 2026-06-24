# syntax=docker/dockerfile:1.7

ARG CUDA_IMAGE=nvidia/cuda:12.8.0-devel-ubuntu22.04
ARG UV_IMAGE=ghcr.io/astral-sh/uv:0.11.23

FROM ${UV_IMAGE} AS uv
FROM ${CUDA_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG TORCH_CUDA_ARCH_LIST="12.0"
ARG PHYSIC_BUILD_JOBS=2
ARG UV_CONCURRENT_DOWNLOADS=2
ARG UV_CONCURRENT_BUILDS=1
ARG UV_CONCURRENT_INSTALLS=2

ENV FORCE_CUDA=1 \
    PYOPENGL_PLATFORM=egl \
    PYTHONUNBUFFERED=1 \
    TORCH_CUDA_ARCH_LIST=${TORCH_CUDA_ARCH_LIST} \
    MAX_JOBS=${PHYSIC_BUILD_JOBS} \
    CMAKE_BUILD_PARALLEL_LEVEL=${PHYSIC_BUILD_JOBS} \
    MAKEFLAGS="-j${PHYSIC_BUILD_JOBS}" \
    UV_COMPILE_BYTECODE=1 \
    UV_CONCURRENT_DOWNLOADS=${UV_CONCURRENT_DOWNLOADS} \
    UV_CONCURRENT_BUILDS=${UV_CONCURRENT_BUILDS} \
    UV_CONCURRENT_INSTALLS=${UV_CONCURRENT_INSTALLS} \
    UV_LINK_MODE=copy \
    UV_PROJECT_ENVIRONMENT=/opt/physic/.venv \
    CAMERAHMR_DATA_DIR=/workspace/Phy-SIC/data \
    HF_HOME=/workspace/Phy-SIC/data/huggingface \
    HF_HUB_CACHE=/workspace/Phy-SIC/data/huggingface/hub \
    HUGGINGFACE_HUB_CACHE=/workspace/Phy-SIC/data/huggingface/hub \
    TORCH_HOME=/workspace/Phy-SIC/data/torch \
    HF_HUB_OFFLINE=1 \
    TRANSFORMERS_OFFLINE=1 \
    DIFFUSERS_OFFLINE=1 \
    MMPOSE_CONFIG=/workspace/Phy-SIC/data/mmpose/configs/wholebody_2d_keypoint/rtmpose/coco-wholebody/rtmpose-l_8xb64-270e_coco-wholebody-256x192.py \
    MMPOSE_CHECKPOINT=/workspace/Phy-SIC/data/mmpose/rtmpose-l_simcc-coco-wholebody_pt-aic-coco_270e-256x192-6f206314_20230124.pth \
    MMCV_WITH_OPS=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PATH="/opt/physic/.venv/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    ffmpeg \
    git \
    libegl1 \
    libgl1 \
    libgles2 \
    libglib2.0-0 \
    libglvnd0 \
    libjpeg-dev \
    libosmesa6 \
    libsm6 \
    libxext6 \
    libxrender1 \
    ninja-build \
    pkg-config \
    python3.10 \
    python3.10-dev \
    python3.10-venv \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/*

COPY --from=uv /uv /uvx /usr/local/bin/

WORKDIR /workspace/Phy-SIC

COPY pyproject.toml uv.lock README.md ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --python /usr/bin/python3.10 --extra cu128 --locked --no-install-project

COPY . .
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --python /usr/bin/python3.10 --extra cu128 --locked

RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --python /opt/physic/.venv/bin/python --no-deps \
    -e external/ml-depth-pro

RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --python /opt/physic/.venv/bin/python \
    "git+https://github.com/luca-medeiros/lang-segment-anything.git@918043ed4666eea04da88aa179eb8d27ef4b1a1d" \
    "git+https://github.com/jonbarron/robust_loss_pytorch@0c25c59ddbd0a14e5d963ae4f3847f8f3974fdc4" \
    "git+https://github.com/warmshao/WiLoR-mini@a20fc482e68d17c0c8fa19c64f3f4544b6a310cf" \
    "git+https://github.com/isarandi/smplfitter.git@13180c45a9201c8113690ad5158fad20b94be36b" \
    "git+https://github.com/microsoft/MoGe.git@0286b495230a074aadf1c76cc5c679e943e5d1c6"

RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --python /opt/physic/.venv/bin/python --no-build-isolation \
    "detectron2 @ git+https://github.com/facebookresearch/detectron2.git" \
    "git+https://github.com/facebookresearch/pytorch3d.git"

RUN --mount=type=cache,target=/root/.cache/uv \
    uv run --no-sync mim install "mmengine>=0.7.1,<1.0.0" && \
    uv run --no-sync mim install "mmcv>=2.0.0,<2.2.0" --no-build-isolation && \
    uv run --no-sync mim install "mmdet>=3.0.0,<3.3.0" && \
    uv run --no-sync mim install "mmpose==1.3.2" --no-deps

CMD ["uv", "run", "--no-sync", "python", "run_optimizer.py"]
