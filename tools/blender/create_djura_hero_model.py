"""
Generates the canonical 3D model of Djura (Джура) with armature and keyframed animations.
Follows Ukrainian Cossack folklore canon, SHR-004, SWR-003, and Invariant I-3 (Zero-Horror).
Compatible with Blender 5.0.1+.
"""

import math
import os
import bpy
import mathutils


def setup_materials():
    mats = {}

    # 1. White linen shirt (Vyshyvanka)
    m_white = bpy.data.materials.new("M_Vyshyvanka_White")
    m_white.use_nodes = True
    m_white.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.95, 0.95, 0.95, 1.0)
    mats["white"] = m_white

    # 2. Red embroidery / sash / boots
    m_red = bpy.data.materials.new("M_Cossack_Red")
    m_red.use_nodes = True
    m_red.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.85, 0.12, 0.12, 1.0)
    mats["red"] = m_red

    # 3. Gold belt / embroidery accent
    m_gold = bpy.data.materials.new("M_Cossack_Gold")
    m_gold.use_nodes = True
    m_gold.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.95, 0.80, 0.12, 1.0)
    mats["gold"] = m_gold

    # 4. Cobalt blue sharovary
    m_blue = bpy.data.materials.new("M_Sharovary_Blue")
    m_blue.use_nodes = True
    m_blue.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.12, 0.32, 0.85, 1.0)
    mats["blue"] = m_blue

    # 5. Skin tone (warm cartoon peach)
    m_skin = bpy.data.materials.new("M_Djura_Skin")
    m_skin.use_nodes = True
    m_skin.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.97, 0.82, 0.72, 1.0)
    mats["skin"] = m_skin

    # 6. Black hair (Oseledets / Eyebrows / Eyes)
    m_black = bpy.data.materials.new("M_Oseledets_Black")
    m_black.use_nodes = True
    m_black.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.04, 0.04, 0.04, 1.0)
    mats["black"] = m_black

    # 7. Saber steel
    m_steel = bpy.data.materials.new("M_Saber_Steel")
    m_steel.use_nodes = True
    m_steel.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.80, 0.85, 0.90, 1.0)
    mats["steel"] = m_steel

    return mats


