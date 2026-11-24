"""Create the original Momo raincoat character in Blender and export GLB for Godot."""
import math
from pathlib import Path

import bpy
import bmesh
from mathutils import Vector


HERE = Path(__file__).resolve().parent
MODEL_OBJECTS = []


def track(obj):
    MODEL_OBJECTS.append(obj)
    return obj


def material(name, color, roughness=0.65, metallic=0.0, emission=None, strength=0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1.0)
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Metallic"].default_value = metallic
    if emission is not None:
        shader.inputs["Emission Color"].default_value = (*emission, 1.0)
        shader.inputs["Emission Strength"].default_value = strength
    return mat


COAT = material("Raincoat | honey ochre", (0.66, 0.31, 0.055), 0.76)
COAT_HI = material("Raincoat | stitched golden edge", (0.92, 0.58, 0.14), 0.69)
COAT_DARK = material("Raincoat | warm shaded panels", (0.43, 0.19, 0.035), 0.78)
LEATHER = material("Satchel | worn chestnut leather", (0.18, 0.075, 0.035), 0.76)
LEATHER_HI = material("Boots | soft dark leather", (0.095, 0.045, 0.028), 0.71)
BRASS = material("Lantern | brushed brass", (0.52, 0.29, 0.075), 0.32, 0.72)
GLASS = material("Lantern | warm glowing glass", (0.98, 0.56, 0.15), 0.23, 0.0, (1.0, 0.32, 0.045), 3.0)
FACE = material("Face | quiet warm shadow", (0.047, 0.025, 0.022), 0.92)
EYE = material("Eyes | soft amber glint", (0.42, 0.23, 0.08), 0.3, 0.12)
SOCK = material("Wool socks", (0.72, 0.64, 0.48), 0.94)


def assign(obj, mat):
    obj.data.materials.append(mat)
    return obj


def smooth(obj):
    if obj.type == "MESH":
        for face in obj.data.polygons:
            face.use_smooth = True
    return obj


def sphere(name, location, scale, mat, segments=40, rings=28):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=location)
    obj = track(bpy.context.object)
    obj.name = name
    obj.scale = scale
    assign(obj, mat)
    smooth(obj)
    return obj


def cylinder_between(name, a, b, radius_a, radius_b, mat, vertices=24):
    a, b = Vector(a), Vector(b)
    direction = b - a
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius_a, radius2=radius_b,
                                    depth=direction.length, location=(a + b) * 0.5)
    obj = track(bpy.context.object)
    obj.name = name
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(direction.normalized())
    assign(obj, mat)
    smooth(obj)
    return obj


def curve(name, points, mat, bevel=0.012, cyclic=False):
    data = bpy.data.curves.new(name, "CURVE")
    data.dimensions = "3D"
    data.resolution_u = 12
    data.bevel_depth = bevel
    data.bevel_resolution = 3
    spline = data.splines.new("BEZIER")
    spline.bezier_points.add(len(points) - 1)
    for point, coordinate in zip(spline.bezier_points, points):
        point.co = coordinate
        point.handle_left_type = "AUTO"
        point.handle_right_type = "AUTO"
    spline.use_cyclic_u = cyclic
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    track(obj)
    data.materials.append(mat)
    return obj


