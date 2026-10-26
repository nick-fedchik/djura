"""
Creates a stylized test Cossack 3D model (.glb) for pipeline testing.
Follows Ukrainian Cossack folklore proportions (large cartoon head, wide sharovary, oseledets).
"""

import os
_PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))  # корінь репозиторію (TLS-02)
import math
import os
import bpy


def create_cossack_model(out_glb_path: str):
    bpy.ops.wm.read_factory_settings(use_empty=True)

    # 1. Torso / Zhupan (Red)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.35, depth=0.6, location=(0, 0, 0.95))
    torso = bpy.context.active_object
    torso.name = "Torso"
    mat_zhupan = bpy.data.materials.new("M_Zhupan_Red")
    mat_zhupan.use_nodes = True
    mat_zhupan.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.85, 0.12, 0.12, 1.0)
    torso.data.materials.append(mat_zhupan)

    # 2. Golden Belt / Poyas
    bpy.ops.mesh.primitive_torus_add(major_radius=0.36, minor_radius=0.06, location=(0, 0, 0.68))
    poyas = bpy.context.active_object
    poyas.name = "Poyas"
    mat_poyas = bpy.data.materials.new("M_Poyas_Gold")
    mat_poyas.use_nodes = True
    mat_poyas.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.95, 0.78, 0.1, 1.0)
    poyas.data.materials.append(mat_poyas)

    # 3. Head (Cartoon sphere, Skin tone)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.35, location=(0, 0, 1.5))
    head = bpy.context.active_object
    head.name = "Head"
    mat_skin = bpy.data.materials.new("M_Skin")
    mat_skin.use_nodes = True
    mat_skin.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.96, 0.80, 0.70, 1.0)
    head.data.materials.append(mat_skin)

    # 4. Cossack Oseledets / Chuprina (Black tuft)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.06, depth=0.35, location=(0.15, 0, 1.82))
    oseledets = bpy.context.active_object
    oseledets.name = "Oseledets"
    oseledets.rotation_euler = (0, math.radians(35), 0)
    mat_hair = bpy.data.materials.new("M_Hair_Black")
    mat_hair.use_nodes = True
    mat_hair.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.05, 0.05, 0.05, 1.0)
    oseledets.data.materials.append(mat_hair)

    # 5. Cossack Moustache (Vusa)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.18, minor_radius=0.04, location=(0, -0.32, 1.42))
    vusa = bpy.context.active_object
    vusa.name = "Vusa"
    vusa.rotation_euler = (math.radians(90), 0, 0)
    vusa.data.materials.append(mat_hair)

    # 6. Sharovary Trousers (Wide Blue Cossack pants)
    # Left leg
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.28, location=(-0.22, 0, 0.45))
    leg_l = bpy.context.active_object
    leg_l.name = "Sharovary_L"
    leg_l.scale = (1.0, 1.0, 1.4)
    mat_sharovary = bpy.data.materials.new("M_Sharovary_Blue")
    mat_sharovary.use_nodes = True
    mat_sharovary.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.12, 0.35, 0.88, 1.0)
    leg_l.data.materials.append(mat_sharovary)

    # Right leg
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.28, location=(0.22, 0, 0.45))
    leg_r = bpy.context.active_object
    leg_r.name = "Sharovary_R"
    leg_r.scale = (1.0, 1.0, 1.4)
    leg_r.data.materials.append(mat_sharovary)

    # 7. Red Cossack Boots (Choboty) touching Z = 0 floor
    bpy.ops.mesh.primitive_cylinder_add(radius=0.12, depth=0.2, location=(-0.22, -0.05, 0.1))
    boot_l = bpy.context.active_object
    boot_l.name = "Boot_L"
    mat_boot = bpy.data.materials.new("M_Boot_Red")
    mat_boot.use_nodes = True
    mat_boot.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.75, 0.08, 0.08, 1.0)
    boot_l.data.materials.append(mat_boot)

    bpy.ops.mesh.primitive_cylinder_add(radius=0.12, depth=0.2, location=(0.22, -0.05, 0.1))
    boot_r = bpy.context.active_object
    boot_r.name = "Boot_R"
    boot_r.data.materials.append(mat_boot)

    # Export to GLB
    os.makedirs(os.path.dirname(os.path.abspath(out_glb_path)), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=out_glb_path, export_format='GLB')
    print(f"Test Cossack GLB model exported to: {out_glb_path}")


if __name__ == "__main__":
    out_path = os.path.abspath(os.path.join(_PROJECT_ROOT, "assets", "models", "test_cossack.glb"))
    create_cossack_model(out_path)
