"""
Sets up a canonical Blender reference studio for modeling Djura (15 y.o.)
Places Front, Side, and Back orthographic reference blueprints aligned to Z=0.
"""

import os
_PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))  # корінь репозиторію (TLS-02)
import os
import bpy


def setup_studio():
    # Reset to clean empty scene
    bpy.ops.wm.read_factory_settings(use_empty=True)

    base_dir = os.path.join(_PROJECT_ROOT, "assets", "sprites")
    front_path = os.path.join(base_dir, "djura_v2_front.png")
    side_path = os.path.join(base_dir, "djura_v2_side.png")
    back_path = os.path.join(base_dir, "djura_v2_back.png")

    def add_ref(name, img_path, loc, rot_rad, size):
        if not os.path.exists(img_path):
            print(f"Warning: {img_path} not found")
            return None
        img = bpy.data.images.load(img_path)
        empty = bpy.data.objects.new(name, None)
        empty.empty_display_type = 'IMAGE'
        empty.data = img
        empty.empty_display_size = size
        empty.location = loc
        empty.rotation_euler = rot_rad
        # Display settings: show in orthographic, adjust opacity
        empty.use_empty_image_alpha = True
        empty.empty_image_offset = (0.0, 0.0)
        bpy.context.collection.objects.link(empty)
        return empty

    # Aligned references:
    # Front at Y = 0.01 (facing -Y)
    add_ref("REF_Front", front_path, (0.0, 0.01, 1.0), (1.5707963, 0.0, 0.0), 2.0)
    # Side at X = 0.01 (facing -X)
    add_ref("REF_Side", side_path, (0.01, 0.0, 1.0), (1.5707963, 0.0, -1.5707963), 2.0)
    # Back at Y = -0.01 (facing +Y)
    add_ref("REF_Back", back_path, (0.0, -0.01, 1.0), (1.5707963, 0.0, 3.1415926), 2.0)

    # Add a ground plane grid reference
    bpy.ops.mesh.primitive_plane_add(size=2.0, location=(0, 0, 0))
    plane = bpy.context.active_object
    plane.name = "Ground_Reference"

    out_blend = os.path.join(_PROJECT_ROOT, "assets", "models", "djura_reference_studio.blend")
    os.makedirs(os.path.dirname(out_blend), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=out_blend)
    print(f"Djura 15yo reference studio scene saved to: {out_blend}")


if __name__ == "__main__":
    setup_studio()
