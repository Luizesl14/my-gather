#!/usr/bin/env python3
"""
Extract a paper-doll overlay layer (hair, top, shoes, glasses...) by subtracting
the base body frames from a "base body wearing the item" sheet.

Why a color-distance threshold instead of exact equality: the generator re-renders
the whole character, so nearly every pixel differs by a small amount (shading /
antialias noise) even where nothing structurally changed. Measured on the pilot,
an exact diff flags ~600 px per frame with half of them on the untouched body,
while a threshold of 60 collapses that to ~190 px on the head and <10 on the body.
The threshold is what separates the real garment from re-render noise.

The region clamp is a second guard: a hair layer cannot legitimately contain
pixels near the feet, so anything outside the item's band is dropped.

Usage:
  python3 scripts/extract_kling_overlay.py \
      --base assets/kling/frames/body/base-unissex \
      --variant assets/kling/frames/_tmp-hair01 \
      --out assets/kling/frames/hair/hair-01 \
      --region hair
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image

FRAME_NAMES = [
    "idle-front", "walk-down-01", "walk-down-02", "walk-down-03",
    "idle-left", "walk-left-01", "walk-left-02", "walk-left-03",
    "idle-right", "walk-right-01", "walk-right-02", "walk-right-03",
    "idle-back", "walk-up-01", "walk-up-02", "walk-up-03",
]

# Vertical band (y_min, y_max inclusive) each layer is allowed to occupy in the
# 32x48 sprite. Anything the diff finds outside the band is re-render noise.
# Tuned for the anime-chibi proportions (head ~y0-28, torso ~26-40, legs 38-47);
# override per-run with --band when a sheet deviates.
REGIONS = {
    "hair": (0, 30),
    "glasses": (8, 24),
    "beard": (14, 32),
    "top": (22, 42),
    "bottom": (32, 46),
    "shoes": (40, 47),
    "full": (0, 47),
}


def extract(base_dir: Path, variant_dir: Path, out_dir: Path, region: str, threshold: int) -> dict:
    band = REGIONS[region]
    out_dir.mkdir(parents=True, exist_ok=True)
    stats = {}

    for name in FRAME_NAMES:
        base = Image.open(base_dir / f"{name}.png").convert("RGBA")
        variant = Image.open(variant_dir / f"{name}.png").convert("RGBA")
        overlay = Image.new("RGBA", base.size, (0, 0, 0, 0))
        # Bandas calibradas em sprite de altura 48; escala para a altura real.
        y_min = round(band[0] * base.height / 48)
        y_max = round(band[1] * base.height / 48)

        kept = 0
        for y in range(base.height):
            if y < y_min or y > y_max:
                continue
            for x in range(base.width):
                pb = base.getpixel((x, y))
                pv = variant.getpixel((x, y))
                if pv[3] == 0:
                    continue
                if max(abs(pb[i] - pv[i]) for i in range(4)) > threshold:
                    overlay.putpixel((x, y), pv)
                    kept += 1

        overlay.save(out_dir / f"{name}.png")
        stats[name] = kept

    return stats


def main() -> None:
    parser = argparse.ArgumentParser(description="Extract a paper-doll overlay by diffing against the base body.")
    parser.add_argument("--base", required=True, help="Directory with the 16 base-body frames")
    parser.add_argument("--variant", required=True, help="Directory with the 16 'body wearing item' frames")
    parser.add_argument("--out", required=True, help="Directory that receives the 16 overlay frames")
    parser.add_argument("--region", required=True, choices=sorted(REGIONS), help="Which band the layer may occupy")
    parser.add_argument("--threshold", type=int, default=60, help="Color distance above which a pixel counts as changed")
    parser.add_argument("--band", help="Override the region band as 'y_min,y_max' (inclusive)")
    args = parser.parse_args()

    if args.band:
        y0, y1 = (int(v) for v in args.band.split(","))
        REGIONS[args.region] = (y0, y1)

    stats = extract(Path(args.base), Path(args.variant), Path(args.out), args.region, args.threshold)

    meta = {
        "region": args.region,
        "band": REGIONS[args.region],
        "threshold": args.threshold,
        "base": args.base,
        "pixelsPerFrame": stats,
    }
    Path(args.out, "overlay-meta.json").write_text(json.dumps(meta, indent=2) + "\n")

    empty = [n for n, c in stats.items() if c == 0]
    print(f"Wrote 16 overlay frames to {args.out}")
    print(f"Pixels kept per frame: min={min(stats.values())} max={max(stats.values())}")
    if empty:
        print(f"WARNING: {len(empty)} frame(s) came out empty: {', '.join(empty)}")


if __name__ == "__main__":
    main()