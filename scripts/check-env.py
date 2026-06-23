import argparse
import importlib.util
import os
import platform
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

PYTHON_MODULES = [
    ("torch", "PyTorch"),
    ("torchvision", "torchvision"),
    ("cv2", "OpenCV"),
    ("numpy", "NumPy"),
    ("omegaconf", "OmegaConf"),
    ("trimesh", "trimesh"),
    ("smplx", "SMPL-X Python package"),
    ("open3d", "Open3D"),
    ("pytorch3d", "PyTorch3D"),
    ("detectron2", "Detectron2"),
    ("mmcv", "MMCV"),
    ("mmdet", "MMDetection"),
    ("mmpose", "ViTPose/MMPose"),
    ("lang_sam", "LangSAM"),
    ("sam2", "SAM2"),
    ("depth_pro", "Depth Pro"),
    ("moge", "MoGe"),
    ("wilor_mini", "WiLoR-mini"),
    ("smplfitter", "SMPLFitter"),
    ("robust_loss_pytorch", "Robust Loss PyTorch"),
    ("xformers", "xFormers"),
    ("embreex", "embreex"),
]

REQUIRED_DATA = [
    "data/body_models/smpl/SMPL_NEUTRAL.pkl",
    "data/body_models/smpl/basicmodel_neutral_lbs_10_207_0_v1.1.0.pkl",
    "data/body_models/smpl/kid_template.npy",
    "data/body_models/smpl/smpl_neutral_tpose.ply",
    "data/body_models/smplx/SMPLX_NEUTRAL.npz",
    "data/body_models/smplx/kid_template.npy",
    "data/body_models/smplx/smplx_neutral_tpose.ply",
    "data/body_models/smplx/smplx_vert_segmentation.json",
    "data/body_models/smpl2smplx_deftrafo_setup.pkl",
    "data/conversions/smpl_to_smplx.pkl",
    "data/conversions/smplx_to_smpl.pkl",
    "data/chmr/cam_model_cleaned.ckpt",
    "data/chmr/camerahmr_checkpoint_cleaned.ckpt",
    "data/chmr/model_final_f05665.pkl",
    "data/chmr/smpl_mean_params.npz",
    "data/vitpose_huge_wholebody.pth",
    "data/depth_pro.pt",
    "data/deco/deco_best.pth",
    "data/deco/pose_hrnet_w32_256x192.pth",
]


def has_module(name: str) -> bool:
    return importlib.util.find_spec(name) is not None


def check_python() -> int:
    print(f"[env] platform: {platform.platform()}")
    print(f"[env] python:   {sys.version.split()[0]} ({sys.executable})")
    if sys.version_info[:2] != (3, 10):
        print("[env] WARN: this project was tested with Python 3.10.")
        return 1
    return 0


def check_modules() -> int:
    missing = []
    for module, label in PYTHON_MODULES:
        if has_module(module):
            print(f"[env] OK   {label}")
        else:
            print(f"[env] MISS {label} ({module})")
            missing.append(module)

    if has_module("torch"):
        import torch

        print(f"[env] torch: {torch.__version__}")
        print(f"[env] torch cuda: {torch.version.cuda}")
        print(f"[env] cuda available: {torch.cuda.is_available()}")
        if torch.cuda.is_available():
            print(f"[env] cuda device: {torch.cuda.get_device_name(0)}")

    return 1 if missing else 0


def check_data() -> int:
    missing = []
    for relative in REQUIRED_DATA:
        path = ROOT / relative
        if path.exists():
            print(f"[data] OK   {relative}")
        else:
            print(f"[data] MISS {relative}")
            missing.append(relative)

    image_dir = ROOT / "images"
    image_count = 0
    if image_dir.exists():
        image_count = sum(
            1
            for item in image_dir.iterdir()
            if item.suffix.lower() in {".jpg", ".jpeg", ".png", ".webp", ".bmp", ".tif", ".tiff"}
        )
    print(f"[data] images: {image_count} files in images/")
    return 1 if missing else 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-only", action="store_true", help="Only check downloaded model/data files.")
    args = parser.parse_args()

    os.chdir(ROOT)
    if args.data_only:
        return check_data()

    rc = 0
    rc |= check_python()
    rc |= check_modules()
    rc |= check_data()
    return rc


if __name__ == "__main__":
    raise SystemExit(main())
