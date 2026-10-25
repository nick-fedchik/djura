#!/usr/bin/env python3
"""
Generates high-resolution cinematic story cards for Stage 1 Level 1
using authentic 2D concept art of the 15-year-old Djura and Mentor Kharakternyk.
All portraits are rendered as crisp, uncorrupted, gold-framed badges.
"""

import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np

FONT_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

def get_font(size):
    if os.path.exists(FONT_PATH):
        return ImageFont.truetype(FONT_PATH, size)
    return ImageFont.load_default()

def create_gold_badge(src_img, target_w, target_h, radius=24, flip_h=False):
    """Creates a pristine, anti-aliased badge with double gold border."""
    if flip_h:
        src_img = src_img.transpose(Image.FLIP_LEFT_RIGHT)
        
    resized = src_img.resize((target_w, target_h), Image.Resampling.LANCZOS)
    badge = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
    mask = Image.new("L", (target_w, target_h), 0)
    
    # Smooth rounded mask
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, target_w - 1, target_h - 1], radius=radius, fill=255)
    badge.paste(resized, (0, 0), mask)
    
    # Gold decorative border
    b_draw = ImageDraw.Draw(badge)
    b_draw.rounded_rectangle([0, 0, target_w - 1, target_h - 1], radius=radius, outline=(235, 195, 65, 255), width=3)
    b_draw.rounded_rectangle([3, 3, target_w - 4, target_h - 4], radius=radius - 2, outline=(65, 45, 18, 220), width=1)
    return badge

def get_mentor_badge(target_w=175, target_h=215):
    p_port = "/home/mfedchyk/Godot/djura-1/assets/sprites/mentor_portrait.png"
    if os.path.exists(p_port):
        im = Image.open(p_port).convert("RGBA")
        crop = im.crop((15, 15, 497, 505))
        return create_gold_badge(crop, target_w, target_h, radius=22)
    # Fallback
    fallback = Image.new("RGBA", (target_w, target_h), (35, 45, 75, 255))
    return create_gold_badge(fallback, target_w, target_h, radius=22)

def get_djura_badge(target_w=175, target_h=215, flip_h=False):
    p_src = "/home/mfedchyk/Godot/djura-1/assets/sprites/djura_v2_02_threequarter_l.png"
    if not os.path.exists(p_src):
        p_src = "/home/mfedchyk/Godot/djura-1/reports/sketches/djura_15yo/djura_02_threequarter_l.png"
    if os.path.exists(p_src):
        im = Image.open(p_src).convert("RGBA")
        # Bust crop: head to belt (vyshyvanka with red embroidery, face, chub, sash)
        crop = im.crop((20, 25, 540, 680))
        return create_gold_badge(crop, target_w, target_h, radius=22, flip_h=flip_h)
    fallback = Image.new("RGBA", (target_w, target_h), (25, 55, 95, 255))
    return create_gold_badge(fallback, target_w, target_h, radius=22, flip_h=flip_h)

