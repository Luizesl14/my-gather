#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

from process_character_frame import normalize_sprite


FRAME_NAMES = [
    ["idle-front", "walk-down-01", "walk-down-02", "walk-down-03"],
    ["idle-left", "walk-left-01", "walk-left-02", "walk-left-03"],
    ["idle-right", "walk-right-01", "walk-right-02", "walk-right-03"],
    ["idle-back", "walk-up-01", "walk-up-02", "walk-up-03"],
]


def main() -> None:
    parser = argparse.ArgumentParser(description="Slice a 4x4 avatar sheet into 32x48 frames.")
    parser.add_argument("input", help="Input 4x4 sprite sheet PNG")
    parser.add_argument("output_dir", help="Directory that receives named frame PNGs")
    args = parser.parse_args()

    input_path = Path(args.input)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    sheet = Image.open(input_path).convert("RGBA")
    cell_w = sheet.width // 4
    cell_h = sheet.height // 4

    for row, names in enumerate(FRAME_NAMES):
        for col, name in enumerate(names):
            crop = sheet.crop((col * cell_w, row * cell_h, (col + 1) * cell_w, (row + 1) * cell_h))
            frame = normalize_sprite(crop)
            frame.save(output_dir / f"{name}.png")
            print(f"Saved: {output_dir / f'{name}.png'}")


if __name__ == "__main__":
    main()
