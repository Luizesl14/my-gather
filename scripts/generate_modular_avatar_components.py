#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "assets" / "sprites" / "customization"
BODY = BASE / "body" / "body-office-01" / "skin-01"

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


def hex_rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16))


def shaded(color: tuple[int, int, int], lightness: int) -> tuple[int, int, int]:
    factor = 0.58 + (lightness / 255) * 0.55
    return tuple(max(0, min(255, round(c * factor))) for c in color)


def is_underlayer(pixel: tuple[int, int, int, int]) -> bool:
    r, g, b, a = pixel
    if a == 0:
        return False
    return r >= 168 and g >= 168 and b >= 168


def recolor_region(frame: Image.Image, color: tuple[int, int, int], y_min: int, y_max: int) -> Image.Image:
    src = frame.convert("RGBA")
    out = Image.new("RGBA", src.size, (0, 0, 0, 0))
    src_px = src.load()
    out_px = out.load()
    for y in range(src.height):
        if y < y_min or y > y_max:
            continue
        for x in range(src.width):
            r, g, b, a = src_px[x, y]
            if not is_underlayer((r, g, b, a)):
                continue
            out_px[x, y] = (*shaded(color, (r + g + b) // 3), a)
    return out


def save_outfit_layers() -> None:
    top_dir = BASE / "outfits" / "tops" / "top-shirt" / "cloth-blue"
    bottom_dir = BASE / "outfits" / "bottoms" / "bottom-pants" / "cloth-black"
    shoes_dir = BASE / "outfits" / "shoes" / "shoes-black"
    for directory in (top_dir, bottom_dir, shoes_dir):
        directory.mkdir(parents=True, exist_ok=True)

    blue = hex_rgb("#4267D6")
    black = hex_rgb("#1F2937")
    shoe = hex_rgb("#1A120E")

    for name in FRAME_NAMES:
        frame = Image.open(BODY / f"{name}.png").convert("RGBA")
        recolor_region(frame, blue, 20, 33).save(top_dir / f"{name}.png")
        recolor_region(frame, black, 31, 43).save(bottom_dir / f"{name}.png")
        recolor_region(frame, shoe, 41, 47).save(shoes_dir / f"{name}.png")


def draw_hair(direction: str) -> Image.Image:
    img = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    hair = (58, 33, 24, 255)
    hi = (94, 58, 42, 255)
    outline = (24, 12, 8, 255)
    if direction == "front":
        d.ellipse((5, 1, 27, 15), fill=hair, outline=outline)
        d.polygon([(5, 9), (8, 17), (11, 10)], fill=hair)
        d.polygon([(27, 9), (24, 17), (21, 10)], fill=hair)
        d.arc((7, 1, 25, 13), 190, 350, fill=hi, width=1)
    elif direction == "back":
        d.ellipse((5, 1, 27, 18), fill=hair, outline=outline)
        d.arc((7, 2, 25, 15), 190, 350, fill=hi, width=1)
    elif direction == "left":
        d.ellipse((6, 1, 27, 17), fill=hair, outline=outline)
        d.rectangle((21, 8, 25, 18), fill=hair)
    else:
        d.ellipse((5, 1, 26, 17), fill=hair, outline=outline)
        d.rectangle((7, 8, 11, 18), fill=hair)
    return img


def draw_beard(direction: str) -> Image.Image:
    img = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    beard = (74, 45, 34, 210)
    if direction == "front":
        d.arc((10, 12, 22, 24), 15, 165, fill=beard, width=2)
        d.line((11, 18, 21, 18), fill=beard, width=1)
    elif direction == "left":
        d.arc((9, 12, 19, 24), 280, 80, fill=beard, width=2)
    elif direction == "right":
        d.arc((13, 12, 23, 24), 100, 260, fill=beard, width=2)
    return img


def draw_glasses(direction: str) -> Image.Image:
    img = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = (18, 18, 18, 230)
    if direction == "front":
        d.ellipse((8, 11, 14, 17), outline=c, width=1)
        d.ellipse((18, 11, 24, 17), outline=c, width=1)
        d.line((14, 14, 18, 14), fill=c, width=1)
    elif direction == "left":
        d.ellipse((8, 11, 15, 17), outline=c, width=1)
        d.line((15, 14, 21, 13), fill=c, width=1)
    elif direction == "right":
        d.ellipse((17, 11, 24, 17), outline=c, width=1)
        d.line((11, 13, 17, 14), fill=c, width=1)
    return img


def draw_badge(direction: str) -> Image.Image:
    img = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
    if direction != "front":
        return img
    d = ImageDraw.Draw(img)
    d.rectangle((20, 27, 24, 32), fill=(245, 245, 232, 255), outline=(40, 40, 40, 255))
    d.line((21, 29, 23, 29), fill=(66, 103, 214, 255), width=1)
    return img


def save_directional_accessory(root: Path, drawer) -> None:
    root.mkdir(parents=True, exist_ok=True)
    for direction in ("front", "back", "left", "right"):
        drawer(direction).save(root / f"{direction}.png")


def main() -> None:
    save_outfit_layers()
    save_directional_accessory(
        BASE / "hair" / "unisex" / "hair-short-01" / "style-01",
        draw_hair,
    )
    save_directional_accessory(
        BASE / "accessories" / "accessory-beard-short",
        draw_beard,
    )
    save_directional_accessory(
        BASE / "accessories" / "accessory-glasses-round",
        draw_glasses,
    )
    save_directional_accessory(
        BASE / "accessories" / "accessory-badge",
        draw_badge,
    )
    print("Generated modular overlays in assets/sprites/customization")


if __name__ == "__main__":
    main()
