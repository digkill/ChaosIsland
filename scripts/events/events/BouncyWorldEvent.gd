extends BaseEvent

var _bouncy_mat: PhysicsMaterial

func _init() -> void:
	event_name = "EVERYTHING IS BOUNCY!"
	description = "Physics? Never heard of her."
	icon = "🏀"
	duration = 30.0

func activate(world: Node) -> void:
	_bouncy_mat = PhysicsMaterial.new()
	_bouncy_mat.bounce = 0.95
	_bouncy_mat.rough = false
	_apply_to_buildings(world, _bouncy_mat)
	for player in _get_players(world):
		if player.has_method("set_jump_force"):
			player.set_jump_force(18.0)

func deactivate(world: Node) -> void:
	_apply_to_buildings(world, null)
	for player in _get_players(world):
		if player.has_method("set_jump_force"):
			player.set_jump_force(8.0)

func _apply_to_buildings(world: Node, mat) -> void:
	var container: Node = world.get_node_or_null("BuildingsContainer")
	if not container:
		return
	for node in container.get_children():
		if node is StaticBody3D:
			node.physics_material_override = mat
