extends Node3D

# Спавн деревьев, камней и подбираемых предметов на острове

func spawn_resources(
	heights: PackedFloat32Array,
	resolution: int,
	island_size: int,
	max_height: float,
	water_norm: float,
	gen_seed: int
) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = gen_seed + 77
	var half := island_size * 0.5
	var _step := float(island_size) / (resolution - 1)
	var water_h := water_norm * max_height
	# Деревья
	for _i in 500:
		var rx := rng.randf_range(-half * 0.85, half * 0.85)
		var rz := rng.randf_range(-half * 0.85, half * 0.85)
		var h := _sample_height(heights, resolution, island_size, rx, rz)
		if h > water_h + 0.8 and h < max_height * 0.72:
			var tree := _make_tree(rng)
			tree.position = Vector3(rx, h, rz)
			tree.rotation.y = rng.randf() * TAU
			add_child(tree)
	# Камни
	for _i in 200:
		var rx := rng.randf_range(-half * 0.8, half * 0.8)
		var rz := rng.randf_range(-half * 0.8, half * 0.8)
		var h := _sample_height(heights, resolution, island_size, rx, rz)
		if h > water_h + 0.3:
			var rock := _make_rock(rng)
			rock.position = Vector3(rx, h - 0.3, rz)
			add_child(rock)
	# Кокосы на земле
	for _i in 80:
		var rx := rng.randf_range(-half * 0.7, half * 0.7)
		var rz := rng.randf_range(-half * 0.7, half * 0.7)
		var h := _sample_height(heights, resolution, island_size, rx, rz)
		if h > water_h + 0.5:
			var coconut := _make_pickup("coconut", rng)
			coconut.position = Vector3(rx, h + 0.5, rz)
			add_child(coconut)

func _sample_height(heights: PackedFloat32Array, res: int, size: int, wx: float, wz: float) -> float:
	var half: float = size * 0.5
	var step: float = float(size) / (res - 1)
	var xi: int = clamp(int((wx + half) / step), 0, res - 1)
	var zi: int = clamp(int((wz + half) / step), 0, res - 1)
	return heights[zi * res + xi]

func _make_tree(rng: RandomNumberGenerator) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.name = "Tree"
	# Ствол
	var trunk_mesh := MeshInstance3D.new()
	var tcyl := CylinderMesh.new()
	var trunk_scale := rng.randf_range(0.7, 1.3)
	tcyl.top_radius = 0.2 * trunk_scale
	tcyl.bottom_radius = 0.28 * trunk_scale
	tcyl.height = 3.5 * trunk_scale
	trunk_mesh.mesh = tcyl
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.55, 0.35, 0.18)
	trunk_mat.roughness = 0.9
	trunk_mesh.material_override = trunk_mat
	trunk_mesh.position.y = tcyl.height * 0.5
	sb.add_child(trunk_mesh)
	# Листва
	var leaves_mesh := MeshInstance3D.new()
	var lsph := SphereMesh.new()
	lsph.radius = 1.8 * trunk_scale
	lsph.height = 2.6 * trunk_scale
	leaves_mesh.mesh = lsph
	var leaves_mat := StandardMaterial3D.new()
	var green_tint := rng.randf_range(0.0, 0.15)
	leaves_mat.albedo_color = Color(0.15 + green_tint, 0.65, 0.18 + green_tint)
	leaves_mat.roughness = 0.8
	leaves_mesh.material_override = leaves_mat
	leaves_mesh.position.y = tcyl.height + lsph.radius * 0.5
	sb.add_child(leaves_mesh)
	# Коллизия — капсула
	var col := CollisionShape3D.new()
	var cs := CapsuleShape3D.new()
	cs.radius = 0.3 * trunk_scale
	cs.height = 3.2 * trunk_scale
	col.shape = cs
	col.position.y = tcyl.height * 0.5
	sb.add_child(col)
	# Метаданные для вырубки
	sb.set_meta("resource_type", "wood")
	sb.set_meta("resource_count", int(rng.randf_range(2, 5)))
	return sb

func _make_rock(rng: RandomNumberGenerator) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.name = "Rock"
	var mesh := MeshInstance3D.new()
	var sm := SphereMesh.new()
	var rock_scale := rng.randf_range(0.4, 1.2)
	sm.radius = rock_scale
	sm.height = rock_scale * rng.randf_range(0.5, 1.0)
	mesh.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(
		rng.randf_range(0.4, 0.6),
		rng.randf_range(0.38, 0.52),
		rng.randf_range(0.36, 0.5))
	mat.roughness = 0.95
	mesh.material_override = mat
	sb.add_child(mesh)
	var col := CollisionShape3D.new()
	var cs := SphereShape3D.new()
	cs.radius = rock_scale
	col.shape = cs
	sb.add_child(col)
	sb.set_meta("resource_type", "stone")
	sb.set_meta("resource_count", int(rng.randf_range(1, 4)))
	return sb

func _make_pickup(item_id: String, _rng: RandomNumberGenerator) -> Area3D:
	var area := Area3D.new()
	area.name = "Pickup_" + item_id
	area.set_meta("item_id", item_id)
	area.set_meta("item_count", 1)
	var mesh := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.25
	sm.height = 0.5
	mesh.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.7, 0.3)
	mesh.material_override = mat
	area.add_child(mesh)
	var col := CollisionShape3D.new()
	var cs := SphereShape3D.new()
	cs.radius = 0.4
	col.shape = cs
	area.add_child(col)
	return area
