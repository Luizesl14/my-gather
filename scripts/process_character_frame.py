#!/usr/bin/env python3
"""
Process a downloaded Magnific image into a 32x48 pixel art sprite frame.

Usage:
  python3 scripts/process_character_frame.py <input_path> <output_path>
  python3 scripts/process_character_frame.py images/downloads/idle-front.png \
      web/assets/sprites/characters/character-07/idle-front.png

The script:
  1. Removes checkerboard/white background (or relies on transparency already set)
  2. Crops to the bounding box of the character
  3. Centers the character on a 96x144 working canvas
  4. Resizes to 32x48 using nearest-neighbor (pixel-perfect)
  5. Saves as PNG with transparency
"""
from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

from PIL import Image


SPRITE_SIZE = (32, 48)
WORK_CANVAS = (96, 144)  # 3× sprite, enough to normalize small pixel art


def remove_checker_background(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size

    def is_bg(x: int, y: int) -> bool:
        r, g, b, a = pixels[x, y]
        if a == 0:
            return False
        is_light = r >= 232 and g >= 232 and b >= 232
        is_gray = abs(r - g) <= 7 and abs(g - b) <= 7 and r >= 215
        return is_light or is_gray

    queue: deque[tuple[int, int]] = deque()
    visited: set[tuple[int, int]] = set()
    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))
    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))

    while queue:
        x, y = queue.popleft()
        if (x, y) in visited or not (0 <= x < width) or not (0 <= y < height):
            continue
        visited.add((x, y))
        if not is_bg(x, y):
            continue
        pixels[x, y] = (255, 255, 255, 0)
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            queue.append((x + dx, y + dy))
    return image


def normalize_sprite(image: Image.Image) -> Image.Image:
    image = remove_checker_background(image)
    bbox = image.getchannel("A").getbbox()
    if bbox:
        image = image.crop(bbox)
    canvas = Image.new("RGBA", WORK_CANVAS, (255, 255, 255, 0))
    x = (WORK_CANVAS[0] - image.width) // 2
    y = WORK_CANVAS[1] - image.height - 6
    canvas.alpha_composite(image, (max(0, x), max(0, y)))
    return canvas.resize(SPRITE_SIZE, Image.Resampling.NEAREST)


def main() -> None:
    if len(sys.argv) < 3:
        print("Usage: process_character_frame.py <input> <output>")
        sys.exit(1)

    input_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])

    if not input_path.exists():
        print(f"Error: input file not found: {input_path}")
        sys.exit(1)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    image = Image.open(input_path).convert("RGBA")
    result = normalize_sprite(image)
    result.save(output_path)
    print(f"Saved: {output_path} ({result.size[0]}×{result.size[1]})")


if __name__ == "__main__":
    main()
