extends BaseEvent

func _init() -> void:
	event_name = "GRAVITY FLIP!"
	description = "Up is down. Down is up. Good luck."
	icon = "🙃"
	duration = 20.0

func activate(world: Node) -> void:
	for player in _get_players(world):
		if player.has_method("set_gravity_multiplier"):
			player.set_gravity_multiplier(-0.5)

func deactivate(world: Node) -> void:
	for player in _get_players(world):
		if player.has_method("set_gravity_multiplier"):
			player.set_gravity_multiplier(1.0)
