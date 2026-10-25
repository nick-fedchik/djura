#!/usr/bin/env python3
"""
Generates high-resolution cinematic story cards for Stage 1 Level 1
using authentic 2D concept art of the 15-year-old Djura and Mentor Kharakternyk.
"""

import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance
import numpy as np

def extract_black_bg(img_path, threshold=20):
    im = Image.open(img_path).convert('RGBA')
    arr = np.array(im, dtype=np.float32)
    rgb = arr[:, :, :3]
    brightness = np.max(rgb, axis=2)
    alpha = np.clip((brightness - threshold) / (threshold * 1.5), 0.0, 1.0) * 255.0
    arr[:, :, 3] = alpha
    result = Image.fromarray(arr.astype(np.uint8))
    bbox = result.getbbox()
    if bbox:
        result = result.crop(bbox)
    return result

def extract_light_bg(img_path, bg_color=(233, 234, 236), tol=28):
    im = Image.open(img_path).convert('RGBA')
    arr = np.array(im, dtype=np.float32)
    rgb = arr[:, :, :3]
    bg = np.array(bg_color, dtype=np.float32)
    dist = np.linalg.norm(rgb - bg, axis=2)
    alpha = np.clip((dist - 14) / (tol - 14), 0.0, 1.0) * 255.0
    arr[:, :, 3] = alpha
    res = Image.fromarray(arr.astype(np.uint8))
    bbox = res.getbbox()
    if bbox:
        res = res.crop(bbox)
    return res

def get_djura_15yo_cutout():
    # Use authentic 2D concept art from reports/sketches/djura_15yo/
    p_3q = "/home/mfedchyk/Godot/djura-1/reports/sketches/djura_15yo/djura_02_threequarter_l.png"
    if os.path.exists(p_3q):
        return extract_light_bg(p_3q)
    p_front = "/home/mfedchyk/Godot/djura-1/reports/sketches/djura_15yo/djura_01_front.png"
    if os.path.exists(p_front):
        return extract_light_bg(p_front)
    return Image.open("/home/mfedchyk/Godot/djura-1/reports/djura_15yo_preview.png").convert("RGBA")

