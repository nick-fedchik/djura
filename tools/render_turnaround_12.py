#!/usr/bin/env python3
"""
Renders a 3D model (.glb / .blend) from 12 orbital camera angles (every 30 degrees).
Generates individual PNG frames and a stitched 12-angle composite turnaround sheet.
"""

import os
_PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))  # корінь репозиторію (TLS-02)
import argparse
import math
import os
import subprocess
import sys


def is_running_in_blender() -> bool:
    try:
        import bpy
        return True
    except ImportError:
        return False


def parse_args():
    parser = argparse.ArgumentParser(description="Render 12-angle turnaround for Meshy 3D models")
    parser.add_argument("--model", type=str, required=True, help="Path to .glb or .blend model")
    parser.add_argument("--name", type=str, default="character", help="Character identifier")
    parser.add_argument("--out-dir", type=str, default=os.path.join(_PROJECT_ROOT, "reports", "turnarounds"), help="Output directory")
    parser.add_argument("--resolution", type=int, default=512, help="Resolution per view")

    if is_running_in_blender():
        if "--" in sys.argv:
            args_to_parse = sys.argv[sys.argv.index("--") + 1 :]
        else:
            args_to_parse = []
        return parser.parse_args(args_to_parse)
    else:
        return parser.parse_args()


if is_running_in_blender():
    import bpy

    def render_12_angles(args):
        scene = bpy.context.scene
        scene.render.resolution_x = args.resolution
        scene.render.resolution_y = args.resolution
        scene.render.image_settings.file_format = 'PNG'
        scene.render.image_settings.color_mode = 'RGBA'
        scene.render.film_transparent = True

        out_dir = os.path.abspath(os.path.join(args.out_dir, args.name))
        os.makedirs(out_dir, exist_ok=True)

        # Clear existing mesh objects if loading GLB
        model_path = os.path.abspath(args.model)
        if model_path.endswith(".glb") or model_path.endswith(".gltf"):
            bpy.ops.wm.read_factory_settings(use_empty=True)
            bpy.ops.import_scene.gltf(filepath=model_path)
        elif model_path.endswith(".blend"):
            # Already open if launched via blender <file.blend> -P ...
            pass

        # Find or create camera and lighting
        cam = None
        for obj in scene.objects:
            if obj.type == 'CAMERA':
                cam = obj
                break

        if not cam:
            cam_data = bpy.data.cameras.new(name="TurnaroundCamera")
            cam_data.type = 'PERSP'
            cam_data.lens = 50
            cam = bpy.data.objects.new(name="TurnaroundCamera", object_data=cam_data)
            scene.collection.objects.link(cam)
        scene.camera = cam

        # Find model center & bounds
        mesh_objs = [o for o in scene.objects if o.type == 'MESH']
        if not mesh_objs:
            print("No mesh objects found in scene!")
            return

        min_z = min([o.bound_box[0][2] * o.scale.z + o.location.z for o in mesh_objs])
        max_z = max([o.bound_box[6][2] * o.scale.z + o.location.z for o in mesh_objs])
        height = max(0.1, max_z - min_z)
        center_z = (min_z + max_z) * 0.5

        # Ensure light exists
        lights = [o for o in scene.objects if o.type == 'LIGHT']
        if not lights:
            light_data = bpy.data.lights.new(name="KeyLight", type='SUN')
            light_data.energy = 3.5
            light_obj = bpy.data.objects.new(name="KeyLight", object_data=light_data)
            light_obj.rotation_euler = (math.radians(45), math.radians(30), math.radians(45))
            scene.collection.objects.link(light_obj)

            fill_data = bpy.data.lights.new(name="FillLight", type='SUN')
            fill_data.energy = 1.8
            fill_obj = bpy.data.objects.new(name="FillLight", object_data=fill_data)
            fill_obj.rotation_euler = (math.radians(30), math.radians(-45), math.radians(-120))
            scene.collection.objects.link(fill_obj)

        dist = height * 1.85
        cam_height = center_z + height * 0.08

        # 12 angles: 0, 30, 60, ..., 330 deg
        for i in range(12):
            angle_deg = i * 30
            angle_rad = math.radians(angle_deg)

            cam_x = dist * math.sin(angle_rad)
            cam_y = -dist * math.cos(angle_rad)
            cam.location = (cam_x, cam_y, cam_height)

            # Look at center
            dx = -cam_x
            dy = -cam_y
            dz = center_z - cam_height
            yaw = math.atan2(dx, -dy)
            pitch = math.atan2(dz, math.sqrt(dx * dx + dy * dy))
            cam.rotation_euler = (math.radians(90) - pitch, 0.0, yaw)

            frame_path = os.path.join(out_dir, f"angle_{angle_deg:03d}.png")
            scene.render.filepath = frame_path
            bpy.ops.render.render(write_still=True)
            print(f"Rendered angle {angle_deg}° -> {frame_path}")

        print(f"Done rendering 12 angles to {out_dir}")


def main():
    args = parse_args()
    if is_running_in_blender():
        render_12_angles(args)
    else:
        # Launch Blender headless
        model_path = os.path.abspath(args.model)
        cmd = [
            "blender",
            "-b",
        ]
        if model_path.endswith(".blend"):
            cmd.append(model_path)
        cmd.extend([
            "-P",
            os.path.abspath(__file__),
            "--",
            "--model",
            model_path,
            "--name",
            args.name,
            "--out-dir",
            args.out_dir,
            "--resolution",
            str(args.resolution),
        ])
        print("Executing:", " ".join(cmd))
        subprocess.run(cmd, check=True)


if __name__ == "__main__":
    main()
