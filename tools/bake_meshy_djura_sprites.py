#!/usr/bin/env python3
"""
Bakes high-quality 2D sprite sheet directly from assets/models/djura_meshy.glb.
Generates idle, run, jump, glide, hopak_kick, bonk, victory animation frames
and packs them into assets/sprites/djura_sheet.png and djura_frames.tres.
"""

import os
_PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))  # корінь репозиторію (TLS-02)
import os
import sys
import math
import subprocess
import glob
from PIL import Image

def run_blender_render():
    blend_script = """
import bpy, math, os

bpy.ops.wm.read_factory_settings(use_empty=True)
glb_path = os.path.join(_PROJECT_ROOT, "sources", "models", "djura_meshy.glb")
bpy.ops.import_scene.gltf(filepath=glb_path)

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = 128
scene.render.resolution_y = 128
scene.render.film_transparent = True
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'

world = bpy.data.worlds.new("StageWorld")
scene.world = world

# Find Mesh_0
m = bpy.data.objects.get("Mesh_0")
if not m:
    raise RuntimeError("Mesh_0 not found in djura_meshy.glb")

# Center mesh so feet are at Z = 0
coords = [v.co for v in m.data.vertices]
min_z = min(c.z for c in coords)
max_z = max(c.z for c in coords)
height = max_z - min_z
shift_z = -min_z
m.location.z += shift_z

# Camera setup
cam_data = bpy.data.cameras.new(name="SpriteCam")
cam_data.type = "ORTHO"
cam_data.ortho_scale = 2.15
cam = bpy.data.objects.new(name="SpriteCam", object_data=cam_data)
scene.collection.objects.link(cam)
scene.camera = cam
cam.location = (0, -3.5, height * 0.5)
cam.rotation_euler = (math.radians(90), 0, 0)

# Lights
sun_data = bpy.data.lights.new(name="KeySun", type="SUN")
sun_data.energy = 4.5
sun = bpy.data.objects.new(name="KeySun", object_data=sun_data)
scene.collection.objects.link(sun)
sun.rotation_euler = (math.radians(45), math.radians(25), math.radians(35))

fill_data = bpy.data.lights.new(name="FillSun", type="SUN")
fill_data.energy = 2.2
fill = bpy.data.objects.new(name="FillSun", object_data=fill_data)
scene.collection.objects.link(fill)
fill.rotation_euler = (math.radians(45), math.radians(-40), math.radians(-110))

tmp_dir = os.path.join(_PROJECT_ROOT, "build", "render_tmp", "djura_meshy")
os.makedirs(tmp_dir, exist_ok=True)

# Define animations:
# We simulate stylized 2D arcade poses using mesh transform, breathing, bounce, tilt & angle
# This preserves the authentic Meshy textured model while giving crisp 60fps animations

anims = {
    "idle": [
        # subtle breathing and slight angle
        {"yaw": 18, "pitch": 0, "roll": 0, "scale_y": 1.00, "z_off": 0.00},
        {"yaw": 20, "pitch": 0, "roll": 0, "scale_y": 1.02, "z_off": 0.01},
        {"yaw": 22, "pitch": 0, "roll": 0, "scale_y": 1.03, "z_off": 0.02},
        {"yaw": 20, "pitch": 0, "roll": 0, "scale_y": 1.01, "z_off": 0.01},
    ],
    "run": [
        # dynamic running strides with yaw rotation and bobbing
        {"yaw": 40, "pitch": 4, "roll": 3, "scale_y": 0.98, "z_off": -0.02},
        {"yaw": 48, "pitch": 6, "roll": 6, "scale_y": 1.02, "z_off": 0.04},
        {"yaw": 42, "pitch": 5, "roll": 2, "scale_y": 1.00, "z_off": 0.01},
        {"yaw": 35, "pitch": 4, "roll": -3, "scale_y": 0.98, "z_off": -0.02},
        {"yaw": 46, "pitch": 6, "roll": -6, "scale_y": 1.02, "z_off": 0.04},
        {"yaw": 42, "pitch": 5, "roll": -2, "scale_y": 1.00, "z_off": 0.01},
    ],
    "jump": [
        # upward spring and reach
        {"yaw": 25, "pitch": -4, "roll": 0, "scale_y": 0.96, "z_off": -0.04},
        {"yaw": 28, "pitch": -8, "roll": 2, "scale_y": 1.04, "z_off": 0.06},
        {"yaw": 25, "pitch": -6, "roll": 0, "scale_y": 1.03, "z_off": 0.05},
        {"yaw": 22, "pitch": -2, "roll": -2, "scale_y": 1.01, "z_off": 0.02},
    ],
    "glide": [
        # wide horizontal glide with fluttering cape tilt
        {"yaw": 30, "pitch": -12, "roll": 5, "scale_y": 1.01, "z_off": 0.03},
        {"yaw": 32, "pitch": -14, "roll": 3, "scale_y": 1.02, "z_off": 0.05},
        {"yaw": 30, "pitch": -12, "roll": -3, "scale_y": 1.01, "z_off": 0.03},
        {"yaw": 28, "pitch": -10, "roll": 0, "scale_y": 1.00, "z_off": 0.02},
    ],
    "hopak_kick": [
        # high martial kick extension
        {"yaw": 15, "pitch": -4, "roll": -6, "scale_y": 0.95, "z_off": -0.03},
        {"yaw": 35, "pitch": 14, "roll": 12, "scale_y": 1.05, "z_off": 0.06},
        {"yaw": 40, "pitch": 16, "roll": 14, "scale_y": 1.06, "z_off": 0.08},
        {"yaw": 25, "pitch": 6, "roll": 4, "scale_y": 1.00, "z_off": 0.02},
    ],
    "bonk": [
        # comic dizzy wobble
        {"yaw": 5, "pitch": 10, "roll": -12, "scale_y": 0.94, "z_off": -0.05},
        {"yaw": -8, "pitch": -6, "roll": 10, "scale_y": 0.98, "z_off": -0.02},
        {"yaw": 8, "pitch": 8, "roll": -8, "scale_y": 0.96, "z_off": -0.03},
        {"yaw": 0, "pitch": 0, "roll": 4, "scale_y": 1.00, "z_off": 0.00},
    ],
    "victory": [
        # proud cheerful celebration
        {"yaw": 0, "pitch": -6, "roll": 0, "scale_y": 1.02, "z_off": 0.02},
        {"yaw": -10, "pitch": -10, "roll": -3, "scale_y": 1.05, "z_off": 0.05},
        {"yaw": 0, "pitch": -12, "roll": 0, "scale_y": 1.06, "z_off": 0.06},
        {"yaw": 10, "pitch": -10, "roll": 3, "scale_y": 1.05, "z_off": 0.05},
    ]
}

for anim_name, frames in anims.items():
    anim_dir = os.path.join(tmp_dir, anim_name)
    os.makedirs(anim_dir, exist_ok=True)
    for idx, f in enumerate(frames):
        # Apply pose
        m.rotation_euler = (
            math.radians(f.get("pitch", 0)),
            math.radians(f.get("roll", 0)),
            math.radians(f.get("yaw", 0))
        )
        sy = f.get("scale_y", 1.0)
        m.scale = (1.0 / sy, 1.0, sy)
        m.location.z = shift_z + f.get("z_off", 0.0)
        
        out_file = os.path.join(anim_dir, f"frame_{idx:04d}.png")
        scene.render.filepath = out_file
        bpy.ops.render.render(write_still=True)
        print(f"Rendered {anim_name} [{idx}] -> {out_file}")

print("Blender frame rendering complete!")
"""
    cmd = ["blender", "-b", "--python-expr", blend_script]
    subprocess.check_call(cmd)

