extends Node3D

@onready var sun: DirectionalLight3D    = $Sun
@onready var world_env: WorldEnvironment = $WorldEnv

var _storm_mode: bool = false
var _base_sky_top    := Color(0.18, 0.48, 0.92)
var _base_sky_horiz  := Color(0.62, 0.79, 0.95)
var _storm_sky_top   := Color(0.12, 0.13, 0.18)
var _storm_sky_horiz := Color(0.22, 0.23, 0.28)

func set_storm_mode(enabled: bool) -> void:
	_storm_mode = enabled
	_apply_sky()

func _apply_sky() -> void:
	if not world_env or not world_env.environment:
		return
	var env := world_env.environment
	if env.sky and env.sky.sky_material is ProceduralSkyMaterial:
		var sky := env.sky.sky_material as ProceduralSkyMaterial
		sky.sky_top_color     = _storm_sky_top     if _storm_mode else _base_sky_top
		sky.sky_horizon_color = _storm_sky_horiz   if _storm_mode else _base_sky_horiz
	if sun:
		sun.light_energy = 0.2 if _storm_mode else 1.2
