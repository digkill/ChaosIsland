extends Node3D

var _storm_active: bool = false
var _rain_particles: GPUParticles3D = null

func _ready() -> void:
	_build_rain()

func _build_rain() -> void:
	_rain_particles = GPUParticles3D.new()
	_rain_particles.amount = 2000
	_rain_particles.lifetime = 1.2
	_rain_particles.position = Vector3(0, 30, 0)
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.1, -1.0, 0.05)
	pm.spread = 180.0
	pm.initial_velocity_min = 20.0
	pm.initial_velocity_max = 28.0
	pm.gravity = Vector3(0, -9.8, 0)
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(80, 1, 80)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.85, 1.0, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_rain_particles.process_material = pm
	_rain_particles.emitting = false
	add_child(_rain_particles)

func start_storm() -> void:
	_storm_active = true
	if _rain_particles:
		_rain_particles.emitting = true

func stop_storm() -> void:
	_storm_active = false
	if _rain_particles:
		_rain_particles.emitting = false

func is_storming() -> bool:
	return _storm_active
