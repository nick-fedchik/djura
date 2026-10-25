#!/usr/bin/env python3
"""
Generates multi-view concept reference sheets for Meshy AI (Image-to-3D / Reference Studio)
for Level 1 and 2 NPCs:
- Qirimli Yigit (14-15 yo archer & falconer)
- Hutsul Legin (14-15 yo mountain fighter with bartka)
- Vohnyk (Sich jumping fire spirit)
- Chortik (Mischievous folk imp)
"""

import os
from PIL import Image, ImageDraw, ImageFont

OUT_DIR = "/home/mfedchyk/Godot/djura-1/reports/sketches"
SPRITES_DIR = "/home/mfedchyk/Godot/djura-1/assets/sprites"
os.makedirs(OUT_DIR, exist_ok=True)

def create_character_sheet(char_id, title, age_role, prompt_summary, palette_colors, sprite_calm, sprite_alt):
    # 1024 x 640 reference studio sheet
    img = Image.new("RGBA", (1024, 640), (235, 238, 242, 255))
    draw = ImageDraw.Draw(img)

    # Header banner
    draw.rectangle([0, 0, 1024, 80], fill=(30, 41, 59, 255))
    draw.text((32, 16), title, fill=(251, 191, 36, 255))
    draw.text((32, 46), age_role, fill=(203, 213, 225, 255))

    # Color palette swatches
    draw.text((680, 24), "COLOR PALETTE (PBR):", fill=(148, 163, 184, 255))
    for i, col in enumerate(palette_colors):
        x = 680 + i * 44
        draw.rectangle([x, 46, x + 34, 70], fill=col, outline=(15, 23, 42, 255), width=2)

    # 2 Character views (Calm & Alt/Action)
    path_calm = os.path.join(SPRITES_DIR, sprite_calm)
    path_alt = os.path.join(SPRITES_DIR, sprite_alt)

    # Left frame: Calm Stance
    draw.rectangle([32, 100, 360, 520], fill=(255, 255, 255, 255), outline=(203, 213, 225, 255), width=2)
    draw.text((48, 110), "FRONT / A-POSE STANCE", fill=(71, 85, 105, 255))
    if os.path.isfile(path_calm):
        c_img = Image.open(path_calm).convert("RGBA")
        c_img.thumbnail((300, 360), Image.Resampling.LANCZOS)
        offset_x = 32 + (328 - c_img.width) // 2
        offset_y = 100 + (420 - c_img.height) // 2 + 10
        img.paste(c_img, (offset_x, offset_y), c_img)

    # Middle frame: Dynamic Action / 3/4
    draw.rectangle([380, 100, 708, 520], fill=(255, 255, 255, 255), outline=(203, 213, 225, 255), width=2)
    draw.text((396, 110), "3/4 ACTION & SILHOUETTE", fill=(71, 85, 105, 255))
    if os.path.isfile(path_alt):
        a_img = Image.open(path_alt).convert("RGBA")
        a_img.thumbnail((300, 360), Image.Resampling.LANCZOS)
        offset_x = 380 + (328 - a_img.width) // 2
        offset_y = 100 + (420 - a_img.height) // 2 + 10
        img.paste(a_img, (offset_x, offset_y), a_img)

    # Right side: Meshy AI Generation Brief
    draw.rectangle([728, 100, 992, 520], fill=(241, 245, 249, 255), outline=(203, 213, 225, 255), width=2)
    draw.text((740, 112), "MESHY.AI GENERATION SPECS", fill=(15, 23, 42, 255))
    y = 145
    for line in prompt_summary:
        draw.text((740, y), line, fill=(51, 65, 85, 255))
        y += 24

    # Footer note
    draw.rectangle([0, 540, 1024, 640], fill=(248, 250, 252, 255))
    draw.text((32, 555), "Invariant I-3 (Zero-Horror): Comedic folklore styling. Ground contact Z=0 (no clipping).", fill=(100, 116, 139, 255))
    draw.text((32, 580), "Ready for Meshy.ai: upload as 2D Image-to-3D reference or copy Text-to-3D prompt from docs/MESHY_3D_TURNAROUND_PROMPTS.md", fill=(100, 116, 139, 255))

    out_file = os.path.join(OUT_DIR, f"{char_id}_meshy_ref.png")
    img.save(out_file, "PNG")
    print(f"Created concept sheet: {out_file}")
    return out_file

