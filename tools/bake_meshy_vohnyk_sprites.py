#!/usr/bin/env python3
"""
Bakes high-resolution 2D sprites directly from assets/models/vohnyk.glb.
Generates:
- assets/sprites/vohnyk_sheet.png & vohnyk_frames.tres (idle, jump, fizzle)
- assets/sprites/vohnyk_manifest.json
"""

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
glb_path = "/home/mfedchyk/Godot/djura-1/assets/models/vohnyk.glb"
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

m = bpy.data.objects.get("Mesh_0")
if not m:
    raise RuntimeError("Mesh_0 not found in vohnyk.glb")

coords = [v.co for v in m.data.vertices]
min_z = min(c.z for c in coords)
max_z = max(c.z for c in coords)
height = max_z - min_z
shift_z = -min_z
m.location.z += shift_z

# Camera setup
cam_data = bpy.data.cameras.new(name="SpriteCam")
cam_data.type = "ORTHO"
cam_data.ortho_scale = height * 1.15
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

tmp_dir = "/home/mfedchyk/Godot/djura-1/build/render_tmp/vohnyk_meshy"
os.makedirs(tmp_dir, exist_ok=True)

anims = {
    "idle": [
        {"yaw": 0, "pitch": 0, "roll": -4, "scale_y": 1.00, "z_off": 0.00},
        {"yaw": 0, "pitch": 0, "roll": 0, "scale_y": 1.04, "z_off": 0.02},
        {"yaw": 0, "pitch": 0, "roll": 4, "scale_y": 1.06, "z_off": 0.03},
        {"yaw": 0, "pitch": 0, "roll": 0, "scale_y": 1.02, "z_off": 0.01},
    ],
    "jump": [
        {"yaw": 0, "pitch": -4, "roll": -2, "scale_y": 0.94, "z_off": -0.04},
        {"yaw": 0, "pitch": -8, "roll": 0, "scale_y": 1.10, "z_off": 0.08},
        {"yaw": 0, "pitch": -6, "roll": 2, "scale_y": 1.08, "z_off": 0.06},
        {"yaw": 0, "pitch": -2, "roll": 0, "scale_y": 1.02, "z_off": 0.02},
    ],
    "fizzle": [
        {"yaw": 30, "pitch": 10, "roll": 10, "scale_y": 0.90, "z_off": -0.05},
        {"yaw": 90, "pitch": 20, "roll": 20, "scale_y": 0.75, "z_off": -0.08},
        {"yaw": 180, "pitch": 15, "roll": -15, "scale_y": 0.60, "z_off": -0.10},
        {"yaw": 270, "pitch": 0, "roll": 0, "scale_y": 0.45, "z_off": -0.12},
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
        print(f"Rendered Vohnyk {anim_name} [{idx}] -> {out_file}")

print("Blender Vohnyk rendering complete!")
"""
    cmd = ["blender", "-b", "--python-expr", blend_script]
    subprocess.check_call(cmd)

def pack_sheet():
    sys.path.insert(0, "/home/mfedchyk/Godot/djura-1/tools/blender")
    import pack_spritesheet

    tmp_dir = "/home/mfedchyk/Godot/djura-1/build/render_tmp/vohnyk_meshy"
    frames_by_anim = {}
    for anim_dir in sorted(os.listdir(tmp_dir)):
        full_path = os.path.join(tmp_dir, anim_dir)
        if os.path.isdir(full_path):
            frames = sorted(glob.glob(os.path.join(full_path, "*.png")))
            if frames:
                frames_by_anim[anim_dir] = frames

    output_png = "/home/mfedchyk/Godot/djura-1/assets/sprites/vohnyk_sheet.png"
    output_tres = "/home/mfedchyk/Godot/djura-1/assets/sprites/vohnyk_frames.tres"
    output_json = "/home/mfedchyk/Godot/djura-1/assets/sprites/vohnyk_manifest.json"

    print("Packing Vohnyk frames into:", output_png)
    pack_spritesheet.pack_spritesheet(
        frames_by_anim=frames_by_anim,
        output_png=output_png,
        output_tres=output_tres,
        output_json=output_json,
        frame_width=128,
        frame_height=128,
        fps=12
    )
    print("Vohnyk sprite sheet packed successfully!")

if __name__ == "__main__":
    run_blender_render()
    pack_sheet()
