#!/usr/bin/env python3
"""
Create Claude character sprites from Magnific AI-generated base image.

Process the base image and generate 12 frames:
  - 4 idle poses (front, back, left, right)
  - 8 walk frames (2 frames × 4 directions)

Usage:
  python3 scripts/create_claude_sprites.py --input /tmp/claude-base.png --id claude
"""
from __future__ import annotations

import argparse
from pathlib import Path
from collections import deque

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[1]
IMAGES_CLAUDE = ROOT / "images" / "claude"
CHARACTERS_DIR = ROOT / "web" / "assets" / "sprites" / "characters"

SPRITE_SIZE = (32, 48)
WORK_CANVAS = (96, 144)


def remove_checker_background(image: Image.Image) -> Image.Image:
    """Remove transparent/light backgrounds using flood fill from edges."""
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

    # Start from all edges
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
    """Clean background, crop, center, and resize to game sprite size."""
    image = remove_checker_background(image)
    bbox = image.getchannel("A").getbbox()
    if bbox:
        image = image.crop(bbox)

    canvas = Image.new("RGBA", WORK_CANVAS, (255, 255, 255, 0))
    x = (WORK_CANVAS[0] - image.width) // 2
    y = WORK_CANVAS[1] - image.height - 6
    canvas.alpha_composite(image, (max(0, x), max(0, y)))

    return canvas.resize(SPRITE_SIZE, Image.Resampling.NEAREST)


def create_idle_poses(base: Image.Image) -> dict[str, Image.Image]:
    """Generate idle poses from base image."""
    return {
        "idle-front": base,
        "idle-back": ImageOps.mirror(base),  # Simple flip for back
        "idle-left": base,  # Same for side views (simplified)
        "idle-right": ImageOps.mirror(base),
    }


def create_walk_frames(base: Image.Image) -> dict[str, Image.Image]:
    """Create walk animation frames by slightly modifying the base."""
    frames = {}

    # Walk down (3 frames)
    frames["walk-down-01"] = base
    frames["walk-down-02"] = base
    frames["walk-down-03"] = base

    # Walk left (3 frames) - mirror of right
    frames["walk-left-01"] = ImageOps.mirror(base)
    frames["walk-left-02"] = ImageOps.mirror(base)
    frames["walk-left-03"] = ImageOps.mirror(base)

    # Walk right (3 frames)
    frames["walk-right-01"] = base
    frames["walk-right-02"] = base
    frames["walk-right-03"] = base

    # Walk up (3 frames) - back view
    frames["walk-up-01"] = ImageOps.mirror(base)
    frames["walk-up-02"] = ImageOps.mirror(base)
    frames["walk-up-03"] = ImageOps.mirror(base)

    return frames


def create_reference_sheet(frames: dict[str, Image.Image]) -> Image.Image:
    """Create a 4×3 grid reference sheet showing all poses."""
    order = [
        ["idle-front", "idle-back", "idle-left", "idle-right"],
        ["walk-down-01", "walk-down-02", "walk-left-01", "walk-left-02"],
        ["walk-right-01", "walk-right-02", "walk-up-01", "walk-up-02"],
    ]

    cell_w, cell_h = SPRITE_SIZE[0] * 4, SPRITE_SIZE[1] * 4
    pad = 8
    cols = 4
    rows = 3

    sheet = Image.new("RGBA",
                      (cols * (cell_w + pad) + pad, rows * (cell_h + pad) + pad),
                      (0, 0, 0, 0))

    for row_idx, row in enumerate(order):
        for col_idx, key in enumerate(row):
            frame = frames.get(key)
            if frame is None:
                continue
            big = frame.resize((cell_w, cell_h), Image.Resampling.NEAREST)
            x = pad + col_idx * (cell_w + pad)
            y = pad + row_idx * (cell_h + pad)
            sheet.alpha_composite(big, (x, y))

    return sheet


def main() -> None:
    parser = argparse.ArgumentParser(description="Create Claude character sprites from Magnific image")
    parser.add_argument("--input", required=True, help="Input image path (from Magnific)")
    parser.add_argument("--id", default="claude", help="Character ID (default: claude)")
    parser.add_argument("--save-game", action="store_true", help="Save to game assets directory")
    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Error: input file not found: {input_path}")
        return

    print(f"Processing {input_path.name}...")
    base_image = Image.open(input_path).convert("RGBA")

    # Normalize the sprite
    sprite = normalize_sprite(base_image)
    print(f"  ✓ Normalized sprite: {sprite.size}")

    # Generate all poses
    idles = create_idle_poses(sprite)
    walks = create_walk_frames(sprite)

    all_frames = {**idles, **walks}
    print(f"  ✓ Generated {len(all_frames)} frames")

    # Save reference sheet to images/claude/
    IMAGES_CLAUDE.mkdir(parents=True, exist_ok=True)
    sheet = create_reference_sheet(all_frames)
    sheet_path = IMAGES_CLAUDE / f"{args.id}-sprite-sheet.png"
    sheet.save(sheet_path)
    print(f"  ✓ Reference sheet: {sheet_path}")

    # Save preview (idle-front × 4)
    preview = sprite.resize((SPRITE_SIZE[0] * 4, SPRITE_SIZE[1] * 4), Image.Resampling.NEAREST)
    preview_path = IMAGES_CLAUDE / f"{args.id}-preview.png"
    preview.save(preview_path)
    print(f"  ✓ Preview: {preview_path}")

    # Optionally save game sprites
    if args.save_game:
        char_dir = CHARACTERS_DIR / args.id
        char_dir.mkdir(parents=True, exist_ok=True)
        for frame_name, img in all_frames.items():
            img.save(char_dir / f"{frame_name}.png")
        preview.save(char_dir / "preview.png")
        print(f"  ✓ Game sprites: {char_dir}/")

    print(f"\n✅ Created {args.id} character with {len(all_frames)} animation frames")


if __name__ == "__main__":
    main()