def get_mentor_cutout():
    p_prev = "/home/mfedchyk/Godot/djura-1/reports/mentor_cossack_preview.png"
    if os.path.exists(p_prev):
        return extract_black_bg(p_prev)
    p_port = "/home/mfedchyk/Godot/djura-1/assets/sprites/mentor_portrait.png"
    if os.path.exists(p_port):
        return Image.open(p_port).convert("RGBA")
    return None

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
    for rad in range(120, 10, -5):
        alpha = int(45 * (1.0 - rad / 120.0))
        glow_draw.ellipse([cx - rad, cy - rad + 15, cx + rad, cy + rad + 15], fill=(255, 140, 30, alpha))
    for rad in range(50, 5, -5):
        alpha = int(90 * (1.0 - rad / 50.0))
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
    for _ in range(16):
        sp_x = cx + np.random.randint(-40, 40)
        sp_y = cy - np.random.randint(5, 85)
        draw.ellipse([sp_x - 1.5, sp_y - 1.5, sp_x + 1.5, sp_y + 1.5], fill=(255, 210, 60, 230))
        
    # Mentor Cossack (Left side)
    m_cut = get_mentor_cutout()
    if m_cut:
        target_h = 220
        target_w = int(m_cut.width * target_h / m_cut.height)
        m_img = m_cut.resize((target_w, target_h), Image.Resampling.LANCZOS)
        bg.paste(m_img, (45, 68), m_img)
        
    # Young 15yo Djura (Right side) - authentic 2D concept art
    d_cut = get_djura_15yo_cutout()
    if d_cut:
        # Flip to face left toward the Mentor and campfire
        d_cut = d_cut.transpose(Image.FLIP_LEFT_RIGHT)
        target_h = 225
        target_w = int(d_cut.width * target_h / d_cut.height)
        d_img = d_cut.resize((target_w, target_h), Image.Resampling.LANCZOS)
        bg.paste(d_img, (400, 62), d_img)
        
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
    cx, cy = int(w * 0.48), int(h * 0.52)
    aura = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    aura_draw = ImageDraw.Draw(aura)
    for rad in range(140, 20, -6):
        alpha = int(45 * (1.0 - rad / 140.0))
        aura_draw.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=(255, 215, 60, alpha))
    for rad in range(65, 10, -5):
        alpha = int(80 * (1.0 - rad / 65.0))
        aura_draw.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=(70, 180, 255, alpha))
    bg = Image.alpha_composite(bg, aura)
    draw = ImageDraw.Draw(bg)
    
    # Sunburst rays of Cossack blessing
    for deg in range(0, 360, 24):
        rad = math.radians(deg)
        x2 = cx + int(math.cos(rad) * 170)
        y2 = cy + int(math.sin(rad) * 170)
        draw.line([(cx, cy), (x2, y2)], fill=(255, 235, 120, 50), width=2)
        
    # Mentor on left raising hand in blessing
    m_cut = get_mentor_cutout()
    if m_cut:
        target_h = 225
        target_w = int(m_cut.width * target_h / m_cut.height)
        m_img = m_cut.resize((target_w, target_h), Image.Resampling.LANCZOS)
        bg.paste(m_img, (35, 68), m_img)
        
    # 15yo Djura in center/right taking the solemn oath
    d_cut = get_djura_15yo_cutout()
    if d_cut:
        target_h = 230
        target_w = int(d_cut.width * target_h / d_cut.height)
        d_img = d_cut.resize((target_w, target_h), Image.Resampling.LANCZOS)
        bg.paste(d_img, (230, 60), d_img)
        
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
    bg = Image.new("RGBA", (w, h), (16, 20, 32, 255))
    draw = ImageDraw.Draw(bg)
    
    # Fortress wall background grid texture
    for y in range(0, h, 20):
        draw.line([(0, y), (w, y)], fill=(24, 30, 48, 180), width=1)
    for x in range(0, w, 40):
        draw.line([(x, 0), (x, h)], fill=(24, 30, 48, 180), width=1)
        
    # Top Mission Banner
    draw.rectangle([20, 12, w - 20, 46], fill=(22, 28, 48, 230), outline=(220, 180, 60, 255), width=2)
    
    # 1. Mission Object: Mine / Bomb with sparking fuse on left
    bx, by = 95, 115
    for rad in range(48, 10, -4):
        draw.ellipse([bx - rad, by - rad, bx + rad, by + rad], fill=(240, 60, 30, int(35 * (1.0 - rad/48.0))))
    draw.ellipse([bx - 32, by - 32, bx + 32, by + 32], fill=(28, 28, 36, 255), outline=(220, 180, 60, 255), width=2)
    draw.ellipse([bx - 18, by - 22, bx - 6, by - 12], fill=(70, 75, 90, 255))
    draw.rectangle([bx - 7, by - 40, bx + 7, by - 30], fill=(80, 85, 95, 255), outline=(220, 180, 60, 255), width=1)
    fuse_pts = [(bx, by - 40), (bx + 4, by - 46), (bx + 10, by - 44)]
    draw.line(fuse_pts, fill=(180, 140, 80, 255), width=3)
    draw.ellipse([bx + 8, by - 47, bx + 14, by - 41], fill=(255, 100, 20, 255))
    draw.ellipse([bx + 9, by - 46, bx + 13, by - 42], fill=(255, 240, 80, 255))
    for angle in range(0, 360, 45):
        ra = math.radians(angle)
        draw.line([(bx + 11, by - 44), (bx + 11 + math.cos(ra)*9, by - 44 + math.sin(ra)*9)], fill=(255, 220, 60, 255), width=1)
        
    draw.rectangle([bx - 45, by + 36, bx + 45, by + 52], fill=(20, 24, 36, 220), outline=(220, 180, 60, 255), width=1)
    
    # 2. Enemy Queue: Escalation arrows and characters
    vohnyk_path = "/home/mfedchyk/Godot/djura-1/reports/sketches/vognyk/vohnyk_concept_meshy.jpg"
    if os.path.exists(vohnyk_path):
        v_img = Image.open(vohnyk_path).convert("RGBA")
        v_img = v_img.resize((100, 100), Image.Resampling.LANCZOS)
        mask = Image.new("L", (100, 100), 0)
        ImageDraw.Draw(mask).ellipse([2, 2, 98, 98], fill=255)
        bg.paste(v_img, (200, 65), mask)
        draw.ellipse([198, 63, 302, 167], outline=(255, 120, 20, 255), width=3)
        draw.rectangle([190, 172, 310, 192], fill=(25, 15, 10, 230), outline=(255, 120, 20, 255), width=1)
        
    draw.line([(318, 115), (348, 115)], fill=(255, 215, 60, 255), width=3)
    draw.polygon([(348, 108), (358, 115), (348, 122)], fill=(255, 215, 60, 255))
    
    chort_path = "/home/mfedchyk/Godot/djura-1/reports/sketches/chort/chort_concept_meshy.jpg"
    if os.path.exists(chort_path):
        c_img = Image.open(chort_path).convert("RGBA")
        c_img = c_img.resize((100, 100), Image.Resampling.LANCZOS)
        mask = Image.new("L", (100, 100), 0)
        ImageDraw.Draw(mask).ellipse([2, 2, 98, 98], fill=255)
        bg.paste(c_img, (365, 65), mask)
        draw.ellipse([363, 63, 467, 167], outline=(180, 50, 220, 255), width=3)
        draw.rectangle([355, 172, 475, 192], fill=(20, 10, 25, 230), outline=(180, 50, 220, 255), width=1)
        
    draw.line([(475, 115), (505, 115)], fill=(255, 215, 60, 255), width=3)
    draw.polygon([(505, 108), (515, 115), (505, 122)], fill=(255, 215, 60, 255))
    
    vidma_path = "/home/mfedchyk/Godot/djura-1/assets/sprites/vidma_calm.png"
    if os.path.exists(vidma_path):
        vi_img = Image.open(vidma_path).convert("RGBA")
        vi_img = vi_img.resize((75, 95), Image.Resampling.LANCZOS)
        bg.paste(vi_img, (520, 68), vi_img)
        draw.ellipse([515, 63, 595, 167], outline=(220, 40, 60, 255), width=3)
        draw.rectangle([510, 172, 595, 192], fill=(30, 10, 15, 230), outline=(220, 40, 60, 255), width=1)
        
    draw.rectangle([0, 0, w - 1, h - 1], outline=(220, 180, 60, 255), width=3)
    draw.rectangle([3, 3, w - 4, h - 4], outline=(60, 45, 20, 200), width=1)
    
    out_path = "/home/mfedchyk/Godot/djura-1/assets/sprites/story/slide_level1_3_mission.png"
    bg.save(out_path)
    print(f"Saved Slide 3 to {out_path}")

if __name__ == "__main__":
    create_slide_1_meeting()
    create_slide_2_pledge()
    create_slide_3_mission()
