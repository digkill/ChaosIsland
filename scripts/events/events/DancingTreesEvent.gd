extends BaseEvent

var _dance_time: float = 0.0
var _trees: Array[Node3D] = []
var _original_rotations: Array[Vector3] = []

func _init() -> void:
	event_name = "TREES ARE DANCING!"
	description = "The forest found its groove. Unbelievable."
	icon = "🌴"
	duration = 25.0

func activate(world: Node) -> void:
	_dance_time = 0.0
	_trees.clear()
	_original_rotations.clear()
	var spawner: Node = world.get_node_or_null("ResourceSpawner")
	if spawner:
		for child in spawner.get_children():
			if "Tree" in child.name or "tree" in child.name:
				_trees.append(child)
				_original_rotations.append(child.rotation)
	# Подписаться на process через таймер (не блокируем process в событии)
	world.set_meta("dancing_trees_active", true)
	world.set_meta("dancing_trees_event", self)

func deactivate(world: Node) -> void:
	world.remove_meta("dancing_trees_active")
	world.remove_meta("dancing_trees_event")
	for i in _trees.size():
		if is_instance_valid(_trees[i]):
			_trees[i].rotation = _original_rotations[i]

func dance(delta: float) -> void:
	_dance_time += delta
	for i in _trees.size():
		if is_instance_valid(_trees[i]):
			_trees[i].rotation.y = sin(_dance_time * 3.0 + i * 0.5) * 0.4
			_trees[i].rotation.z = sin(_dance_time * 2.0 + i * 0.8) * 0.15
			_trees[i].position.y = _original_rotations[i].y + abs(sin(_dance_time * 4.0 + i)) * 0.5
