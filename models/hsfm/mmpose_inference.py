import os
from pathlib import Path
from typing import List

import numpy as np
import torch

os.environ["PYOPENGL_PLATFORM"] = "egl"


PROJECT_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_MMPOSE_CONFIG = (
    PROJECT_ROOT
    / "data"
    / "mmpose"
    / "configs"
    / "wholebody_2d_keypoint"
    / "rtmpose"
    / "coco-wholebody"
    / "rtmpose-l_8xb64-270e_coco-wholebody-256x192.py"
)
DEFAULT_MMPOSE_CHECKPOINT = (
    PROJECT_ROOT
    / "data"
    / "mmpose"
    / "rtmpose-l_simcc-coco-wholebody_pt-aic-coco_270e-256x192-6f206314_20230124.pth"
)
COCO_WHOLEBODY_KEYPOINT_COUNT = 133


def _env_flag(name: str) -> bool:
    value = os.getenv(name, "")
    return value.lower() not in {"", "0", "false", "no", "off"}


enable_offload = not _env_flag("DISABLE_OFFLOAD")
model = None


def _resolve_path(path: str | Path) -> Path:
    resolved = Path(os.path.expandvars(os.path.expanduser(str(path))))
    if not resolved.is_absolute():
        resolved = PROJECT_ROOT / resolved
    return resolved


def _get_model_paths() -> tuple[Path, Path]:
    config_path = _resolve_path(os.getenv("MMPOSE_CONFIG", DEFAULT_MMPOSE_CONFIG))
    checkpoint_path = _resolve_path(
        os.getenv("MMPOSE_CHECKPOINT", DEFAULT_MMPOSE_CHECKPOINT)
    )
    return config_path, checkpoint_path


def load_mmpose(device: str = "cuda"):
    """Load the MMPose RTMPose whole-body model used for 2D keypoints."""
    global model
    if model is not None:
        return model

    config_path, checkpoint_path = _get_model_paths()
    missing = [str(path) for path in (config_path, checkpoint_path) if not path.exists()]
    if missing:
        raise FileNotFoundError(
            "Missing MMPose model files:\n"
            + "\n".join(f"  - {path}" for path in missing)
            + "\nRun fetch_data.sh/fetch_data.bat, or set MMPOSE_CONFIG and "
            "MMPOSE_CHECKPOINT to mounted files."
        )

    from mmpose.apis import init_model
    from mmpose.utils import register_all_modules

    register_all_modules()
    model = init_model(str(config_path), str(checkpoint_path), device=device)
    model.eval()

    if enable_offload:
        model.cpu()
        torch.cuda.empty_cache()

    return model


def delete_mmpose():
    """Release the loaded MMPose model."""
    global model
    if model is not None:
        del model
        model = None
        torch.cuda.empty_cache()


def _extract_keypoints(result) -> tuple[np.ndarray, np.ndarray]:
    pred_instances = result.pred_instances
    keypoints = np.asarray(pred_instances.keypoints)
    scores = np.asarray(pred_instances.keypoint_scores)

    if keypoints.ndim == 3:
        keypoints = keypoints[0]
    if scores.ndim == 2:
        scores = scores[0]

    if keypoints.shape != (COCO_WHOLEBODY_KEYPOINT_COUNT, 2):
        raise ValueError(
            "Expected MMPose whole-body keypoints with shape "
            f"({COCO_WHOLEBODY_KEYPOINT_COUNT}, 2), got {keypoints.shape}."
        )
    if scores.shape != (COCO_WHOLEBODY_KEYPOINT_COUNT,):
        raise ValueError(
            "Expected MMPose whole-body scores with shape "
            f"({COCO_WHOLEBODY_KEYPOINT_COUNT},), got {scores.shape}."
        )

    return keypoints, scores


def get_human_pose_2d_mmpose(image_np: np.ndarray, boxes: List[np.ndarray]):
    """
    Estimate COCO-WholeBody 2D keypoints for detected humans.

    Args:
        image_np: RGB image array.
        boxes: Human bounding boxes in xyxy format.

    Returns:
        keypoints: Array with shape (N, 133, 2).
        scores: Array with shape (N, 133).
    """
    pose_model = load_mmpose()
    boxes_np = np.asarray(boxes, dtype=np.float32)
    if boxes_np.size == 0:
        return (
            np.empty((0, COCO_WHOLEBODY_KEYPOINT_COUNT, 2), dtype=np.float32),
            np.empty((0, COCO_WHOLEBODY_KEYPOINT_COUNT), dtype=np.float32),
        )
    boxes_np = boxes_np.reshape(-1, 4)

    if enable_offload:
        pose_model.cuda()

    from mmpose.apis import inference_topdown

    # MMPose configs use bgr_to_rgb=True, so pass BGR input like OpenCV-based demos.
    image_bgr = np.ascontiguousarray(image_np[:, :, ::-1])
    results = inference_topdown(
        pose_model,
        image_bgr,
        bboxes=boxes_np,
        bbox_format="xyxy",
    )

    if enable_offload:
        pose_model.cpu()
        torch.cuda.empty_cache()

    if len(results) != len(boxes_np):
        raise RuntimeError(
            f"MMPose returned {len(results)} pose results for {len(boxes_np)} boxes."
        )

    keypoints, scores = zip(*[_extract_keypoints(result) for result in results])
    return np.stack(keypoints).astype(np.float32), np.stack(scores).astype(np.float32)
