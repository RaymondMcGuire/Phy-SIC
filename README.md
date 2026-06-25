<h2 align="center">
  <a href="https://yuxuan-xue.com/physic/">PhySIC: Physically Plausible 3D Human-Scene Interaction and Contact from a Single Image</a>
</h2>

<h5 align="center">

[![arXiv](https://img.shields.io/badge/Arxiv-2510.11649-b31b1b.svg?logo=arXiv)](http://arxiv.org/abs/2510.11649) 
[![Home Page](https://img.shields.io/badge/Project-Website-C27185.svg)](https://yuxuan-xue.com/physic/) 

[Pradyumna Yalandur Muralidhar](https://pradyumanym.github.io/)<sup>★</sup>,
[Yuxuan Xue](https://yuxuan-xue.com/)<sup>★†</sup>,
[Xianghui Xie](https://virtualhumans.mpi-inf.mpg.de/people/Xie.html),
Margaret Kostyrko,
[Gerard Pons-Moll](https://virtualhumans.mpi-inf.mpg.de/)
</h5>

<div align="center">
TL;DR: Human-Scene Interaction and Contact from a Single Image with Physical Plausibility.
</div>
<br>

https://github.com/user-attachments/assets/86105b9b-ff49-41de-8fd8-dbf25e3e0b26

## Getting Started

### Installation
Please follow the instructions in [INSTALL.md](INSTALL.md) to set up the environment.

### Downloading Data
Please run the following script to download the required data on Linux/WSL:
```bash
bash fetch_data.sh
```

On Windows, use:
```bat
fetch_data.bat
```

This requires access to [SMPL](https://smpl.is.tue.mpg.de/), [SMPL-X](https://smpl-x.is.tue.mpg.de/), [AGORA](https://agora.is.tue.mpg.de/), and [CameraHMR](https://camerahmr.is.tue.mpg.de/). Please enter the credentials when prompted.
The MMPose RTMPose whole-body config/checkpoint is downloaded into `data/mmpose/`; Docker Compose mounts `data/` into the container by default. To use a different host model folder, set `PHYSIC_DATA_DIR` before running Compose.

Runtime models from Hugging Face can also be pre-downloaded into the mounted `data/huggingface/` cache. On Windows, use:

```bat
fetch_hf_data.bat
```

This creates a lightweight `.hf-download-venv` for `huggingface_hub` only, downloads into the local `data/` folder, and lets Docker read the same files through `PHYSIC_DATA_DIR`. Public runtime repos such as MoGe, GroundingDINO, and WiLoR-mini are included. `black-forest-labs/FLUX.1-dev` and `theSure/Omnieraser` are gated/restricted on Hugging Face, so `fetch_hf_data.bat` downloads them by default and needs `HF_TOKEN` in `.env` after accepting/requesting access on both model pages. Docker runtime is forced offline for Hugging Face and does not receive the token.

### Running the Code
To run the code, copy images to the `images/` directory. Then execute:

```bash
docker compose run --rm physic
```

For a local uv environment, use:

```bash
uv run --no-sync python run_optimizer.py
```

Results are saved under:

```text
outputs/<run_name>/<image_stem>/
```

For the default config, this is usually:

```text
outputs/wild_results/<image_stem>/
```

Each completed image folder contains:

```text
scene_image.png          # OmniEraser inpainted scene image
scene_data_final.pkl     # saved numerical reconstruction data
humanscene.ply/.glb      # combined scene + human
scene_only.ply/.glb      # scene only, vertex-colored
human_only.ply/.glb      # SMPL-X human only, gray
```

The exported meshes use vertex colors, not UV texture maps. Blender usually reads the `.glb` files more reliably than `.ply` for vertex-color display.

### Docker Command Reference

Build the CUDA 12.8 image:

```bash
docker compose build physic
```

Run the full pipeline:

```bash
docker compose run --rm physic
```

Check the container exit code after a run:

```bash
echo "EXIT_CODE=$?"
```

Inspect effective Compose settings:

```bash
docker compose config | grep -E "PHYSIC_OMNI|PHYSIC_MOGE|PYTORCH_CUDA_ALLOC_CONF|mem_limit"
```

Recommended low-memory settings for FLUX/OmniEraser in `.env`:

```env
PHYSIC_MEM_LIMIT=64g
PHYSIC_OMNI_DEVICE=cuda:1
PHYSIC_OMNI_OFFLOAD=sequential
PHYSIC_OMNI_IMAGE_SIZE=768
PHYSIC_OMNI_STEPS=20
PHYSIC_MOGE_ATTENTION=sdpa
PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
```

### Export Existing Results

If `scene_data_final.pkl` and `scene_image.png` already exist, you can regenerate PLY/GLB files without rerunning the full optimization:

```bash
docker compose run --rm --no-deps --entrypoint /bin/bash physic -lc \
  'uv run --no-sync python export_results.py outputs/wild_results/man_couch'
```

Export every completed result under `outputs/wild_results`:

```bash
docker compose run --rm --no-deps --entrypoint /bin/bash physic -lc \
  'uv run --no-sync python export_results.py outputs/wild_results'
```

Only export GLB files:

```bash
docker compose run --rm --no-deps --entrypoint /bin/bash physic -lc \
  'uv run --no-sync python export_results.py outputs/wild_results --formats glb'
```

Only export the merged human-scene asset:

```bash
docker compose run --rm --no-deps --entrypoint /bin/bash physic -lc \
  'uv run --no-sync python export_results.py outputs/wild_results --merged-only'
```
 
## Roadmap

- [x] **Demo code release**
- [ ] **Evaluation code**

## Acknowledgements
This code is built on top of many great open-source projects. We would like to thank the authors of the following repositories:
- [OmniEraser](https://github.com/PRIS-CV/Omnieraser) for the image inpainting code.
- [MoGe](https://github.com/microsoft/MoGe) for affine-invariant depth estimation.
- [CameraHMR](https://github.com/pixelite1201/CameraHMR/) and the current [RaymondMcGuire/CameraHMR](https://github.com/RaymondMcGuire/CameraHMR) submodule for the initial human mesh estimation.
- [WiLoR](https://github.com/rolpotamias/WiLoR)/[WiLoR-mini](https://github.com/warmshao/WiLoR-mini) for initial hand pose estimation.
- [DECO](https://github.com/sha2nkt/deco) for contact estimation.
- [DepthPro](https://github.com/apple/ml-depth-pro) for metric depth estimation.
- [HSfM](https://github.com/hongsukchoi/HSfM_RELEASE) and [MMPose/RTMPose](https://github.com/open-mmlab/mmpose) for the whole-body 2D pose estimation pipeline.
- [LangSAM](https://github.com/luca-medeiros/lang-segment-anything), [GroundingDINO](https://github.com/IDEA-Research/GroundingDINO), and [Segment-Anything](https://github.com/facebookresearch/segment-anything) for the segmentation code and models.
- [SMPLFitter](https://github.com/isarandi/smplfitter)/[NLF](https://github.com/isarandi/nlf) for the SMPL-to-SMPL-X converter.

and many others.

## Citation

If you find our work useful, please cite:

```bibtex
@inproceedings{ym2025physic,
  author    = {Yalandur Muralidhar, Pradyumna and Xue, Yuxuan and Xie, Xianghui and Kostyrko, Margaret and Pons-Moll, Gerard},
  title     = {PhySIC: Physically Plausible 3D Human-Scene Interaction and Contact from a Single Image},
  journal   = {SIGGRAPH Asia 2025 Conference Papers},
  year      = {2025},
}
```
