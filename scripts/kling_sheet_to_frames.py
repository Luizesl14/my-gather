#!/usr/bin/env python3
"""
Slice a Kling-generated sprite sheet into the 16 game frames (32x48).

Unlike process_character_frame.normalize_sprite, this does NOT bbox-crop each
frame independently. Every cell is cut from the same grid and scaled by the same
factor onto the same offsets, so the body sheet and every overlay sheet (hair,
top, shoes, glasses) land on the same pixel grid. That shared registration is
what makes the modular paper-doll composition possible.

The generator tends to emit 5 columns and to draw separator lines, and it does
not reliably produce a right-facing row, so the right side is mirrored from the
left. Those are handled here rather than by re-rolling the (paid) generation.

Usage:
  python3 scripts/kling_sheet_to_frames.py <sheet.png> <out_dir> [--cols 5]
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image

DEFAULT_SIZE = "128x128"

ROW_FRONT, ROW_LEFT, ROW_BACK = 0, 1, 3

FRONT_NAMES = ["idle-front", "walk-down-01", "walk-down-02", "walk-down-03"]
LEFT_NAMES = ["idle-left", "walk-left-01", "walk-left-02", "walk-left-03"]
RIGHT_NAMES = ["idle-right", "walk-right-01", "walk-right-02", "walk-right-03"]
BACK_NAMES = ["idle-back", "walk-up-01", "walk-up-02", "walk-up-03"]


def hex_to_rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16))


def key_out_magenta(image: Image.Image) -> Image.Image:
    """Drop every magenta-ish pixel: the flat background and the darker separator
    lines the model draws are both magenta-dominant, while the character art is
    skin/gray/black. Keying on hue rather than an exact value catches both."""
    image = image.convert("RGBA")
    px = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = px[x, y]
            if r > 90 and b > 90 and g < r - 40 and g < b - 40:
                px[x, y] = (0, 0, 0, 0)
    return image


def remove_grid_lines(image: Image.Image, darkness: int = 70, coverage: float = 0.75) -> Image.Image:
    """Erase the separator lines the model draws between cells. A separator runs
    edge-to-edge across the whole sheet, so a column/row where most opaque pixels
    are near-black is a line; a character outline never spans the full sheet."""
    px = image.load()
    w, h = image.size
    for x in range(w):
        dark = opaque = 0
        for y in range(h):
            r, g, b, a = px[x, y]
            if a > 0:
                opaque += 1
                if r < darkness and g < darkness and b < darkness:
                    dark += 1
        if opaque and dark / h > coverage:
            for y in range(h):
                px[x, y] = (0, 0, 0, 0)
    for y in range(h):
        dark = 0
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 0 and r < darkness and g < darkness and b < darkness:
                dark += 1
        if dark / w > coverage:
            for x in range(w):
                px[x, y] = (0, 0, 0, 0)
    return image


def defringe_magenta(image: Image.Image) -> Image.Image:
    """Kill the magenta halo: border pixels that blend the background into the
    outline survive the chroma key but still lean magenta (green well below red
    and blue). Only pixels touching transparency are candidates, so the blush
    and other legitimately pink art in the sprite interior is safe."""
    px = image.load()
    w, h = image.size
    doomed = []
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0 or not (g < r - 15 and g < b - 15):
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] == 0:
                    doomed.append((x, y))
                    break
    for x, y in doomed:
        px[x, y] = (0, 0, 0, 0)
    return image


def cell_to_frame(
    cell: Image.Image, scale: float, mirror: bool, w: int, h: int
) -> Image.Image:
    if mirror:
        cell = cell.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    small = cell.resize(
        (max(1, round(cell.width * scale)), max(1, round(cell.height * scale))),
        Image.Resampling.NEAREST,
    )
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    x = (w - small.width) // 2
    y = h - small.height
    canvas.alpha_composite(small, (max(0, x), max(0, y)))
    return canvas


def main() -> None:
    parser = argparse.ArgumentParser(description="Slice a Kling sheet into 16 aligned 32x48 frames.")
    parser.add_argument("sheet", help="Input sprite sheet PNG")
    parser.add_argument("out_dir", help="Directory that receives the named frame PNGs")
    parser.add_argument("--cols", type=int, default=5, help="Columns in the generated grid")
    parser.add_argument("--rows", type=int, default=4, help="Rows in the generated grid")
    parser.add_argument(
        "--walk-cols",
        default="1,3,4",
        help="Which grid columns form the 3-frame walk cycle (default 1,3,4)",
    )
    parser.add_argument("--idle-col", type=int, default=0, help="Which grid column is the idle pose")
    parser.add_argument(
        "--no-chroma",
        action="store_true",
        help="Sheet already has a transparent background; skip chroma keying",
    )
    parser.add_argument(
        "--size",
        default=DEFAULT_SIZE,
        help="Output frame size WxH (default 128x128)",
    )
    parser.add_argument(
        "--inset",
        type=int,
        default=0,
        help="Pixels to trim from every cell edge (removes grid separator lines "
        "the model draws in colors that cannot be chroma-keyed, e.g. black)",
    )
    args = parser.parse_args()

    sheet = Image.open(args.sheet).convert("RGBA")
    if not args.no_chroma:
        sheet = key_out_magenta(sheet)
        sheet = remove_grid_lines(sheet)
        sheet = defringe_magenta(sheet)

    sprite_w, sprite_h = (int(v) for v in args.size.lower().split("x"))

    cell_w = sheet.width // args.cols
    cell_h = sheet.height // args.rows
    inner_w = cell_w - 2 * args.inset
    inner_h = cell_h - 2 * args.inset
    scale = min(sprite_w / inner_w, sprite_h / inner_h)

    walk_cols = [int(c) for c in args.walk_cols.split(",")]
    cols = [args.idle_col, *walk_cols]

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    plan = [
        (ROW_FRONT, FRONT_NAMES, False),
        (ROW_LEFT, LEFT_NAMES, False),
        (ROW_LEFT, RIGHT_NAMES, True),  # right is the mirror of left
        (ROW_BACK, BACK_NAMES, False),
    ]

    for row, names, mirror in plan:
        for col, name in zip(cols, names):
            cell = sheet.crop(
                (
                    col * cell_w + args.inset,
                    row * cell_h + args.inset,
                    (col + 1) * cell_w - args.inset,
                    (row + 1) * cell_h - args.inset,
                )
            )
            cell_to_frame(cell, scale, mirror, sprite_w, sprite_h).save(
                out_dir / f"{name}.png"
            )

    meta = {
        "source": Path(args.sheet).name,
        "grid": {"cols": args.cols, "rows": args.rows},
        "cell": {"w": cell_w, "h": cell_h},
        "sprite": {"w": sprite_w, "h": sprite_h},
        "scale": scale,
        "idleCol": args.idle_col,
        "walkCols": walk_cols,
        "rightMirroredFromLeft": True,
    }
    (out_dir / "sheet-meta.json").write_text(json.dumps(meta, indent=2) + "\n")
    print(f"Wrote 16 frames + sheet-meta.json to {out_dir}")


if __name__ == "__main__":
    main()