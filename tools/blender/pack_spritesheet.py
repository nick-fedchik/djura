"""
Sprite Sheet Packer and Godot 4 SpriteFrames (.tres) Generator.
Follows SWR-003-05 and ADR-003.

Takes rendered frame folders and produces:
1. Packed sprite sheet PNG (<character_name>_sheet.png).
2. Godot 4 SpriteFrames resource (<character_name>_frames.tres).
3. Metadata JSON manifest (<character_name>_manifest.json).
"""

import json
import math
import os
from typing import Dict, List, Tuple
from PIL import Image


def pack_spritesheet(
    frames_by_anim: Dict[str, List[str]],
    output_png: str,
    output_tres: str,
    output_json: str,
    frame_width: int = 128,
    frame_height: int = 128,
    fps: int = 12,
    flip_horizontal: bool = False,
) -> None:
    """
    Packs all animation frames into a single sprite sheet and creates Godot 4 .tres resource.
    """
    # Count total frames and build ordered list
    ordered_frames: List[Tuple[str, int, str]] = []  # (anim_name, frame_idx, file_path)
    for anim_name, frame_files in frames_by_anim.items():
        sorted_files = sorted(frame_files)
        for idx, fpath in enumerate(sorted_files):
            ordered_frames.append((anim_name, idx, fpath))

    total_frames = len(ordered_frames)
    if total_frames == 0:
        raise ValueError("No frames found to pack into sprite sheet.")

    # Calculate optimal grid layout (prefer near-square or power of two width)
    cols = math.ceil(math.sqrt(total_frames))
    rows = math.ceil(total_frames / cols)

    sheet_width = cols * frame_width
    sheet_height = rows * frame_height

    # Create transparent atlas
    sheet_img = Image.new("RGBA", (sheet_width, sheet_height), (0, 0, 0, 0))

    manifest_frames = []
    atlas_regions = []

    for slot_idx, (anim_name, frame_idx, fpath) in enumerate(ordered_frames):
        col = slot_idx % cols
        row = slot_idx // cols
        x = col * frame_width
        y = row * frame_height

        frame_img = Image.open(fpath).convert("RGBA")
        if frame_img.size != (frame_width, frame_height):
            frame_img = frame_img.resize((frame_width, frame_height), Image.Resampling.LANCZOS)
        if flip_horizontal:
            frame_img = frame_img.transpose(Image.FLIP_LEFT_RIGHT)

        sheet_img.paste(frame_img, (x, y))

        manifest_frames.append({
            "animation": anim_name,
            "frame_index": frame_idx,
            "x": x,
            "y": y,
            "w": frame_width,
            "h": frame_height,
        })
        atlas_regions.append((anim_name, x, y, frame_width, frame_height))

    # Save sprite sheet image
    os.makedirs(os.path.dirname(os.path.abspath(output_png)), exist_ok=True)
    sheet_img.save(output_png, format="PNG")
    print(f"Packed sprite sheet saved to: {output_png} ({sheet_width}x{sheet_height}, {total_frames} frames)")

    # Save JSON manifest
    manifest_data = {
        "format": "djura_spritesheet_v1",
        "sheet_width": sheet_width,
        "sheet_height": sheet_height,
        "frame_width": frame_width,
        "frame_height": frame_height,
        "fps": fps,
        "pivot_point": [frame_width / 2.0, float(frame_height)],  # Feet pivot
        "total_frames": total_frames,
        "frames": manifest_frames,
    }
    with open(output_json, "w", encoding="utf-8") as f:
        json.dump(manifest_data, f, indent=2, ensure_ascii=False)
    print(f"Manifest JSON saved to: {output_json}")

    # Generate Godot 4 SpriteFrames .tres resource
    # Godot path relative to project root
    # e.g., res://assets/sprites/<basename>.png
    rel_png_path = os.path.relpath(output_png, "/home/mfedchyk/Godot/djura-1")
    godot_tex_res = f"res://{rel_png_path}"

    generate_godot_spriteframes_tres(
        atlas_regions=atlas_regions,
        godot_tex_res=godot_tex_res,
        output_tres_path=output_tres,
        fps=fps,
    )
    print(f"Godot SpriteFrames resource saved to: {output_tres}")


def generate_godot_spriteframes_tres(
    atlas_regions: List[Tuple[str, int, int, int, int]],
    godot_tex_res: str,
    output_tres_path: str,
    fps: int = 12,
) -> None:
    """
    Generates a native Godot 4 text resource format (.tres) for SpriteFrames
    using sub-resources of type AtlasTexture.
    """
    # Group frames by animation
    anims: Dict[str, List[Tuple[int, int, int, int]]] = {}
    for anim_name, x, y, w, h in atlas_regions:
        if anim_name not in anims:
            anims[anim_name] = []
        anims[anim_name].append((x, y, w, h))

    total_subresources = len(atlas_regions) + 1  # textures + external/parent

    lines = [
        f'[gd_resource type="SpriteFrames" load_steps={total_subresources + 1} format=3]',
        "",
        f'[ext_resource type="Texture2D" path="{godot_tex_res}" id="1_sheet"]',
        "",
    ]

    # Generate AtlasTexture sub-resources
    sub_id = 1
    anim_frame_refs: Dict[str, List[str]] = {name: [] for name in anims}

    for anim_name, region_list in anims.items():
        for x, y, w, h in region_list:
            sub_id += 1
            res_id = f"AtlasTexture_{sub_id}"
            lines.append(f'[sub_resource type="AtlasTexture" id="{res_id}"]')
            lines.append('atlas = ExtResource("1_sheet")')
            lines.append(f'region = Rect2({x}, {y}, {w}, {h})')
            lines.append("")
            anim_frame_refs[anim_name].append(f'SubResource("{res_id}")')

    # Generate animations array in SpriteFrames resource
    lines.append('[resource]')

    anim_entries = []
    for anim_name, refs in anim_frame_refs.items():
        loop_val = 1 if anim_name in ("idle", "run", "glide") else 0
        frames_array = ", ".join([f'{{\n"duration": 1.0,\n"texture": {ref}\n}}' for ref in refs])
        entry = (
            "{\n"
            f'"frames": [{frames_array}],\n'
            f'"loop": {loop_val},\n'
            f'"name": &"{anim_name}",\n'
            f'"speed": {float(fps)}\n'
            "}"
        )
        anim_entries.append(entry)

    lines.append("animations = [" + ",\n".join(anim_entries) + "]")

    with open(output_tres_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
