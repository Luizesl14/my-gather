#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from collections import deque
from typing import Iterable

from PIL import Image
from PIL import ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE_CHARACTERS = ROOT / "images" / "ChatGPT Image 4 de jun. de 2026, 12_42_53 (1).png"
SOURCE_SOCIAL = ROOT / "images" / "ChatGPT Image 4 de jun. de 2026, 12_51_54.png"
ASSETS = ROOT / "web" / "assets"
CHARACTERS_DIR = ASSETS / "sprites" / "characters"
COMPONENTS_DIR = ASSETS / "components"
TILESETS_DIR = ASSETS / "tilesets"
FURNITURE_DIR = ASSETS / "furniture"
MAPS_DIR = ASSETS / "maps"
ATLASES_DIR = ASSETS / "atlases"
CUSTOMIZATION_DIR = ASSETS / "sprites" / "customization"

SPRITE_SIZE = (32, 48)
WORK_CANVAS = (96, 144)

FRAME_NAMES = [
    "idle-front",
    "idle-back",
    "idle-left",
    "idle-right",
    "walk-down-01",
    "walk-down-02",
    "walk-left-01",
    "walk-left-02",
    "walk-right-01",
    "walk-right-02",
    "walk-up-01",
    "walk-up-02",
]

FRAME_KEYS = {
    "idle-front": "idleFront",
    "idle-back": "idleBack",
    "idle-left": "idleLeft",
    "idle-right": "idleRight",
    "walk-down-01": "walkDown",
    "walk-down-02": "walkDown",
    "walk-left-01": "walkLeft",
    "walk-left-02": "walkLeft",
    "walk-right-01": "walkRight",
    "walk-right-02": "walkRight",
    "walk-up-01": "walkUp",
    "walk-up-02": "walkUp",
}

CHARACTER_ROWS = [
    {
        "id": "character-01",
        "displayName": "Brown Hair Blue Suit",
        "description": "Homem cabelo castanho, roupa social azul.",
        "rowSpan": (69, 182),
    },
    {
        "id": "character-02",
        "displayName": "Glasses Green Cardigan",
        "description": "Mulher cabelo preso, oculos, cardigan verde.",
        "rowSpan": (197, 321),
    },
    {
        "id": "character-03",
        "displayName": "Bearded Blue Shirt",
        "description": "Homem pele escura, barba, camisa azul.",
        "rowSpan": (337, 459),
    },
    {
        "id": "character-04",
        "displayName": "Blonde Gray Blazer",
        "description": "Mulher loira, blazer cinza/bege.",
        "rowSpan": (474, 585),
    },
    {
        "id": "character-05",
        "displayName": "Black Hair White Shirt",
        "description": "Pessoa cabelo preto, oculos, camisa branca.",
        "rowSpan": (596, 710),
    },
    {
        "id": "character-06",
        "displayName": "Long Hair Lilac Outfit",
        "description": "Mulher pele media/escura, cabelo longo, roupa lilas.",
        "rowSpan": (723, 833),
    },
    {
        "id": "character-07",
        "displayName": "Red Beard Green Sweater",
        "description": "Homem ruivo/barba, sweater verde.",
        "rowSpan": (843, 952),
    },
    {
        "id": "character-08",
        "displayName": "Black Ponytail Dark Jacket",
        "description": "Mulher cabelo preto preso, jaqueta escura.",
        "rowSpan": (963, 1072),
    },
]

DERIVED_CHARACTER_ROWS = [
    {
        "id": "character-09",
        "displayName": "Gray Hair Suspenders",
        "description": "Pessoa mais velha, cabelo grisalho, camisa clara e suspensorios.",
        "baseId": "character-05",
        "variant": "gray-suspenders",
    },
    {
        "id": "character-10",
        "displayName": "Beige Coat Gold Accessories",
        "description": "Mulher pele escura, casaco bege e acessorios dourados.",
        "baseId": "character-06",
        "variant": "beige-coat",
    },
]

