#!/usr/bin/env python3
"""
3D-to-2D Sprite Renderer for "Джура: початок шляху козака".
Follows SHR-004, SWR-003, ADR-003, and Invariants I-3, I-4.

Can be run directly via:
    python3 tools/render_sprites_3d.py --model path/to/model.glb --name cossack_hero
or via Blender:
    blender -b templates/render_stage.blend -P tools/render_sprites_3d.py -- --model path/to/model.glb --name cossack_hero
"""

import os
_PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))  # корінь репозиторію (TLS-02)
import argparse
import glob
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


if is_running_in_blender():
    import bpy

    # Add blender tools directory to path
    tools_dir = os.path.dirname(os.path.abspath(__file__))
    blender_pkg_dir = os.path.join(tools_dir, "blender")
    if blender_pkg_dir not in sys.path:
        sys.path.insert(0, blender_pkg_dir)

    import cossack_toon_shader


def parse_args():
    parser = argparse.ArgumentParser(description="Render 3D model into 2D sprite sheets")
    parser.add_argument("--model", type=str, required=True, help="Path to .glb or .fbx model file")
    parser.add_argument("--name", type=str, default="cossack", help="Character name for output files")
    parser.add_argument("--template", type=str, default="templates/render_stage.blend", help="Blender stage template")
    parser.add_argument("--out-dir", type=str, default="assets/sprites", help="Output directory for sprite sheets")
    parser.add_argument("--temp-dir", type=str, default="", help="Temp directory for rendered PNG frames")
    parser.add_argument("--resolution", type=int, default=128, help="Frame resolution in pixels (square)")
    parser.add_argument("--fps", type=int, default=12, help="Animation frame rate")
    parser.add_argument("--outline-thickness", type=float, default=0.025, help="Inverted Hull outline thickness")

    # In Blender, args after '--' are passed to the script
    if is_running_in_blender():
        if "--" in sys.argv:
            args_to_parse = sys.argv[sys.argv.index("--") + 1 :]
        else:
            args_to_parse = []
        return parser.parse_args(args_to_parse)
    else:
        return parser.parse_args()


# ==============================================================================
# BLENDER INTERNAL EXECUTION LOGIC
# ==============================================================================
def render_in_blender(args):
    """Executes inside Blender 5.0.1+"""
    scene = bpy.context.scene

    # Set resolution
    scene.render.resolution_x = args.resolution
    scene.render.resolution_y = args.resolution
    scene.render.fps = args.fps

    # Temp render directory for individual frames
    if args.temp_dir:
        temp_dir = os.path.abspath(args.temp_dir)
    else:
        temp_dir = os.path.abspath(os.path.join(os.path.dirname(os.path.dirname(__file__)), "build", "render_tmp", args.name))
    os.makedirs(temp_dir, exist_ok=True)

    # 1. Import Model
    model_path = os.path.abspath(args.model)
    print(f"[Blender] Importing model from: {model_path}")

    # Track existing objects
    existing_objs = set(bpy.data.objects)

    ext = os.path.splitext(model_path)[1].lower()
    if ext in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=model_path)
    elif ext == ".fbx":
        bpy.ops.import_scene.fbx(filepath=model_path)
    else:
        raise ValueError(f"Unsupported model extension: {ext}. Use .glb, .gltf, or .fbx.")

    new_objs = [obj for obj in bpy.data.objects if obj not in existing_objs]
    if not new_objs:
        raise RuntimeError("No objects imported from model file.")

    # Find root object and meshes
    mesh_objs = [obj for obj in new_objs if obj.type == 'MESH']
    armature_objs = [obj for obj in new_objs if obj.type == 'ARMATURE']

    print(f"[Blender] Imported {len(mesh_objs)} meshes, {len(armature_objs)} armatures.")

    # 2. Floor Alignment (Z = 0 Invariant)
    # Calculate bounding box minimum Z in world space
    min_z = float("inf")
    max_z = float("-inf")
    for m in mesh_objs:
        for corner in [m.matrix_world @ mathutils.Vector(c) for c in m.bound_box]:
            min_z = min(min_z, corner.z)
            max_z = max(max_z, corner.z)

    height = max_z - min_z
    print(f"[Blender] Model height: {height:.2f}m, min_z: {min_z:.2f}m")

    # Shift root objects so feet are at Z = 0
    shift_z = -min_z
    for obj in new_objs:
        if obj.parent is None:
            obj.location.z += shift_z

    # 3. Apply Stylized Cel-Shader and Inverted Hull Outline
    print(f"[Blender] Applying Kyivnaukfilm Cel-Shader & Inverted Hull outline (thickness={args.outline_thickness})...")
    for m in mesh_objs:
        cossack_toon_shader.process_character_mesh(m, thickness=args.outline_thickness)

    # 4. Detect Animations / Actions
    actions_to_render = []
    if armature_objs and bpy.data.actions:
        for act in bpy.data.actions:
            actions_to_render.append(act)

    frames_rendered_map = {}

    if actions_to_render:
        # Render each action
        for act in actions_to_render:
            anim_name = act.name.lower().replace(" ", "_")
            anim_folder = os.path.join(temp_dir, anim_name)
            os.makedirs(anim_folder, exist_ok=True)

            print(f"[Blender] Rendering animation action: {anim_name} (Frames {int(act.frame_range[0])} to {int(act.frame_range[1])})...")

            for arm in armature_objs:
                if not arm.animation_data:
                    arm.animation_data_create()
                arm.animation_data.action = act

            frame_start = int(act.frame_range[0])
            frame_end = int(act.frame_range[1])

            frames_rendered_map[anim_name] = []

            for frame in range(frame_start, frame_end + 1):
                scene.frame_set(frame)
                out_path = os.path.join(anim_folder, f"frame_{frame:04d}.png")
                scene.render.filepath = out_path
                bpy.ops.render.render(write_still=True)
                frames_rendered_map[anim_name].append(out_path)
    else:
        # Static model: Render a 8-direction turntable / idle preview
        print("[Blender] No skeletal actions found. Generating standard 8-frame turntable preview...")
        anim_name = "idle"
        anim_folder = os.path.join(temp_dir, anim_name)
        os.makedirs(anim_folder, exist_ok=True)

        frames_rendered_map[anim_name] = []
        root_obj = new_objs[0] if new_objs else None

        num_frames = 8
        for i in range(num_frames):
            angle = (2.0 * math.pi / num_frames) * i
            if root_obj:
                root_obj.rotation_euler.z = angle

            out_path = os.path.join(anim_folder, f"frame_{i:04d}.png")
            scene.render.filepath = out_path
            bpy.ops.render.render(write_still=True)
            frames_rendered_map[anim_name].append(out_path)

    print("[Blender] Rendering completed successfully.")


