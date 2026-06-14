#!/usr/bin/env python3
"""
Register a new character in characters.json and pubspec.yaml.

Usage:
  python3 scripts/register_character.py \
    --id character-07 \
    --name "Alice" \
    --description "Alice from the marketing team"

Expects all 16 PNG frames to already exist in:
  web/assets/sprites/characters/<id>/

Frames required:
  idle-front.png  idle-back.png  idle-left.png  idle-right.png
  walk-down-01.png  walk-down-02.png  walk-down-03.png
  walk-left-01.png  walk-left-02.png  walk-left-03.png
  walk-right-01.png walk-right-02.png walk-right-03.png
  walk-up-01.png    walk-up-02.png    walk-up-03.png

Also generates a preview.png (128x192) from idle-front.png.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
CHARACTERS_DIR = ROOT / "web" / "assets" / "sprites" / "characters"
PUBSPEC = ROOT / "web" / "pubspec.yaml"

REQUIRED_FRAMES = [
    "idle-front", "idle-back", "idle-left", "idle-right",
    "walk-down-01", "walk-down-02", "walk-down-03",
    "walk-left-01", "walk-left-02", "walk-left-03",
    "walk-right-01", "walk-right-02", "walk-right-03",
    "walk-up-01", "walk-up-02", "walk-up-03",
]


def build_frames(character_id: str) -> dict[str, object]:
    return {
        "idleFront": f"{character_id}/idle-front.png",
        "idleBack": f"{character_id}/idle-back.png",
        "idleLeft": f"{character_id}/idle-left.png",
        "idleRight": f"{character_id}/idle-right.png",
        "walkDown": [f"{character_id}/walk-down-0{i}.png" for i in range(1, 4)],
        "walkLeft": [f"{character_id}/walk-left-0{i}.png" for i in range(1, 4)],
        "walkRight": [f"{character_id}/walk-right-0{i}.png" for i in range(1, 4)],
        "walkUp": [f"{character_id}/walk-up-0{i}.png" for i in range(1, 4)],
    }


def generate_preview(character_dir: Path) -> None:
    src = character_dir / "idle-front.png"
    dst = character_dir / "preview.png"
    if not src.exists():
        return
    img = Image.open(src).convert("RGBA")
    img = img.resize((128, 192), Image.Resampling.NEAREST)
    img.save(dst)
    print(f"Generated preview: {dst.name}")


def add_to_pubspec(character_id: str) -> None:
    content = PUBSPEC.read_text(encoding="utf-8")
    asset_line = f"    - assets/sprites/characters/{character_id}/\n"

    if asset_line.strip() in content:
        print(f"pubspec.yaml: {character_id} already registered")
        return

    # Insert after the last character entry
    pattern = r"(    - assets/sprites/characters/character-\d+/\n)"
    matches = list(re.finditer(pattern, content))
    if matches:
        last_match = matches[-1]
        insert_pos = last_match.end()
        content = content[:insert_pos] + asset_line + content[insert_pos:]
        PUBSPEC.write_text(content, encoding="utf-8")
        print(f"pubspec.yaml: added {character_id}")
    else:
        print("Warning: could not find character asset entries in pubspec.yaml — add manually:")
        print(f"  {asset_line.strip()}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Register a new character in the game catalog")
    parser.add_argument("--id", required=True, help="Character ID, e.g. character-07")
    parser.add_argument("--name", required=True, help="Display name, e.g. Alice")
    parser.add_argument("--description", default="", help="Short description")
    args = parser.parse_args()

    character_id = args.id
    character_dir = CHARACTERS_DIR / character_id

    # Validate frames exist
    missing = [f for f in REQUIRED_FRAMES if not (character_dir / f"{f}.png").exists()]
    if missing:
        print(f"Error: missing frames in {character_dir}:")
        for m in missing:
            print(f"  {m}.png")
        sys.exit(1)

    # Generate preview
    generate_preview(character_dir)

    # Load characters.json
    catalog_path = CHARACTERS_DIR / "characters.json"
    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))

    # Check if already registered
    if any(c["id"] == character_id for c in catalog["characters"]):
        print(f"Character {character_id} already in characters.json")
    else:
        catalog["characters"].append({
            "id": character_id,
            "displayName": args.name,
            "description": args.description or args.name,
            "default": False,
            "frames": build_frames(character_id),
            "hitbox": {"x": 6, "y": 22, "w": 20, "h": 24},
        })
        catalog_path.write_text(
            json.dumps(catalog, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        print(f"characters.json: registered {character_id} ({args.name})")

    # Update pubspec.yaml
    add_to_pubspec(character_id)

    print(f"\nDone! Character {character_id} ({args.name}) is ready to use.")


if __name__ == "__main__":
    main()
