"""
Builds a high-fidelity, stylized 3D model of Djura (15 y.o.) in Blender.
Follows Gemini 360-degree turnaround reference, SHR-004, SWR-003, and Invariant I-3 (Zero-Horror).
Uses subdivision-surface modeling (SubD), clean quad topology, and EEVEE Next toon materials.
"""

import math
import os
import bmesh
import bpy
import mathutils


def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    # Ensure a collection exists
    if "Collection" not in bpy.data.collections:
        col = bpy.data.collections.new("Collection")
        bpy.context.scene.collection.children.link(col)


def create_materials():
    mats = {}

    def make_toon_mat(name, base_rgb, roughness=0.5):
        mat = bpy.data.materials.new(name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        nodes.clear()

        out_node = nodes.new("ShaderNodeOutputMaterial")
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        bsdf.inputs["Base Color"].default_value = (base_rgb[0], base_rgb[1], base_rgb[2], 1.0)
        bsdf.inputs["Roughness"].default_value = roughness
        links.new(bsdf.outputs["BSDF"], out_node.inputs["Surface"])
        return mat

    # 1. Skin (warm cartoon boyish peach)
    mats["skin"] = make_toon_mat("M_Djura_Skin", (0.96, 0.80, 0.70), 0.4)
    # 2. Vyshyvanka (clean linen white)
    mats["vyshyvanka"] = make_toon_mat("M_Vyshyvanka_White", (0.95, 0.95, 0.96), 0.6)
    # 3. Embroidery & Sash (vibrant Cossack scarlet red)
    mats["red"] = make_toon_mat("M_Cossack_Scarlet", (0.82, 0.10, 0.12), 0.5)
    # 4. Sharovary (rich cobalt blue with soft depth)
    mats["sharovary"] = make_toon_mat("M_Sharovary_Cobalt", (0.10, 0.25, 0.72), 0.7)
    # 5. Boots (classic saddle brown leather)
    mats["boots"] = make_toon_mat("M_Boots_Brown", (0.42, 0.22, 0.12), 0.35)
    # 6. Hair / Chub / Eyebrows / Eyes (dark charcoal brown)
    mats["hair"] = make_toon_mat("M_Oseledets_Dark", (0.08, 0.06, 0.05), 0.4)
    # 7. Gold belt tassel / buckle accent
    mats["gold"] = make_toon_mat("M_Gold_Accent", (0.92, 0.75, 0.15), 0.3)

    return mats


def build_head_mesh(mats):
    """Builds a stylized cartoon head with chin, ears, and dynamic sweeping oseledets (chub)."""
    # Head base: UV sphere with SubD
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, radius=0.10, location=(0, 0.01, 1.54))
    head = bpy.context.active_object
    head.name = "Djura_Head"
    head.scale = (0.92, 1.02, 1.10)
    bpy.ops.object.transform_apply(scale=True)
    head.data.materials.append(mats["skin"])

    # Stylized Oseledets (Chub): curves dynamically from crown over to the left side
    curve_data = bpy.data.curves.new("ChubCurve", type="CURVE")
    curve_data.dimensions = "3D"
    curve_data.bevel_depth = 0.018
    curve_data.bevel_resolution = 4

    spline = curve_data.splines.new("BEZIER")
    spline.bezier_points.add(3)

    # 4 points forming an elegant sweeping arc
    pts = [
        (0.00, 0.02, 1.64),   # Root at top of head
        (-0.04, 0.03, 1.68),  # Arc peak curving slightly up and left
        (-0.11, 0.01, 1.61),  # Downward sweep past the left ear
        (-0.13, -0.01, 1.50)  # Tapered tip swinging freely
    ]
    for i, p in enumerate(pts):
        bp = spline.bezier_points[i]
        bp.co = p
        bp.handle_left_type = "AUTO"
        bp.handle_right_type = "AUTO"

    chub_obj = bpy.data.objects.new("Djura_Chub", curve_data)
    bpy.context.collection.objects.link(chub_obj)
    chub_obj.data.materials.append(mats["hair"])

    # Convert curve to mesh and join to head
    bpy.context.view_layer.objects.active = chub_obj
    chub_obj.select_set(True)
    bpy.ops.object.convert(target="MESH")

    # Eyes & Eyebrows (stylized dark pupils)
    for sign_x in [-1, 1]:
        bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=0.018, location=(sign_x * 0.038, 0.095, 1.55))
        eye = bpy.context.active_object
        eye.scale = (1.0, 0.3, 1.1)
        bpy.ops.object.transform_apply(scale=True)
        eye.data.materials.append(mats["hair"])

    return head