# ==============================================================================
# CLI HOST WRAPPER (Runs outside Blender)
# ==============================================================================
def main():
    args = parse_args()

    project_root = os.path.abspath(_PROJECT_ROOT)
    template_path = os.path.join(project_root, args.template)

    if not os.path.isfile(template_path):
        # Generate stage template if missing
        print(f"Template not found at {template_path}. Generating template...")
        cmd_tmpl = [
            "blender", "-b", "-P",
            os.path.join(project_root, "tools/blender/setup_render_stage.py")
        ]
        subprocess.check_call(cmd_tmpl)

    # 1. Run Blender headless to render frames
    model_abs_path = os.path.abspath(args.model)
    script_abs_path = os.path.abspath(__file__)
    temp_base = os.path.join(project_root, "build", "render_tmp", args.name)
    os.makedirs(temp_base, exist_ok=True)

    cmd_render = [
        "blender", "-b", template_path,
        "-P", script_abs_path,
        "--",
        "--model", model_abs_path,
        "--name", args.name,
        "--temp-dir", temp_base,
        "--resolution", str(args.resolution),
        "--fps", str(args.fps),
        "--outline-thickness", str(args.outline_thickness),
    ]

    print(f"Launching Blender headless renderer for '{args.name}'...")
    subprocess.check_call(cmd_render)

    # 2. Pack frames into sprite sheet & generate Godot .tres
    sys.path.insert(0, os.path.join(project_root, "tools/blender"))
    import pack_spritesheet

    temp_base = os.path.join(project_root, "build", "render_tmp", args.name)
    frames_by_anim = {}
    for anim_dir in sorted(os.listdir(temp_base)):
        full_dir = os.path.join(temp_base, anim_dir)
        if os.path.isdir(full_dir):
            frames = sorted(glob.glob(os.path.join(full_dir, "*.png")))
            if frames:
                frames_by_anim[anim_dir] = frames

    output_png = os.path.join(project_root, args.out_dir, f"{args.name}_sheet.png")
    output_tres = os.path.join(project_root, args.out_dir, f"{args.name}_frames.tres")
    output_json = os.path.join(project_root, args.out_dir, f"{args.name}_manifest.json")

    print(f"Packing {sum(len(v) for v in frames_by_anim.values())} frames into sprite sheet...")
    pack_spritesheet.pack_spritesheet(
        frames_by_anim=frames_by_anim,
        output_png=output_png,
        output_tres=output_tres,
        output_json=output_json,
        frame_width=args.resolution,
        frame_height=args.resolution,
        fps=args.fps,
    )
    print(f"\n[DONE] Successfully generated 2D sprite package for '{args.name}'!")


if __name__ == "__main__":
    if is_running_in_blender():
        import mathutils
        args = parse_args()
        render_in_blender(args)
    else:
        main()
