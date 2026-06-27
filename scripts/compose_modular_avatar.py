#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
CUSTOM = ROOT / "assets" / "sprites" / "customization"

FRAME_NAMES = [
    "idle-front",
    "idle-back",
    "idle-left",
    "idle-right",
    "walk-down-01",
    "walk-down-02",
    "walk-down-03",
    "walk-left-01",
    "walk-left-02",
    "walk-left-03",
    "walk-right-01",
    "walk-right-02",
    "walk-right-03",
    "walk-up-01",
    "walk-up-02",
    "walk-up-03",
]

FRAME_TO_DIRECTION = {
    "idle-front": "front",
    "idle-back": "back",
    "idle-left": "left",
    "idle-right": "right",
    "walk-down-01": "front",
    "walk-down-02": "front",
    "walk-down-03": "front",
    "walk-left-01": "left",
    "walk-left-02": "left",
    "walk-left-03": "left",
    "walk-right-01": "right",
    "walk-right-02": "right",
    "walk-right-03": "right",
    "walk-up-01": "back",
    "walk-up-02": "back",
    "walk-up-03": "back",
}


def load(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def composite_frame(frame: str, profile: dict[str, object]) -> Image.Image:
    direction = FRAME_TO_DIRECTION[frame]
    canvas = Image.new("RGBA", (32, 48), (0, 0, 0, 0))

    layer_paths = [
        CUSTOM / "body" / str(profile["bodyId"]) / str(profile["skinToneId"]) / f"{frame}.png",
        CUSTOM / "outfits" / "bottoms" / str(profile["bottomId"]) / str(profile["bottomColorId"]) / f"{frame}.png",
        CUSTOM / "outfits" / "tops" / str(profile["topId"]) / str(profile["topColorId"]) / f"{frame}.png",
        CUSTOM / "outfits" / "shoes" / str(profile["shoesId"]) / f"{frame}.png",
        CUSTOM / "hair-fitted" / str(profile["bodyId"]) / str(profile["hairGender"]) / str(profile["hairPackId"]) / str(profile["hairStyleId"]) / f"{direction}.png",
    ]

    for accessory in profile.get("accessoryIds", []):
        layer_paths.append(CUSTOM / "accessories" / str(accessory) / f"{direction}.png")

    for path in layer_paths:
        if path.exists():
            canvas.alpha_composite(load(path))
    return canvas


def make_sheet(output_dir: Path) -> None:
    rows = [
        ["idle-front", "walk-down-01", "walk-down-02", "walk-down-03"],
        ["idle-left", "walk-left-01", "walk-left-02", "walk-left-03"],
        ["idle-right", "walk-right-01", "walk-right-02", "walk-right-03"],
        ["idle-back", "walk-up-01", "walk-up-02", "walk-up-03"],
    ]
    sheet = Image.new("RGBA", (32 * 4, 48 * 4), (0, 0, 0, 0))
    preview = Image.new("RGBA", (128 * 4 + 12 * 5, 192 * 4 + 12 * 5), (32, 32, 32, 255))
    for r, row in enumerate(rows):
        for c, frame in enumerate(row):
            img = load(output_dir / f"{frame}.png")
            sheet.alpha_composite(img, (c * 32, r * 48))
            preview.alpha_composite(img.resize((128, 192), Image.Resampling.NEAREST), (12 + c * 140, 12 + r * 204))
    sheet.save(output_dir / "sprite-sheet.png")
    preview.save(output_dir / "sprite-sheet-preview.png")


def main() -> None:
    parser = argparse.ArgumentParser(description="Compose a complete validation avatar from modular layers.")
    parser.add_argument("--id", default="avatar-office-01", help="Output avatar id")
    args = parser.parse_args()

    profile = {
        "bodyId": "body-office-01",
        "skinToneId": "skin-01",
        "hairGender": "male",
        "hairPackId": "male-hair-pack-02",
        "hairStyleId": "style-01",
        "topId": "top-shirt",
        "topColorId": "cloth-blue",
        "bottomId": "bottom-pants",
        "bottomColorId": "cloth-black",
        "shoesId": "shoes-black",
        "accessoryIds": [
            "accessory-beard-short",
            "accessory-glasses-round",
            "accessory-badge",
        ],
    }

    output_dir = CUSTOM / "assembled" / args.id
    output_dir.mkdir(parents=True, exist_ok=True)
    for frame in FRAME_NAMES:
        composite_frame(frame, profile).save(output_dir / f"{frame}.png")
    make_sheet(output_dir)
    (output_dir / "profile.json").write_text(json.dumps(profile, indent=2, ensure_ascii=False) + "\n")
    print(f"Generated assembled avatar: {output_dir}")


if __name__ == "__main__":
    main()