def coat_mesh():
    # A gently scalloped, multi-ring rain cape with enough folds to catch the light.
    rings = [
        (0.24, 0.61, 0.35), (0.34, 0.66, 0.38), (0.50, 0.56, 0.34),
        (0.76, 0.46, 0.30), (1.02, 0.37, 0.27), (1.23, 0.31, 0.245),
        (1.39, 0.26, 0.22),
    ]
    segments = 64
    vertices, faces = [], []
    for ring_index, (z, rx, ry) in enumerate(rings):
        for j in range(segments):
            angle = (2 * math.pi * j / segments) + math.pi / 2
            fold = 0.023 * math.cos(angle * 9.0 + 0.4) + 0.009 * math.cos(angle * 17.0)
            flare = 0.035 * math.cos(angle * 7.0 + 0.7) if ring_index < 2 else 0.0
            factor = 1.0 + fold + flare
            zz = z + (0.035 * math.cos(angle * 8.0) if ring_index == 0 else 0.0)
            vertices.append((math.cos(angle) * rx * factor, math.sin(angle) * ry * factor, zz))
    for i in range(len(rings) - 1):
        for j in range(segments):
            a = i * segments + j
            b = i * segments + (j + 1) % segments
            faces.append((a, b, b + segments, a + segments))
    mesh = bpy.data.meshes.new("Cape | softly folded mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(COAT)
    mesh.materials.append(COAT_DARK)
    obj = bpy.data.objects.new("Momo | sculpted rain cape", mesh)
    bpy.context.collection.objects.link(obj)
    track(obj)
    for polygon in mesh.polygons:
        polygon.use_smooth = True
        # Narrow shaded panels add cloth depth without painted texture maps.
        center = polygon.center
        if int((math.atan2(center.y, center.x) + math.pi) * 8) % 5 == 0:
            polygon.material_index = 1
    solid = obj.modifiers.new("Soft cloth thickness", "SOLIDIFY")
    solid.thickness = 0.025
    solid.offset = -0.2
    return obj


def star_mesh(location, outer=0.112, inner=0.046, mat=BRASS):
    verts = []
    for i in range(10):
        angle = math.pi / 2 + i * math.pi / 5
        radius = outer if i % 2 == 0 else inner
        verts.append((math.cos(angle) * radius, 0.0, math.sin(angle) * radius))
    faces = [(0, i, i + 1) for i in range(1, 9)]
    mesh = bpy.data.meshes.new("Five point star")
    mesh.from_pydata(verts, [], faces)
    obj = bpy.data.objects.new("Little brass star", mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = location
    track(obj)
    assign(obj, mat)
    solid = obj.modifiers.new("Cast star edge", "SOLIDIFY")
    solid.thickness = 0.035
    bevel = obj.modifiers.new("Polished star bevel", "BEVEL")
    bevel.width = 0.012
    bevel.segments = 3
    return obj


def make_character():
    coat_mesh()

    # Folded shoulder mantle and oversized hood frame the softly shadowed face.
    mantle = sphere("Momo | shoulder capelet", (0, -0.005, 1.28), (0.38, 0.30, 0.23), COAT_HI)
    hood = sphere("Momo | oversized soft hood", (0, 0.035, 1.58), (0.435, 0.405, 0.49), COAT)
    hood_opening = sphere("Momo | dark hood opening", (0, -0.290, 1.49), (0.285, 0.155, 0.32), FACE)
    face = sphere("Momo | face in lantern light", (0, -0.365, 1.45), (0.205, 0.075, 0.205), material("Face | warm skin", (0.38, 0.19, 0.095), 0.82))
    # Hood brim and seam are raised cords that catch the amber key light.
    brim = []
    for i in range(17):
        t = i / 16.0
        x = -0.36 + 0.72 * t
        y = -0.342 + 0.055 * abs(2 * t - 1)
        z = 1.42 - 0.17 * math.sin(math.pi * t)
        brim.append((x, y, z))
    curve("Hood | padded opening seam", brim, COAT_HI, 0.026)

    # Two subtle amber eyes beneath the hood; friendly and readable at small scale.
    for side in (-1, 1):
        sphere("Momo | eye glimmer", (side * 0.075, -0.438, 1.48), (0.026, 0.014, 0.038), EYE, 20, 12)

    # Soft sleeves and mittens. One hand carries the little brass lantern.
    for side in (-1, 1):
        shoulder = (side * 0.29, -0.01, 1.20)
        elbow = (side * 0.48, -0.07, 0.86)
        wrist = (side * (0.54 if side < 0 else 0.64), -0.13, 0.71 if side < 0 else 0.83)
        cylinder_between("Momo | raincoat sleeve", shoulder, elbow, 0.17, 0.135, COAT_HI)
        cylinder_between("Momo | gathered cuff", elbow, wrist, 0.14, 0.105, COAT)
        sphere("Momo | mitten", wrist, (0.115, 0.105, 0.105), material("Mittens | warm wool", (0.55, 0.30, 0.16), 0.88))

    # Wool leggings and rounded, lace-up boots sit below the scalloped cape.
    for side in (-1, 1):
        x = side * 0.205
        cylinder_between("Momo | wool leg", (x, 0.015, 0.36), (x, -0.01, 0.18), 0.115, 0.095, SOCK)
        sphere("Momo | leather boot", (x, -0.08, 0.105), (0.16, 0.26, 0.11), LEATHER_HI)
        sphere("Momo | boot toe", (x, -0.24, 0.105), (0.15, 0.13, 0.09), LEATHER)
        for lace in range(3):
            z = 0.12 + lace * 0.045
            curve("Boot | waxed lace", [(x - 0.075, -0.323, z), (x, -0.34, z + 0.025), (x + 0.075, -0.323, z)], BRASS, 0.008)

    # A tiny crossbody pouch and strap keep the silhouette tactile and story-ready.
    curve("Satchel | crossbody strap", [(-0.23, -0.265, 1.30), (-0.30, -0.30, 1.07), (-0.38, -0.34, 0.80), (-0.39, -0.33, 0.63)], LEATHER, 0.046)
    sphere("Satchel | rounded leather bag", (-0.40, -0.235, 0.71), (0.19, 0.13, 0.19), LEATHER)
    sphere("Satchel | brass clasp", (-0.40, -0.373, 0.71), (0.035, 0.018, 0.04), BRASS, 20, 12)
    star_mesh((0.17, -0.356, 1.12), 0.095, 0.04)

    # Lantern: individual metal frame, glass body, crown, loop and tiny bail.
    lx, ly, lz = 0.74, -0.14, 0.78
    cylinder_between("Lantern | lower foot", (lx, ly, lz - 0.16), (lx, ly, lz - 0.125), 0.13, 0.105, BRASS)
    sphere("Lantern | luminous glass", (lx, ly, lz), (0.095, 0.095, 0.13), GLASS)
    cylinder_between("Lantern | upper crown", (lx, ly, lz + 0.12), (lx, ly, lz + 0.19), 0.10, 0.045, BRASS)
    curve("Lantern | carry loop", [(lx - 0.075, ly, lz + 0.18), (lx - 0.08, ly, lz + 0.34), (lx, ly, lz + 0.41), (lx + 0.08, ly, lz + 0.34), (lx + 0.075, ly, lz + 0.18)], BRASS, 0.017)
    for side in (-1, 1):
        cylinder_between("Lantern | brass guard", (lx + side * 0.12, ly, lz - 0.115), (lx + side * 0.095, ly, lz + 0.12), 0.012, 0.012, BRASS, 12)
    # Warm lantern light is a visible emissive GLB material plus polished framing.


def create_studio():
    world = bpy.data.worlds.new("Midnight teal studio") if not bpy.data.worlds else bpy.data.worlds[0]
    bpy.context.scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.018, 0.055, 0.064, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.24
    bpy.ops.object.camera_add(location=(3.4, -6.4, 2.55))
    camera = bpy.context.object
    camera.name = "Studio Camera | Momo portrait"
    target = Vector((0, 0, 1.10))
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 3.02
    bpy.context.scene.camera = camera
    for name, location, energy, size, color in [
        ("Key | warm softbox", (3.0, -4.0, 5.5), 430, 4.0, (1.0, 0.74, 0.43)),
        ("Fill | moon teal", (-3.2, -1.8, 2.5), 280, 3.2, (0.30, 0.72, 0.78)),
        ("Rim | lantern gold", (0.4, 2.4, 4.3), 520, 2.0, (1.0, 0.49, 0.17)),
    ]:
        bpy.ops.object.light_add(type="AREA", location=location)
        light = bpy.context.object
        light.name = name
        light.data.energy = energy
        light.data.shape = "DISK"
        light.data.size = size
        light.data.color = color
        light.rotation_euler = (Vector((0, 0, 1.0)) - light.location).to_track_quat("-Z", "Y").to_euler()
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 40
    scene.render.resolution_x = 720
    scene.render.resolution_y = 900
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.view_settings.view_transform = "AgX"
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(HERE.parent / "momo-blender-preview.png")


def main():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    make_character()
    create_studio()
    scene = bpy.context.scene
    # Save an editable native project with the model, camera, materials, and lighting.
    bpy.ops.wm.save_as_mainfile(filepath=str(HERE / "momo.blend"))
    # Export only the character mesh collection as a runtime-ready glTF binary.
    bpy.ops.object.select_all(action="DESELECT")
    for obj in MODEL_OBJECTS:
        if obj.name in bpy.data.objects:
            obj.select_set(True)
    bpy.context.view_layer.objects.active = MODEL_OBJECTS[0]
    bpy.ops.export_scene.gltf(
        filepath=str(HERE / "momo.glb"),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_materials="EXPORT",
        export_texcoords=True,
        export_normals=True,
    )
    # Keep an inspectable, transparent preview render with the editable source.
    scene.render.resolution_percentage = 82
    scene.cycles.samples = 24
    bpy.ops.render.render(write_still=True)
    print("Created", HERE / "momo.blend", HERE / "momo.glb")


if __name__ == "__main__":
    main()
