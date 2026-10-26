#!/usr/bin/env python3
"""
Bakes high-quality 2D animated sprite sheet from assets/models/djura_meshy.glb
using skeletal rigging in Blender to produce real running, jumping, boxing strikes,
and authentic Cossack Victory Hopak (Переможний Гопак) animations.
"""

import os
_PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))  # корінь репозиторію (TLS-02)
import os
import sys
import math
import subprocess

def run():
    blend_script = """
import bpy, math, os, sys

bpy.ops.wm.read_factory_settings(use_empty=True)
glb_path = os.path.join(_PROJECT_ROOT, "sources", "models", "djura_meshy.glb")
bpy.ops.import_scene.gltf(filepath=glb_path)

m = bpy.data.objects.get("Mesh_0")
if not m:
    raise RuntimeError("Mesh_0 not found in djura_meshy.glb")

for mod in list(m.modifiers):
    m.modifiers.remove(mod)

# Convert material to pure flat cartoon Emission (zero 3D shadows, zero shaded sides)
if m.data.materials:
    mat = m.data.materials[0]
    nt = mat.node_tree
    base_tex_node = None
    for n in nt.nodes:
        if n.type == 'TEX_IMAGE' and 'Image Texture' == n.name:
            base_tex_node = n
            break
    if base_tex_node:
        output_node = [n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL'][0]
        for p in [n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED']:
            nt.nodes.remove(p)
        emit_node = nt.nodes.new(type='ShaderNodeEmission')
        emit_node.inputs['Strength'].default_value = 1.0
        nt.links.new(base_tex_node.outputs['Color'], emit_node.inputs['Color'])
        nt.links.new(emit_node.outputs['Emission'], output_node.inputs['Surface'])

# Create custom armature
bpy.ops.object.armature_add(enter_editmode=True, location=(0,0,0))
arm_obj = bpy.context.active_object
arm_data = arm_obj.data
bpy.ops.armature.select_all(action='SELECT')
bpy.ops.armature.delete()

root = arm_data.edit_bones.new('Root')
root.head = (0, 0, 0.0)
root.tail = (0, 0, 0.22)

spine = arm_data.edit_bones.new('Spine')
spine.head = (0, 0, 0.22)
spine.tail = (0, 0, 0.55)
spine.parent = root

head = arm_data.edit_bones.new('Head')
head.head = (0, 0, 0.55)
head.tail = (0, 0, 0.95)
head.parent = spine

arm_l = arm_data.edit_bones.new('Arm.L')
arm_l.head = (0.15, 0, 0.45)
arm_l.tail = (0.28, 0, 0.15)
arm_l.parent = spine

forearm_l = arm_data.edit_bones.new('ForeArm.L')
forearm_l.head = (0.28, 0, 0.15)
forearm_l.tail = (0.42, 0, -0.15)
forearm_l.parent = arm_l

arm_r = arm_data.edit_bones.new('Arm.R')
arm_r.head = (-0.15, 0, 0.45)
arm_r.tail = (-0.28, 0, 0.15)
arm_r.parent = spine

forearm_r = arm_data.edit_bones.new('ForeArm.R')
forearm_r.head = (-0.28, 0, 0.15)
forearm_r.tail = (-0.42, 0, -0.15)
forearm_r.parent = arm_r

thigh_l = arm_data.edit_bones.new('Thigh.L')
thigh_l.head = (0.10, 0, 0.0)
thigh_l.tail = (0.10, 0, -0.42)
thigh_l.parent = root

shin_l = arm_data.edit_bones.new('Shin.L')
shin_l.head = (0.10, 0, -0.42)
shin_l.tail = (0.10, 0, -0.95)
shin_l.parent = thigh_l

thigh_r = arm_data.edit_bones.new('Thigh.R')
thigh_r.head = (-0.10, 0, 0.0)
thigh_r.tail = (-0.10, 0, -0.42)
thigh_r.parent = root

shin_r = arm_data.edit_bones.new('Shin.R')
shin_r.head = (-0.10, 0, -0.42)
shin_r.tail = (-0.10, 0, -0.95)
shin_r.parent = thigh_r

bpy.ops.object.mode_set(mode='OBJECT')

m.parent = arm_obj
mod = m.modifiers.new(name='Armature', type='ARMATURE')
mod.object = arm_obj

bone_names = ['Root', 'Spine', 'Head', 'Arm.L', 'ForeArm.L', 'Arm.R', 'ForeArm.R', 'Thigh.L', 'Shin.L', 'Thigh.R', 'Shin.R']
vgroups = {name: m.vertex_groups.new(name=name) for name in bone_names}

for v in m.data.vertices:
    x, y, z = v.co.x, v.co.y, v.co.z
    idx = v.index
    if z < -0.42:
        if x >= 0:
            vgroups['Shin.L'].add([idx], 1.0, 'REPLACE')
        else:
            vgroups['Shin.R'].add([idx], 1.0, 'REPLACE')
    elif z < 0.0:
        if x >= 0:
            vgroups['Thigh.L'].add([idx], 1.0, 'REPLACE')
        else:
            vgroups['Thigh.R'].add([idx], 1.0, 'REPLACE')
    elif z >= 0.55:
        vgroups['Head'].add([idx], 1.0, 'REPLACE')
    else:
        if abs(x) > 0.15:
            if x > 0:
                if z < 0.15:
                    vgroups['ForeArm.L'].add([idx], 1.0, 'REPLACE')
                else:
                    vgroups['Arm.L'].add([idx], 1.0, 'REPLACE')
            else:
                if z < 0.15:
                    vgroups['ForeArm.R'].add([idx], 1.0, 'REPLACE')
                else:
                    vgroups['Arm.R'].add([idx], 1.0, 'REPLACE')
        elif z < 0.22:
            vgroups['Root'].add([idx], 1.0, 'REPLACE')
        else:
            vgroups['Spine'].add([idx], 1.0, 'REPLACE')

scene = bpy.context.scene
scene.render.engine = 'BLENDER_EEVEE'
scene.render.resolution_x = 128
scene.render.resolution_y = 128
scene.render.film_transparent = True
scene.render.image_settings.file_format = 'PNG'
scene.eevee.taa_render_samples = 8

cam_data = bpy.data.cameras.new(name='SpriteCam')
cam_data.type = 'ORTHO'
cam_data.ortho_scale = 2.02
cam = bpy.data.objects.new(name='SpriteCam', object_data=cam_data)
scene.collection.objects.link(cam)
scene.camera = cam
cam.location = (0, -3.5, 0.0)
cam.rotation_euler = (math.radians(90), 0, 0)

sun_data = bpy.data.lights.new(name='KeySun', type='SUN')
sun_data.energy = 5.0
sun = bpy.data.objects.new(name='KeySun', object_data=sun_data)
scene.collection.objects.link(sun)
sun.rotation_euler = (math.radians(45), math.radians(25), math.radians(35))

fill_data = bpy.data.lights.new(name='FillSun', type='SUN')
fill_data.energy = 2.5
fill = bpy.data.objects.new(name='FillSun', object_data=fill_data)
scene.collection.objects.link(fill)
fill.rotation_euler = (math.radians(45), math.radians(-40), math.radians(-110))

tmp_dir = os.path.join(_PROJECT_ROOT, "build", "render_tmp", "djura_smooth")
os.makedirs(tmp_dir, exist_ok=True)

bpy.ops.object.mode_set(mode='POSE')
pb = arm_obj.pose.bones
for b in pb:
    b.rotation_mode = 'XYZ'

def reset_pose():
    for b in pb:
        b.rotation_euler = (0, 0, 0)
        b.location = (0, 0, 0)
        b.scale = (1, 1, 1)
    arm_obj.rotation_euler = (0, 0, 0)
    arm_obj.location = (0, 0, 0)
    
    # Authentic cartoon proportions (billowing Cossack sharovary, broad chest & expressive head)
    pb['Thigh.L'].scale = (1.26, 1.15, 1.0)
    pb['Shin.L'].scale = (1.24, 1.15, 1.0)
    pb['Thigh.R'].scale = (1.26, 1.15, 1.0)
    pb['Shin.R'].scale = (1.24, 1.15, 1.0)
    pb['Root'].scale = (1.22, 1.10, 1.0)
    pb['Spine'].scale = (1.18, 1.08, 1.0)
    pb['Head'].scale = (1.16, 1.16, 1.16)
    pb['Arm.L'].scale = (1.12, 1.12, 1.0)
    pb['ForeArm.L'].scale = (1.12, 1.12, 1.0)
    pb['Arm.R'].scale = (1.12, 1.12, 1.0)
    pb['ForeArm.R'].scale = (1.12, 1.12, 1.0)

anims = {}

# 1. IDLE (8 frames) - Smooth breathing and subtle heroic pulse facing 3/4 right
anims["idle"] = []
for i in range(8):
    t = float(i) / 8.0 * math.tau
    b = math.sin(t)
    anims["idle"].append({
        "yaw": 30,
        "spine": -3.5 * b,
        "arm_l": -8.0 - 4.0 * b,
        "arm_r": 8.0 + 4.0 * b,
        "thigh_l": -2.0 * math.cos(t),
        "shin_l": 0.0,
        "thigh_r": 2.0 * math.cos(t),
        "shin_r": 0.0,
        "z": 0.015 * b
    })

# 2. RUN (10 frames) - Athletic Cossack sprint facing RIGHT with forward lean
anims["run"] = []
for i in range(10):
    t = float(i) / 10.0 * math.tau
    s = math.sin(t)
    # Forward sprint facing right:
    # Negative thigh angle swings leg forward (-Y, into movement direction)
    # Positive thigh angle pushes leg back (+Y)
    th_r = -44.0 * s
    sh_r = max(0.0, 52.0 * -s) + max(0.0, 16.0 * s)
    th_l = 44.0 * s
    sh_l = max(0.0, 52.0 * s) + max(0.0, 16.0 * -s)
    anims["run"].append({
        "yaw": 75,
        "spine": 14.0 + 2.0 * abs(s), # forward torso lean into the sprint
        "arm_r": 40.0 * s,            # counter-swinging arms (opposite to leg)
        "arm_l": -40.0 * s,
        "thigh_r": th_r,
        "shin_r": sh_r,
        "thigh_l": th_l,
        "shin_l": sh_l,
        "z": -0.02 * (1.0 - abs(s)) + 0.02 * abs(s)
    })

# 3. JUMP (8 frames) - Crouch -> Leap -> Apex -> Landing facing right
anims["jump"] = [
    {"yaw": 65, "spine": 16, "arm_l": 20, "arm_r": 20, "thigh_l": -32, "shin_l": 52, "thigh_r": -32, "shin_r": 52, "z": -0.05},
    {"yaw": 65, "spine": -6, "arm_l": -50, "arm_r": -50, "thigh_l": -45, "shin_l": 50, "thigh_r": -35, "shin_r": 40, "z": 0.04},
    {"yaw": 65, "spine": -9, "arm_l": -65, "arm_r": -65, "thigh_l": -58, "shin_l": 62, "thigh_r": -48, "shin_r": 52, "z": 0.07},
    {"yaw": 65, "spine": -7, "arm_l": -60, "arm_r": -60, "thigh_l": -50, "shin_l": 55, "thigh_r": -40, "shin_r": 45, "z": 0.08},
    {"yaw": 65, "spine": -3, "arm_l": -45, "arm_r": -45, "thigh_l": -35, "shin_l": 40, "thigh_r": -25, "shin_r": 30, "z": 0.09},
    {"yaw": 65, "spine": 0, "arm_l": -30, "arm_r": -30, "thigh_l": -22, "shin_l": 25, "thigh_r": -18, "shin_r": 20, "z": 0.06},
    {"yaw": 65, "spine": 5, "arm_l": -15, "arm_r": -15, "thigh_l": -12, "shin_l": 15, "thigh_r": -12, "shin_r": 15, "z": 0.02},
    {"yaw": 65, "spine": 12, "arm_l": 10, "arm_r": 10, "thigh_l": -22, "shin_l": 32, "thigh_r": -22, "shin_r": 32, "z": -0.02}
]

# 4. GLIDE (8 frames) - Aerodynamic flight with wing arms facing right
anims["glide"] = []
for i in range(8):
    t = float(i) / 8.0 * math.tau
    w = math.sin(t)
    anims["glide"].append({
        "yaw": 70,
        "spine": 25.0 + 3.0 * w,
        "arm_r": -78.0 + 6.0 * w,
        "arm_l": -78.0 - 6.0 * w,
        "thigh_r": -25.0 + 4.0 * math.cos(t),
        "shin_r": 16.0,
        "thigh_l": -28.0 - 4.0 * math.cos(t),
        "shin_l": 18.0,
        "z": 0.04 + 0.015 * w
    })

# 5. PUNCH (8 frames) - Boxing Steelhammer Jab / Straight Strike to the right
anims["punch"] = [
    {"yaw": 75, "spine": 0, "arm_l": 15, "arm_r": -20, "thigh_l": 5, "shin_l": 10, "thigh_r": -5, "shin_r": 5, "z": 0.0},
    {"yaw": 75, "spine": -5, "arm_l": 30, "arm_r": -30, "thigh_l": 8, "shin_l": 12, "thigh_r": -8, "shin_r": 8, "z": 0.01},
    {"yaw": 75, "spine": 10, "arm_l": -35, "arm_r": -45, "thigh_l": 15, "shin_l": 18, "thigh_r": -15, "shin_r": 12, "z": 0.0},
    {"yaw": 75, "spine": 14, "arm_l": -85, "arm_r": -50, "thigh_l": 25, "shin_l": 22, "thigh_r": -25, "shin_r": 20, "z": 0.01},
    {"yaw": 75, "spine": 15, "arm_l": -90, "arm_r": -52, "thigh_l": 28, "shin_l": 25, "thigh_r": -28, "shin_r": 22, "z": 0.02}, # Peak impact hold!
    {"yaw": 75, "spine": 10, "arm_l": -65, "arm_r": -45, "thigh_l": 20, "shin_l": 18, "thigh_r": -20, "shin_r": 15, "z": 0.01},
    {"yaw": 75, "spine": 5, "arm_l": -20, "arm_r": -30, "thigh_l": 10, "shin_l": 12, "thigh_r": -10, "shin_r": 10, "z": 0.0},
    {"yaw": 75, "spine": 0, "arm_l": 10, "arm_r": -15, "thigh_l": 0, "shin_l": 0, "thigh_r": 0, "shin_r": 0, "z": 0.0}
]

# 6. HOPAK_KICK (8 frames) - Martial Cossack Tynok / Shchupak Kick to the right
anims["hopak_kick"] = [
    {"yaw": 75, "spine": 8, "arm_l": -25, "arm_r": -25, "thigh_l": 10, "shin_l": 20, "thigh_r": -40, "shin_r": 60, "z": -0.02},
    {"yaw": 75, "spine": 5, "arm_l": -30, "arm_r": -20, "thigh_l": 15, "shin_l": 25, "thigh_r": -65, "shin_r": 75, "z": 0.01},
    {"yaw": 75, "spine": -12, "arm_l": -40, "arm_r": 30, "thigh_l": 20, "shin_l": 28, "thigh_r": 82, "shin_r": 25, "z": 0.05},
    {"yaw": 75, "spine": -16, "arm_l": -50, "arm_r": 40, "thigh_l": 25, "shin_l": 30, "thigh_r": 90, "shin_r": 0, "z": 0.08}, # Full 90-degree martial boot strike!
    {"yaw": 75, "spine": -18, "arm_l": -55, "arm_r": 45, "thigh_l": 26, "shin_l": 32, "thigh_r": 92, "shin_r": 0, "z": 0.08}, # Power impact hold!
    {"yaw": 75, "spine": -10, "arm_l": -35, "arm_r": 30, "thigh_l": 18, "shin_l": 22, "thigh_r": 65, "shin_r": 20, "z": 0.04},
    {"yaw": 75, "spine": 0, "arm_l": -20, "arm_r": -10, "thigh_l": 10, "shin_l": 15, "thigh_r": 35, "shin_r": 40, "z": 0.01},
    {"yaw": 75, "spine": 5, "arm_l": -20, "arm_r": -15, "thigh_l": 0, "shin_l": 5, "thigh_r": 0, "shin_r": 5, "z": 0.0}
]

# 7. VICTORY / HOPAK_DANCE (12 frames) - Authentic Cossack Victory Hopak (Присядка, Повзунець, Руки в боки, Стрибок)
anims["victory"] = [
    # 0: Pride stance
    {"yaw": 15, "spine": -6, "arm_l": -40, "arm_r": -40, "thigh_l": 0, "shin_l": 0, "thigh_r": 0, "shin_r": 0, "z": 0.01},
    # 1: Deep drop into Cossack squat (Присядка)
    {"yaw": 25, "spine": 15, "arm_l": 30, "arm_r": -30, "thigh_l": -75, "shin_l": 95, "thigh_r": -75, "shin_r": 95, "z": -0.14},
    # 2: Deep squat with arms crossed over chest
    {"yaw": 30, "spine": 18, "arm_l": -35, "arm_r": 35, "thigh_l": -80, "shin_l": 105, "thigh_r": -80, "shin_r": 105, "z": -0.16},
    # 3: ПОВЗУНЕЦЬ 1 - Right boot shoots straight out horizontally!
    {"yaw": 55, "spine": -10, "arm_l": 45, "arm_r": -45, "thigh_l": -75, "shin_l": 100, "thigh_r": 88, "shin_r": 0, "z": -0.13},
    # 4: Full extension hold of right boot
    {"yaw": 55, "spine": -12, "arm_l": 50, "arm_r": -50, "thigh_l": -75, "shin_l": 100, "thigh_r": 90, "shin_r": 0, "z": -0.13},
    # 5: Retract right boot back into squat
    {"yaw": 30, "spine": 16, "arm_l": -30, "arm_r": 30, "thigh_l": -80, "shin_l": 105, "thigh_r": -80, "shin_r": 105, "z": -0.15},
    # 6: ПОВЗУНЕЦЬ 2 - Left boot shoots straight out horizontally!
    {"yaw": 20, "spine": -10, "arm_l": -45, "arm_r": 45, "thigh_l": 88, "shin_l": 0, "thigh_r": -75, "shin_r": 100, "z": -0.13},
    # 7: Retract left boot back into squat
    {"yaw": 25, "spine": 16, "arm_l": -30, "arm_r": 30, "thigh_l": -80, "shin_l": 105, "thigh_r": -80, "shin_r": 105, "z": -0.15},
    # 8: Explosive upward leap from squat!
    {"yaw": 15, "spine": -10, "arm_l": -90, "arm_r": -90, "thigh_l": -30, "shin_l": 35, "thigh_r": -30, "shin_r": 35, "z": 0.06},
    # 9: Airborne triumph with arms raised high!
    {"yaw": 10, "spine": -15, "arm_l": -135, "arm_r": -135, "thigh_l": -15, "shin_l": 20, "thigh_r": 15, "shin_r": 20, "z": 0.08},
    # 10: Landing proudly with hands on hips («руки в боки»)!
    {"yaw": 10, "spine": -5, "arm_l": 65, "arm_r": -65, "thigh_l": 0, "shin_l": 5, "thigh_r": 0, "shin_r": 5, "z": 0.02},
    # 11: Cheerful victory smile & nod
    {"yaw": 10, "spine": 0, "arm_l": 60, "arm_r": -60, "thigh_l": 0, "shin_l": 0, "thigh_r": 0, "shin_r": 0, "z": 0.0}
]

# 8. BONK (8 frames) - Dizzy wobble and recovery
anims["bonk"] = [
    {"yaw": 25, "spine": -20, "arm_l": 45, "arm_r": -45, "thigh_l": -10, "shin_l": 10, "thigh_r": 10, "shin_r": 10, "z": -0.02},
    {"yaw": 30, "spine": -25, "arm_l": 55, "arm_r": -55, "thigh_l": -15, "shin_l": 15, "thigh_r": 15, "shin_r": 15, "z": -0.04},
    {"yaw": 35, "spine": 12, "arm_l": -35, "arm_r": 35, "thigh_l": 12, "shin_l": 18, "thigh_r": -12, "shin_r": 18, "z": -0.03},
    {"yaw": 35, "spine": 15, "arm_l": -40, "arm_r": 40, "thigh_l": 15, "shin_l": 20, "thigh_r": -15, "shin_r": 20, "z": -0.04},
    {"yaw": 15, "spine": -10, "arm_l": 30, "arm_r": -30, "thigh_l": -12, "shin_l": 18, "thigh_r": 12, "shin_r": 18, "z": -0.02},
    {"yaw": 15, "spine": -12, "arm_l": 35, "arm_r": -35, "thigh_l": -15, "shin_l": 20, "thigh_r": 15, "shin_r": 20, "z": -0.03},
    {"yaw": 25, "spine": 5, "arm_l": -10, "arm_r": 10, "thigh_l": 0, "shin_l": 5, "thigh_r": 0, "shin_r": 5, "z": -0.01},
    {"yaw": 30, "spine": 0, "arm_l": -5, "arm_r": 5, "thigh_l": 0, "shin_l": 0, "thigh_r": 0, "shin_r": 0, "z": 0.0}
]

# 9. FALL (8 frames) - Aerodynamic descent & falcon dive facing right
anims["fall"] = []
for i in range(8):
    t = float(i) / 8.0 * math.tau
    w = math.sin(t)
    anims["fall"].append({
        "yaw": 70,
        "spine": 12.0 + 2.0 * w,
        "arm_r": 28.0 + 4.0 * w,
        "arm_l": -28.0 - 4.0 * w,
        "thigh_r": 15.0 + 2.0 * math.cos(t),
        "shin_r": 10.0,
        "thigh_l": 18.0 - 2.0 * math.cos(t),
        "shin_l": 12.0,
        "z": 0.01 * w
    })

# 10. ROLL (8 frames) - Parkour tuck & 360-degree combat roll facing right
anims["roll"] = []
for i in range(8):
    ang = float(i) / 8.0 * 360.0
    anims["roll"].append({
        "yaw": 90,
        "roll": ang,
        "spine": 35.0,
        "arm_l": 60.0,
        "arm_r": -60.0,
        "thigh_l": -80.0,
        "shin_l": 110.0,
        "thigh_r": -80.0,
        "shin_r": 110.0,
        "z": -0.04
    })

frames_by_anim = {}
total_to_render = sum(len(f) for f in anims.values())
rendered_count = 0

print(f"Total animations: {len(anims)}, total frames to bake: {total_to_render}")

for anim_name, frames in anims.items():
    anim_dir = os.path.join(tmp_dir, anim_name)
    os.makedirs(anim_dir, exist_ok=True)
    frames_by_anim[anim_name] = []
    
    for idx, f in enumerate(frames):
        reset_pose()
        
        yaw = f.get("yaw", 0)
        pitch = f.get("pitch", 0)
        roll = f.get("roll", 0)
        arm_obj.rotation_euler = (math.radians(pitch), math.radians(roll), math.radians(yaw))
        arm_obj.location.z = f.get("z", 0.0)
        
        pb['Spine'].rotation_euler = (math.radians(f.get("spine", 0)), 0, 0)
        pb['Arm.L'].rotation_euler = (math.radians(f.get("arm_l", 0)), 0, 0)
        pb['ForeArm.L'].rotation_euler = (math.radians(f.get("arm_l", 0) * 0.75), 0, 0)
        pb['Arm.R'].rotation_euler = (math.radians(f.get("arm_r", 0)), 0, 0)
        pb['ForeArm.R'].rotation_euler = (math.radians(f.get("arm_r", 0) * 0.75), 0, 0)
        pb['Thigh.L'].rotation_euler = (math.radians(f.get("thigh_l", 0)), 0, 0)
        pb['Shin.L'].rotation_euler = (math.radians(f.get("shin_l", 0)), 0, 0)
        pb['Thigh.R'].rotation_euler = (math.radians(f.get("thigh_r", 0)), 0, 0)
        pb['Shin.R'].rotation_euler = (math.radians(f.get("shin_r", 0)), 0, 0)
        
        out_file = os.path.join(anim_dir, f"frame_{idx:04d}.png")
        scene.render.filepath = out_file
        bpy.ops.render.render(write_still=True)
        frames_by_anim[anim_name].append(out_file)
        rendered_count += 1
        print(f"[{rendered_count}/{total_to_render}] Rendered {anim_name} ({idx+1}/{len(frames)}) -> {out_file}")

print("All frames rendered successfully!")

# Pack into spritesheet
sys.path.insert(0, os.path.join(_PROJECT_ROOT, "tools", "blender"))
import pack_spritesheet

out_png = os.path.join(_PROJECT_ROOT, "assets", "sprites", "djura_sheet.png")
out_tres = os.path.join(_PROJECT_ROOT, "assets", "sprites", "djura_frames.tres")
out_json = os.path.join(_PROJECT_ROOT, "assets", "sprites", "djura_manifest.json")

pack_spritesheet.pack_spritesheet(
    frames_by_anim=frames_by_anim,
    output_png=out_png,
    output_tres=out_tres,
    output_json=out_json,
    frame_width=128,
    frame_height=128,
    fps=12,
    flip_horizontal=False,
    cartoon_fx=True
)
print("SUCCESS: Packed 70-frame animated Meshy Djura sheet, frames.tres and manifest.json!")
"""

    cmd = ["blender", "-b", "--python-expr", blend_script]
    subprocess.check_call(cmd)

if __name__ == "__main__":
    run()
