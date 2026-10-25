"""
Cossack Toon Shader and Kyivnaukfilm Inverted Hull Outline Generator.
Follows SWR-003-02, ADR-003, and Invariant I-4.
Compatible with Blender 5.0.1+ (EEVEE Next).
"""

from typing import Optional, Tuple
import bpy


def get_or_create_ink_material(name: str = "M_Outline_Ink") -> bpy.types.Material:
    """Creates or returns an emissive black material with backface culling for Inverted Hull."""
    if name in bpy.data.materials:
        return bpy.data.materials[name]

    mat = bpy.data.materials.new(name=name)
    if hasattr(mat, "use_backface_culling"):
        mat.use_backface_culling = True

    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    emission = nodes.new('ShaderNodeEmission')
    emission.inputs['Color'].default_value = (0.01, 0.01, 0.01, 1.0)  # Pure deep black ink
    emission.inputs['Strength'].default_value = 1.0

    out = nodes.new('ShaderNodeOutputMaterial')
    links.new(emission.outputs['Emission'], out.inputs['Surface'])
    return mat


def convert_material_to_cel(mat: bpy.types.Material, num_bands: int = 3) -> None:
    """
    Transforms any standard PBR / Principled BSDF material into a stylized 3-tone Cel-shader
    using Shader to RGB and a Constant ColorRamp.
    """
    if not mat.node_tree:
        return

    nodes = mat.node_tree.nodes
    links = mat.node_tree.links

    # Find the output node
    out_node = next((n for n in nodes if n.type == 'OUTPUT_MATERIAL'), None)
    if not out_node:
        out_node = nodes.new('ShaderNodeOutputMaterial')

    # Look for existing principled BSDF or diffuse
    bsdf_node = next((n for n in nodes if 'BSDF' in n.type), None)
    if not bsdf_node:
        bsdf_node = nodes.new('ShaderNodeBsdfDiffuse')

    # Find any base color texture connected to BSDF
    base_color_link = None
    if 'Base Color' in bsdf_node.inputs and bsdf_node.inputs['Base Color'].links:
        base_color_link = bsdf_node.inputs['Base Color'].links[0].from_socket
    elif 'Color' in bsdf_node.inputs and bsdf_node.inputs['Color'].links:
        base_color_link = bsdf_node.inputs['Color'].links[0].from_socket

    # Extract base color value if no texture
    default_color = (0.8, 0.8, 0.8, 1.0)
    if 'Base Color' in bsdf_node.inputs:
        default_color = bsdf_node.inputs['Base Color'].default_value
    elif 'Color' in bsdf_node.inputs:
        default_color = bsdf_node.inputs['Color'].default_value

    # Create Shader to RGB
    s2rgb = nodes.new('ShaderNodeShaderToRGB')
    s2rgb.location = (bsdf_node.location.x + 220, bsdf_node.location.y)

    bsdf_output = bsdf_node.outputs.get('BSDF') or bsdf_node.outputs[0]
    links.new(bsdf_output, s2rgb.inputs['Shader'])

    # Create ColorRamp for light intensity steps
    ramp = nodes.new('ShaderNodeValToRGB')
    ramp.location = (s2rgb.location.x + 200, s2rgb.location.y)
    c_ramp = ramp.color_ramp
    c_ramp.interpolation = 'CONSTANT'

    # Set up 3 stepped tones: Shadow (0.4), Midtone (0.8), Highlight (1.0)
    c_ramp.elements[0].position = 0.0
    c_ramp.elements[0].color = (0.35, 0.35, 0.40, 1.0)  # Shadow with cool folklore tint
    c_ramp.elements[1].position = 0.35
    c_ramp.elements[1].color = (0.85, 0.85, 0.85, 1.0)  # Midtone

    if len(c_ramp.elements) < 3:
        elem_high = c_ramp.elements.new(0.85)
    else:
        elem_high = c_ramp.elements[2]
        elem_high.position = 0.85
    elem_high.color = (1.0, 1.0, 1.0, 1.0)  # Full highlight

    links.new(s2rgb.outputs['Color'], ramp.inputs['Fac'])

    # Multiply stepped lighting with base color / texture
    mix = nodes.new('ShaderNodeMix')
    mix.data_type = 'RGBA'
    mix.blend_type = 'MULTIPLY'
    mix.inputs['Factor'].default_value = 1.0
    mix.location = (ramp.location.x + 240, ramp.location.y)

    links.new(ramp.outputs['Color'], mix.inputs[6])  # Color A

    if base_color_link:
        links.new(base_color_link, mix.inputs[7])  # Color B
    else:
        mix.inputs[7].default_value = default_color

    # Connect to emission surface for crisp unlit cartoon look
    emission = nodes.new('ShaderNodeEmission')
    emission.location = (mix.location.x + 200, mix.location.y)
    links.new(mix.outputs[2], emission.inputs['Color'])

    links.new(emission.outputs['Emission'], out_node.inputs['Surface'])


def apply_inverted_hull(
    obj: bpy.types.Object,
    outline_mat: bpy.types.Material,
    thickness: float = 0.025,
) -> None:
    """
    Applies the Kyivnaukfilm Inverted Hull outline using a Solidify modifier
    with flipped normals and an emissive black material slot.
    """
    if obj.type != 'MESH':
        return

    # Add outline material to object slot if not present
    slot_idx = -1
    for i, slot in enumerate(obj.material_slots):
        if slot.material == outline_mat:
            slot_idx = i
            break

    if slot_idx == -1:
        obj.data.materials.append(outline_mat)
        slot_idx = len(obj.material_slots) - 1

    # Remove existing outline modifier if already present
    mod_name = "Kyivnaukfilm_Outline"
    existing_mod = obj.modifiers.get(mod_name)
    if existing_mod:
        obj.modifiers.remove(existing_mod)

    # Add Solidify modifier
    mod = obj.modifiers.new(name=mod_name, type='SOLIDIFY')
    mod.thickness = thickness
    mod.offset = 1.0  # Push outward along vertex normals
    mod.use_flip_normals = True
    mod.use_rim = False  # Avoid front caps
    mod.material_offset = slot_idx  # Route extruded shell to black outline material


def process_character_mesh(
    obj: bpy.types.Object,
    outline_mat: Optional[bpy.types.Material] = None,
    thickness: float = 0.025,
) -> None:
    """Processes a character mesh: converts all non-outline materials to cel-shading and applies Inverted Hull."""
    if obj.type != 'MESH':
        return

    if outline_mat is None:
        outline_mat = get_or_create_ink_material()

    # Convert existing materials
    for slot in obj.material_slots:
        if slot.material and slot.material != outline_mat:
            convert_material_to_cel(slot.material)

    # Apply Inverted Hull
    apply_inverted_hull(obj, outline_mat, thickness=thickness)


def process_character_hierarchy(
    root: bpy.types.Object,
    thickness: float = 0.025,
) -> None:
    """Recursively traverses object hierarchy to process all meshes."""
    outline_mat = get_or_create_ink_material()

    def _traverse(node: bpy.types.Object):
        if node.type == 'MESH':
            process_character_mesh(node, outline_mat, thickness)
        for child in node.children:
            _traverse(child)

    _traverse(root)