def create_djura_character(out_glb_path: str):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    mats = setup_materials()

    # Create Armature
    arm_data = bpy.data.armatures.new("DjuraArmature")
    arm_obj = bpy.data.objects.new("DjuraRig", arm_data)
    scene.collection.objects.link(arm_obj)
    bpy.context.view_layer.objects.active = arm_obj

    # Define Bone Hierarchy in Edit Mode
    bpy.ops.object.mode_set(mode='EDIT')
    bones = arm_data.edit_bones

    root = bones.new("Root")
    root.head = (0, 0, 0)
    root.tail = (0, 0, 0.2)

    hips = bones.new("Hips")
    hips.head = (0, 0, 0.55)
    hips.tail = (0, 0, 0.75)
    hips.parent = root

    chest = bones.new("Chest")
    chest.head = (0, 0, 0.75)
    chest.tail = (0, 0, 1.15)
    chest.parent = hips

    head_b = bones.new("Head")
    head_b.head = (0, 0, 1.15)
    head_b.tail = (0, 0, 1.65)
    head_b.parent = chest

    chub_b = bones.new("Chub")
    chub_b.head = (0.1, 0, 1.60)
    chub_b.tail = (0.35, 0, 1.45)
    chub_b.parent = head_b

    # Arms
    arm_l = bones.new("Arm_L")
    arm_l.head = (-0.28, 0, 1.05)
    arm_l.tail = (-0.55, 0, 0.85)
    arm_l.parent = chest

    arm_r = bones.new("Arm_R")
    arm_r.head = (0.28, 0, 1.05)
    arm_r.tail = (0.55, 0, 0.85)
    arm_r.parent = chest

    # Legs (Sharovary & Feet)
    leg_l = bones.new("Leg_L")
    leg_l.head = (-0.22, 0, 0.55)
    leg_l.tail = (-0.22, 0, 0.10)
    leg_l.parent = hips

    foot_l = bones.new("Foot_L")
    foot_l.head = (-0.22, 0, 0.10)
    foot_l.tail = (-0.22, -0.22, 0.0)
    foot_l.parent = leg_l

    leg_r = bones.new("Leg_R")
    leg_r.head = (0.22, 0, 0.55)
    leg_r.tail = (0.22, 0, 0.10)
    leg_r.parent = hips

    foot_r = bones.new("Foot_R")
    foot_r.head = (0.22, 0, 0.10)
    foot_r.tail = (0.22, -0.22, 0.0)
    foot_r.parent = leg_r

    bpy.ops.object.mode_set(mode='OBJECT')

    # Helper function to parent mesh to a bone
    def parent_to_bone(obj, bone_name):
        obj.parent = arm_obj
        obj.parent_type = 'BONE'
        obj.parent_bone = bone_name

    # 1. Hips & Belt
    bpy.ops.mesh.primitive_cylinder_add(radius=0.28, depth=0.22, location=(0, 0, 0.65))
    sash_obj = bpy.context.active_object
    sash_obj.name = "Poyas_Sash"
    sash_obj.data.materials.append(mats["red"])
    parent_to_bone(sash_obj, "Hips")

    # Belt Buckle / Gold Knot
    bpy.ops.mesh.primitive_cube_add(size=0.10, location=(0, -0.28, 0.65))
    buckle = bpy.context.active_object
    buckle.name = "Poyas_Knot"
    buckle.data.materials.append(mats["gold"])
    parent_to_bone(buckle, "Hips")

    # Saber on hip
    bpy.ops.mesh.primitive_cylinder_add(radius=0.04, depth=0.65, location=(-0.30, -0.05, 0.55))
    saber = bpy.context.active_object
    saber.name = "Saber"
    saber.rotation_euler = (math.radians(25), math.radians(-15), 0)
    saber.data.materials.append(mats["steel"])
    parent_to_bone(saber, "Hips")

    # 2. Chest & Torso (White Vyshyvanka)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.28, depth=0.45, location=(0, 0, 0.95))
    chest_obj = bpy.context.active_object
    chest_obj.name = "Torso_Vyshyvanka"
    chest_obj.scale = (1.0, 0.85, 1.0)
    chest_obj.data.materials.append(mats["white"])
    parent_to_bone(chest_obj, "Chest")

    # Red Collar Embroidery
    bpy.ops.mesh.primitive_cylinder_add(radius=0.18, depth=0.12, location=(0, 0, 1.15))
    collar = bpy.context.active_object
    collar.name = "Collar_Red"
    collar.data.materials.append(mats["red"])
    parent_to_bone(collar, "Chest")

    # 3. Head & Oseledets
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.32, location=(0, 0, 1.45))
    head_obj = bpy.context.active_object
    head_obj.name = "Head_Djura"
    head_obj.data.materials.append(mats["skin"])
    parent_to_bone(head_obj, "Head")

    # Eyes (Left & Right cartoon eyes)
    for side, x in [("L", -0.11), ("R", 0.11)]:
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.06, location=(x, -0.28, 1.48))
        eye = bpy.context.active_object
        eye.name = f"Eye_{side}"
        eye.scale = (1.0, 0.4, 1.2)
        eye.data.materials.append(mats["black"])
        parent_to_bone(eye, "Head")

    # Eyebrows
    for side, x, rot in [("L", -0.12, 10), ("R", 0.12, -10)]:
        bpy.ops.mesh.primitive_cube_add(size=0.05, location=(x, -0.30, 1.58))
        brow = bpy.context.active_object
        brow.name = f"Eyebrow_{side}"
        brow.scale = (1.6, 0.4, 0.4)
        brow.rotation_euler = (0, 0, math.radians(rot))
        brow.data.materials.append(mats["black"])
        parent_to_bone(brow, "Head")

    # Cossack Oseledets (Curved tuft of black hair)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.07, depth=0.45, location=(0.18, 0, 1.62))
    chub_obj = bpy.context.active_object
    chub_obj.name = "Oseledets_Chub"
    chub_obj.rotation_euler = (0, math.radians(45), 0)
    chub_obj.data.materials.append(mats["black"])
    parent_to_bone(chub_obj, "Chub")

    # 4. Arms & Hands
    for side, bone_name, x_dir in [("L", "Arm_L", -1), ("R", "Arm_R", 1)]:
        # Upper sleeve (White Vyshyvanka)
        bpy.ops.mesh.primitive_cylinder_add(radius=0.12, depth=0.30, location=(x_dir * 0.42, 0, 0.95))
        sleeve = bpy.context.active_object
        sleeve.name = f"Sleeve_{side}"
        sleeve.rotation_euler = (0, math.radians(x_dir * -30), 0)
        sleeve.data.materials.append(mats["white"])
        parent_to_bone(sleeve, bone_name)

        # Red Cuff
        bpy.ops.mesh.primitive_cylinder_add(radius=0.10, depth=0.08, location=(x_dir * 0.52, 0, 0.88))
        cuff = bpy.context.active_object
        cuff.name = f"Cuff_{side}"
        cuff.rotation_euler = (0, math.radians(x_dir * -30), 0)
        cuff.data.materials.append(mats["red"])
        parent_to_bone(cuff, bone_name)

        # Hand (Fist / Palm)
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.09, location=(x_dir * 0.58, 0, 0.83))
        hand = bpy.context.active_object
        hand.name = f"Hand_{side}"
        hand.data.materials.append(mats["skin"])
        parent_to_bone(hand, bone_name)

    # 5. Wide Sharovary (Left and Right)
    for side, bone_name, x in [("L", "Leg_L", -0.22), ("R", "Leg_R", 0.22)]:
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.28, location=(x, 0, 0.38))
        sharovar = bpy.context.active_object
        sharovar.name = f"Sharovary_{side}"
        sharovar.scale = (1.1, 1.1, 1.45)
        sharovar.data.materials.append(mats["blue"])
        parent_to_bone(sharovar, bone_name)

    # 6. Red Boots (Choboty) touching Z=0
    for side, bone_name, x in [("L", "Foot_L", -0.22), ("R", "Foot_R", 0.22)]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.11, depth=0.18, location=(x, -0.06, 0.09))
        boot = bpy.context.active_object
        boot.name = f"Boot_{side}"
        boot.data.materials.append(mats["red"])
        parent_to_bone(boot, bone_name)

    # --------------------------------------------------------------------------
    # KEYFRAME ANIMATIONS
    # --------------------------------------------------------------------------
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode='POSE')
    pose_bones = arm_obj.pose.bones

    def create_action(name: str) -> bpy.types.Action:
        act = bpy.data.actions.new(name=name)
        if not arm_obj.animation_data:
            arm_obj.animation_data_create()
        arm_obj.animation_data.action = act
        return act

    def set_bone_key(bone_name: str, frame: int, loc=None, rot_euler=None):
        b = pose_bones[bone_name]
        b.rotation_mode = 'XYZ'
        if loc is not None:
            b.location = loc
            b.keyframe_insert(data_path="location", frame=frame)
        if rot_euler is not None:
            b.rotation_euler = [math.radians(deg) for deg in rot_euler]
            b.keyframe_insert(data_path="rotation_euler", frame=frame)

    # --------------------------------------------------------------------------
    # 1. Action: "idle" (8 frames)
    # Gentle breathing, rhythmic weight bounce and chub sway
    # --------------------------------------------------------------------------
    act_idle = create_action("idle")
    for f in range(1, 9):
        t = (f - 1) / 8.0 * 2 * math.pi
        bob = math.sin(t) * 0.03
        sway = math.cos(t) * 3.0
        chub_bob = math.sin(t - 0.5) * 8.0

        set_bone_key("Hips", f, loc=(0, 0, bob), rot_euler=(0, 0, sway * 0.5))
        set_bone_key("Chest", f, rot_euler=(0, 0, -sway * 0.3))
        set_bone_key("Head", f, rot_euler=(0, 0, sway * 0.4))
        set_bone_key("Chub", f, rot_euler=(0, chub_bob, 0))
        set_bone_key("Arm_L", f, rot_euler=(0, 0, 5 + bob * 50))
        set_bone_key("Arm_R", f, rot_euler=(0, 0, -5 - bob * 50))

    # --------------------------------------------------------------------------
    # 2. Action: "run" (8 frames)
    # Fast Cossack running stride, arms pumping, legs alternating
    # --------------------------------------------------------------------------
    act_run = create_action("run")
    for f in range(1, 9):
        t = (f - 1) / 8.0 * 2 * math.pi
        leg_l_angle = math.sin(t) * 35.0
        leg_r_angle = -leg_l_angle
        arm_l_angle = -math.sin(t) * 40.0
        arm_r_angle = -arm_l_angle
        bob_run = abs(math.sin(t)) * 0.06

        set_bone_key("Hips", f, loc=(0, 0, bob_run), rot_euler=(10, 0, math.sin(t) * 5))
        set_bone_key("Chest", f, rot_euler=(-5, 0, 0))
        set_bone_key("Leg_L", f, rot_euler=(leg_l_angle, 0, 0))
        set_bone_key("Leg_R", f, rot_euler=(leg_r_angle, 0, 0))
        set_bone_key("Arm_L", f, rot_euler=(arm_l_angle, 0, 0))
        set_bone_key("Arm_R", f, rot_euler=(arm_r_angle, 0, 0))
        set_bone_key("Chub", f, rot_euler=(-15, math.sin(t) * 12, 0))

    # --------------------------------------------------------------------------
    # 3. Action: "jump" (6 frames)
    # Crouch $\to$ explosive leap with tucked legs and raised arms
    # --------------------------------------------------------------------------
    act_jump = create_action("jump")
    jump_keys = [
        # Frame 1: Crouch anticipation
        (1, (0, 0, -0.10), (10, 0, 0), (25, 0, 0), (-15, 0, 0)),
        # Frame 2: Takeoff stretch
        (2, (0, 0, 0.15), (-10, 0, 0), (-10, 0, 0), (80, 0, 0)),
        # Frame 3: Apex tuck
        (3, (0, 0, 0.35), (0, 0, 0), (-35, 0, 0), (120, 0, 0)),
        # Frame 4: Apex float
        (4, (0, 0, 0.38), (0, 0, 0), (-40, 0, 0), (110, 0, 0)),
        # Frame 5: Descent prepare
        (5, (0, 0, 0.20), (5, 0, 0), (-20, 0, 0), (60, 0, 0)),
        # Frame 6: Landing compress
        (6, (0, 0, -0.05), (10, 0, 0), (15, 0, 0), (10, 0, 0)),
    ]
    for f, hip_loc, hip_rot, leg_rot, arm_rot in jump_keys:
        set_bone_key("Hips", f, loc=hip_loc, rot_euler=hip_rot)
        set_bone_key("Leg_L", f, rot_euler=leg_rot)
        set_bone_key("Leg_R", f, rot_euler=leg_rot)
        set_bone_key("Arm_L", f, rot_euler=arm_rot)
        set_bone_key("Arm_R", f, rot_euler=arm_rot)
        set_bone_key("Chub", f, rot_euler=(30, 0, 0) if f <= 3 else (-20, 0, 0))

    # --------------------------------------------------------------------------
    # 4. Action: "glide" (6 frames)
    # Arms spread wide like falcon wings, sharovary parachute billowing
    # --------------------------------------------------------------------------
    act_glide = create_action("glide")
    for f in range(1, 7):
        t = (f - 1) / 6.0 * 2 * math.pi
        bank = math.sin(t) * 6.0
        wing_flap = math.cos(t) * 8.0

        set_bone_key("Hips", f, loc=(0, 0, 0.20), rot_euler=(-20, bank, 0))
        set_bone_key("Chest", f, rot_euler=(-10, 0, 0))
        set_bone_key("Arm_L", f, rot_euler=(0, 0, 80 + wing_flap))
        set_bone_key("Arm_R", f, rot_euler=(0, 0, -80 - wing_flap))
        set_bone_key("Leg_L", f, rot_euler=(15, 0, -15))
        set_bone_key("Leg_R", f, rot_euler=(15, 0, 15))
        set_bone_key("Chub", f, rot_euler=(-25, 0, math.sin(t) * 15))

    # --------------------------------------------------------------------------
    # 5. Action: "hopak_kick" (8 frames)
    # Acrobatic Combat Hopak: low windup into explosive aerial split kick (щупак)
    # --------------------------------------------------------------------------
    act_hopak = create_action("hopak_kick")
    hopak_keys = [
        # Frame 1: Low crouch (присядка)
        (1, (0, 0, -0.22), (20, 0, 0), (60, 0, 0), (-60, 0, 0), (-20, 0, 0)),
        # Frame 2: Push off
        (2, (0, 0, -0.05), (10, 0, 0), (30, 0, 0), (-30, 0, 0), (20, 0, 0)),
        # Frame 3: Leap launch
        (3, (0, 0, 0.20), (0, 0, 0), (-30, 0, 0), (70, 0, 0), (60, 0, 0)),
        # Frame 4: Aerial split kick (Щупак peak)
        (4, (0, 0, 0.35), (-10, 0, 0), (-85, 0, 0), (85, 0, 0), (110, 0, 0)),
        # Frame 5: Hold kick peak
        (5, (0, 0, 0.32), (-10, 0, 0), (-80, 0, 0), (80, 0, 0), (105, 0, 0)),
        # Frame 6: Retract legs
        (6, (0, 0, 0.18), (0, 0, 0), (-30, 0, 0), (30, 0, 0), (50, 0, 0)),
        # Frame 7: Descent
        (7, (0, 0, 0.05), (10, 0, 0), (15, 0, 0), (-15, 0, 0), (10, 0, 0)),
        # Frame 8: Resolute stance
        (8, (0, 0, 0.0), (0, 0, 0), (0, 0, 0), (0, 0, 0), (0, 0, 0)),
    ]
    for f, h_loc, h_rot, leg_l_r, leg_r_r, arm_r in hopak_keys:
        set_bone_key("Hips", f, loc=h_loc, rot_euler=h_rot)
        set_bone_key("Leg_L", f, rot_euler=leg_l_r)
        set_bone_key("Leg_R", f, rot_euler=leg_r_r)
        set_bone_key("Arm_L", f, rot_euler=arm_r)
        set_bone_key("Arm_R", f, rot_euler=(-arm_r[0], arm_r[1], -arm_r[2]))
        set_bone_key("Chub", f, rot_euler=(-20 if f in (4, 5) else 15, 0, 0))

    # --------------------------------------------------------------------------
    # 6. Action: "bonk" (6 frames)
    # Slapstick comedic recoil, rubber bounce, zero horror (I-3)
    # --------------------------------------------------------------------------
    act_bonk = create_action("bonk")
    bonk_keys = [
        # Frame 1: Impact squish
        (1, (0, 0, -0.15), (0, 0, 0), (15, 0, 0), (15, 0, 0), (-60, 0, 0), (15, 0, 0)),
        # Frame 2: Shock recoil backward
        (2, (0, 0.12, 0.05), (-25, 0, 0), (-10, 0, 0), (-10, 0, 0), (-80, 0, 0), (-35, 0, 0)),
        # Frame 3: Flail arms
        (3, (0, 0.08, 0.02), (-15, 0, 0), (5, 0, 0), (5, 0, 0), (80, 0, 0), (20, 0, 0)),
        # Frame 4: Dizzied shake
        (4, (0, 0.02, -0.05), (5, 0, 0), (10, 0, 0), (10, 0, 0), (40, 0, 0), (-15, 0, 0)),
        # Frame 5: Shake head
        (5, (0, 0.0, -0.02), (0, 0, 0), (5, 0, 0), (5, 0, 0), (15, 0, 0), (10, 0, 0)),
        # Frame 6: Ready recovery
        (6, (0, 0, 0), (0, 0, 0), (0, 0, 0), (0, 0, 0), (0, 0, 0), (0, 0, 0)),
    ]
    for f, h_loc, h_rot, leg_l_r, leg_r_r, arm_r, chub_r in bonk_keys:
        set_bone_key("Hips", f, loc=h_loc, rot_euler=h_rot)
        set_bone_key("Leg_L", f, rot_euler=leg_l_r)
        set_bone_key("Leg_R", f, rot_euler=leg_r_r)
        set_bone_key("Arm_L", f, rot_euler=arm_r)
        set_bone_key("Arm_R", f, rot_euler=arm_r)
        set_bone_key("Chub", f, rot_euler=chub_r)

    # --------------------------------------------------------------------------
    # 7. Action: "victory" (8 frames)
    # Joyous victory dance, hands on hips $\to$ triumphant arm raise
    # --------------------------------------------------------------------------
    act_vic = create_action("victory")
    vic_keys = [
        (1, (0, 0, 0.0), (0, 0, 0), (0, 0, 0), (0, 0, 0), (0, 45, 30)),
        (2, (0, 0, -0.08), (10, 0, 0), (25, 0, 0), (25, 0, 0), (0, 45, 30)),
        (3, (0, 0, 0.15), (-5, 0, 0), (-15, 0, 0), (-15, 0, 0), (0, 0, 110)),
        (4, (0, 0, 0.28), (0, 0, 0), (-30, 0, -15), (-30, 0, 15), (0, 0, 140)),
        (5, (0, 0, 0.25), (0, 0, 0), (-25, 0, -10), (-25, 0, 10), (0, 0, 135)),
        (6, (0, 0, 0.10), (5, 0, 0), (-10, 0, 0), (-10, 0, 0), (0, 0, 120)),
        (7, (0, 0, -0.04), (8, 0, 0), (15, 0, 0), (15, 0, 0), (0, 30, 60)),
        (8, (0, 0, 0.0), (0, 0, 0), (0, 0, 0), (0, 0, 0), (0, 45, 30)),
    ]
    for f, h_loc, h_rot, leg_l_r, leg_r_r, arm_r in vic_keys:
        set_bone_key("Hips", f, loc=h_loc, rot_euler=h_rot)
        set_bone_key("Leg_L", f, rot_euler=leg_l_r)
        set_bone_key("Leg_R", f, rot_euler=leg_r_r)
        set_bone_key("Arm_L", f, rot_euler=arm_r)
        set_bone_key("Arm_R", f, rot_euler=(-arm_r[0], -arm_r[1], -arm_r[2]))
        set_bone_key("Head", f, rot_euler=(-10 if f in (4, 5) else 0, 0, 0))
        set_bone_key("Chub", f, rot_euler=(-25 if f in (4, 5) else 10, 0, 0))

    bpy.ops.object.mode_set(mode='OBJECT')

    # Export to GLB with all actions baked
    os.makedirs(os.path.dirname(os.path.abspath(out_glb_path)), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=out_glb_path,
        export_format='GLB',
        export_animations=True,
        export_anim_single_armature=True,
    )
    print(f"Djura hero 3D model with 7 actions exported to: {out_glb_path}")

    # Also save native .blend file for direct viewing/editing in Blender
    blend_path = os.path.splitext(out_glb_path)[0] + ".blend"
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    print(f"Native Blender scene saved to: {blend_path}")


if __name__ == "__main__":
    out_path = os.path.abspath("/home/mfedchyk/Godot/djura-1/assets/models/djura_hero.glb")
    create_djura_character(out_path)
