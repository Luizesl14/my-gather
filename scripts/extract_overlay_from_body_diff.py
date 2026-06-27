#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image

from process_character_frame import normalize_sprite

ROOT = Path(__file__).resolve().parents[1]
CUSTOM = ROOT / "assets" / "sprites" / "customization"


FRAME_NAMES = [
    ["idle-front", "walk-down-01", "walk-down-02", "walk-down-03"],
    ["idle-left", "walk-left-01", "walk-left-02", "walk-left-03"],
    ["idle-right", "walk-right-01", "walk-right-02", "walk-right-03"],
    ["idle-back", "walk-up-01", "walk-up-02", "walk-up-03"],
]

REGIONS = {
    "top": (10, 31),
    "bottom": (24, 47),
    "shoes": (36, 47),
    "beard": (8, 24),
    "glasses": (8, 22),
    "badge": (20, 34),
}

DIFF_THRESHOLD = 28


def diff_overlay(base: Image.Image, generated: Image.Image, y_min: int, y_max: int) -> Image.Image:
    base = base.convert("RGBA")
    generated = generated.convert("RGBA")
    out = Image.new("RGBA", base.size, (0, 0, 0, 0))
    bp = base.load()
    gp = generated.load()
    op = out.load()
    for y in range(base.height):
        if y < y_min or y > y_max:
            continue
        for x in range(base.width):
            br, bg, bb, ba = bp[x, y]
            gr, gg, gb, ga = gp[x, y]
            if ga == 0:
                continue
            dist = abs(gr - br) + abs(gg - bg) + abs(gb - bb) + abs(ga - ba)
            if dist >= DIFF_THRESHOLD:
                op[x, y] = (gr, gg, gb, ga)
    return out


def build_preview(output_dir: Path, overlay_name: str) -> None:
    body_dir = CUSTOM / "body" / "body-office-01" / "skin-01"
    rows = FRAME_NAMES
    preview = Image.new("RGBA", (128 * 4 + 12 * 5, 192 * 4 + 12 * 5), (32, 32, 32, 255))
    for r, row in enumerate(rows):
        for c, frame in enumerate(row):
            body = Image.open(body_dir / f"{frame}.png").convert("RGBA")
            overlay = Image.open(output_dir / f"{frame}.png").convert("RGBA")
            body.alpha_composite(overlay)
            preview.alpha_composite(body.resize((128, 192), Image.Resampling.NEAREST), (12 + c * 140, 12 + r * 204))
    preview.save(output_dir / "preview-on-body.png")


def main() -> None:
    parser = argparse.ArgumentParser(description="Extract an overlay from a generated sheet by diffing against the body.")
    parser.add_argument("category", choices=sorted(REGIONS.keys()))
    parser.add_argument("body_sheet", help="Reference body sheet PNG")
    parser.add_argument("generated_sheet", help="Generated sheet PNG that includes the garment/accessory")
    parser.add_argument("output_dir", help="Output directory for 32x48 overlays")
    args = parser.parse_args()

    body_sheet = Image.open(args.body_sheet).convert("RGBA")
    gen_sheet = Image.open(args.generated_sheet).convert("RGBA")
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    cell_w = body_sheet.width // 4
    cell_h = body_sheet.height // 4
    y_min, y_max = REGIONS[args.category]

    for row, names in enumerate(FRAME_NAMES):
        for col, frame_name in enumerate(names):
            body_crop = body_sheet.crop((col * cell_w, row * cell_h, (col + 1) * cell_w, (row + 1) * cell_h))
            gen_crop = gen_sheet.crop((col * cell_w, row * cell_h, (col + 1) * cell_w, (row + 1) * cell_h))
            body_frame = normalize_sprite(body_crop)
            gen_frame = normalize_sprite(gen_crop)
            overlay = diff_overlay(body_frame, gen_frame, y_min, y_max)
            overlay.save(output_dir / f"{frame_name}.png")
            print(f"Saved: {output_dir / f'{frame_name}.png'}")

    build_preview(output_dir, args.category)
    metadata = {
        "category": args.category,
        "bodySheet": args.body_sheet,
        "generatedSheet": args.generated_sheet,
        "frames": {frame: str((output_dir / f"{frame}.png").as_posix()) for row in FRAME_NAMES for frame in row},
        "preview": str((output_dir / "preview-on-body.png").as_posix()),
    }
    (output_dir / "metadata.json").write_text(json.dumps(metadata, indent=2, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main()
