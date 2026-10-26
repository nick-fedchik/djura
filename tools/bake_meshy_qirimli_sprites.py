#!/usr/bin/env python3
"""
Bakes high-resolution 2D sprites and portraits from assets/models/qirimli.glb.
Generates:
- assets/sprites/qirimli_portrait.png (for story cards & dialogs)
- assets/sprites/qirimli_sheet.png & qirimli_frames.tres (for in-game QirimliAlly)
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
glb_path = os.path.join(_PROJECT_ROOT, "sources", "models", "qirimli.glb")
bpy.ops.import_scene.gltf(filepath=glb_path)

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = 256
scene.render.resolution_y = 256
scene.render.film_transparent = True
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'

world = bpy.data.worlds.new("StageWorld")
scene.world = world

m = bpy.data.objects.get("Mesh_0")
if not m:
    raise RuntimeError("Mesh_0 not found in qirimli.glb")

coords = [v.co for v in m.data.vertices]
min_z = min(c.z for c in coords)
max_z = max(c.z for c in coords)
height = max_z - min_z
shift_z = -min_z
m.location.z += shift_z

# Camera setup
cam_data = bpy.data.cameras.new(name="SpriteCam")
cam_data.type = "ORTHO"
cam_data.ortho_scale = height * 1.12
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

tmp_dir = os.path.join(_PROJECT_ROOT, "build", "render_tmp", "qirimli_meshy")
os.makedirs(tmp_dir, exist_ok=True)

# 1. Render close-up Portrait for story cards
cam_data.ortho_scale = 0.85
cam.location = (0, -2.5, height * 0.78)
portrait_path = os.path.join(_PROJECT_ROOT, "assets", "sprites", "qirimli_portrait.png")
scene.render.filepath = portrait_path
bpy.ops.render.render(write_still=True)
print("Rendered Qirimli portrait:", portrait_path)

# 2. Reset Camera to full body for gameplay animations
cam_data.ortho_scale = height * 1.12
cam.location = (0, -3.5, height * 0.5)

anims = {
    "idle": [
        {"yaw": 15, "pitch": 0, "roll": 0, "scale_y": 1.00, "z_off": 0.00},
        {"yaw": 18, "pitch": 0, "roll": 0, "scale_y": 1.02, "z_off": 0.01},
        {"yaw": 20, "pitch": 0, "roll": 0, "scale_y": 1.03, "z_off": 0.02},
        {"yaw": 18, "pitch": 0, "roll": 0, "scale_y": 1.01, "z_off": 0.01},
    ],
    "shoot": [
        {"yaw": 25, "pitch": 2, "roll": -2, "scale_y": 0.98, "z_off": -0.01},
        {"yaw": 35, "pitch": 4, "roll": -4, "scale_y": 1.02, "z_off": 0.02},
        {"yaw": 32, "pitch": 3, "roll": -3, "scale_y": 1.01, "z_off": 0.01},
        {"yaw": 20, "pitch": 0, "roll": 0, "scale_y": 1.00, "z_off": 0.00},
    ],
    "victory": [
        {"yaw": 0, "pitch": -4, "roll": 0, "scale_y": 1.02, "z_off": 0.02},
        {"yaw": -8, "pitch": -8, "roll": -2, "scale_y": 1.04, "z_off": 0.04},
        {"yaw": 0, "pitch": -10, "roll": 0, "scale_y": 1.05, "z_off": 0.05},
        {"yaw": 8, "pitch": -8, "roll": 2, "scale_y": 1.04, "z_off": 0.04},
    ]
}

for anim_name, frames in anims.items():
    anim_dir = os.path.join(tmp_dir, anim_name)
    os.makedirs(anim_dir, exist_ok=True)
    for idx, f in enumerate(frames):
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
        print(f"Rendered Qirimli {anim_name} [{idx}] -> {out_file}")

print("Blender Qirimli rendering complete!")
"""
    cmd = ["blender", "-b", "--python-expr", blend_script]
    subprocess.check_call(cmd)

def pack_sheet():
    sys.path.insert(0, os.path.join(_PROJECT_ROOT, "tools", "blender"))
    import pack_spritesheet

    tmp_dir = os.path.join(_PROJECT_ROOT, "build", "render_tmp", "qirimli_meshy")
    frames_by_anim = {}
    for anim_dir in sorted(os.listdir(tmp_dir)):
        full_path = os.path.join(tmp_dir, anim_dir)
        if os.path.isdir(full_path):
            frames = sorted(glob.glob(os.path.join(full_path, "*.png")))
            if frames:
                frames_by_anim[anim_dir] = frames

    output_png = os.path.join(_PROJECT_ROOT, "assets", "sprites", "qirimli_sheet.png")
    output_tres = os.path.join(_PROJECT_ROOT, "assets", "sprites", "qirimli_frames.tres")
    output_json = os.path.join(_PROJECT_ROOT, "assets", "sprites", "qirimli_manifest.json")

    print("Packing Qirimli frames into:", output_png)
    pack_spritesheet.pack_spritesheet(
        frames_by_anim=frames_by_anim,
        output_png=output_png,
        output_tres=output_tres,
        output_json=output_json,
        frame_width=256,
        frame_height=256,
        fps=12
    )
    print("Qirimli sprite sheet packed successfully!")

if __name__ == "__main__":
    run_blender_render()
    pack_sheet()
