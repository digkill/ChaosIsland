extends Node3D

# Корневой скрипт GameWorld — инициализирует окружение и координирует старт

func _ready() -> void:
	_setup_environment()
	_setup_water()
	_setup_spawners()
	_attach_weather_script()
	# Seed устанавливается через set_meta до add_child в Main.gd
	var gen_seed: int = int(get_meta("island_seed", 42))
	var gen: Node = $IslandGenerator
	gen.generation_done.connect(_on_generation_done, CONNECT_ONE_SHOT)
	gen.generate(gen_seed)

func _on_generation_done() -> void:
	await get_tree().create_timer(0.3).timeout
	_spawn_local_player()

func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var proc_sky := ProceduralSkyMaterial.new()
	proc_sky.sky_top_color       = Color(0.18, 0.48, 0.92)
	proc_sky.sky_horizon_color   = Color(0.62, 0.79, 0.95)
	proc_sky.ground_bottom_color  = Color(0.18, 0.32, 0.15)
	proc_sky.ground_horizon_color = Color(0.53, 0.62, 0.42)
	sky.sky_material = proc_sky
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.3
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.1
	env.glow_enabled = true
	env.glow_intensity = 0.4
	$SkyEnvironment/WorldEnv.environment = env

func _setup_water() -> void:
	var water: MeshInstance3D = $WaterPlane
	var plane := PlaneMesh.new()
	plane.size = Vector2(600, 600)
	plane.subdivide_width = 64
	plane.subdivide_depth = 64
	water.mesh = plane
	water.position = Vector3(0, 6.0, 0)
	var water_shader: Shader = load("res://assets/shaders/water.gdshader")
	if water_shader:
		var mat := ShaderMaterial.new()
		mat.shader = water_shader
		water.material_override = mat
	else:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.15, 0.55, 0.85, 0.8)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.roughness = 0.05
		water.material_override = mat

func _setup_spawners() -> void:
	var ps: MultiplayerSpawner = $PlayersSpawner
	ps.spawn_path = NodePath("PlayersContainer")
	ps.add_spawnable_scene("res://scenes/player/Player.tscn")

func _attach_weather_script() -> void:
	var weather: Node3D = $WeatherSystem
	if not weather.get_script():
		var ws: Script = load("res://scripts/world/WeatherSystem.gd")
		if ws:
			weather.set_script(ws)

func _spawn_local_player() -> void:
	var container: Node3D = $PlayersContainer
	var my_id := multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1
	# Избегаем дублирования если NetworkManager уже заспавнил
	if container.get_node_or_null(str(my_id)):
		return
	# Спавним только если нет подключения (сингл / хост без пиров)
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	var player_scene: PackedScene = load("res://scenes/player/Player.tscn")
	if not player_scene:
		push_error("Player.tscn not found")
		return
	var player: Node = player_scene.instantiate()
	player.name = str(my_id)
	player.set_multiplayer_authority(my_id)
	container.add_child(player, true)
