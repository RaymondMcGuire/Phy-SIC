#!/usr/bin/env python3
"""Pre-download Hugging Face runtime models into the mounted data directory."""

from __future__ import annotations

import argparse
import os
from pathlib import Path


HF_REPOS = [
    ("black-forest-labs/FLUX.1-dev", True),
    ("theSure/Omnieraser", False),
    ("Ruicheng/moge-vitl", False),
    ("IDEA-Research/grounding-dino-base", False),
]


def resolve_path(path: str | Path) -> Path:
    resolved = Path(path).expanduser()
    if not resolved.is_absolute():
        resolved = Path.cwd() / resolved
    return resolved.resolve()


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Download Phy-SIC Hugging Face runtime models into data/."
    )
    parser.add_argument(
        "--data-dir",
        default=os.getenv("PHYSIC_DATA_DIR", "data"),
        help="Data directory mounted by Docker Compose. Default: data",
    )
    parser.add_argument(
        "--token",
        default=os.getenv("HF_TOKEN") or os.getenv("HUGGING_FACE_HUB_TOKEN"),
        help="Hugging Face token. Defaults to HF_TOKEN/HUGGING_FACE_HUB_TOKEN.",
    )
    parser.add_argument(
        "--skip-gated",
        action="store_true",
        help="Skip gated repositories such as black-forest-labs/FLUX.1-dev.",
    )
    args = parser.parse_args()

    data_dir = resolve_path(args.data_dir)
    hf_home = data_dir / "huggingface"
    hub_cache = hf_home / "hub"
    torch_home = data_dir / "torch"

    os.environ.setdefault("HF_HOME", str(hf_home))
    os.environ.setdefault("HF_HUB_CACHE", str(hub_cache))
    os.environ.setdefault("HUGGINGFACE_HUB_CACHE", str(hub_cache))
    os.environ.setdefault("TORCH_HOME", str(torch_home))
    os.environ["HF_HUB_OFFLINE"] = "0"
    os.environ["TRANSFORMERS_OFFLINE"] = "0"
    os.environ["DIFFUSERS_OFFLINE"] = "0"

    from huggingface_hub import snapshot_download

    print(f"[hf] data dir: {data_dir}")
    print(f"[hf] hub cache: {hub_cache}")
    hub_cache.mkdir(parents=True, exist_ok=True)
    torch_home.mkdir(parents=True, exist_ok=True)

    missing_token_for_gated = [
        repo_id for repo_id, gated in HF_REPOS if gated and not args.token
    ]
    if missing_token_for_gated and not args.skip_gated:
        repos = ", ".join(missing_token_for_gated)
        raise SystemExit(
            "HF token is required for gated repo(s): "
            f"{repos}\n"
            "Accept the model license on Hugging Face, then set HF_TOKEN in .env "
            "or pass --token. Use --skip-gated only if you do not plan to run "
            "OmniEraser/FLUX."
        )

    for repo_id, gated in HF_REPOS:
        if gated and args.skip_gated:
            print(f"[skip] {repo_id} (gated)")
            continue

        print(f"[download] {repo_id}")
        path = snapshot_download(
            repo_id=repo_id,
            cache_dir=str(hub_cache),
            token=args.token if gated or args.token else None,
        )
        print(f"[ok] {repo_id} -> {path}")

    print("[hf] Done.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
