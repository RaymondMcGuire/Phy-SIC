#!/usr/bin/env python3
"""Export existing Phy-SIC result folders to PLY/GLB assets."""

from __future__ import annotations

import argparse
from pathlib import Path


def _parse_formats(values: list[str]) -> list[str]:
    formats: list[str] = []
    for value in values:
        for item in value.split(","):
            item = item.strip().lower()
            if item:
                formats.append(item)

    unknown = sorted(set(formats) - {"ply", "glb"})
    if unknown:
        raise ValueError(f"Unsupported export format(s): {', '.join(unknown)}")

    return sorted(set(formats), key=formats.index)


def _has_result_files(path: Path) -> bool:
    return (path / "scene_data_final.pkl").is_file() and (path / "scene_image.png").is_file()


def _iter_result_dirs(paths: list[Path]) -> list[Path]:
    result_dirs: list[Path] = []

    for path in paths:
        path = path.expanduser()
        if path.is_file() and path.name == "scene_data_final.pkl":
            path = path.parent

        if _has_result_files(path):
            result_dirs.append(path)
            continue

        if path.is_dir():
            for pkl_path in path.rglob("scene_data_final.pkl"):
                candidate = pkl_path.parent
                if _has_result_files(candidate):
                    result_dirs.append(candidate)

    unique: list[Path] = []
    seen: set[Path] = set()
    for path in result_dirs:
        resolved = path.resolve()
        if resolved not in seen:
            unique.append(path)
            seen.add(resolved)

    return unique


def _export_scene(scene, output_base: Path, formats: list[str]) -> None:
    for fmt in formats:
        output_path = output_base.with_suffix(f".{fmt}")
        scene.export(output_path)
        print(f"[export] {output_path}")


def export_result_dir(
    result_dir: Path,
    formats: list[str],
    max_faces: int,
    separated: bool,
    split_humans: bool,
    coordinate_system: str,
) -> None:
    import torch

    from utils.vis import get_individual_human_scenes, get_scene

    print(f"[export] Result directory: {result_dir.resolve()}")

    with torch.amp.autocast(enabled=False, device_type="cuda"):
        merged_scene = get_scene(
            result_dir,
            max_faces=max_faces,
            coordinate_system=coordinate_system,
        )
    _export_scene(merged_scene, result_dir / "humanscene", formats)

    if separated:
        with torch.amp.autocast(enabled=False, device_type="cuda"):
            scene_only, human_only = get_scene(
                result_dir,
                separate_human_scene=True,
                max_faces=max_faces,
                coordinate_system=coordinate_system,
            )
        _export_scene(scene_only, result_dir / "scene_only", formats)
        _export_scene(human_only, result_dir / "human_only", formats)

        if split_humans:
            with torch.amp.autocast(enabled=False, device_type="cuda"):
                human_scenes = get_individual_human_scenes(
                    result_dir,
                    max_faces=max_faces,
                    coordinate_system=coordinate_system,
                )
            for idx, human_scene in enumerate(human_scenes, start=1):
                _export_scene(human_scene, result_dir / f"human_{idx}", formats)


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Export existing Phy-SIC result folders containing scene_data_final.pkl "
            "and scene_image.png to PLY/GLB."
        )
    )
    parser.add_argument(
        "paths",
        nargs="*",
        default=["outputs/wild_results"],
        help=(
            "Result folder(s), scene_data_final.pkl file(s), or parent folders to scan. "
            "Default: outputs/wild_results"
        ),
    )
    parser.add_argument(
        "--formats",
        nargs="+",
        default=["ply", "glb"],
        help="Export formats: ply, glb, or comma-separated values. Default: ply glb",
    )
    parser.add_argument(
        "--max-faces",
        type=int,
        default=int(1e18),
        help="Maximum scene faces before decimation. Default: no practical limit.",
    )
    parser.add_argument(
        "--merged-only",
        action="store_true",
        help=(
            "Only export humanscene.* and skip scene_only.*, human_only.*, "
            "and per-person human_N.* files."
        ),
    )
    parser.add_argument(
        "--no-split-humans",
        action="store_true",
        help="Skip per-person human_1.* / human_2.* exports.",
    )
    parser.add_argument(
        "--coordinate-system",
        default="gltf",
        choices=["camera", "gltf", "blender"],
        help=(
            "Output axis basis. 'camera' keeps legacy Phy-SIC camera coordinates; "
            "'gltf' is recommended for GLB import into Blender/Unity; "
            "'blender' writes raw Blender-native Z-up vertices. Default: gltf."
        ),
    )
    args = parser.parse_args()

    formats = _parse_formats(args.formats)
    result_dirs = _iter_result_dirs([Path(path) for path in args.paths])

    if not result_dirs:
        raise FileNotFoundError(
            "No result folders found. Expected scene_data_final.pkl and scene_image.png."
        )

    for result_dir in result_dirs:
        export_result_dir(
            result_dir=result_dir,
            formats=formats,
            max_faces=args.max_faces,
            separated=not args.merged_only,
            split_humans=not args.no_split_humans,
            coordinate_system=args.coordinate_system,
        )

    print(f"[export] Done. Exported {len(result_dirs)} result folder(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
