#!/usr/bin/env python3
"""
Generates high-resolution cinematic story cards for Stage 1 Level 1
using authentic 3D Meshy renders and Ukrainian Cossack folklore aesthetics.
"""

import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance
import numpy as np

def create_slide_1_meeting():
    w, h = 600, 300
    # Nocturnal Dnipro atmospheric gradient background
    bg = Image.new("RGBA", (w, h), (14, 20, 36, 255))
    draw = ImageDraw.Draw(bg)
    
    # Deep sky gradient & stars
    for y in range(h):
        ratio = y / float(h)
        r = int(10 + ratio * 20)
        g = int(14 + ratio * 25)
        b = int(28 + ratio * 35)
        draw.line([(0, y), (w, y)], fill=(r, g, b, 255))
        
    # Twinkling stars
    np.random.seed(42)
    for _ in range(40):
        sx = np.random.randint(0, w)
        sy = np.random.randint(0, int(h * 0.6))
        sr = np.random.uniform(1.0, 2.5)
        alpha = np.random.randint(140, 255)
        draw.ellipse([sx - sr, sy - sr, sx + sr, sy + sr], fill=(255, 245, 200, alpha))
        
    # Ancient Sich Oak on the left
    oak_pts = [(0, h), (40, 220), (60, 160), (30, 110), (90, 80), (140, 120), (120, 180), (80, 240), (90, h)]
    draw.polygon(oak_pts, fill=(12, 16, 24, 255))
    
    # Dnipro river horizon
    river_pts = [(0, int(h * 0.75)), (w, int(h * 0.72)), (w, h), (0, h)]
    draw.polygon(river_pts, fill=(18, 28, 48, 255))
    
    # Warm golden campfire in center
    cx, cy = int(w * 0.5), int(h * 0.72)
    glow_overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_overlay)
    for rad in range(110, 10, -5):
        alpha = int(45 * (1.0 - rad / 110.0))
        glow_draw.ellipse([cx - rad, cy - rad + 15, cx + rad, cy + rad + 15], fill=(255, 140, 30, alpha))
    for rad in range(45, 5, -5):
        alpha = int(90 * (1.0 - rad / 45.0))
        glow_draw.ellipse([cx - rad, cy - rad + 15, cx + rad, cy + rad + 15], fill=(255, 220, 70, alpha))
    bg = Image.alpha_composite(bg, glow_overlay)
    draw = ImageDraw.Draw(bg)
    
    # Campfire logs & fire
    draw.line([(cx - 24, cy + 28), (cx + 24, cy + 20)], fill=(65, 35, 18, 255), width=7)
    draw.line([(cx + 22, cy + 28), (cx - 22, cy + 20)], fill=(75, 42, 22, 255), width=7)
    flame_pts = [(cx - 16, cy + 22), (cx, cy - 14), (cx + 16, cy + 22)]
    draw.polygon(flame_pts, fill=(255, 150, 20, 255))
    inner_flame = [(cx - 8, cy + 22), (cx, cy - 6), (cx + 8, cy + 22)]
    draw.polygon(inner_flame, fill=(255, 230, 80, 255))

    # Sparks
    for _ in range(12):
        sp_x = cx + np.random.randint(-40, 40)
        sp_y = cy - np.random.randint(5, 75)
        draw.ellipse([sp_x - 1.5, sp_y - 1.5, sp_x + 1.5, sp_y + 1.5], fill=(255, 210, 60, 230))
        
    # Mentor Cossack (Left side)
    mentor_path = "/home/mfedchyk/Godot/djura-1/reports/mentor_cossack_preview.png"
    if os.path.exists(mentor_path):
        m_img = Image.open(mentor_path).convert("RGBA")
        m_img = m_img.resize((210, 210), Image.Resampling.LANCZOS)
        # Flip to face the fire/Djura on the right
        bg.paste(m_img, (35, 65), m_img)
        
    # Young Djura (Right side)
    djura_path = "/home/mfedchyk/Godot/djura-1/reports/meshy_djura_preview.png"
    if os.path.exists(djura_path):
        d_img = Image.open(djura_path).convert("RGBA")
        d_img = d_img.resize((185, 185), Image.Resampling.LANCZOS)
        # Flip to face the Mentor on the left
        d_img = d_img.transpose(Image.FLIP_LEFT_RIGHT)
        bg.paste(d_img, (380, 80), d_img)
        
    # Labels / Title badge
    draw.rectangle([w//2 - 140, 10, w//2 + 140, 38], fill=(18, 22, 38, 230), outline=(220, 180, 60, 255), width=2)
    # Gold decorative border
    draw.rectangle([0, 0, w - 1, h - 1], outline=(220, 180, 60, 255), width=3)
    draw.rectangle([3, 3, w - 4, h - 4], outline=(60, 45, 20, 200), width=1)
    
    out_path = "/home/mfedchyk/Godot/djura-1/assets/sprites/story/slide_level1_1_meeting.png"
    bg.save(out_path)
    print(f"Saved Slide 1 to {out_path}")

def create_slide_2_pledge():
    w, h = 600, 300
    bg = Image.new("RGBA", (w, h), (18, 14, 30, 255))
    draw = ImageDraw.Draw(bg)
    
    # Rich dawn twilight gradient
    for y in range(h):
        ratio = y / float(h)
        r = int(24 + ratio * 35)
        g = int(16 + ratio * 20)
        b = int(38 + ratio * 25)
        draw.line([(0, y), (w, y)], fill=(r, g, b, 255))
        
    # Golden celestial aura behind Djura
    cx, cy = int(w * 0.5), int(h * 0.5)
    aura = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    aura_draw = ImageDraw.Draw(aura)
    for rad in range(140, 20, -6):
        alpha = int(40 * (1.0 - rad / 140.0))
        aura_draw.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=(255, 215, 60, alpha))
    for rad in range(65, 10, -5):
        alpha = int(75 * (1.0 - rad / 65.0))
        aura_draw.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=(70, 180, 255, alpha))
    bg = Image.alpha_composite(bg, aura)
    draw = ImageDraw.Draw(bg)
    
    # Sunburst rays of Cossack blessing
    for deg in range(0, 360, 30):
        rad = math.radians(deg)
        x2 = cx + int(math.cos(rad) * 160)
        y2 = cy + int(math.sin(rad) * 160)
        draw.line([(cx, cy), (x2, y2)], fill=(255, 235, 120, 45), width=2)
        
    # Mentor on left raising hand in blessing
    mentor_path = "/home/mfedchyk/Godot/djura-1/reports/mentor_cossack_preview.png"
    if os.path.exists(mentor_path):
        m_img = Image.open(mentor_path).convert("RGBA")
        m_img = m_img.resize((190, 190), Image.Resampling.LANCZOS)
        bg.paste(m_img, (25, 75), m_img)
        
    # Djura in center/right taking the solemn oath
    djura_path = "/home/mfedchyk/Godot/djura-1/reports/meshy_djura_preview.png"
    if os.path.exists(djura_path):
        d_img = Image.open(djura_path).convert("RGBA")
        d_img = d_img.resize((215, 215), Image.Resampling.LANCZOS)
        bg.paste(d_img, (220, 55), d_img)
        
    # Floating Kyreya cape & golden sash on the right
    kyreya_pts = [(470, 90), (510, 60), (550, 90), (540, 160), (510, 180), (480, 160)]
    draw.polygon(kyreya_pts, fill=(28, 85, 190, 230), outline=(255, 215, 60, 255))
    draw.line([(480, 165), (540, 165)], fill=(255, 215, 60, 255), width=4)
    # Tassels
    draw.line([(500, 165), (495, 205)], fill=(255, 215, 60, 255), width=2)
    draw.line([(520, 165), (525, 205)], fill=(255, 215, 60, 255), width=2)

    # Gold frame
    draw.rectangle([0, 0, w - 1, h - 1], outline=(220, 180, 60, 255), width=3)
    draw.rectangle([3, 3, w - 4, h - 4], outline=(60, 45, 20, 200), width=1)
    
    out_path = "/home/mfedchyk/Godot/djura-1/assets/sprites/story/slide_level1_2_pledge.png"
    bg.save(out_path)
    print(f"Saved Slide 2 to {out_path}")