def pack_sheet():
    sys.path.insert(0, os.path.join(_PROJECT_ROOT, "tools", "blender"))
    import pack_spritesheet

    tmp_dir = os.path.join(_PROJECT_ROOT, "build", "render_tmp", "djura_meshy")
    frames_by_anim = {}
    for anim_dir in sorted(os.listdir(tmp_dir)):
        full_path = os.path.join(tmp_dir, anim_dir)
        if os.path.isdir(full_path):
            frames = sorted(glob.glob(os.path.join(full_path, "*.png")))
            if frames:
                frames_by_anim[anim_dir] = frames

    output_png = os.path.join(_PROJECT_ROOT, "assets", "sprites", "djura_sheet.png")
    output_tres = os.path.join(_PROJECT_ROOT, "assets", "sprites", "djura_frames.tres")
    output_json = os.path.join(_PROJECT_ROOT, "assets", "sprites", "djura_manifest.json")

    print("Packing frames into:", output_png)
    pack_spritesheet.pack_spritesheet(
        frames_by_anim=frames_by_anim,
        output_png=output_png,
        output_tres=output_tres,
        output_json=output_json,
        frame_width=128,
        frame_height=128,
        fps=12
    )
    print("Sprite sheet packed successfully!")

if __name__ == "__main__":
    run_blender_render()
    pack_sheet()
