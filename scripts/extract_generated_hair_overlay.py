#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image

from process_character_frame import normalize_sprite


FRAME_NAMES = [
    ["idle-front", "walk-down-01", "walk-down-02", "walk-down-03"],
    ["idle-left", "walk-left-01", "walk-left-02", "walk-left-03"],
    ["idle-right", "walk-right-01", "walk-right-02", "walk-right-03"],
    ["idle-back", "walk-up-01", "walk-up-02", "walk-up-03"],
]

DIRECTION_BY_FRAME = {
    "idle-front": "front",
    "walk-down-01": "front",
    "walk-down-02": "front",
    "walk-down-03": "front",
    "idle-left": "left",
    "walk-left-01": "left",
    "walk-left-02": "left",
    "walk-left-03": "left",
    "idle-right": "right",
    "walk-right-01": "right",
    "walk-right-02": "right",
    "walk-right-03": "right",
    "idle-back": "back",
    "walk-up-01": "back",
    "walk-up-02": "back",
    "walk-up-03": "back",
}


def is_hair_pixel(r: int, g: int, b: int, a: int, y: int) -> bool:
    if a < 24:
        return False
    if y > 27:
        return False
    # Brown hair body.
    if 42 <= r <= 170 and 24 <= g <= 125 and 12 <= b <= 95 and r >= g - 8 and g >= b - 14:
        return True
    # Red/auburn hair body.
    if 82 <= r <= 205 and 18 <= g <= 105 and 8 <= b <= 85 and r >= g + 18 and g >= b - 10:
        return True
    # Black/dark gray hair body.
    if y <= 26 and r <= 88 and g <= 88 and b <= 92:
        return True
    # Dark hair outline in the head region.
    if y <= 24 and r <= 64 and g <= 52 and b <= 44:
        return True
    return False


def extract_hair(frame: Image.Image) -> Image.Image:
    normalized = normalize_sprite(frame)
    out = Image.new("RGBA", normalized.size, (0, 0, 0, 0))
    src = normalized.load()
    dst = out.load()
    for y in range(normalized.height):
        for x in range(normalized.width):
            r, g, b, a = src[x, y]
            if is_hair_pixel(r, g, b, a, y):
                dst[x, y] = (r, g, b, a)
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description="Extract hair overlays from a generated full avatar sheet.")
    parser.add_argument("input", help="Generated 4x4 sheet that includes the avatar with hair")
    parser.add_argument("output_dir", help="Output hair overlay directory")
    args = parser.parse_args()

    sheet = Image.open(args.input).convert("RGBA")
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    cell_w = sheet.width // 4
    cell_h = sheet.height // 4

    frame_map: dict[str, str] = {}
    for row, names in enumerate(FRAME_NAMES):
        for col, frame_name in enumerate(names):
            crop = sheet.crop((col * cell_w, row * cell_h, (col + 1) * cell_w, (row + 1) * cell_h))
            hair = extract_hair(crop)
            out_path = output_dir / f"{frame_name}.png"
            hair.save(out_path)
            frame_map[frame_name] = str(out_path)
            print(f"Saved: {out_path}")

    directional_dir = output_dir / "directional"
    directional_dir.mkdir(exist_ok=True)
    for source_name, direction in (
        ("idle-front", "front"),
        ("idle-back", "back"),
        ("idle-left", "left"),
        ("idle-right", "right"),
    ):
        Image.open(output_dir / f"{source_name}.png").save(directional_dir / f"{direction}.png")

    metadata = {
        "id": output_dir.name,
        "displayName": output_dir.name.replace("-", " ").title(),
        "sourceSheet": args.input,
        "frames": {
            frame: str((output_dir / f"{frame}.png").as_posix())
            for row in FRAME_NAMES
            for frame in row
        },
        "directional": {
            direction: str((directional_dir / f"{direction}.png").as_posix())
            for direction in ("front", "back", "left", "right")
        },
    }
    (output_dir / "metadata.json").write_text(json.dumps(metadata, indent=2, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main()
