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
    UV_NO_SYNC=1

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

RUN uv lock && uv sync --frozen --no-dev
RUN uv run mim install "mmcv==1.3.9" --no-deps && uv run mim install "mmdet<3"

ENV PATH="/opt/physic/.venv/bin:${PATH}" \
    PYTHONPATH="/workspace/Phy-SIC:/workspace/Phy-SIC/external/CameraHMR:/workspace/Phy-SIC/external/lang-segment-anything:/workspace/Phy-SIC/external/ml-depth-pro/src:/workspace/Phy-SIC/external/ViTPose"

CMD ["bash"]
