extends BaseEvent

var _chickens: Array[RigidBody3D] = []
var _spawn_timer: SceneTreeTimer = null

func _init() -> void:
	event_name = "IT'S RAINING CHICKENS!"
	description = "The sky has gone full poultry mode."
	icon = "🐔"
	duration = 30.0

func activate(world: Node) -> void:
	_chickens.clear()
	_spawn_batch(world)

func _spawn_batch(world: Node) -> void:
	var container: Node = world.get_node_or_null("ItemsContainer")
	if not container:
		return
	for _i in 40:
		var chicken := _make_chicken()
		chicken.position = Vector3(
			randf_range(-50, 50),
			55.0 + randf_range(0, 20),
			randf_range(-50, 50))
		container.add_child(chicken, true)
		_chickens.append(chicken)

func _make_chicken() -> RigidBody3D:
	var rb := RigidBody3D.new()
	rb.gravity_scale = 0.3
	var mesh := MeshInstance3D.new()
	var m := SphereMesh.new()
	m.radius = 0.35
	m.height = 0.7
	mesh.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.2)
	mat.roughness = 0.8
	mesh.material_override = mat
	rb.add_child(mesh)
	var col := CollisionShape3D.new()
	col.shape = SphereShape3D.new()
	col.shape.radius = 0.35
	rb.add_child(col)
	# Имя для идентификации
	rb.name = "Chicken"
	return rb

func deactivate(_world: Node) -> void:
	for c in _chickens:
		if is_instance_valid(c):
			c.queue_free()
	_chickens.clear()
