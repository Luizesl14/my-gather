#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
CUSTOM = ROOT / "assets" / "sprites" / "customization"
SOURCE = CUSTOM / "hair"
FITTED = CUSTOM / "hair-fitted" / "body-office-01"
BODY = CUSTOM / "body" / "body-office-01" / "skin-01"
PREVIEWS = CUSTOM / "previews" / "hair-fit"

DIRECTIONS = ("front", "back", "left", "right")
OFFSETS = {
    "front": (0, 0),
    "back": (0, -1),
    "left": (-1, 0),
    "right": (1, 0),
}


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    return image.convert("RGBA").getchannel("A").getbbox()


def fit_hair(src: Image.Image, direction: str) -> Image.Image:
    image = src.convert("RGBA")
    bbox = alpha_bbox(image)
    if bbox:
        image = image.crop(bbox)

    target_w = {
        "front": 27,
        "back": 27,
        "left": 24,
        "right": 24,
    }[direction]
    scale = target_w / image.width
    target_h = max(1, round(image.height * scale))
    image = image.resize((target_w, target_h), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
    dx, dy = OFFSETS[direction]
    x = (32 - image.width) // 2 + dx
    y = {
        "front": 0,
        "back": -1,
        "left": 0,
        "right": 0,
    }[direction] + dy
    canvas.alpha_composite(image, (x, y))
    return canvas


def body_frame(direction: str) -> Image.Image:
    frame_name = {
        "front": "idle-front",
        "back": "idle-back",
        "left": "idle-left",
        "right": "idle-right",
    }[direction]
    return Image.open(BODY / f"{frame_name}.png").convert("RGBA")


def render_preview(pack_id: str, style_id: str, fitted_dir: Path) -> Path:
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    cells = []
    for direction in DIRECTIONS:
        composed = body_frame(direction)
        composed.alpha_composite(Image.open(fitted_dir / f"{direction}.png").convert("RGBA"))
        cells.append(composed.resize((128, 192), Image.Resampling.NEAREST))

    preview = Image.new("RGBA", (128 * 4 + 12 * 5, 192 + 24), (32, 32, 32, 255))
    for i, cell in enumerate(cells):
        preview.alpha_composite(cell, (12 + i * (128 + 12), 12))
    out = PREVIEWS / f"{pack_id}-{style_id}.png"
    preview.save(out)
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description="Fit Trae hair overlays to body-office-01 32x48 sprites.")
    parser.add_argument("--limit", type=int, default=0, help="Limit styles processed for quick tests.")
    args = parser.parse_args()

    catalog = {"version": 1, "bodyId": "body-office-01", "packs": []}
    count = 0

    for gender_dir in sorted(p for p in SOURCE.iterdir() if p.is_dir() and p.name in {"female", "male"}):
        for pack_dir in sorted(p for p in gender_dir.iterdir() if p.is_dir()):
            pack = {
                "id": pack_dir.name,
                "gender": gender_dir.name,
                "displayName": pack_dir.name.replace("-", " ").title(),
                "styles": [],
            }
            for style_dir in sorted(p for p in pack_dir.iterdir() if p.is_dir()):
                if args.limit and count >= args.limit:
                    break
                if not all((style_dir / f"{direction}.png").exists() for direction in DIRECTIONS):
                    continue
                target_dir = FITTED / gender_dir.name / pack_dir.name / style_dir.name
                target_dir.mkdir(parents=True, exist_ok=True)
                for direction in DIRECTIONS:
                    fit_hair(Image.open(style_dir / f"{direction}.png"), direction).save(target_dir / f"{direction}.png")
                preview = render_preview(pack_dir.name, style_dir.name, target_dir)
                pack["styles"].append(
                    {
                        "id": style_dir.name,
                        "displayName": style_dir.name.replace("-", " ").title(),
                        "frames": {
                            direction: str((target_dir / f"{direction}.png").relative_to(CUSTOM))
                            for direction in DIRECTIONS
                        },
                        "preview": str(preview.relative_to(CUSTOM)),
                    }
                )
                count += 1
            if pack["styles"]:
                catalog["packs"].append(pack)
            if args.limit and count >= args.limit:
                break
        if args.limit and count >= args.limit:
            break

    out = FITTED / "hair-fitted-catalog.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + "\n")
    print(f"Fitted {count} hair styles")
    print(f"Catalog: {out}")


if __name__ == "__main__":
    main()
