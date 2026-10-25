"""
Setup Render Stage Template for Cossack 3D-to-2D Sprite Pipeline.
Follows SWR-003-01 and ADR-003.

Usage:
    blender -b -P tools/blender/setup_render_stage.py
"""

import math
import os
import sys
import bpy

def setup_render_stage(output_blend_path: str):
    # Clear existing objects in default scene
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene

    # 1. Render engine and color settings
    scene.render.engine = 'BLENDER_EEVEE_NEXT' if hasattr(bpy.types.RenderSettings, "engine") else 'BLENDER_EEVEE'
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    scene.render.image_settings.color_depth = '8'
    scene.render.resolution_x = 256
    scene.render.resolution_y = 256
    scene.render.resolution_percentage = 100

    # Color management: Standard (linear to sRGB without filmic contrast desaturation for pure cartoon colors)
    if hasattr(scene, "view_settings"):
        scene.view_settings.view_transform = 'Standard'
        scene.view_settings.look = 'None'

    # 2. Orthographic Camera
    cam_data = bpy.data.cameras.new(name="SpriteCamera")
    cam_data.type = 'ORTHO'
    cam_data.ortho_scale = 2.2  # Covers ~2.0m character height with margin
    cam_obj = bpy.data.objects.new(name="SpriteCamera", object_data=cam_data)
    scene.collection.objects.link(cam_obj)
    scene.camera = cam_obj

    # Position camera: directly in front, elevated slightly (Z=1.0m, Y=-5.0m), looking at Z=1.0m (center of mass)
    cam_obj.location = (0.0, -5.0, 1.0)
    cam_obj.rotation_euler = (math.radians(90.0), 0.0, 0.0)

    # 3. Three-point Cartoon Lighting setup
    # Key light (45 deg angle, warm white)
    key_light_data = bpy.data.lights.new(name="KeyLight", type='SUN')
    key_light_data.energy = 3.5
    key_light_data.color = (1.0, 0.98, 0.95)
    key_light_obj = bpy.data.objects.new(name="KeyLight", object_data=key_light_data)
    key_light_obj.rotation_euler = (math.radians(45.0), math.radians(15.0), math.radians(-30.0))
    scene.collection.objects.link(key_light_obj)

    # Fill light (-45 deg angle, soft cool blue fill)
    fill_light_data = bpy.data.lights.new(name="FillLight", type='SUN')
    fill_light_data.energy = 1.2
    fill_light_data.color = (0.85, 0.92, 1.0)
    fill_light_obj = bpy.data.objects.new(name="FillLight", object_data=fill_light_data)
    fill_light_obj.rotation_euler = (math.radians(50.0), math.radians(-20.0), math.radians(60.0))
    scene.collection.objects.link(fill_light_obj)

    # Rim light (back-top, creates cartoon outline separation)
    rim_light_data = bpy.data.lights.new(name="RimLight", type='SUN')
    rim_light_data.energy = 2.0
    rim_light_data.color = (1.0, 1.0, 1.0)
    rim_light_obj = bpy.data.objects.new(name="RimLight", object_data=rim_light_data)
    rim_light_obj.rotation_euler = (math.radians(-60.0), 0.0, math.radians(180.0))
    scene.collection.objects.link(rim_light_obj)

    # Ensure output directory exists
    os.makedirs(os.path.dirname(output_blend_path), exist_ok=True)

    # Save template blend file
    bpy.ops.wm.save_as_mainfile(filepath=output_blend_path)
    print(f"Render stage template saved successfully to: {output_blend_path}")

if __name__ == "__main__":
    blend_path = os.path.abspath("/home/mfedchyk/Godot/djura-1/templates/render_stage.blend")
    setup_render_stage(blend_path)
