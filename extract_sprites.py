"""
Extracts sprite frames from 4x4 grid sprite sheets using sprite_config.json.
Grid layout: 4 cols x 4 rows — each row is a direction, each column a walk frame.
Usage: python3 extract_sprites.py
"""
import json
import os
from PIL import Image

CONFIG_FILE = "sprite_config.json"
OUT_DIR     = "web/assets/sprites/characters"


def detect_grid_bounds(sheet, alpha_thr=30):
    """Detect content bounds for each column and row by alpha sum gaps.

    Solid-background rows (alpha coverage ≥ 80 % of width) are excluded before
    the column analysis so they don't flood the gap zones and merge all columns.
    """
    w, h = sheet.size
    pix  = sheet.load()

    row_sums = [sum(pix[x, y][3] for x in range(w)) for y in range(h)]

    def find_bands(sums, length, min_frac=0.02):
        thr = max(sums) * min_frac
        bands, in_band, start = [], False, 0
        for i, s in enumerate(sums):
            if s >= thr and not in_band:
                in_band = True; start = i
            elif s < thr and in_band:
                bands.append((start, i)); in_band = False
        if in_band:
            bands.append((start, length))
        return bands

    row_bands = find_bands(row_sums, h)

    # If the last row band is a solid background (avg alpha > 220 per pixel),
    # exclude it so the column analysis isn't flooded by uniform background rows.
    content_h = h
    if row_bands:
        last_y0, last_y1 = row_bands[-1]
        last_band_rows = last_y1 - last_y0
        last_band_sum = sum(row_sums[y] for y in range(last_y0, last_y1))
        avg_alpha = last_band_sum / (last_band_rows * w) if last_band_rows * w > 0 else 0
        if avg_alpha > 220 and len(row_bands) > 1:
            content_h = last_y0  # stop before the background band

    col_sums = [sum(pix[x, y][3] for y in range(content_h)) for x in range(w)]
    col_bands = find_bands(col_sums, w)

    return col_bands, row_bands


def extract_cell(sheet, col_band, row_band, alpha_thr=30):
    """Crop and tight-trim a cell to its visible character content."""
    cx0, cx1 = col_band
    ry0, ry1 = row_band
    cell = sheet.crop((cx0, ry0, cx1, ry1))
    pix  = cell.load()
    cw, ch = cell.size

    xs = [x for x in range(cw) if any(pix[x, y][3] > alpha_thr for y in range(ch))]
    ys = [y for y in range(ch) if any(pix[x, y][3] > alpha_thr for x in range(cw))]

    if not xs or not ys:
        return cell

    return cell.crop((min(xs), min(ys), max(xs) + 1, max(ys) + 1))


def smart_resize(img, tw, th):
    """Scale to fit tw×th, maintain aspect ratio, anchor bottom-center."""
    cw, ch = img.size
    if cw == 0 or ch == 0:
        return Image.new("RGBA", (tw, th), (0, 0, 0, 0))
    scale = min(tw / cw, th / ch)
    nw    = max(1, int(cw * scale))
    nh    = max(1, int(ch * scale))
    resized = img.resize((nw, nh), Image.NEAREST)
    out = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
    ox  = (tw - nw) // 2
    oy  = th - nh
    out.paste(resized, (ox, oy), resized)
    return out


def process_character(char_cfg, frame_grid, game_w, game_h, prev_w, prev_h, alpha_thr):
    source  = char_cfg["source"]
    char_id = char_cfg["id"]

    if not os.path.exists(source):
        print(f"  SKIP {char_id}: {source} not found")
        return

    sheet = Image.open(source).convert("RGBA")
    col_bands, row_bands = detect_grid_bounds(sheet, alpha_thr / 255)

    if len(col_bands) < 4 or len(row_bands) < 4:
        print(f"  WARN {char_id}: detected {len(col_bands)} cols x {len(row_bands)} rows — expected 4x4")

    out_dir = os.path.join(OUT_DIR, char_id)
    os.makedirs(out_dir, exist_ok=True)

    for frame_name, (row_idx, col_idx) in frame_grid.items():
        if row_idx >= len(row_bands) or col_idx >= len(col_bands):
            print(f"  WARN {char_id}/{frame_name}: index ({row_idx},{col_idx}) out of range")
            continue

        content = extract_cell(sheet, col_bands[col_idx], row_bands[row_idx], alpha_thr)
        sprite  = smart_resize(content, game_w, game_h)
        sprite.save(os.path.join(out_dir, f"{frame_name}.png"))

    # Preview: idle-front
    idle_row, idle_col = frame_grid["idle-front"]
    if idle_row < len(row_bands) and idle_col < len(col_bands):
        content = extract_cell(sheet, col_bands[idle_col], row_bands[idle_row], alpha_thr)
        preview = smart_resize(content, prev_w, prev_h)
        preview.save(os.path.join(out_dir, "preview.png"))

    print(f"  {char_id} ({char_cfg.get('displayName', char_id)}): OK")


def main():
    base = os.path.dirname(os.path.abspath(__file__))
    os.chdir(base)

    with open(CONFIG_FILE, encoding="utf-8") as f:
        cfg = json.load(f)

    game_w, game_h = cfg["game_size"]
    prev_w, prev_h = cfg["preview_size"]
    alpha_thr      = cfg.get("alpha_threshold", 30)
    frame_grid     = cfg["frame_grid"]

    print("Extracting sprites from sprite_config.json ...")
    for char_cfg in cfg["characters"]:
        process_character(char_cfg, frame_grid, game_w, game_h, prev_w, prev_h, alpha_thr)
    print("Done.")


if __name__ == "__main__":
    main()