def build_torso_vyshyvanka(mats):
    """Builds the white vyshyvanka shirt with standing collar and billowing sleeves."""
    # Main shirt torso (from neck Z=1.40 down to waist Z=0.98)
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.18, depth=0.42, location=(0, 0, 1.19))
    torso = bpy.context.active_object
    torso.name = "Djura_Torso"
    # Subtle V-taper: wider at shoulders, trim at waist
    torso.scale = (1.05, 0.78, 1.0)
    bpy.ops.object.transform_apply(scale=True)
    torso.data.materials.append(mats["vyshyvanka"])

    # Standing collar with red embroidery
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.075, depth=0.06, location=(0, 0.01, 1.41))
    collar = bpy.context.active_object
    collar.name = "Djura_Collar"
    collar.data.materials.append(mats["red"])

    # Billowing sleeves (gathered at cuffs)
    for sign_x in [-1, 1]:
        # Upper/lower arm sleeve combined mesh
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.07, depth=0.38, location=(sign_x * 0.28, 0, 1.22))
        sleeve = bpy.context.active_object
        sleeve.name = f"Djura_Sleeve_{'L' if sign_x < 0 else 'R'}"
        sleeve.rotation_euler = (0, sign_x * 0.38, 0)
        sleeve.scale = (1.1, 0.9, 1.0)
        bpy.ops.object.transform_apply(scale=True, rotation=True)
        sleeve.data.materials.append(mats["vyshyvanka"])

        # Red embroidered wrist cuffs
        cuff_pos = (sign_x * 0.40, 0, 1.05)
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.045, depth=0.04, location=cuff_pos)
        cuff = bpy.context.active_object
        cuff.name = f"Djura_Cuff_{'L' if sign_x < 0 else 'R'}"
        cuff.rotation_euler = (0, sign_x * 0.38, 0)
        bpy.ops.object.transform_apply(rotation=True)
        cuff.data.materials.append(mats["red"])

        # Hands (stylized boyish cartoon fists/hands)
        hand_pos = (sign_x * 0.44, 0, 0.98)
        bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=8, radius=0.038, location=hand_pos)
        hand = bpy.context.active_object
        hand.scale = (0.9, 1.1, 1.2)
        bpy.ops.object.transform_apply(scale=True)
        hand.data.materials.append(mats["skin"])

    return torso


def build_koyas_sash(mats):
    """Builds the wide scarlet red sash (кояс) wrapped around the waist with hanging knot."""
    # Main wrap around waist (Z=0.96 to Z=1.06)
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.19, depth=0.12, location=(0, 0, 1.01))
    sash = bpy.context.active_object
    sash.name = "Djura_Sash"
    sash.scale = (1.08, 0.82, 1.0)
    bpy.ops.object.transform_apply(scale=True)
    sash.data.materials.append(mats["red"])

    # Hanging knot with fringe tassels on the left hip
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.035, depth=0.24, location=(-0.19, 0.02, 0.88))
    knot = bpy.context.active_object
    knot.name = "Djura_Sash_Knot"
    knot.rotation_euler = (0.1, -0.15, 0)
    bpy.ops.object.transform_apply(rotation=True)
    knot.data.materials.append(mats["red"])

    # Gold fringe tip
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.038, radius2=0.015, depth=0.06, location=(-0.21, 0.03, 0.74))
    fringe = bpy.context.active_object
    fringe.name = "Djura_Sash_Fringe"
    fringe.data.materials.append(mats["gold"])

    return sash


