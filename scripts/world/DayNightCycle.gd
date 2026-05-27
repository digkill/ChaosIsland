class_name DayNightCycle
extends Node

@export var day_duration: float = 600.0  # секунд на полный цикл
@export var start_time: float = 0.3      # 0=полночь, 0.25=рассвет, 0.5=полдень

@onready var sun: DirectionalLight3D = get_parent().get_node("SkyEnvironment/Sun")
@onready var env_node: WorldEnvironment = get_parent().get_node("SkyEnvironment/WorldEnv")

var time_of_day: float = 0.3  # 0..1

func _process(delta: float) -> void:
	time_of_day = fmod(time_of_day + delta / day_duration, 1.0)
	_update_lighting()

func _update_lighting() -> void:
	# Угол солнца: 0.25 = восход, 0.5 = зенит, 0.75 = закат
	var sun_angle: float = (time_of_day - 0.25) * TAU
	if sun:
		sun.rotation_degrees.x = -90.0 + sin(sun_angle) * 90.0
		sun.rotation_degrees.y = cos(sun_angle) * 45.0
		# Яркость
		var brightness: float = clamp(sin(sun_angle), 0.0, 1.0)
		sun.light_energy = lerp(0.0, 1.8, brightness)
		# Цвет заката
		var t: float = clamp(1.0 - brightness * 2.0, 0.0, 1.0)
		sun.light_color = Color(1.0, lerp(1.0, 0.4, t), lerp(1.0, 0.1, t))
	# Освещение окружения
	if env_node and env_node.environment:
		var env: Environment = env_node.environment
		var day_factor: float = clamp(sin(sun_angle) * 1.5, 0.0, 1.0)
		var sky_color_top: Color = Color(0.05, 0.07, 0.25).lerp(Color(0.2, 0.5, 0.9),  day_factor)
		var sky_color_horiz: Color = Color(0.05, 0.05, 0.15).lerp(Color(0.6, 0.75, 0.95), day_factor)
		env.sky_custom_fov = 0
		# Ambient
		env.ambient_light_energy = lerp(0.05, 0.35, day_factor)

func get_time_string() -> String:
	var hours := int(time_of_day * 24.0)
	var minutes := int((time_of_day * 24.0 - hours) * 60.0)
	return "%02d:%02d" % [hours, minutes]

func is_daytime() -> bool:
	return time_of_day > 0.22 and time_of_day < 0.78