# Component spans detected from the grouped character sheet. Each frame keeps padding
# around the detected sprite, then normalizes the canvas to avoid layout shifting.
COLUMN_SPANS = [
    (74, 138),
    (187, 250),
    (293, 355),
    (405, 472),
    (520, 588),
    (637, 706),
    (754, 821),
    (875, 945),
    (985, 1055),
    (1108, 1178),
    (1223, 1293),
    (1333, 1403),
]

SOCIAL_SPRITES = [
    {
        "id": "chat",
        "type": "bubble",
        "target": ASSETS / "sprites" / "bubbles" / "chat.png",
        "box": (24, 62, 54, 54),
    },
    {
        "id": "typing",
        "type": "bubble",
        "target": ASSETS / "sprites" / "bubbles" / "typing.png",
        "box": (102, 62, 62, 54),
    },
    {
        "id": "call",
        "type": "bubble",
        "target": ASSETS / "sprites" / "bubbles" / "call.png",
        "box": (264, 62, 54, 54),
    },
    {
        "id": "knock",
        "type": "bubble",
        "target": ASSETS / "sprites" / "bubbles" / "knock.png",
        "box": (402, 54, 72, 66),
    },
    {
        "id": "shout",
        "type": "bubble",
        "target": ASSETS / "sprites" / "bubbles" / "shout.png",
        "box": (664, 58, 70, 58),
    },
    {
        "id": "wave",
        "type": "gesture",
        "target": ASSETS / "sprites" / "gestures" / "wave.png",
        "box": (788, 58, 56, 58),
    },
    {
        "id": "coffee",
        "type": "reaction",
        "target": ASSETS / "sprites" / "reactions" / "coffee.png",
        "box": (754, 274, 62, 58),
    },
    {
        "id": "help",
        "type": "reaction",
        "target": ASSETS / "sprites" / "reactions" / "help.png",
        "box": (982, 278, 54, 54),
    },
]


def ensure_dirs(paths: Iterable[Path]) -> None:
    for path in paths:
        path.mkdir(parents=True, exist_ok=True)


