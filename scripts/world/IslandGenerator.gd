extends Node3D

@export var island_size: int    = 200
@export var mesh_resolution: int = 96
@export var max_height: float   = 38.0
@export var water_level_norm: float = 0.42
@export var seed: int = 42

var _noise := FastNoiseLite.new()
var _heights: PackedFloat32Array
var _mesh_instance: MeshInstance3D
var _static_body: StaticBody3D

signal generation_done()

func _ready() -> void:
	if multiplayer.is_server() or not multiplayer.has_multiplayer_peer():
		generate(seed)

func generate(gen_seed: int) -> void:
	seed = gen_seed
	_setup_noise()
	_heights = _build_heights()
	_build_mesh()
	_build_collision()
	generation_done.emit()
	get_node("../ResourceSpawner").spawn_resources(_heights, mesh_resolution, island_size, max_height, water_level_norm, seed)

func _setup_noise() -> void:
	_noise.seed = seed
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.005
	_noise.fractal_octaves = 6
	_noise.fractal_lacunarity = 2.1
	_noise.fractal_gain = 0.48

func _build_heights() -> PackedFloat32Array:
	var h := PackedFloat32Array()
	h.resize(mesh_resolution * mesh_resolution)
	var half := island_size * 0.5
	var noise2 := FastNoiseLite.new()
	noise2.seed = seed + 999
	noise2.frequency = 0.02
	for z in mesh_resolution:
		for x in mesh_resolution:
			var wx := (float(x) / (mesh_resolution - 1) - 0.5) * island_size
			var wz := (float(z) / (mesh_resolution - 1) - 0.5) * island_size
			var n := (_noise.get_noise_2d(wx, wz) + 1.0) * 0.5
			var dist := Vector2(wx, wz).length() / half
			var mask := pow(clamp(1.0 - smoothstep(0.3, 0.82, dist), 0.0, 1.0), 1.3)
			var beach := (noise2.get_noise_2d(wx, wz) + 1.0) * 0.5 * 0.06
			h[z * mesh_resolution + x] = (n * mask + beach * mask) * max_height
	return h

func _build_mesh() -> void:
	if _mesh_instance:
		_mesh_instance.queue_free()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := float(island_size) / (mesh_resolution - 1)
	var half := island_size * 0.5
	for z in mesh_resolution:
		for x in mesh_resolution:
			var px := x * step - half
			var pz := z * step - half
			var py: float = _heights[z * mesh_resolution + x]
			var uv := Vector2(float(x) / (mesh_resolution - 1),
							  float(z) / (mesh_resolution - 1))
			st.set_uv(uv)
			st.set_uv2(Vector2(py / max_height, 0.0))
			st.add_vertex(Vector3(px, py, pz))
	for z in (mesh_resolution - 1):
		for x in (mesh_resolution - 1):
			var i := z * mesh_resolution + x
			st.add_index(i)
			st.add_index(i + mesh_resolution)
			st.add_index(i + 1)
			st.add_index(i + 1)
			st.add_index(i + mesh_resolution)
			st.add_index(i + mesh_resolution + 1)
	st.generate_normals()
	st.generate_tangents()
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = st.commit()
	_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var mat: Material = _create_terrain_material()
	_mesh_instance.material_override = mat
	add_child(_mesh_instance)

func _build_collision() -> void:
	if _static_body:
		_static_body.queue_free()

	_static_body = StaticBody3D.new()
	_static_body.collision_layer = 1
	_static_body.collision_mask = 1
	var col := CollisionShape3D.new()
	var shape := HeightMapShape3D.new()
	shape.map_width = mesh_resolution
	shape.map_depth = mesh_resolution
	shape.map_data = _heights
	col.shape = shape

	# Важно: масштабируем StaticBody3D, а не CollisionShape3D
	# (масштабирование CollisionShape3D часто приводит к проваливанию сквозь коллизию)
	var sf := float(island_size) / (mesh_resolution - 1)
	_static_body.scale = Vector3(sf, 1.0, sf)
	_static_body.position = Vector3(-island_size * 0.5, 0.0, -island_size * 0.5)

	_static_body.add_child(col)
	add_child(_static_body)

func _create_terrain_material() -> Material:
	var shader: Shader = load("res://assets/shaders/terrain.gdshader") as Shader
	if not shader:
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(0.3, 0.6, 0.2)
		sm.roughness = 0.9
		return sm
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("sand_color",  Color(0.93, 0.87, 0.6))
	mat.set_shader_parameter("grass_color", Color(0.28, 0.65, 0.2))
	mat.set_shader_parameter("rock_color",  Color(0.5, 0.45, 0.4))
	mat.set_shader_parameter("snow_color",  Color(0.95, 0.95, 0.98))
	mat.set_shader_parameter("water_line",  water_level_norm)
	mat.set_shader_parameter("max_height",  max_height)
	return mat

func get_height_at(world_pos: Vector2) -> float:
	if _heights.is_empty():
		return 0.0
	var half := island_size * 0.5
	var step := float(island_size) / (mesh_resolution - 1)
	var xi := int((world_pos.x + half) / step)
	var zi := int((world_pos.y + half) / step)
	xi = clamp(xi, 0, mesh_resolution - 1)
	zi = clamp(zi, 0, mesh_resolution - 1)
	return _heights[zi * mesh_resolution + xi]