def draw_nameplate(draw, text, x_center, y_bottom, font_size=11, bg_color=(18, 22, 38, 235), border_color=(235, 195, 65, 255)):
    font = get_font(font_size)
    bbox = font.getbbox(text)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    pad_x, pad_y = 10, 4
    x1 = x_center - text_w // 2 - pad_x
    y1 = y_bottom - text_h - pad_y * 2
    x2 = x_center + text_w // 2 + pad_x
    y2 = y_bottom
    draw.rounded_rectangle([x1, y1, x2, y2], radius=6, fill=bg_color, outline=border_color, width=1)
    draw.text((x_center - text_w // 2, y1 + pad_y - 1), text, fill=(255, 245, 220, 255), font=font)

def create_slide_1_meeting():
    w, h = 600, 300
    bg = Image.new("RGBA", (w, h), (12, 16, 30, 255))
    draw = ImageDraw.Draw(bg)
    
    # Deep nocturnal sky gradient
    for y in range(h):
        ratio = y / float(h)
        r = int(10 + ratio * 16)
        g = int(14 + ratio * 20)
        b = int(28 + ratio * 32)
        draw.line([(0, y), (w, y)], fill=(r, g, b, 255))
        
    # Twinkling stars
    np.random.seed(42)
    for _ in range(45):
        sx = np.random.randint(0, w)
        sy = np.random.randint(0, int(h * 0.65))
        sr = np.random.uniform(1.0, 2.2)
        alpha = np.random.randint(140, 255)
        draw.ellipse([sx - sr, sy - sr, sx + sr, sy + sr], fill=(255, 245, 210, alpha))
        
    # Silhouette of the Ancient Sich Oak on the left background
    oak_pts = [(0, h), (35, 210), (55, 150), (25, 100), (80, 75), (130, 110), (110, 170), (75, 230), (85, h)]
    draw.polygon(oak_pts, fill=(8, 12, 20, 255))
    
    # Dnipro river horizon
    river_pts = [(0, int(h * 0.76)), (w, int(h * 0.74)), (w, h), (0, h)]
    draw.polygon(river_pts, fill=(16, 24, 44, 255))
    
    # Golden Sich Campfire in center
    cx, cy = int(w * 0.5), int(h * 0.70)
    glow_overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_overlay)
    for rad in range(120, 10, -5):
        alpha = int(45 * (1.0 - rad / 120.0))
        glow_draw.ellipse([cx - rad, cy - rad + 15, cx + rad, cy + rad + 15], fill=(255, 140, 30, alpha))
    for rad in range(50, 5, -5):
        alpha = int(95 * (1.0 - rad / 50.0))
        glow_draw.ellipse([cx - rad, cy - rad + 15, cx + rad, cy + rad + 15], fill=(255, 220, 70, alpha))
    bg = Image.alpha_composite(bg, glow_overlay)
    draw = ImageDraw.Draw(bg)
    
    # Campfire logs & flames
    draw.line([(cx - 22, cy + 26), (cx + 22, cy + 18)], fill=(65, 35, 18, 255), width=6)
    draw.line([(cx + 20, cy + 26), (cx - 20, cy + 18)], fill=(75, 42, 22, 255), width=6)
    flame_pts = [(cx - 15, cy + 20), (cx, cy - 16), (cx + 15, cy + 20)]
    draw.polygon(flame_pts, fill=(255, 150, 20, 255))
    inner_flame = [(cx - 8, cy + 20), (cx, cy - 8), (cx + 8, cy + 20)]
    draw.polygon(inner_flame, fill=(255, 230, 80, 255))

    # Sparks
    for _ in range(18):
        sp_x = cx + np.random.randint(-35, 35)
        sp_y = cy - np.random.randint(5, 95)
        draw.ellipse([sp_x - 1.5, sp_y - 1.5, sp_x + 1.5, sp_y + 1.5], fill=(255, 210, 60, 230))
        
    # Mentor Cossack Badge (Left side)
    m_badge = get_mentor_badge(175, 215)
    bg.paste(m_badge, (24, 48), m_badge)
    draw_nameplate(draw, "КОЗАК-ХАРАКТЕРНИК", 24 + 175 // 2, 285, font_size=10)
    
    # 15yo Djura Badge (Right side, flipped horizontally to face Mentor & Campfire)
    d_badge = get_djura_badge(175, 215, flip_h=True)
    bg.paste(d_badge, (w - 24 - 175, 48), d_badge)
    draw_nameplate(draw, "ЮНИЙ ДЖУРА (15 РОКІВ)", w - 24 - 175 // 2, 285, font_size=10)
    
    # Top Title Banner
    t_font = get_font(13)
    title_text = "ЗУСТРІЧ З НАСТАВНИКОМ-ХАРАКТЕРНИКОМ"
    t_bbox = t_font.getbbox(title_text)
    t_w = t_bbox[2] - t_bbox[0]
    draw.rounded_rectangle([w // 2 - t_w // 2 - 16, 10, w // 2 + t_w // 2 + 16, 38], radius=8, fill=(18, 22, 38, 235), outline=(235, 195, 65, 255), width=2)
    draw.text((w // 2 - t_w // 2, 16), title_text, fill=(255, 225, 120, 255), font=t_font)
    
    # Outer double gold border
    draw.rectangle([0, 0, w - 1, h - 1], outline=(235, 195, 65, 255), width=3)
    draw.rectangle([3, 3, w - 4, h - 4], outline=(65, 45, 18, 200), width=1)
    
    out_path = "/home/mfedchyk/Godot/djura-1/assets/sprites/story/slide_level1_1_meeting.png"
    bg.save(out_path)
    print(f"Saved Slide 1 to {out_path}")

def create_slide_2_pledge():
    w, h = 600, 300
    bg = Image.new("RGBA", (w, h), (18, 14, 32, 255))
    draw = ImageDraw.Draw(bg)
    
    # Dawn twilight gradient
    for y in range(h):
        ratio = y / float(h)
        r = int(22 + ratio * 32)
        g = int(14 + ratio * 20)
        b = int(36 + ratio * 24)
        draw.line([(0, y), (w, y)], fill=(r, g, b, 255))
        
    # Celestial golden sunburst aura in center (behind Djura)
    cx, cy = int(w * 0.44), int(h * 0.52)
    aura = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    aura_draw = ImageDraw.Draw(aura)
    for rad in range(150, 20, -6):
        alpha = int(48 * (1.0 - rad / 150.0))
        aura_draw.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=(255, 215, 60, alpha))
    for rad in range(70, 10, -5):
        alpha = int(85 * (1.0 - rad / 70.0))
        aura_draw.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=(70, 180, 255, alpha))
    bg = Image.alpha_composite(bg, aura)
    draw = ImageDraw.Draw(bg)
    
    # Sunburst rays of Cossack blessing
    for deg in range(0, 360, 20):
        rad = math.radians(deg)
        x2 = cx + int(math.cos(rad) * 190)
        y2 = cy + int(math.sin(rad) * 190)
        draw.line([(cx, cy), (x2, y2)], fill=(255, 235, 120, 55), width=2)
        
    # Mentor Cossack Badge (Left side)
    m_badge = get_mentor_badge(165, 205)
    bg.paste(m_badge, (20, 52), m_badge)
    draw_nameplate(draw, "БЛАГОСЛОВЕННЯ НАСТАВНИКА", 20 + 165 // 2, 285, font_size=9)
    
    # 15yo Djura Badge (Center, taking the oath)
    d_badge = get_djura_badge(165, 205, flip_h=False)
    bg.paste(d_badge, (198, 52), d_badge)
    draw_nameplate(draw, "КЛЯТВА ДЖУРИ НА СІЧІ", 198 + 165 // 2, 285, font_size=9)
    
    # Floating Cossack Wing-Cape (Kyreya) on the Right
    k_box_x = 380
    k_box_w = 200
    draw.rounded_rectangle([k_box_x, 52, k_box_x + k_box_w, 257], radius=20, fill=(16, 20, 36, 220), outline=(235, 195, 65, 255), width=2)
    
    # Draw ornate winged kyreya with silk folds & gold embroidery
    kcx, kcy = k_box_x + k_box_w // 2, 140
    # Cape silhouette
    cape_pts = [
        (kcx - 55, kcy - 35), (kcx, kcy - 50), (kcx + 55, kcy - 35),
        (kcx + 70, kcy + 25), (kcx + 40, kcy + 55), (kcx, kcy + 38),
        (kcx - 40, kcy + 55), (kcx - 70, kcy + 25)
    ]
    draw.polygon(cape_pts, fill=(24, 75, 180, 240), outline=(255, 215, 60, 255))
    
    # Golden silk sash & embroidered shoulder brooches
    draw.line([(kcx - 45, kcy - 30), (kcx + 45, kcy - 30)], fill=(255, 215, 60, 255), width=5)
    draw.ellipse([kcx - 48, kcy - 33, kcx - 40, kcy - 25], fill=(255, 235, 120, 255))
    draw.ellipse([kcx + 40, kcy - 33, kcx + 48, kcy - 25], fill=(255, 235, 120, 255))
    # Tassels
    for tx in [-25, 0, 25]:
        draw.line([(kcx + tx, kcy + 42), (kcx + tx, kcy + 75)], fill=(255, 215, 60, 255), width=3)
        draw.ellipse([kcx + tx - 3, kcy + 72, kcx + tx + 3, kcy + 78], fill=(220, 60, 40, 255))
        
    draw_nameplate(draw, "КРИЛАТА КИРЕЯ ХАРАКТЕРНИКА", kcx, 285, font_size=9)
    
    # Top Title Banner
    t_font = get_font(13)
    title_text = "ВИБІР СЕРЦЯ: «Я ГОТОВИЙ БУТИ ДЖУРОЮ!»"
    t_bbox = t_font.getbbox(title_text)
    t_w = t_bbox[2] - t_bbox[0]
    draw.rounded_rectangle([w // 2 - t_w // 2 - 16, 10, w // 2 + t_w // 2 + 16, 38], radius=8, fill=(18, 22, 38, 235), outline=(235, 195, 65, 255), width=2)
    draw.text((w // 2 - t_w // 2, 16), title_text, fill=(255, 225, 120, 255), font=t_font)
    
    # Outer double gold border
    draw.rectangle([0, 0, w - 1, h - 1], outline=(235, 195, 65, 255), width=3)
    draw.rectangle([3, 3, w - 4, h - 4], outline=(65, 45, 18, 200), width=1)
    
    out_path = "/home/mfedchyk/Godot/djura-1/assets/sprites/story/slide_level1_2_pledge.png"
    bg.save(out_path)
    print(f"Saved Slide 2 to {out_path}")

def create_slide_3_mission():
    w, h = 600, 300
    bg = Image.new("RGBA", (w, h), (14, 18, 30, 255))
    draw = ImageDraw.Draw(bg)
    
    # Fortress wall background grid texture
    for y in range(0, h, 20):
        draw.line([(0, y), (w, y)], fill=(22, 28, 46, 180), width=1)
    for x in range(0, w, 40):
        draw.line([(x, 0), (x, h)], fill=(22, 28, 46, 180), width=1)
        
    # 1. Mission Object: Powder Bomb Core on left
    bx, by = 85, 150
    # Core glow
    for rad in range(65, 15, -5):
        draw.ellipse([bx - rad, by - rad, bx + rad, by + rad], fill=(240, 60, 30, int(35 * (1.0 - rad / 65.0))))
    draw.ellipse([bx - 38, by - 38, bx + 38, by + 38], fill=(26, 26, 34, 255), outline=(235, 195, 65, 255), width=2)
    draw.ellipse([bx - 22, by - 26, bx - 8, by - 14], fill=(70, 75, 90, 255))
    draw.rectangle([bx - 8, by - 48, bx + 8, by - 36], fill=(80, 85, 95, 255), outline=(235, 195, 65, 255), width=1)
    # Fuse
    fuse_pts = [(bx, by - 48), (bx + 6, by - 56), (bx + 14, by - 52)]
    draw.line(fuse_pts, fill=(180, 140, 80, 255), width=4)
    # Sparking sparkler
    draw.ellipse([bx + 12, by - 56, bx + 20, by - 48], fill=(255, 100, 20, 255))
    draw.ellipse([bx + 13, by - 55, bx + 19, by - 49], fill=(255, 240, 80, 255))
    for angle in range(0, 360, 36):
        ra = math.radians(angle)
        draw.line([(bx + 16, by - 52), (bx + 16 + math.cos(ra) * 11, by - 52 + math.sin(ra) * 11)], fill=(255, 220, 60, 255), width=2)
        
    draw_nameplate(draw, "ПОРОХОВА БОМБА", bx, 230, font_size=9)
    
    # 2. Enemy Escalation Progression (Vohnyk -> Chort -> Vidma)
    # Section Frame for Enemies
    draw.rounded_rectangle([170, 52, 582, 262], radius=16, fill=(16, 20, 34, 230), outline=(235, 195, 65, 255), width=2)
    
    # Enemy 1: Vohnyk (Level 1)
    vohnyk_path = "/home/mfedchyk/Godot/djura-1/reports/sketches/vognyk/vohnyk_concept_meshy.jpg"
    vx, vy = 235, 135
    if os.path.exists(vohnyk_path):
        v_img = Image.open(vohnyk_path).convert("RGBA")
        v_img = v_img.resize((100, 100), Image.Resampling.LANCZOS)
        mask = Image.new("L", (100, 100), 0)
        ImageDraw.Draw(mask).ellipse([2, 2, 98, 98], fill=255)
        bg.paste(v_img, (vx - 50, vy - 50), mask)
    draw.ellipse([vx - 52, vy - 52, vx + 52, vy + 52], outline=(255, 130, 25, 255), width=3)
    draw_nameplate(draw, "1. ВОГНИК (Рівень 1)", vx, vy + 75, font_size=9, border_color=(255, 130, 25, 255))
    
    # Arrow 1 -> 2
    draw.line([(vx + 62, vy), (vx + 98, vy)], fill=(255, 215, 60, 255), width=3)
    draw.polygon([(vx + 98, vy - 7), (vx + 108, vy), (vx + 98, vy + 7)], fill=(255, 215, 60, 255))
    
    # Enemy 2: Chort (Level 3)
    chort_path = "/home/mfedchyk/Godot/djura-1/reports/sketches/chort/chort_concept_meshy.jpg"
    cx, cy = 375, 135
    if os.path.exists(chort_path):
        c_img = Image.open(chort_path).convert("RGBA")
        c_img = c_img.resize((100, 100), Image.Resampling.LANCZOS)
        mask = Image.new("L", (100, 100), 0)
        ImageDraw.Draw(mask).ellipse([2, 2, 98, 98], fill=255)
        bg.paste(c_img, (cx - 50, cy - 50), mask)
    draw.ellipse([cx - 52, cy - 52, cx + 52, cy + 52], outline=(180, 60, 230, 255), width=3)
    draw_nameplate(draw, "2. ЧОРТИК (Рівень 3)", cx, cy + 75, font_size=9, border_color=(180, 60, 230, 255))
    
    # Arrow 2 -> 3
    draw.line([(cx + 62, cy), (cx + 98, cy)], fill=(255, 215, 60, 255), width=3)
    draw.polygon([(cx + 98, cy - 7), (cx + 108, cy), (cx + 98, cy + 7)], fill=(255, 215, 60, 255))
    
    # Enemy 3: Vidma (Level 5)
    vidma_path = "/home/mfedchyk/Godot/djura-1/assets/sprites/vidma_calm.png"
    wix, wiy = 515, 135
    if os.path.exists(vidma_path):
        vi_img = Image.open(vidma_path).convert("RGBA")
        vi_img = vi_img.resize((85, 100), Image.Resampling.LANCZOS)
        bg.paste(vi_img, (wix - 42, wiy - 50), vi_img)
    draw.ellipse([wix - 52, wiy - 52, wix + 52, wiy + 52], outline=(230, 45, 75, 255), width=3)
    draw_nameplate(draw, "3. ВІДЬМА (Рівень 5)", wix, wiy + 75, font_size=9, border_color=(230, 45, 75, 255))
    
    # Top Title Banner
    t_font = get_font(13)
    title_text = "НАКАЗ НАСТАВНИКА: БОМБИ ТА ЧЕРГА НЕЧИСТІ"
    t_bbox = t_font.getbbox(title_text)
    t_w = t_bbox[2] - t_bbox[0]
    draw.rounded_rectangle([w // 2 - t_w // 2 - 16, 10, w // 2 + t_w // 2 + 16, 38], radius=8, fill=(18, 22, 38, 235), outline=(235, 195, 65, 255), width=2)
    draw.text((w // 2 - t_w // 2, 16), title_text, fill=(255, 225, 120, 255), font=t_font)
    
    # Outer double gold border
    draw.rectangle([0, 0, w - 1, h - 1], outline=(235, 195, 65, 255), width=3)
    draw.rectangle([3, 3, w - 4, h - 4], outline=(65, 45, 18, 200), width=1)
    
    out_path = "/home/mfedchyk/Godot/djura-1/assets/sprites/story/slide_level1_3_mission.png"
    bg.save(out_path)
    print(f"Saved Slide 3 to {out_path}")

if __name__ == "__main__":
    create_slide_1_meeting()
    create_slide_2_pledge()
    create_slide_3_mission()
