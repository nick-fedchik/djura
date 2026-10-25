#!/usr/bin/env python3
"""
Stitches 12 angle PNGs (angle_000.png ... angle_330.png) into a single composite turnaround sheet.
"""

import glob
import os
import sys
from PIL import Image, ImageDraw, ImageFont


def stitch_12(folder, out_path, name="Character"):
    angles = [0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330]
    images = []

    for a in angles:
        p = os.path.join(folder, f"angle_{a:03d}.png")
        if not os.path.exists(p):
            print(f"Missing {p}")
            return
        img = Image.open(p).convert("RGBA")
        images.append((a, img))

    w, h = images[0][1].size
    cols = 6
    rows = 2
    pad = 8
    header_h = 40
    footer_h = 24

    sheet_w = cols * w + (cols + 1) * pad
    sheet_h = rows * (h + footer_h) + (rows + 1) * pad + header_h

    sheet = Image.new("RGBA", (sheet_w, sheet_h), (18, 22, 32, 255))
    draw = ImageDraw.Draw(sheet)

    # Title
    draw.text((pad + 10, pad + 8), f"12-ANGLE 360° TURNAROUND: {name.upper()}", fill=(255, 220, 70, 255))

    for idx, (a, img) in enumerate(images):
        col = idx % cols
        row = idx // cols

        x = pad + col * (w + pad)
        y = header_h + pad + row * (h + footer_h + pad)

        # Draw frame bg & border
        draw.rectangle([x, y, x + w, y + h], fill=(28, 34, 48, 255), outline=(65, 80, 110, 255), width=1)
        sheet.paste(img, (x, y), img)

        # Angle caption
        lbl = f"{a}°"
        draw.text((x + w // 2 - 12, y + h + 4), lbl, fill=(180, 210, 255, 255))

    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    sheet.save(out_path)
    print(f"Turnaround sheet saved to: {out_path}")


if __name__ == "__main__":
    folder = sys.argv[1] if len(sys.argv) > 1 else "reports/turnarounds/djura_hero"
    out = sys.argv[2] if len(sys.argv) > 2 else "reports/turnarounds/djura_hero_turnaround_12.png"
    name = sys.argv[3] if len(sys.argv) > 3 else "Юний Джура (15 років)"
    stitch_12(folder, out, name)