def remove_checker_background(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size

    def is_background_pixel(x: int, y: int) -> bool:
        r, g, b, a = pixels[x, y]
        if a == 0:
            return False
        is_light_checker = r >= 232 and g >= 232 and b >= 232
        is_gray_checker = abs(r - g) <= 7 and abs(g - b) <= 7 and r >= 215
        return is_light_checker or is_gray_checker

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
        if (x, y) in visited or x < 0 or y < 0 or x >= width or y >= height:
            continue
        visited.add((x, y))
        if not is_background_pixel(x, y):
            continue
        pixels[x, y] = (255, 255, 255, 0)
        queue.append((x + 1, y))
        queue.append((x - 1, y))
        queue.append((x, y + 1))
        queue.append((x, y - 1))
    return image


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    return image.getchannel("A").getbbox()


def normalize_sprite(image: Image.Image) -> Image.Image:
    image = remove_checker_background(image)
    bbox = alpha_bbox(image)
    if bbox:
        image = image.crop(bbox)
    canvas = Image.new("RGBA", WORK_CANVAS, (255, 255, 255, 0))
    x = (WORK_CANVAS[0] - image.width) // 2
    y = WORK_CANVAS[1] - image.height - 6
    canvas.alpha_composite(image, (max(0, x), max(0, y)))
    return canvas.resize(SPRITE_SIZE, Image.Resampling.NEAREST)


def normalize_icon(image: Image.Image) -> Image.Image:
    image = remove_checker_background(image)
    bbox = alpha_bbox(image)
    if bbox:
        image = image.crop(bbox)
    canvas = Image.new("RGBA", (64, 64), (255, 255, 255, 0))
    x = (64 - image.width) // 2
    y = (64 - image.height) // 2
    canvas.alpha_composite(image, (max(0, x), max(0, y)))
    return canvas.resize((32, 32), Image.Resampling.NEAREST)


def frame_metadata(character_id: str) -> dict[str, object]:
    frames: dict[str, object] = {
        "idleFront": f"{character_id}/idle-front.png",
        "idleBack": f"{character_id}/idle-back.png",
        "idleLeft": f"{character_id}/idle-left.png",
        "idleRight": f"{character_id}/idle-right.png",
        "walkDown": [],
        "walkLeft": [],
        "walkRight": [],
        "walkUp": [],
    }
    for frame in FRAME_NAMES:
        key = FRAME_KEYS[frame]
        rel = f"{character_id}/{frame}.png"
        if isinstance(frames[key], list):
            frames[key].append(rel)
    return frames


def recolor_pixel(
    pixel: tuple[int, int, int, int],
    target: tuple[int, int, int],
    strength: float = 0.9,
) -> tuple[int, int, int, int]:
    r, g, b, a = pixel
    if a == 0:
        return pixel
    nr = round(r * (1 - strength) + target[0] * strength)
    ng = round(g * (1 - strength) + target[1] * strength)
    nb = round(b * (1 - strength) + target[2] * strength)
    return (nr, ng, nb, a)


def make_gray_suspenders_variant(sprite: Image.Image, frame_name: str) -> Image.Image:
    image = sprite.copy().convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            avg = (r + g + b) / 3
            is_dark_hair_area = y <= 22 and avg < 115 and abs(r - g) <= 28 and abs(g - b) <= 28
            if is_dark_hair_area and avg > 28:
                target = (166, 171, 176) if avg > 70 else (104, 110, 116)
                pixels[x, y] = recolor_pixel((r, g, b, a), target, 0.85)

    draw = ImageDraw.Draw(image)
    if "front" in frame_name or "down" in frame_name:
        draw.line((11, 33, 11, 42), fill="#8F2B24", width=1)
        draw.line((21, 33, 21, 42), fill="#8F2B24", width=1)
    elif "back" in frame_name or "up" in frame_name:
        draw.line((11, 32, 11, 42), fill="#8F2B24", width=1)
        draw.line((21, 32, 21, 42), fill="#8F2B24", width=1)
    elif "left" in frame_name:
        draw.line((14, 33, 14, 42), fill="#8F2B24", width=1)
    elif "right" in frame_name:
        draw.line((18, 33, 18, 42), fill="#8F2B24", width=1)
    return image


def make_beige_coat_variant(sprite: Image.Image, frame_name: str) -> Image.Image:
    image = sprite.copy().convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            avg = (r + g + b) / 3
            is_body_area = 7 <= x <= 24 and 29 <= y <= 38
            is_skin = r > 165 and 95 <= g <= 170 and b < 125
            is_dark_outline_or_hair = avg < 38
            is_lilac_top = is_body_area and not is_skin and not is_dark_outline_or_hair
            is_light_bottom = y >= 37 and avg > 165 and abs(r - g) < 55 and abs(g - b) < 55
            if is_lilac_top:
                pixels[x, y] = recolor_pixel((r, g, b, a), (203, 163, 105), 0.96)
            elif is_light_bottom:
                pixels[x, y] = recolor_pixel((r, g, b, a), (42, 45, 53), 0.86)

    draw = ImageDraw.Draw(image)
    if "front" in frame_name or "down" in frame_name:
        draw.point((23, 16), fill="#D7A83E")
        draw.point((9, 16), fill="#D7A83E")
        draw.line((15, 23, 15, 33), fill="#5A3A24", width=1)
    elif "left" in frame_name:
        draw.point((11, 16), fill="#D7A83E")
    elif "right" in frame_name:
        draw.point((21, 16), fill="#D7A83E")
    return image


def make_derived_variant(sprite: Image.Image, frame_name: str, variant: str) -> Image.Image:
    if variant == "gray-suspenders":
        return make_gray_suspenders_variant(sprite, frame_name)
    if variant == "beige-coat":
        return make_beige_coat_variant(sprite, frame_name)
    raise ValueError(f"Unknown character variant: {variant}")


def generate_characters() -> None:
    source = Image.open(SOURCE_CHARACTERS).convert("RGBA")
    ensure_dirs([CHARACTERS_DIR])
    characters = []

    for row in CHARACTER_ROWS:
        character_id = row["id"]
        character_dir = CHARACTERS_DIR / character_id
        ensure_dirs([character_dir])

        for frame_name, (left, right) in zip(FRAME_NAMES, COLUMN_SPANS):
            padding_x = 14
            crop_left = max(0, left - padding_x)
            row_top, row_bottom = row["rowSpan"]
            crop_top = max(0, row_top - 8)
            crop_right = min(source.width, right + padding_x)
            crop_bottom = min(source.height, row_bottom + 8)
            sprite = source.crop((crop_left, crop_top, crop_right, crop_bottom))
            normalized = normalize_sprite(sprite)
            normalized.save(character_dir / f"{frame_name}.png")

        characters.append(
            {
                "id": character_id,
                "displayName": row["displayName"],
                "description": row["description"],
                "default": character_id == "character-01",
                "frames": frame_metadata(character_id),
                "hitbox": {"x": 6, "y": 22, "w": 20, "h": 24},
            }
        )

    for row in DERIVED_CHARACTER_ROWS:
        character_id = row["id"]
        character_dir = CHARACTERS_DIR / character_id
        ensure_dirs([character_dir])

        for frame_name in FRAME_NAMES:
            base_path = CHARACTERS_DIR / row["baseId"] / f"{frame_name}.png"
            sprite = Image.open(base_path).convert("RGBA")
            variant = make_derived_variant(sprite, frame_name, row["variant"])
            variant.save(character_dir / f"{frame_name}.png")

        characters.append(
            {
                "id": character_id,
                "displayName": row["displayName"],
                "description": row["description"],
                "default": False,
                "frames": frame_metadata(character_id),
                "hitbox": {"x": 6, "y": 22, "w": 20, "h": 24},
            }
        )

    manifest = {
        "version": 1,
        "source": "images/ChatGPT Image 4 de jun. de 2026, 12_42_53 (1).png",
        "sourceReferences": [
            "images/ChatGPT Image 4 de jun. de 2026, 12_56_36.png"
        ],
        "tileSize": 32,
        "spriteSize": {"w": SPRITE_SIZE[0], "h": SPRITE_SIZE[1]},
        "animations": {
            "idle": {"fps": 1, "loop": False},
            "walk": {"fps": 8, "loop": True},
        },
        "characters": characters,
    }
    (CHARACTERS_DIR / "characters.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def generate_component_manifest() -> None:
    ensure_dirs(
        [
            COMPONENTS_DIR,
            ASSETS / "sprites" / "gestures",
            ASSETS / "sprites" / "bubbles",
            ASSETS / "sprites" / "reactions",
            ASSETS / "tilesets",
            ASSETS / "furniture",
            ASSETS / "maps",
            ASSETS / "atlases",
        ]
    )
    manifest = {
        "version": 1,
        "components": [
            {"id": "office-canvas", "type": "renderer", "requiredAssets": ["tilesets", "furniture", "characters"]},
            {"id": "avatar-sprite", "type": "character", "metadata": "sprites/characters/characters.json"},
            {"id": "desk-component", "type": "map-object", "requiredStates": ["default", "occupied", "callPending", "hasUnreadNotes"]},
            {"id": "room-component", "type": "map-zone", "requiredStates": ["empty", "occupied", "meetingActive", "locked"]},
            {"id": "interaction-bubble", "type": "overlay", "requiredSprites": ["typing", "call", "knock", "coffee", "help", "shout"]},
            {"id": "bottom-action-toolbar", "type": "ui", "requiredSprites": ["chat", "wave", "call", "coffee", "help", "shout"]},
        ],
    }
    (COMPONENTS_DIR / "components.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def save_tile(path: Path, base: str, line: str | None = None, pattern: str = "grid") -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image = Image.new("RGBA", (32, 32), base)
    draw = ImageDraw.Draw(image)
    if pattern == "grid":
        for pos in (0, 16, 31):
            draw.line((pos, 0, pos, 31), fill=line or "#00000022")
            draw.line((0, pos, 31, pos), fill=line or "#00000022")
    elif pattern == "wood":
        for y in range(4, 32, 8):
            draw.line((0, y, 31, y), fill=line or "#7B4A24")
        draw.line((10, 0, 10, 31), fill=line or "#7B4A24")
        draw.line((22, 0, 22, 31), fill=line or "#7B4A24")
    elif pattern == "carpet":
        for x in range(2, 32, 4):
            draw.line((x, 0, x, 31), fill=line or "#FFFFFF22")
    elif pattern == "zone":
        draw.rounded_rectangle((2, 2, 29, 29), radius=4, outline=line or "#4267D6", width=2)
    image.save(path)


def generate_tilesets() -> None:
    TILESETS_DIR.mkdir(parents=True, exist_ok=True)
    tiles = [
        {"id": "floor-office-light", "path": "floor-office-light.png", "collision": False, "base": "#E8EDF2", "line": "#CAD3DD", "pattern": "grid"},
        {"id": "floor-wood-light", "path": "floor-wood-light.png", "collision": False, "base": "#C88946", "line": "#8F5D2D", "pattern": "wood"},
        {"id": "carpet-blue", "path": "carpet-blue.png", "collision": False, "base": "#2F5F8F", "line": "#D8E8FF44", "pattern": "carpet"},
        {"id": "carpet-green", "path": "carpet-green.png", "collision": False, "base": "#63794A", "line": "#E5F0D244", "pattern": "carpet"},
        {"id": "wall-office", "path": "wall-office.png", "collision": True, "base": "#F2E8D6", "line": "#2F3540", "pattern": "grid"},
        {"id": "glass-wall", "path": "glass-wall.png", "collision": True, "base": "#A9DDF2", "line": "#4E7890", "pattern": "grid"},
        {"id": "interactive-zone-blue", "path": "interactive-zone-blue.png", "collision": False, "base": "#00000000", "line": "#4267D6", "pattern": "zone"},
    ]
    for tile in tiles:
        save_tile(TILESETS_DIR / tile["path"], tile["base"], tile["line"], tile["pattern"])
    (TILESETS_DIR / "tilesets.json").write_text(
        json.dumps({"version": 1, "tileSize": 32, "tiles": tiles}, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def new_sprite(size: tuple[int, int]) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGBA", size, (255, 255, 255, 0))
    return image, ImageDraw.Draw(image)


def generate_furniture() -> None:
    FURNITURE_DIR.mkdir(parents=True, exist_ok=True)
    furniture: list[dict[str, object]] = []

    def add(name: str, size: tuple[int, int], draw_fn, collision: dict[str, int] | None) -> None:
        image, draw = new_sprite(size)
        draw_fn(draw, size)
        path = FURNITURE_DIR / f"{name}.png"
        image.save(path)
        furniture.append(
            {
                "id": name,
                "path": f"{name}.png",
                "size": {"w": size[0], "h": size[1]},
                "collision": collision,
            }
        )

    def desk(draw: ImageDraw.ImageDraw, size: tuple[int, int]) -> None:
        draw.rounded_rectangle((2, 10, 62, 38), radius=2, fill="#A96A32", outline="#2A1A10", width=2)
        draw.rectangle((45, 18, 58, 38), fill="#7A4A26", outline="#2A1A10")
        draw.line((6, 14, 58, 14), fill="#D79A58")

    def chair(draw: ImageDraw.ImageDraw, size: tuple[int, int]) -> None:
        draw.rounded_rectangle((8, 4, 24, 20), radius=4, fill="#263242", outline="#111827", width=2)
        draw.rounded_rectangle((6, 18, 26, 30), radius=3, fill="#1F2937", outline="#111827", width=2)

    def meeting_table(draw: ImageDraw.ImageDraw, size: tuple[int, int]) -> None:
        draw.rounded_rectangle((5, 10, 91, 42), radius=8, fill="#B7793C", outline="#2A1A10", width=2)
        draw.line((12, 16, 84, 16), fill="#DCA15F")

    def plant(draw: ImageDraw.ImageDraw, size: tuple[int, int]) -> None:
        draw.ellipse((7, 2, 20, 16), fill="#3B8A3E", outline="#1F4D25")
        draw.ellipse((14, 4, 29, 19), fill="#4BA64F", outline="#1F4D25")
        draw.ellipse((2, 8, 17, 22), fill="#2F7A35", outline="#1F4D25")
        draw.rectangle((10, 22, 24, 31), fill="#8A552C", outline="#2A1A10")

    def sofa(draw: ImageDraw.ImageDraw, size: tuple[int, int]) -> None:
        draw.rounded_rectangle((4, 10, 60, 34), radius=6, fill="#2F5F8F", outline="#14263A", width=2)
        draw.line((32, 11, 32, 33), fill="#1D3D5E")
        draw.rounded_rectangle((2, 22, 10, 42), radius=4, fill="#244C74", outline="#14263A")
        draw.rounded_rectangle((54, 22, 62, 42), radius=4, fill="#244C74", outline="#14263A")

    def cabinet(draw: ImageDraw.ImageDraw, size: tuple[int, int]) -> None:
        draw.rectangle((6, 2, 26, 30), fill="#707986", outline="#222831", width=2)
        for y in (8, 16, 24):
            draw.line((8, y, 24, y), fill="#2F3540")
            draw.rectangle((18, y - 3, 22, y - 1), fill="#D6DEE8")

    def door(draw: ImageDraw.ImageDraw, size: tuple[int, int]) -> None:
        draw.rectangle((5, 2, 27, 31), fill="#8B542B", outline="#2A1A10", width=2)
        draw.ellipse((21, 16, 24, 19), fill="#F2C94C")

    def window(draw: ImageDraw.ImageDraw, size: tuple[int, int]) -> None:
        draw.rectangle((2, 8, 62, 28), fill="#A9DDF2", outline="#2F5268", width=2)
        draw.line((32, 8, 32, 28), fill="#2F5268")
        draw.line((10, 24, 26, 10), fill="#FFFFFF99")

    add("desk-wood", (64, 48), desk, {"x": 4, "y": 14, "w": 58, "h": 28})
    add("chair-blue", (32, 32), chair, {"x": 6, "y": 18, "w": 20, "h": 12})
    add("meeting-table-wood", (96, 56), meeting_table, {"x": 5, "y": 12, "w": 86, "h": 34})
    add("plant-pot", (32, 32), plant, {"x": 9, "y": 22, "w": 17, "h": 10})
    add("sofa-blue", (64, 48), sofa, {"x": 4, "y": 14, "w": 58, "h": 28})
    add("cabinet-gray", (32, 32), cabinet, {"x": 6, "y": 2, "w": 20, "h": 28})
    add("door-wood", (32, 32), door, {"x": 5, "y": 2, "w": 22, "h": 29})
    add("window-glass", (64, 32), window, None)
    (FURNITURE_DIR / "furniture.json").write_text(
        json.dumps({"version": 1, "furniture": furniture}, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def generate_social_atlas() -> None:
    ATLASES_DIR.mkdir(parents=True, exist_ok=True)
    entries = [
        ("bubble-chat", ASSETS / "sprites" / "bubbles" / "chat.png"),
        ("bubble-typing", ASSETS / "sprites" / "bubbles" / "typing.png"),
        ("bubble-call", ASSETS / "sprites" / "bubbles" / "call.png"),
        ("bubble-knock", ASSETS / "sprites" / "bubbles" / "knock.png"),
        ("bubble-shout", ASSETS / "sprites" / "bubbles" / "shout.png"),
        ("gesture-wave", ASSETS / "sprites" / "gestures" / "wave.png"),
        ("reaction-coffee", ASSETS / "sprites" / "reactions" / "coffee.png"),
        ("reaction-help", ASSETS / "sprites" / "reactions" / "help.png"),
    ]
    atlas = Image.new("RGBA", (len(entries) * 32, 32), (255, 255, 255, 0))
    frames = {}
    for index, (frame_id, path) in enumerate(entries):
        sprite = Image.open(path).convert("RGBA")
        x = index * 32
        atlas.alpha_composite(sprite, (x, 0))
        frames[frame_id] = {"x": x, "y": 0, "w": 32, "h": 32}
    atlas.save(ATLASES_DIR / "social-actions.png")
    (ATLASES_DIR / "social-actions.json").write_text(
        json.dumps({"version": 1, "image": "social-actions.png", "frames": frames}, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def generate_default_map() -> None:
    MAPS_DIR.mkdir(parents=True, exist_ok=True)
    width, height = 28, 18
    floor_tiles = [{"tile": "floor-office-light", "x": x, "y": y} for y in range(height) for x in range(width)]
    carpet_tiles = [{"tile": "carpet-blue", "x": x, "y": y} for y in range(10, 15) for x in range(16, 24)]
    wall_tiles = (
        [{"tile": "wall-office", "x": x, "y": 0} for x in range(width)]
        + [{"tile": "wall-office", "x": x, "y": height - 1} for x in range(width)]
        + [{"tile": "wall-office", "x": 0, "y": y} for y in range(height)]
        + [{"tile": "wall-office", "x": width - 1, "y": y} for y in range(height)]
        + [{"tile": "glass-wall", "x": x, "y": 8} for x in range(15, 26)]
    )
    objects = [
        {"id": "desk-ana", "asset": "desk-wood", "x": 4, "y": 4, "layer": 3, "targetType": "desk"},
        {"id": "chair-ana", "asset": "chair-blue", "x": 5, "y": 5, "layer": 3},
        {"id": "desk-luiz", "asset": "desk-wood", "x": 4, "y": 10, "layer": 3, "targetType": "desk"},
        {"id": "chair-luiz", "asset": "chair-blue", "x": 5, "y": 11, "layer": 3},
        {"id": "meeting-table-alpha", "asset": "meeting-table-wood", "x": 18, "y": 11, "layer": 3, "targetType": "room"},
        {"id": "sofa-lounge", "asset": "sofa-blue", "x": 10, "y": 4, "layer": 3},
        {"id": "plant-reception", "asset": "plant-pot", "x": 2, "y": 2, "layer": 3},
        {"id": "cabinet-north", "asset": "cabinet-gray", "x": 24, "y": 3, "layer": 3},
        {"id": "door-alpha", "asset": "door-wood", "x": 19, "y": 8, "layer": 4, "targetType": "room"},
        {"id": "window-alpha", "asset": "window-glass", "x": 21, "y": 8, "layer": 4},
    ]
    map_json = {
        "id": "office-default",
        "name": "Office Default MVP",
        "version": 1,
        "width": width,
        "height": height,
        "tileSize": 32,
        "assetPackId": "office-default-v1",
        "spawn": {"x": 2, "y": 15, "direction": "front"},
        "layers": [
            {"name": "floor", "tiles": floor_tiles},
            {"name": "carpet", "tiles": carpet_tiles},
            {"name": "walls", "tiles": wall_tiles},
            {"name": "objects", "objects": objects},
        ],
        "collision": [
            {"x": 0, "y": 0, "w": width, "h": 1},
            {"x": 0, "y": height - 1, "w": width, "h": 1},
            {"x": 0, "y": 0, "w": 1, "h": height},
            {"x": width - 1, "y": 0, "w": 1, "h": height},
            {"x": 4, "y": 4, "w": 2, "h": 1},
            {"x": 4, "y": 10, "w": 2, "h": 1},
            {"x": 18, "y": 11, "w": 3, "h": 1},
            {"x": 15, "y": 8, "w": 11, "h": 1},
        ],
        "desks": [
            {"id": "desk-ana", "ownerUserId": "mock-user-ana", "name": "Mesa de Ana", "x": 4, "y": 4, "w": 2, "h": 1},
            {"id": "desk-luiz", "ownerUserId": "mock-user-luiz", "name": "Mesa de Luiz", "x": 4, "y": 10, "w": 2, "h": 1},
        ],
        "rooms": [
            {"id": "room-alpha", "name": "Sala Alpha", "type": "MeetingRoom", "x": 16, "y": 9, "w": 8, "h": 6, "capacity": 6}
        ],
        "interactiveZones": [
            {"id": "zone-desk-ana", "type": "visitDesk", "x": 3, "y": 5, "w": 4, "h": 2, "targetId": "desk-ana"},
            {"id": "zone-desk-luiz", "type": "visitDesk", "x": 3, "y": 11, "w": 4, "h": 2, "targetId": "desk-luiz"},
            {"id": "zone-room-alpha", "type": "enterRoom", "x": 18, "y": 8, "w": 3, "h": 2, "targetId": "room-alpha"},
        ],
    }
    (MAPS_DIR / "office-default.json").write_text(
        json.dumps(map_json, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def generate_asset_pack_manifest() -> None:
    manifest = {
        "id": "office-default-v1",
        "version": 1,
        "tileSize": 32,
        "paths": {
            "characters": "sprites/characters/characters.json",
            "socialSprites": "sprites/social-sprites.json",
            "tilesets": "tilesets/tilesets.json",
            "furniture": "furniture/furniture.json",
            "socialAtlas": "atlases/social-actions.json",
            "defaultMap": "maps/office-default.json",
            "components": "components/components.json",
        },
    }
    (ASSETS / "asset-pack.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def save_swatch(path: Path, color: str, border: str = "#111827") -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image = Image.new("RGBA", (32, 32), (255, 255, 255, 0))
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((3, 3, 29, 29), radius=4, fill=color, outline=border, width=2)
    draw.line((7, 24, 25, 6), fill="#FFFFFF66", width=2)
    image.save(path)


def generate_customization_swatches() -> None:
    groups = {
        "skin-tones": [
            ("skin-01", "#F6D8B5"),
            ("skin-02", "#E7B678"),
            ("skin-03", "#C47A3A"),
            ("skin-04", "#8A4B2A"),
            ("skin-05", "#5A2E1B"),
            ("skin-06", "#2D1810"),
        ],
        "hair-colors": [
            ("hair-black", "#1E1E1E"),
            ("hair-dark-brown", "#3A2118"),
            ("hair-brown", "#5A3422"),
            ("hair-light-brown", "#8A542B"),
            ("hair-blonde", "#D9A441"),
            ("hair-red", "#B85A24"),
            ("hair-gray", "#A7A7A7"),
            ("hair-white", "#E8E8E8"),
        ],
        "clothing-colors": [
            ("cloth-white", "#F8FAFC"),
            ("cloth-black", "#1F2937"),
            ("cloth-blue", "#4267D6"),
            ("cloth-green", "#35A85A"),
            ("cloth-yellow", "#F2C94C"),
            ("cloth-orange", "#F2994A"),
            ("cloth-red", "#E5484D"),
            ("cloth-purple", "#8B5CF6"),
            ("cloth-lilac", "#B79AF2"),
            ("cloth-beige", "#D8B98F"),
        ],
        "accent-colors": [
            ("accent-blue", "#4267D6"),
            ("accent-green", "#35A85A"),
            ("accent-yellow", "#F2C94C"),
            ("accent-orange", "#F2994A"),
            ("accent-red", "#E5484D"),
            ("accent-purple", "#8B5CF6"),
        ],
    }
    for group, colors in groups.items():
        for swatch_id, color in colors:
            save_swatch(CUSTOMIZATION_DIR / group / f"{swatch_id}.png", color)


def generate_social_sprites() -> None:
    if not SOURCE_SOCIAL.exists():
        return
    source = Image.open(SOURCE_SOCIAL).convert("RGBA")
    for item in SOCIAL_SPRITES:
        item["target"].parent.mkdir(parents=True, exist_ok=True)
        x, y, w, h = item["box"]
        icon = source.crop((x, y, x + w, y + h))
        normalize_icon(icon).save(item["target"])

    manifest = {
        "version": 1,
        "source": "images/ChatGPT Image 4 de jun. de 2026, 12_51_54.png",
        "spriteSize": {"w": 32, "h": 32},
        "sprites": [
            {
                "id": item["id"],
                "type": item["type"],
                "path": str(item["target"].relative_to(ASSETS)),
            }
            for item in SOCIAL_SPRITES
        ],
    }
    (ASSETS / "sprites" / "social-sprites.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def main() -> None:
    if not SOURCE_CHARACTERS.exists():
        raise SystemExit(f"Missing source image: {SOURCE_CHARACTERS}")
    generate_characters()
    generate_social_sprites()
    generate_tilesets()
    generate_furniture()
    generate_social_atlas()
    generate_default_map()
    generate_asset_pack_manifest()
    generate_customization_swatches()
    generate_component_manifest()
    print("Generated character sprites and component manifest.")


if __name__ == "__main__":
    main()
