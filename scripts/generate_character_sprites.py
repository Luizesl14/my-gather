#!/usr/bin/env python3
"""
Generate pixel art character sprites with true RGBA transparent background.

Draws everything as RGBA from the first pixel — no background removal needed,
no pixelated edges. Characters are chibi-style matching the game's existing
sprite proportions (32x48 game size).

Usage:
  python3 scripts/generate_character_sprites.py
    --id character-07
    --name "Alice"
    --skin "#F6D8B5"
    --hair "#1E1E1E"
    --shirt "#4267D6"
    --pants "#1F2937"
    --shoes "#3A2118"
    --save-game            # also copy frames to web/assets/sprites/characters/
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
IMAGES_CLAUDE = ROOT / "images" / "claude"
CHARACTERS_DIR = ROOT / "web" / "assets" / "sprites" / "characters"

# Working resolution: 3× the 32×48 game sprite = 96×144
# We draw at 3× for clarity, then scale down with NEAREST for pixel-perfect output
W, H = 96, 144
GAME_W, GAME_H = 32, 48


def hex_to_rgb(h: str) -> tuple[int, int, int]:
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


def lighten(rgb: tuple[int, int, int], amount: int = 35) -> tuple[int, int, int]:
    return tuple(min(255, c + amount) for c in rgb)  # type: ignore


def darken(rgb: tuple[int, int, int], amount: int = 40) -> tuple[int, int, int]:
    return tuple(max(0, c - amount) for c in rgb)  # type: ignore


def rgba(rgb: tuple[int, int, int], a: int = 255) -> tuple[int, int, int, int]:
    return (*rgb, a)


OUTLINE = (20, 10, 5)

# ── Palette builder ────────────────────────────────────────────────────────────

class Palette:
    def __init__(self, skin: str, hair: str, shirt: str, pants: str, shoes: str):
        self.skin       = hex_to_rgb(skin)
        self.skin_hi    = lighten(self.skin, 28)
        self.skin_sh    = darken(self.skin, 35)
        self.hair       = hex_to_rgb(hair)
        self.hair_hi    = lighten(self.hair, 25)
        self.hair_sh    = darken(self.hair, 45)
        self.shirt      = hex_to_rgb(shirt)
        self.shirt_hi   = lighten(self.shirt, 30)
        self.shirt_sh   = darken(self.shirt, 40)
        self.pants      = hex_to_rgb(pants)
        self.pants_sh   = darken(self.pants, 35)
        self.shoes      = hex_to_rgb(shoes)
        self.shoes_sh   = darken(self.shoes, 40)
        self.outline    = OUTLINE
        self.white      = (245, 245, 240)
        self.pupil      = (20, 10, 5)
        self.iris       = (80, 45, 20)


# ── Drawing primitives ─────────────────────────────────────────────────────────

def canvas() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def filled_ellipse(draw: ImageDraw.ImageDraw, cx: int, cy: int, rx: int, ry: int,
                   fill: tuple, outline: tuple = OUTLINE, width: int = 2) -> None:
    draw.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=rgba(fill), outline=rgba(outline), width=width)


def filled_rect(draw: ImageDraw.ImageDraw, x0: int, y0: int, x1: int, y1: int,
                fill: tuple, outline: tuple | None = OUTLINE, width: int = 2) -> None:
    kw: dict = {"fill": rgba(fill)}
    if outline:
        kw["outline"] = rgba(outline)
        kw["width"] = width
    draw.rectangle((x0, y0, x1, y1), **kw)


def rounded_rect(draw: ImageDraw.ImageDraw, x0: int, y0: int, x1: int, y1: int,
                 radius: int, fill: tuple, outline: tuple = OUTLINE, width: int = 2) -> None:
    draw.rounded_rectangle((x0, y0, x1, y1), radius=radius, fill=rgba(fill),
                           outline=rgba(outline), width=width)


# ── Character part drawers ─────────────────────────────────────────────────────

def draw_head_front(draw: ImageDraw.ImageDraw, p: Palette, cx: int = 48, cy: int = 30) -> None:
    # Main head oval
    filled_ellipse(draw, cx, cy, 26, 28, p.skin)
    # Highlight top-left of head
    filled_ellipse(draw, cx - 8, cy - 12, 10, 10, p.skin_hi, outline=p.skin_hi, width=0)
    # Shadow bottom of head (chin area)
    filled_ellipse(draw, cx, cy + 16, 20, 12, p.skin_sh, outline=p.skin_sh, width=0)
    # Re-draw outline over shading
    filled_ellipse(draw, cx, cy, 26, 28, fill=p.skin, outline=p.outline, width=2)

    # Eyes
    # Left eye
    lx, ey = cx - 9, cy - 4
    rounded_rect(draw, lx - 6, ey - 3, lx + 6, ey + 4, 2, p.white, p.outline, 1)
    draw.ellipse((lx - 3, ey - 2, lx + 3, ey + 3), fill=rgba(p.iris))
    draw.ellipse((lx - 1, ey - 1, lx + 1, ey + 1), fill=rgba(p.pupil))
    draw.point((lx - 2, ey - 2), fill=rgba(p.white))  # eye shine

    # Right eye
    rx_e = cx + 9
    rounded_rect(draw, rx_e - 6, ey - 3, rx_e + 6, ey + 4, 2, p.white, p.outline, 1)
    draw.ellipse((rx_e - 3, ey - 2, rx_e + 3, ey + 3), fill=rgba(p.iris))
    draw.ellipse((rx_e - 1, ey - 1, rx_e + 1, ey + 1), fill=rgba(p.pupil))
    draw.point((rx_e - 2, ey - 2), fill=rgba(p.white))

    # Eyebrows
    draw.line((lx - 6, ey - 6, lx + 5, ey - 8), fill=rgba(p.hair), width=2)
    draw.line((rx_e - 5, ey - 8, rx_e + 6, ey - 6), fill=rgba(p.hair), width=2)

    # Nose (subtle)
    draw.ellipse((cx - 1, cy + 4, cx + 1, cy + 6), fill=rgba(p.skin_sh))

    # Mouth
    draw.arc((cx - 8, cy + 10, cx + 8, cy + 20), start=10, end=170, fill=rgba(p.skin_sh), width=2)

    # Cheek blush (subtle)
    draw.ellipse((lx - 8, cy + 6, lx + 2, cy + 12), fill=(255, 190, 170, 60))
    draw.ellipse((rx_e - 2, cy + 6, rx_e + 8, cy + 12), fill=(255, 190, 170, 60))


def draw_head_back(draw: ImageDraw.ImageDraw, p: Palette, cx: int = 48, cy: int = 30) -> None:
    filled_ellipse(draw, cx, cy, 26, 28, p.skin)
    # Shadow at bottom visible
    filled_ellipse(draw, cx, cy + 16, 20, 12, p.skin_sh, outline=p.skin_sh, width=0)
    filled_ellipse(draw, cx, cy, 26, 28, fill=p.skin, outline=p.outline, width=2)


def draw_head_left(draw: ImageDraw.ImageDraw, p: Palette, cx: int = 48, cy: int = 30) -> None:
    # Slightly narrower (profile)
    filled_ellipse(draw, cx, cy, 22, 28, p.skin)
    # Highlight
    filled_ellipse(draw, cx + 6, cy - 10, 10, 10, p.skin_hi, outline=p.skin_hi, width=0)
    filled_ellipse(draw, cx, cy, 22, 28, fill=p.skin, outline=p.outline, width=2)

    # One eye (right eye from character's perspective = visible on left side)
    ex, ey = cx - 6, cy - 4
    rounded_rect(draw, ex - 5, ey - 3, ex + 5, ey + 4, 2, p.white, p.outline, 1)
    draw.ellipse((ex - 2, ey - 2, ex + 2, ey + 3), fill=rgba(p.iris))
    draw.ellipse((ex - 1, ey - 1, ex + 1, ey + 1), fill=rgba(p.pupil))

    # Nose in profile
    draw.line((cx - 22, cy + 4, cx - 16, cy + 8), fill=rgba(p.skin_sh), width=2)

    # Ear on right side
    draw.ellipse((cx + 18, cy - 6, cx + 26, cy + 6), fill=rgba(p.skin), outline=rgba(p.outline), width=1)


def draw_head_right(draw: ImageDraw.ImageDraw, p: Palette, cx: int = 48, cy: int = 30) -> None:
    filled_ellipse(draw, cx, cy, 22, 28, p.skin)
    filled_ellipse(draw, cx - 6, cy - 10, 10, 10, p.skin_hi, outline=p.skin_hi, width=0)
    filled_ellipse(draw, cx, cy, 22, 28, fill=p.skin, outline=p.outline, width=2)

    ex, ey = cx + 6, cy - 4
    rounded_rect(draw, ex - 5, ey - 3, ex + 5, ey + 4, 2, p.white, p.outline, 1)
    draw.ellipse((ex - 2, ey - 2, ex + 2, ey + 3), fill=rgba(p.iris))
    draw.ellipse((ex - 1, ey - 1, ex + 1, ey + 1), fill=rgba(p.pupil))

    draw.line((cx + 22, cy + 4, cx + 16, cy + 8), fill=rgba(p.skin_sh), width=2)
    draw.ellipse((cx - 26, cy - 6, cx - 18, cy + 6), fill=rgba(p.skin), outline=rgba(p.outline), width=1)


def draw_hair_front(draw: ImageDraw.ImageDraw, p: Palette, cx: int = 48, cy: int = 30,
                    style: str = "medium") -> None:
    # Hair base over head top
    if style == "medium":
        # Top/sides coverage
        draw.ellipse((cx - 28, cy - 30, cx + 28, cy + 2), fill=rgba(p.hair), outline=rgba(p.outline), width=2)
        # Side bangs
        draw.ellipse((cx - 30, cy - 18, cx - 10, cy + 8), fill=rgba(p.hair), outline=rgba(p.hair), width=0)
        draw.ellipse((cx + 10, cy - 18, cx + 30, cy + 8), fill=rgba(p.hair), outline=rgba(p.hair), width=0)
        # Hair highlight
        draw.ellipse((cx - 10, cy - 28, cx + 10, cy - 16), fill=rgba(p.hair_hi), outline=rgba(p.hair_hi), width=0)
        # Re-outline
        draw.arc((cx - 28, cy - 30, cx + 28, cy + 2), start=180, end=360, fill=rgba(p.outline), width=2)
        draw.line((cx - 28, cy - 14, cx - 28, cy + 2), fill=rgba(p.outline), width=2)
        draw.line((cx + 28, cy - 14, cx + 28, cy + 2), fill=rgba(p.outline), width=2)
    elif style == "short":
        draw.ellipse((cx - 26, cy - 30, cx + 26, cy - 8), fill=rgba(p.hair), outline=rgba(p.outline), width=2)
        draw.ellipse((cx - 10, cy - 28, cx + 10, cy - 18), fill=rgba(p.hair_hi), outline=rgba(p.hair_hi), width=0)


def draw_hair_back(draw: ImageDraw.ImageDraw, p: Palette, cx: int = 48, cy: int = 30,
                   style: str = "medium") -> None:
    draw.ellipse((cx - 28, cy - 30, cx + 28, cy + 14), fill=rgba(p.hair), outline=rgba(p.outline), width=2)
    draw.ellipse((cx - 10, cy - 28, cx + 10, cy - 16), fill=rgba(p.hair_hi), outline=rgba(p.hair_hi), width=0)


def draw_hair_side(draw: ImageDraw.ImageDraw, p: Palette, cx: int = 48, cy: int = 30,
                   direction: str = "left") -> None:
    ox = -2 if direction == "left" else 2
    draw.ellipse((cx - 24 + ox, cy - 30, cx + 24 + ox, cy + 10), fill=rgba(p.hair), outline=rgba(p.outline), width=2)
    draw.ellipse((cx - 8 + ox, cy - 28, cx + 8 + ox, cy - 16), fill=rgba(p.hair_hi), outline=rgba(p.hair_hi), width=0)


def draw_body_front(draw: ImageDraw.ImageDraw, p: Palette,
                    neck_y: int = 58, body_end: int = 108) -> None:
    # Neck
    filled_rect(draw, 40, neck_y, 56, neck_y + 14, p.skin, p.outline, 1)

    # Shoulders + torso
    rounded_rect(draw, 20, neck_y + 10, 76, body_end, 6, p.shirt)
    # Shirt highlight (left side)
    draw.rectangle((22, neck_y + 12, 34, body_end - 4), fill=rgba(p.shirt_hi))
    # Shirt shadow (right side)
    draw.rectangle((62, neck_y + 12, 74, body_end - 4), fill=rgba(p.shirt_sh))
    # Re-outline
    rounded_rect(draw, 20, neck_y + 10, 76, body_end, 6, fill=p.shirt, outline=p.outline, width=2)

    # Arms
    # Left arm
    rounded_rect(draw, 8, neck_y + 12, 24, body_end - 8, 6, p.shirt)
    draw.rectangle((10, neck_y + 14, 16, body_end - 16), fill=rgba(p.shirt_hi))
    rounded_rect(draw, 8, neck_y + 12, 24, body_end - 8, 6, fill=p.shirt, outline=p.outline, width=2)
    # Left hand
    rounded_rect(draw, 10, body_end - 16, 22, body_end, 4, p.skin, p.outline, 1)

    # Right arm
    rounded_rect(draw, 72, neck_y + 12, 88, body_end - 8, 6, p.shirt)
    draw.rectangle((80, neck_y + 14, 86, body_end - 16), fill=rgba(p.shirt_sh))
    rounded_rect(draw, 72, neck_y + 12, 88, body_end - 8, 6, fill=p.shirt, outline=p.outline, width=2)
    # Right hand
    rounded_rect(draw, 74, body_end - 16, 86, body_end, 4, p.skin, p.outline, 1)


def draw_body_back(draw: ImageDraw.ImageDraw, p: Palette,
                   neck_y: int = 58, body_end: int = 108) -> None:
    filled_rect(draw, 40, neck_y, 56, neck_y + 14, p.skin, p.outline, 1)
    rounded_rect(draw, 20, neck_y + 10, 76, body_end, 6, p.shirt)
    draw.rectangle((22, neck_y + 12, 34, body_end - 4), fill=rgba(p.shirt_hi))
    draw.rectangle((62, neck_y + 12, 74, body_end - 4), fill=rgba(p.shirt_sh))
    rounded_rect(draw, 20, neck_y + 10, 76, body_end, 6, fill=p.shirt, outline=p.outline, width=2)

    rounded_rect(draw, 8, neck_y + 12, 24, body_end - 8, 6, p.shirt)
    rounded_rect(draw, 8, neck_y + 12, 24, body_end - 8, 6, fill=p.shirt, outline=p.outline, width=2)
    rounded_rect(draw, 10, body_end - 16, 22, body_end, 4, p.skin, p.outline, 1)
    rounded_rect(draw, 72, neck_y + 12, 88, body_end - 8, 6, p.shirt)
    rounded_rect(draw, 72, neck_y + 12, 88, body_end - 8, 6, fill=p.shirt, outline=p.outline, width=2)
    rounded_rect(draw, 74, body_end - 16, 86, body_end, 4, p.skin, p.outline, 1)


def draw_body_side(draw: ImageDraw.ImageDraw, p: Palette, direction: str = "left",
                   neck_y: int = 58, body_end: int = 108) -> None:
    ox = -4 if direction == "left" else 4
    filled_rect(draw, 40 + ox, neck_y, 56 + ox, neck_y + 14, p.skin, p.outline, 1)
    rounded_rect(draw, 24 + ox, neck_y + 10, 72 + ox, body_end, 6, p.shirt)
    rounded_rect(draw, 24 + ox, neck_y + 10, 72 + ox, body_end, 6, fill=p.shirt, outline=p.outline, width=2)

    # Front arm (closer to camera)
    front_x = (6 if direction == "left" else 64) + ox
    rounded_rect(draw, front_x, neck_y + 12, front_x + 16, body_end - 6, 6, p.shirt)
    rounded_rect(draw, front_x, neck_y + 12, front_x + 16, body_end - 6, 6, fill=p.shirt, outline=p.outline, width=2)
    rounded_rect(draw, front_x + 2, body_end - 14, front_x + 14, body_end + 2, 4, p.skin, p.outline, 1)


def draw_legs_front(draw: ImageDraw.ImageDraw, p: Palette,
                    leg_top: int = 108, leg_bot: int = 138,
                    l_off: int = 0, r_off: int = 0) -> None:
    # Left leg
    rounded_rect(draw, 26, leg_top + l_off, 46, leg_bot + l_off, 4, p.pants)
    draw.rectangle((28, leg_top + 4 + l_off, 34, leg_bot - 4 + l_off), fill=rgba(lighten(p.pants, 15)))
    rounded_rect(draw, 26, leg_top + l_off, 46, leg_bot + l_off, 4, fill=p.pants, outline=p.outline, width=2)
    # Left shoe
    rounded_rect(draw, 24, leg_bot + l_off, 48, leg_bot + 12 + l_off, 3, p.shoes, p.outline, 2)

    # Right leg
    rounded_rect(draw, 50, leg_top + r_off, 70, leg_bot + r_off, 4, p.pants)
    draw.rectangle((62, leg_top + 4 + r_off, 68, leg_bot - 4 + r_off), fill=rgba(darken(p.pants, 15)))
    rounded_rect(draw, 50, leg_top + r_off, 70, leg_bot + r_off, 4, fill=p.pants, outline=p.outline, width=2)
    # Right shoe
    rounded_rect(draw, 48, leg_bot + r_off, 72, leg_bot + 12 + r_off, 3, p.shoes, p.outline, 2)


def draw_legs_back(draw: ImageDraw.ImageDraw, p: Palette,
                   leg_top: int = 108, leg_bot: int = 138,
                   l_off: int = 0, r_off: int = 0) -> None:
    draw_legs_front(draw, p, leg_top, leg_bot, l_off, r_off)


def draw_legs_side(draw: ImageDraw.ImageDraw, p: Palette, direction: str = "left",
                   leg_top: int = 108, leg_bot: int = 138,
                   front_off: int = 0, back_off: int = 6) -> None:
    ox = -4 if direction == "left" else 4

    # Back leg (partially hidden)
    rounded_rect(draw, 36 + ox, leg_top + back_off, 58 + ox, leg_bot + back_off, 4, darken(p.pants, 20))
    rounded_rect(draw, 36 + ox, leg_top + back_off, 58 + ox, leg_bot + back_off, 4,
                 fill=darken(p.pants, 20), outline=p.outline, width=2)
    rounded_rect(draw, 32 + ox, leg_bot + back_off, 62 + ox, leg_bot + 12 + back_off, 3, p.shoes, p.outline, 2)

    # Front leg
    rounded_rect(draw, 36 + ox, leg_top + front_off, 58 + ox, leg_bot + front_off, 4, p.pants)
    rounded_rect(draw, 36 + ox, leg_top + front_off, 58 + ox, leg_bot + front_off, 4,
                 fill=p.pants, outline=p.outline, width=2)
    rounded_rect(draw, 32 + ox, leg_bot + front_off, 62 + ox, leg_bot + 12 + front_off, 3, p.shoes, p.outline, 2)


# ── Frame builders ─────────────────────────────────────────────────────────────

NECK_Y = 56
BODY_END = 108
LEG_TOP = 108
LEG_BOT = 136


def make_idle_front(p: Palette) -> Image.Image:
    img, draw = canvas()
    draw_legs_front(draw, p, LEG_TOP, LEG_BOT)
    draw_body_front(draw, p, NECK_Y, BODY_END)
    draw_head_front(draw, p)
    draw_hair_front(draw, p)
    return img.resize((GAME_W, GAME_H), Image.Resampling.NEAREST)


def make_idle_back(p: Palette) -> Image.Image:
    img, draw = canvas()
    draw_legs_back(draw, p, LEG_TOP, LEG_BOT)
    draw_body_back(draw, p, NECK_Y, BODY_END)
    draw_head_back(draw, p)
    draw_hair_back(draw, p)
    return img.resize((GAME_W, GAME_H), Image.Resampling.NEAREST)


def make_idle_left(p: Palette) -> Image.Image:
    img, draw = canvas()
    draw_legs_side(draw, p, "left", LEG_TOP, LEG_BOT, 0, 0)
    draw_body_side(draw, p, "left", NECK_Y, BODY_END)
    draw_head_left(draw, p)
    draw_hair_side(draw, p, direction="left")
    return img.resize((GAME_W, GAME_H), Image.Resampling.NEAREST)


def make_idle_right(p: Palette) -> Image.Image:
    img, draw = canvas()
    draw_legs_side(draw, p, "right", LEG_TOP, LEG_BOT, 0, 0)
    draw_body_side(draw, p, "right", NECK_Y, BODY_END)
    draw_head_right(draw, p)
    draw_hair_side(draw, p, direction="right")
    return img.resize((GAME_W, GAME_H), Image.Resampling.NEAREST)


def make_walk_down(p: Palette, frame: int) -> Image.Image:
    img, draw = canvas()
    offsets = [(-8, 4), (0, 0), (8, -4)]
    l_off, r_off = offsets[(frame - 1) % 3]
    draw_legs_front(draw, p, LEG_TOP, LEG_BOT, l_off, r_off)
    draw_body_front(draw, p, NECK_Y - 2, BODY_END - 2)
    draw_head_front(draw, p, 48, 28)
    draw_hair_front(draw, p, 48, 28)
    return img.resize((GAME_W, GAME_H), Image.Resampling.NEAREST)


def make_walk_up(p: Palette, frame: int) -> Image.Image:
    img, draw = canvas()
    offsets = [(-8, 4), (0, 0), (8, -4)]
    l_off, r_off = offsets[(frame - 1) % 3]
    draw_legs_back(draw, p, LEG_TOP, LEG_BOT, l_off, r_off)
    draw_body_back(draw, p, NECK_Y - 2, BODY_END - 2)
    draw_head_back(draw, p, 48, 28)
    draw_hair_back(draw, p, 48, 28)
    return img.resize((GAME_W, GAME_H), Image.Resampling.NEAREST)


def make_walk_left(p: Palette, frame: int) -> Image.Image:
    img, draw = canvas()
    leg_offsets = [(0, 8), (0, 0), (8, 0)]
    front_off, back_off = leg_offsets[(frame - 1) % 3]
    draw_legs_side(draw, p, "left", LEG_TOP, LEG_BOT, front_off, back_off)
    draw_body_side(draw, p, "left", NECK_Y - 2, BODY_END - 2)
    draw_head_left(draw, p, 48, 28)
    draw_hair_side(draw, p, direction="left")
    return img.resize((GAME_W, GAME_H), Image.Resampling.NEAREST)


def make_walk_right(p: Palette, frame: int) -> Image.Image:
    img, draw = canvas()
    leg_offsets = [(0, 8), (0, 0), (8, 0)]
    front_off, back_off = leg_offsets[(frame - 1) % 3]
    draw_legs_side(draw, p, "right", LEG_TOP, LEG_BOT, front_off, back_off)
    draw_body_side(draw, p, "right", NECK_Y - 2, BODY_END - 2)
    draw_head_right(draw, p, 48, 28)
    draw_hair_side(draw, p, direction="right")
    return img.resize((GAME_W, GAME_H), Image.Resampling.NEAREST)


# ── Reference sheet for images/claude/ ────────────────────────────────────────

def make_reference_sheet(frames: dict[str, Image.Image], name: str, p: Palette) -> Image.Image:
    """4×4 grid: row1=idle, row2=walk-down, row3=walk-side, row4=walk-up"""
    order = [
        ["idle-front", "idle-back", "idle-left", "idle-right"],
        ["walk-down-01", "walk-down-02", "walk-down-03", None],
        ["walk-left-01", "walk-left-02", "walk-left-03", None],
        ["walk-right-01", "walk-right-02", "walk-right-03", None],
        ["walk-up-01", "walk-up-02", "walk-up-03", None],
    ]
    # Scale up 4× for the reference sheet (128×192 per cell)
    cell_w, cell_h = GAME_W * 4, GAME_H * 4
    pad = 8
    cols = 4
    rows = len(order)
    sheet = Image.new("RGBA", (cols * (cell_w + pad) + pad, rows * (cell_h + pad) + pad), (0, 0, 0, 0))

    for row_idx, row in enumerate(order):
        for col_idx, key in enumerate(row):
            if key is None:
                continue
            frame = frames.get(key)
            if frame is None:
                continue
            big = frame.resize((cell_w, cell_h), Image.Resampling.NEAREST)
            x = pad + col_idx * (cell_w + pad)
            y = pad + row_idx * (cell_h + pad)
            sheet.alpha_composite(big, (x, y))

    return sheet


# ── Main ───────────────────────────────────────────────────────────────────────

def build_character(p: Palette) -> dict[str, Image.Image]:
    return {
        "idle-front":    make_idle_front(p),
        "idle-back":     make_idle_back(p),
        "idle-left":     make_idle_left(p),
        "idle-right":    make_idle_right(p),
        "walk-down-01":  make_walk_down(p, 1),
        "walk-down-02":  make_walk_down(p, 2),
        "walk-down-03":  make_walk_down(p, 3),
        "walk-left-01":  make_walk_left(p, 1),
        "walk-left-02":  make_walk_left(p, 2),
        "walk-left-03":  make_walk_left(p, 3),
        "walk-right-01": make_walk_right(p, 1),
        "walk-right-02": make_walk_right(p, 2),
        "walk-right-03": make_walk_right(p, 3),
        "walk-up-01":    make_walk_up(p, 1),
        "walk-up-02":    make_walk_up(p, 2),
        "walk-up-03":    make_walk_up(p, 3),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate pixel art character sprites")
    parser.add_argument("--id",      default="character-07", help="character-07, character-08, ...")
    parser.add_argument("--name",    default="New Character")
    parser.add_argument("--skin",    default="#F6D8B5",  help="Skin tone hex")
    parser.add_argument("--hair",    default="#2A1A0A",  help="Hair color hex")
    parser.add_argument("--shirt",   default="#4267D6",  help="Shirt/top color hex")
    parser.add_argument("--pants",   default="#1F2937",  help="Pants color hex")
    parser.add_argument("--shoes",   default="#3A2118",  help="Shoes color hex")
    parser.add_argument("--save-game", action="store_true",
                        help="Also save frames to web/assets/sprites/characters/<id>/")
    args = parser.parse_args()

    p = Palette(args.skin, args.hair, args.shirt, args.pants, args.shoes)
    print(f"Generating {args.id} ({args.name})...")

    frames = build_character(p)

    # Save reference sheet to images/claude/
    IMAGES_CLAUDE.mkdir(parents=True, exist_ok=True)
    sheet_path = IMAGES_CLAUDE / f"{args.id}-sprite-sheet.png"
    sheet = make_reference_sheet(frames, args.name, p)
    sheet.save(sheet_path)
    print(f"Reference sheet: {sheet_path}")

    # Save preview (idle-front × 4)
    preview = frames["idle-front"].resize((GAME_W * 4, GAME_H * 4), Image.Resampling.NEAREST)
    preview_path = IMAGES_CLAUDE / f"{args.id}-preview.png"
    preview.save(preview_path)
    print(f"Preview:         {preview_path}")

    if args.save_game:
        char_dir = CHARACTERS_DIR / args.id
        char_dir.mkdir(parents=True, exist_ok=True)
        for frame_name, img in frames.items():
            img.save(char_dir / f"{frame_name}.png")
        # Thumbnail preview
        frames["idle-front"].resize((GAME_W * 4, GAME_H * 4), Image.Resampling.NEAREST).save(
            char_dir / "preview.png"
        )
        print(f"Game sprites:    {char_dir}/")


# ── Palette presets (can be imported) ─────────────────────────────────────────

PRESETS = {
    # name: (skin, hair, shirt, pants, shoes)
    "clara-pele-clara-cabelo-preto":  ("#F5D0A9", "#1A0A05", "#8B5CF6", "#1F2937", "#3A2118"),
    "morena-cabelo-castanho-azul":    ("#C47A3A", "#5A3422", "#4267D6", "#1F2937", "#2A1A10"),
    "pele-escura-cabelo-preto-verde": ("#5A2E1B", "#1E1E1E", "#35A85A", "#2D3748", "#1A0E08"),
    "asiatico-cabelo-preto-vermelho": ("#E8C49A", "#1A1A1A", "#E5484D", "#1F2937", "#2A1A10"),
    "senior-cabelo-grisalho-bege":    ("#D4A87A", "#8C8C8C", "#D8B98F", "#4A5568", "#3A2118"),
    "jovem-loiro-camisa-branca":      ("#FDE8C8", "#D9A441", "#F8FAFC", "#2D3748", "#3A2118"),
}


if __name__ == "__main__":
    main()
