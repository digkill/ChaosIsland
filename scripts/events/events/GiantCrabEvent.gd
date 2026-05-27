extends BaseEvent

var _crab: Node3D = null

func _init() -> void:
	event_name = "GIANT CRAB ATTACK!"
	description = "He's big. He's angry. He's very crabby."
	icon = "🦀"
	duration = 45.0

func activate(world: Node) -> void:
	var container: Node = world.get_node_or_null("ItemsContainer")
	if not container:
		return
	_crab = _make_giant_crab()
	# Спавним на краю острова
	_crab.position = Vector3(60.0, 5.0, 0.0)
	container.add_child(_crab, true)

func _make_giant_crab() -> Node3D:
	var root := Node3D.new()
	root.name = "GiantCrab"
	# Тело краба
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(4.0, 1.5, 3.0)
	body.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.2, 0.1)
	mat.roughness = 0.6
	body.material_override = mat
	root.add_child(body)
	# Клешни
	for side in [-1, 1]:
		var claw := MeshInstance3D.new()
		var cm := BoxMesh.new()
		cm.size = Vector3(1.5, 1.0, 1.0)
		claw.mesh = cm
		claw.material_override = mat
		claw.position = Vector3(side * 3.2, 0.3, -1.2)
		root.add_child(claw)
	# Физика
	var rb := RigidBody3D.new()
	rb.name = "GiantCrabBody"
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(4.0, 1.5, 3.0)
	col.shape = shape
	rb.add_child(col)
	rb.add_child(root)
	rb.gravity_scale = 0.5
	return rb

func deactivate(_world: Node) -> void:
	if is_instance_valid(_crab):
		_crab.queue_free()
	_crab = null