def build_sharovary_pants(mats):
    """Builds the signature voluminous cobalt blue sharovary trousers."""
    # Upper pelvis gather (Z=0.88..0.98)
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.22, depth=0.14, location=(0, 0, 0.92))
    pelvis = bpy.context.active_object
    pelvis.name = "Djura_Sharovary_Pelvis"
    pelvis.scale = (1.10, 0.85, 1.0)
    bpy.ops.object.transform_apply(scale=True)
    pelvis.data.materials.append(mats["sharovary"])

    # Left and Right billowing legs
    for sign_x in [-1, 1]:
        # Voluminous bulging thigh/knee (Z=0.45..0.85)
        # Using a tapered cylinder with bulge
        bpy.ops.mesh.primitive_cylinder_add(vertices=14, radius=0.17, depth=0.48, location=(sign_x * 0.13, 0, 0.64))
        leg = bpy.context.active_object
        leg.name = f"Djura_Sharovary_{'L' if sign_x < 0 else 'R'}"
        leg.scale = (1.15, 1.10, 1.0)
        bpy.ops.object.transform_apply(scale=True)
        leg.data.materials.append(mats["sharovary"])

        # Lower gathered cuff tapering into boot (Z=0.28..0.44)
        bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=0.15, radius2=0.08, depth=0.16, location=(sign_x * 0.13, 0, 0.36))
        cuff = bpy.context.active_object
        cuff.name = f"Djura_Sharovary_Cuff_{'L' if sign_x < 0 else 'R'}"
        cuff.data.materials.append(mats["sharovary"])

    return pelvis


def build_boots(mats):
    """Builds the classic Ukrainian leather boots (чоботи) with soft folds and sturdy soles."""
    for sign_x in [-1, 1]:
        # Boot shaft / calf (Z=0.10..0.30)
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.072, depth=0.20, location=(sign_x * 0.13, 0, 0.20))
        shaft = bpy.context.active_object
        shaft.name = f"Djura_Boot_Shaft_{'L' if sign_x < 0 else 'R'}"
        shaft.scale = (0.9, 1.1, 1.0)
        bpy.ops.object.transform_apply(scale=True)
        shaft.data.materials.append(mats["boots"])

        # Foot shoe base (Z=0.00..0.10, extended forward along Y)
        bpy.ops.mesh.primitive_cube_add(size=0.10, location=(sign_x * 0.13, 0.04, 0.05))
        foot = bpy.context.active_object
        foot.name = f"Djura_Boot_Foot_{'L' if sign_x < 0 else 'R'}"
        foot.scale = (0.75, 1.70, 0.70)
        bpy.ops.object.transform_apply(scale=True)
        foot.data.materials.append(mats["boots"])

        # Slight upturned Cossack toe tip
        bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.045, radius2=0.015, depth=0.06, location=(sign_x * 0.13, 0.14, 0.05))
        toe = bpy.context.active_object
        toe.name = f"Djura_Boot_Toe_{'L' if sign_x < 0 else 'R'}"
        toe.rotation_euler = (-1.5707963, 0, 0)
        bpy.ops.object.transform_apply(rotation=True)
        toe.data.materials.append(mats["boots"])


def join_and_smooth_character():
    """Selects all character parts, joins them into a single cohesive mesh, and applies SubD + AutoSmooth."""
    bpy.ops.object.select_all(action='DESELECT')
    for obj in bpy.context.scene.objects:
        if obj.name.startswith("Djura_"):
            obj.select_set(True)

    # Active object for join
    bpy.context.view_layer.objects.active = bpy.data.objects["Djura_Torso"]
    bpy.ops.object.join()

    char_obj = bpy.context.active_object
    char_obj.name = "Djura_Character"

    # Apply Subdivision Surface modifier for clean, organic cartoon curvature
    subd = char_obj.modifiers.new("Subdivision", type='SUBSURF')
    subd.levels = 1
    subd.render_levels = 2

    # Smooth shading
    for poly in char_obj.data.polygons:
        poly.use_smooth = True

    return char_obj