def main():
    # 1. Qirimli Yigit
    create_character_sheet(
        char_id="qirimli",
        title="QIRIMLI YIGIT (КРИМЛИ-ПОБРАТИМ)",
        age_role="14–15 YEARS OLD (DJURA'S PEER) | ARCHER & FALCONER",
        prompt_summary=[
            "• Age: 14-15 yo teenager",
            "• Hat: Karakul fur börk",
            "• Crest: Golden Tarak-Tamga",
            "• Coat: Turquoise-blue silk",
            "• Weapon: Steppe recurve bow",
            "• Ally: Alert steppe falcon",
            "• Clean-shaven (no beard)",
            "• Stylized cartoon PBR",
            "• Symmetrical standing A-pose"
        ],
        palette_colors=[
            (14, 116, 144),  # Turquoise silk
            (30, 41, 59),    # Dark navy wool
            (251, 191, 36),  # Golden crest
            (180, 83, 9),    # Warm leather
            (248, 250, 252), # Linen feather
            (217, 119, 6)    # Honey falcon
        ],
        sprite_calm="qirimli_calm.png",
        sprite_alt="qirimli_alt.png"
    )

    # 2. Hutsul Legin
    create_character_sheet(
        char_id="hutsul",
        title="HUTSUL LEGIN (ГУЦУЛИК-ЛЕГІНЬ)",
        age_role="14–15 YEARS OLD (DJURA'S PEER) | CARPATHIAN FIGHTER",
        prompt_summary=[
            "• Age: 14-15 yo teenager",
            "• Hat: Black felt krysanya",
            "• Decor: Red cord & peacock feather",
            "• Vest: Embroidered shearling keptar",
            "• Pants: Vibrant red hachi",
            "• Weapon: Brass bartka axe",
            "• Clean-shaven (no beard)",
            "• Stylized cartoon PBR",
            "• Symmetrical standing A-pose"
        ],
        palette_colors=[
            (220, 38, 38),   # Scarlet wool
            (255, 255, 255), # White sheepskin
            (20, 20, 20),    # Black felt
            (217, 119, 6),   # Polished brass
            (13, 148, 136),  # Teal peacock feather
            (180, 83, 9)     # Leather cheres belt
        ],
        sprite_calm="hutsul_calm.png",
        sprite_alt="hutsul_alt.png"
    )

    # 3. Vohnyk
    create_character_sheet(
        char_id="vohnyk",
        title="VOHNYK-STRYBYNETS (ВОГНИК)",
        age_role="LEVEL 1 SPIRIT | JUMPING SICH FLAME ELEMENTAL",
        prompt_summary=[
            "• Cute flame mascot creature",
            "• Size: 0.45x Djura's height",
            "• Glowing golden-yellow core",
            "• Warm scarlet-orange wisps",
            "• Big cartoon amber eyes",
            "• Cheeky cartoon grin",
            "• Dynamic flying embers",
            "• Zero-horror (Ghibli/Pixar)",
            "• Emissive stylized PBR"
        ],
        palette_colors=[
            (254, 240, 138), # Core white-yellow
            (245, 158, 11),  # Amber flame
            (239, 68, 68),   # Scarlet flame tip
            (185, 28, 28),   # Deep ruby ember
            (40, 20, 10),    # Charcoal pupils
            (252, 211, 77)   # Sparks
        ],
        sprite_calm="vognyk_calm.png",
        sprite_alt="vognyk_alt.png"
    )

    # 4. Chortik
    create_character_sheet(
        char_id="chort",
        title="CHORTIK-BESKETNYK (ЧОРТИК)",
        age_role="LEVEL 1-2 COMEDIC VILLAIN | MISCHIEVOUS STEPPE IMP",
        prompt_summary=[
            "• Small charcoal-grey furry imp",
            "• Nikolai Gogol comic comedy",
            "• Cute curved reddish horns",
            "• Round pink piggy snout",
            "• Big yellow cartoon eyes",
            "• Sticking-out funny tongue",
            "• Tiny cloven hooves",
            "• Flexible curly tail",
            "• Zero-horror policy"
        ],
        palette_colors=[
            (30, 30, 35),    # Charcoal fur
            (244, 114, 182), # Pink snout
            (185, 28, 28),   # Curved red horns
            (250, 204, 21),  # Yellow cartoon eyes
            (80, 50, 40),    # Cloven hooves
            (225, 29, 72)    # Pink tongue
        ],
        sprite_calm="chort_calm.png",
        sprite_alt="chort_alt.png"
    )

if __name__ == "__main__":
    main()