def create_slide_3_mission():
    w, h = 600, 300
    bg = Image.new("RGBA", (w, h), (14, 16, 24, 255))
    draw = ImageDraw.Draw(bg)
    
    # Night fortress platforms & beams
    for y in range(h):
        ratio = y / float(h)
        r = int(12 + ratio * 15)
        g = int(14 + ratio * 18)
        b = int(22 + ratio * 28)
        draw.line([(0, y), (w, y)], fill=(r, g, b, 255))
        
    # Wooden defense platforms
    draw.rectangle([30, 235, 570, 248], fill=(90, 58, 34, 255), outline=(140, 95, 55, 255), width=2)
    draw.rectangle([180, 145, 570, 156], fill=(90, 58, 34, 255), outline=(140, 95, 55, 255), width=2)
    
    # 1. Mission Object: Powder Bomb with burning fuse on the left
    bx, by = 90, 200
    draw.ellipse([bx - 26, by - 26, bx + 26, by + 26], fill=(22, 22, 26, 255), outline=(65, 65, 75, 255), width=3)
    # Highlight
    draw.ellipse([bx - 16, by - 18, bx - 6, by - 8], fill=(85, 85, 105, 255))
    # Bomb fuse cap & burning wick
    draw.rectangle([bx - 6, by - 33, bx + 6, by - 26], fill=(140, 110, 50, 255))
    draw.line([(bx, by - 33), (bx + 8, by - 44)], fill=(180, 140, 80, 255), width=3)
    # Spark
    draw.ellipse([bx + 6, by - 48, bx + 14, by - 40], fill=(255, 180, 40, 255))
    draw.ellipse([bx + 8, by - 46, bx + 12, by - 42], fill=(255, 255, 200, 255))
    # Spark rays
    for angle in [0, 45, 90, 135, 180, 225, 270, 315]:
        ra = math.radians(angle)
        draw.line([(bx + 10, by - 44), (bx + 10 + math.cos(ra)*9, by - 44 + math.sin(ra)*9)], fill=(255, 220, 60, 255), width=1)
        
    # Text badge for Bomb
    draw.rectangle([bx - 45, by + 32, bx + 45, by + 48], fill=(20, 24, 36, 220), outline=(220, 180, 60, 255), width=1)
    
    # 2. Enemy Queue: Escalation arrows and characters
    # Enemy 1: Vohnyk (Spawns Level 1)
    vohnyk_path = "/home/mfedchyk/Godot/djura-1/reports/sketches/vognyk/vohnyk_concept_meshy.jpg"
    if os.path.exists(vohnyk_path):
        v_img = Image.open(vohnyk_path).convert("RGBA")
        v_img = v_img.resize((100, 100), Image.Resampling.LANCZOS)
        # Apply circular crop & fiery outline
        mask = Image.new("L", (100, 100), 0)
        ImageDraw.Draw(mask).ellipse([2, 2, 98, 98], fill=255)
        bg.paste(v_img, (200, 65), mask)
        draw.ellipse([198, 63, 302, 167], outline=(255, 120, 20, 255), width=3)
        draw.rectangle([190, 172, 310, 192], fill=(25, 15, 10, 230), outline=(255, 120, 20, 255), width=1)
        
    # Arrow 1: "+2 РІВНІ"
    draw.line([(318, 115), (348, 115)], fill=(255, 215, 60, 255), width=3)
    draw.polygon([(348, 108), (358, 115), (348, 122)], fill=(255, 215, 60, 255))
    
    # Enemy 2: Chort (Spawns Level 3)
    chort_path = "/home/mfedchyk/Godot/djura-1/reports/sketches/chort/chort_concept_meshy.jpg"
    if os.path.exists(chort_path):
        c_img = Image.open(chort_path).convert("RGBA")
        c_img = c_img.resize((100, 100), Image.Resampling.LANCZOS)
        mask = Image.new("L", (100, 100), 0)
        ImageDraw.Draw(mask).ellipse([2, 2, 98, 98], fill=255)
        bg.paste(c_img, (365, 65), mask)
        draw.ellipse([363, 63, 467, 167], outline=(180, 50, 220, 255), width=3)
        draw.rectangle([355, 172, 475, 192], fill=(20, 10, 25, 230), outline=(180, 50, 220, 255), width=1)
        
    # Arrow 2: "+2 РІВНІ"
    draw.line([(475, 115), (505, 115)], fill=(255, 215, 60, 255), width=3)
    draw.polygon([(505, 108), (515, 115), (505, 122)], fill=(255, 215, 60, 255))
    
    # Enemy 3: Vidma (Spawns Level 5)
    vidma_path = "/home/mfedchyk/Godot/djura-1/assets/sprites/vidma_calm.png"
    if os.path.exists(vidma_path):
        vi_img = Image.open(vidma_path).convert("RGBA")
        vi_img = vi_img.resize((75, 95), Image.Resampling.LANCZOS)
        bg.paste(vi_img, (520, 68), vi_img)
        draw.ellipse([515, 63, 595, 167], outline=(220, 40, 60, 255), width=3)
        draw.rectangle([510, 172, 595, 192], fill=(30, 10, 15, 230), outline=(220, 40, 60, 255), width=1)
        
    # Gold frame
    draw.rectangle([0, 0, w - 1, h - 1], outline=(220, 180, 60, 255), width=3)
    draw.rectangle([3, 3, w - 4, h - 4], outline=(60, 45, 20, 200), width=1)
    
    out_path = "/home/mfedchyk/Godot/djura-1/assets/sprites/story/slide_level1_3_mission.png"
    bg.save(out_path)
    print(f"Saved Slide 3 to {out_path}")

if __name__ == "__main__":
    create_slide_1_meeting()
    create_slide_2_pledge()
    create_slide_3_mission()