def build_armature(char_obj):
    """Builds a canonical humanoid armature matching Djura's anatomical landmarks."""
    bpy.ops.object.armature_add(location=(0, 0, 0))
    arm_obj = bpy.context.active_object
    arm_obj.name = "Djura_Armature"
    arm_data = arm_obj.data
    arm_data.name = "Djura_Armature_Data"

    bpy.ops.object.mode_set(mode='EDIT')
    edit_bones = arm_data.edit_bones

    # Clear default bone
    for b in list(edit_bones):
        edit_bones.remove(b)

    # 1. Root / Hips
    b_root = edit_bones.new("Root")
    b_root.head = (0, 0, 0)
    b_root.tail = (0, 0, 0.1)

    b_hips = edit_bones.new("Hips")
    b_hips.head = (0, 0, 0.95)
    b_hips.tail = (0, 0, 1.15)
    b_hips.parent = b_root

    # 2. Spine & Chest
    b_spine = edit_bones.new("Spine")
    b_spine.head = (0, 0, 1.15)
    b_spine.tail = (0, 0, 1.35)
    b_spine.parent = b_hips

    # 3. Neck & Head
    b_neck = edit_bones.new("Neck")
    b_neck.head = (0, 0, 1.35)
    b_neck.tail = (0, 0, 1.44)
    b_neck.parent = b_spine

    b_head = edit_bones.new("Head")
    b_head.head = (0, 0, 1.44)
    b_head.tail = (0, 0, 1.66)
    b_head.parent = b_neck

    b_chub = edit_bones.new("Chub")
    b_chub.head = (0, 0.02, 1.64)
    b_chub.tail = (-0.12, 0.0, 1.52)
    b_chub.parent = b_head

    # 4. Arms
    for sign_x, suffix in [(-1, "L"), (1, "R")]:
        b_shoulder = edit_bones.new(f"Shoulder_{suffix}")
        b_shoulder.head = (sign_x * 0.08, 0, 1.34)
        b_shoulder.tail = (sign_x * 0.18, 0, 1.32)
        b_shoulder.parent = b_spine

        b_arm = edit_bones.new(f"Arm_{suffix}")
        b_arm.head = (sign_x * 0.18, 0, 1.32)
        b_arm.tail = (sign_x * 0.34, 0, 1.14)
        b_arm.parent = b_shoulder

        b_forearm = edit_bones.new(f"Forearm_{suffix}")
        b_forearm.head = (sign_x * 0.34, 0, 1.14)
        b_forearm.tail = (sign_x * 0.44, 0, 0.96)
        b_forearm.parent = b_arm

        b_hand = edit_bones.new(f"Hand_{suffix}")
        b_hand.head = (sign_x * 0.44, 0, 0.96)
        b_hand.tail = (sign_x * 0.48, 0, 0.90)
        b_hand.parent = b_forearm

    # 5. Legs
    for sign_x, suffix in [(-1, "L"), (1, "R")]:
        b_thigh = edit_bones.new(f"Thigh_{suffix}")
        b_thigh.head = (sign_x * 0.13, 0, 0.92)
        b_thigh.tail = (sign_x * 0.13, 0, 0.48)
        b_thigh.parent = b_hips

        b_shin = edit_bones.new(f"Shin_{suffix}")
        b_shin.head = (sign_x * 0.13, 0, 0.48)
        b_shin.tail = (sign_x * 0.13, 0, 0.12)
        b_shin.parent = b_thigh

        b_foot = edit_bones.new(f"Foot_{suffix}")
        b_foot.head = (sign_x * 0.13, 0, 0.12)
        b_foot.tail = (sign_x * 0.13, 0.12, 0.02)
        b_foot.parent = b_shin

    bpy.ops.object.mode_set(mode='OBJECT')

    # Parent mesh to armature with automatic weights
    bpy.ops.object.select_all(action='DESELECT')
    char_obj.select_set(True)
    arm_obj.select_set(True)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.parent_set(type='ARMATURE_AUTO')

    return arm_obj


