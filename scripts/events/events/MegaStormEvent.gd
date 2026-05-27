extends BaseEvent

func _init() -> void:
	event_name = "MEGA STORM!"
	description = "Wind, rain, chaos, and absolutely zero umbrellas."
	icon = "⛈️"
	duration = 35.0

func activate(world: Node) -> void:
	var weather: Node = world.get_node_or_null("WeatherSystem")
	if weather and weather.has_method("start_storm"):
		weather.start_storm()
	# Усиливаем силу ветра (толкаем игроков)
	for player in _get_players(world):
		if player.has_method("apply_wind"):
			player.apply_wind(Vector3(randf_range(-15, 15), 5, randf_range(-15, 15)))
	# Меняем освещение на мрачное
	var sky: Node = world.get_node_or_null("SkyEnvironment")
	if sky:
		sky.set_storm_mode(true)

func deactivate(world: Node) -> void:
	var weather: Node = world.get_node_or_null("WeatherSystem")
	if weather and weather.has_method("stop_storm"):
		weather.stop_storm()
	for player in _get_players(world):
		if player.has_method("apply_wind"):
			player.apply_wind(Vector3.ZERO)
	var sky: Node = world.get_node_or_null("SkyEnvironment")
	if sky:
		sky.set_storm_mode(false)
