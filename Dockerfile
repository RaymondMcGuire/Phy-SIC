# syntax=docker/dockerfile:1.7

FROM nvidia/cuda:12.1.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    AM_I_DOCKER=False \
    BUILD_WITH_CUDA=True \
    DATA_ROOT=data \
    PYOPENGL_PLATFORM=egl \
    PYTHONUNBUFFERED=1 \
    UV_PROJECT_ENVIRONMENT=/opt/physic/.venv \
    UV_PYTHON=/usr/bin/python3.10 \
    UV_LINK_MODE=copy \
    UV_NO_SYNC=1 \
    UV_CONCURRENT_BUILDS=1 \
    UV_CONCURRENT_DOWNLOADS=2 \
    UV_CONCURRENT_INSTALLS=2 \
    MAX_JOBS=1 \
    CMAKE_BUILD_PARALLEL_LEVEL=1 \
    MAKEFLAGS=-j1 \
    NINJAFLAGS=-j1 \
    TORCH_CUDA_ARCH_LIST="9.0+PTX"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    cmake \
    curl \
    ffmpeg \
    git \
    libegl1 \
    libgl1 \
    libglib2.0-0 \
    libglvnd0 \
    libosmesa6-dev \
    libsm6 \
    libx11-6 \
    libxext6 \
    libxrender1 \
    ninja-build \
    python3-pip \
    python3.10 \
    python3.10-dev \
    python3.10-venv \
    unzip \
    wget \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN python3.10 -m pip install --no-cache-dir --upgrade pip setuptools wheel uv

WORKDIR /workspace/Phy-SIC

COPY . .

RUN --mount=type=cache,target=/root/.cache/uv uv lock
RUN --mount=type=cache,target=/root/.cache/uv uv sync --frozen --no-dev
RUN --mount=type=cache,target=/root/.cache/uv uv pip install --python /opt/physic/.venv/bin/python --no-deps \
    "sam-2 @ git+https://github.com/facebookresearch/segment-anything-2@c2ec8e14a185632b0a5d8b161928ceb50197eddc"
RUN --mount=type=cache,target=/root/.cache/uv uv pip install --python /opt/physic/.venv/bin/python "setuptools==69.5.1"
RUN uv run mim install "mmcv==1.3.9" --no-deps && uv run mim install "mmdet<3"

ENV PATH="/opt/physic/.venv/bin:${PATH}" \
    PYTHONPATH="/workspace/Phy-SIC:/workspace/Phy-SIC/external/CameraHMR:/workspace/Phy-SIC/external/lang-segment-anything:/workspace/Phy-SIC/external/ml-depth-pro/src:/workspace/Phy-SIC/external/ViTPose"

CMD ["bash"]