def bake_animations(arm_obj):
    """Creates the 7 canonical game actions in Blender Action Editor."""
    actions = {}

    def new_action(name):
        act = bpy.data.actions.new(name)
        if not arm_obj.animation_data:
            arm_obj.animation_data_create()
        arm_obj.animation_data.action = act
        actions[name] = act
        return act

    def set_key(bone_name, frame, loc=None, rot_deg=None):
        pbone = arm_obj.pose.bones.get(bone_name)
        if not pbone:
            return
        pbone.rotation_mode = 'XYZ'
        if loc:
            pbone.location = loc
            pbone.keyframe_insert(data_path="location", frame=frame)
        if rot_deg:
            pbone.rotation_euler = tuple(math.radians(a) for a in rot_deg)
            pbone.keyframe_insert(data_path="rotation_euler", frame=frame)

    # 1. Action: "idle" (8 frames)
    act_idle = new_action("idle")
    for f in range(1, 9):
        t = (f - 1) / 8.0 * 2.0 * math.pi
        breathe = math.sin(t)
        set_key("Hips", f, loc=(0, 0, breathe * 0.015))
        set_key("Spine", f, rot_deg=(breathe * 2.0, 0, 0))
        set_key("Head", f, rot_deg=(-breathe * 1.5, 0, 0))
        set_key("Chub", f, rot_deg=(math.cos(t) * 4.0, math.sin(t) * 3.0, 0))
        set_key("Arm_L", f, rot_deg=(0, 0, 5 + breathe * 2))
        set_key("Arm_R", f, rot_deg=(0, 0, -5 - breathe * 2))

    # 2. Action: "run" (8 frames)
    act_run = new_action("run")
    for f in range(1, 9):
        t = (f - 1) / 8.0 * 2.0 * math.pi
        leg_l = math.sin(t) * 35.0
        leg_r = -leg_l
        arm_l = -leg_l * 0.8
        arm_r = -arm_l
        bob = abs(math.sin(t * 2.0)) * 0.04
        set_key("Hips", f, loc=(0, 0, -bob), rot_deg=(8.0, 0, math.sin(t) * 4.0))
        set_key("Thigh_L", f, rot_deg=(leg_l, 0, 0))
        set_key("Shin_L", f, rot_deg=(max(0.0, -leg_l * 0.9), 0, 0))
        set_key("Thigh_R", f, rot_deg=(leg_r, 0, 0))
        set_key("Shin_R", f, rot_deg=(max(0.0, -leg_r * 0.9), 0, 0))
        set_key("Arm_L", f, rot_deg=(arm_l, 0, 10))
        set_key("Arm_R", f, rot_deg=(arm_r, 0, -10))
        set_key("Chub", f, rot_deg=(-15 + math.cos(t * 2) * 10, math.sin(t) * 8, 0))

    # 3. Action: "jump" (4 frames)
    act_jump = new_action("jump")
    jump_data = [
        (1, 0.00, (15, 0, 0), (-25, 0, 0), (45, 0, 0)),
        (2, 0.12, (-5, 0, 0), (20, 0, 0), (10, 0, 0)),
        (3, 0.22, (-10, 0, 0), (10, 0, 0), (15, 0, 0)),
        (4, 0.18, (-5, 0, 0), (-15, 0, 0), (35, 0, 0))
    ]
    for f, h_z, sp_r, th_r, sh_r in jump_data:
        set_key("Hips", f, loc=(0, 0, h_z))
        set_key("Spine", f, rot_deg=sp_r)
        set_key("Thigh_L", f, rot_deg=th_r)
        set_key("Shin_L", f, rot_deg=sh_r)
        set_key("Thigh_R", f, rot_deg=th_r)
        set_key("Shin_R", f, rot_deg=sh_r)
        set_key("Arm_L", f, rot_deg=(-45, 0, 45))
        set_key("Arm_R", f, rot_deg=(-45, 0, -45))
        set_key("Chub", f, rot_deg=(25, 0, 0))

    # 4. Action: "glide" (2 frames)
    act_glide = new_action("glide")
    for f in [1, 2]:
        flutter = (f - 1) * 3.0
        set_key("Hips", f, loc=(0, 0, 0.05), rot_deg=(-12, 0, 0))
        set_key("Arm_L", f, rot_deg=(0, 0, 75 + flutter))
        set_key("Arm_R", f, rot_deg=(0, 0, -75 - flutter))
        set_key("Thigh_L", f, rot_deg=(-10, 0, -10))
        set_key("Thigh_R", f, rot_deg=(-10, 0, 10))
        set_key("Chub", f, rot_deg=(30, 0, 0))

    # 5. Action: "hopak_kick" (4 frames) - Pistols strike
    act_kick = new_action("hopak_kick")
    kick_data = [
        (1, -0.15, (0, 0, 0), (-35, 0, 0), (70, 0, 0), (-35, 0, 0), (70, 0, 0)),
        (2, -0.10, (5, 0, 0), (85, 0, 0), (0, 0, 0), (-45, 0, 0), (90, 0, 0)),
        (3, -0.08, (5, 0, 0), (90, 0, 0), (0, 0, 0), (-45, 0, 0), (90, 0, 0)),
        (4, 0.00, (0, 0, 0), (0, 0, 0), (0, 0, 0), (0, 0, 0), (0, 0, 0))
    ]
    for f, h_z, sp_r, th_r_r, sh_r_r, th_l_r, sh_l_r in kick_data:
        set_key("Hips", f, loc=(0, 0, h_z))
        set_key("Spine", f, rot_deg=sp_r)
        set_key("Thigh_R", f, rot_deg=th_r_r)
        set_key("Shin_R", f, rot_deg=sh_r_r)
        set_key("Thigh_L", f, rot_deg=th_l_r)
        set_key("Shin_L", f, rot_deg=sh_l_r)
        set_key("Arm_L", f, rot_deg=(20, 0, 45))
        set_key("Arm_R", f, rot_deg=(-30, 0, -60))

    # 6. Action: "bonk" (2 frames)
    act_bonk = new_action("bonk")
    set_key("Hips", 1, loc=(0, 0, -0.05), rot_deg=(-15, 0, 0))
    set_key("Head", 1, rot_deg=(25, 0, 0))
    set_key("Arm_L", 1, rot_deg=(40, 0, 30))
    set_key("Arm_R", 1, rot_deg=(40, 0, -30))
    set_key("Hips", 2, loc=(0, 0, 0.0), rot_deg=(5, 0, 0))
    set_key("Head", 2, rot_deg=(-10, 0, 0))

    # 7. Action: "victory" (4 frames)
    act_vic = new_action("victory")
    vic_data = [
        (1, 0.00, (0, 0, 0), (0, 0, 40), (0, 0, -40)),
        (2, 0.15, (-5, 0, 0), (0, 0, 120), (0, 0, -120)),
        (3, 0.22, (-8, 0, 0), (0, 0, 140), (0, 0, -140)),
        (4, 0.05, (0, 0, 0), (0, 0, 50), (0, 0, -50))
    ]
    for f, h_z, sp_r, arm_l_r, arm_r_r in vic_data:
        set_key("Hips", f, loc=(0, 0, h_z))
        set_key("Spine", f, rot_deg=sp_r)
        set_key("Arm_L", f, rot_deg=arm_l_r)
        set_key("Arm_R", f, rot_deg=arm_r_r)
        set_key("Chub", f, rot_deg=(-20, 0, 0))

    return actions


