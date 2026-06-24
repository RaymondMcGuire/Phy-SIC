#!/usr/bin/env bash
set -euo pipefail

# Install uv first if needed:
# curl -LsSf https://astral.sh/uv/install.sh | sh

export AM_I_DOCKER="${AM_I_DOCKER:-False}"
export BUILD_WITH_CUDA="${BUILD_WITH_CUDA:-True}"
export FORCE_CUDA="${FORCE_CUDA:-1}"
export PYOPENGL_PLATFORM="${PYOPENGL_PLATFORM:-egl}"
export MAX_JOBS="${MAX_JOBS:-2}"
export CMAKE_BUILD_PARALLEL_LEVEL="${CMAKE_BUILD_PARALLEL_LEVEL:-2}"
export MAKEFLAGS="${MAKEFLAGS:--j2}"
export UV_CONCURRENT_DOWNLOADS="${UV_CONCURRENT_DOWNLOADS:-2}"
export UV_CONCURRENT_BUILDS="${UV_CONCURRENT_BUILDS:-1}"
export UV_CONCURRENT_INSTALLS="${UV_CONCURRENT_INSTALLS:-2}"
export PIP_DISABLE_PIP_VERSION_CHECK="${PIP_DISABLE_PIP_VERSION_CHECK:-1}"
export PIP_NO_CACHE_DIR="${PIP_NO_CACHE_DIR:-1}"

uv sync --extra cu128 --locked

uv pip install --no-deps \
  -e external/ml-depth-pro \
  -e external/ViTPose

uv pip install \
  "git+https://github.com/luca-medeiros/lang-segment-anything.git@918043ed4666eea04da88aa179eb8d27ef4b1a1d" \
  "git+https://github.com/jonbarron/robust_loss_pytorch@0c25c59ddbd0a14e5d963ae4f3847f8f3974fdc4" \
  "git+https://github.com/warmshao/WiLoR-mini@a20fc482e68d17c0c8fa19c64f3f4544b6a310cf" \
  "git+https://github.com/isarandi/smplfitter.git@13180c45a9201c8113690ad5158fad20b94be36b" \
  "git+https://github.com/microsoft/MoGe.git@0286b495230a074aadf1c76cc5c679e943e5d1c6"

uv pip install --no-build-isolation \
  "detectron2 @ git+https://github.com/facebookresearch/detectron2.git" \
  "git+https://github.com/facebookresearch/pytorch3d.git"

uv run --no-sync mim install "mmcv==1.3.9" --no-deps
uv run --no-sync mim install "mmdet==2.14.0" --no-deps