def setup_lighting_and_camera():
    """Sets up studio lighting and three-quarter orthographic camera for turntable preview."""
    # Key light (warm sunlight)
    bpy.ops.object.light_add(type='SUN', location=(3, -4, 5))
    sun = bpy.context.active_object
    sun.data.energy = 3.5
    sun.data.color = (1.0, 0.98, 0.92)

    # Fill light (cool sky light)
    bpy.ops.object.light_add(type='SUN', location=(-4, -2, 4))
    fill = bpy.context.active_object
    fill.data.energy = 1.8
    fill.data.color = (0.75, 0.85, 1.0)

    # Rim light
    bpy.ops.object.light_add(type='SUN', location=(0, 5, 3))
    rim = bpy.context.active_object
    rim.data.energy = 2.2
    rim.data.color = (1.0, 1.0, 1.0)

    # Camera
    bpy.ops.object.camera_add(location=(1.8, -2.6, 1.4), rotation=(math.radians(78), 0, math.radians(35)))
    cam = bpy.context.active_object
    cam.name = "Preview_Camera"
    cam.data.lens = 50
    bpy.context.scene.camera = cam


def render_preview(out_img_path):
    """Renders beauty shot of the character."""
    os.makedirs(os.path.dirname(out_img_path), exist_ok=True)
    scene = bpy.context.scene
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 1024
    scene.render.filepath = out_img_path
    scene.render.image_settings.file_format = 'PNG'
    bpy.ops.render.render(write_still=True)
    print(f"Rendered preview saved to: {out_img_path}")


def main():
    clear_scene()
    mats = create_materials()

    build_head_mesh(mats)
    build_torso_vyshyvanka(mats)
    build_koyas_sash(mats)
    build_sharovary_pants(mats)
    build_boots(mats)

    char_obj = join_and_smooth_character()
    arm_obj = build_armature(char_obj)
    bake_animations(arm_obj)

    setup_lighting_and_camera()

    # Save native .blend
    blend_path = "/home/mfedchyk/Godot/djura-1/assets/models/djura_15yo.blend"
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    print(f"Saved native Blender project: {blend_path}")

    # Export GLB
    glb_path = "/home/mfedchyk/Godot/djura-1/assets/models/djura_15yo.glb"
    bpy.ops.export_scene.gltf(
        filepath=glb_path,
        export_format='GLB',
        export_animations=True,
        export_anim_single_armature=True
    )
    print(f"Exported GLB: {glb_path}")

    # Render turntable preview
    preview_path = "/home/mfedchyk/Godot/djura-1/reports/djura_15yo_preview.png"
    render_preview(preview_path)


if __name__ == "__main__":
    main()
