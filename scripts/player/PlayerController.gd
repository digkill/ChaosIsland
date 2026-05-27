extends CharacterBody3D

const BASE_SPEED: float    = 6.0
const RUN_SPEED: float     = 10.5
const JUMP_FORCE: float    = 9.0
const BASE_GRAVITY: float  = -22.0

@onready var camera_arm: SpringArm3D     = $CameraArm
@onready var anim_player: AnimationPlayer = $Body/AnimationPlayer
@onready var name_tag: Label3D            = $NameTag
@onready var stats: PlayerStats          = $PlayerStats
@onready var inventory: PlayerInventory  = $PlayerInventory
@onready var ray: RayCast3D               = $InteractRay
@onready var sync: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var body_mesh: MeshInstance3D    = $Body/BodyMesh

var gravity_multiplier: float = 1.0
var jump_force_override: float = -1.0
var wind_force: Vector3 = Vector3.ZERO
var is_in_build_mode: bool = false
var current_anim: String = "idle"
var player_display_name: String = "Player"
var player_color: Color = Color.CYAN

func _ready() -> void:
	if not is_multiplayer_authority():
		_disable_local_controls()
		return
	_setup_local_player()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	floor_snap_length = 0.5  # помогает не проваливаться на неровностях
	collision_layer = 1
	collision_mask = 1

func _setup_local_player() -> void:
	var cam := camera_arm.get_child(0) as Camera3D
	if cam:
		cam.current = true
	var info: Dictionary = NetworkManager.players_info.get(get_multiplayer_authority(), {})
	player_display_name = info.get("name", "Player%d" % get_multiplayer_authority())
	player_color = info.get("color", Color.CYAN)
	name_tag.text = player_display_name
	_apply_color(player_color)
	# Позиция спавна — случайная точка на острове (с правильной высотой)
	var rng := RandomNumberGenerator.new()
	rng.seed = get_multiplayer_authority()
	var spawn_x := rng.randf_range(-30, 30)
	var spawn_z := rng.randf_range(-30, 30)

	# Пытаемся получить реальную высоту острова
	var island_gen := get_tree().current_scene.get_node_or_null("IslandGenerator") as Node
	if island_gen and island_gen.has_method("get_height_at"):
		var terrain_y := island_gen.get_height_at(Vector2(spawn_x, spawn_z))
		position = Vector3(spawn_x, terrain_y + 2.0, spawn_z)  # +2 чтобы не застрять в земле
	else:
		position = Vector3(spawn_x, 30.0, spawn_z)

func _disable_local_controls() -> void:
	set_physics_process(false)
	# Камера нелокального игрока не активна
	if has_node("CameraArm/Camera3D"):
		$CameraArm/Camera3D.current = false

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement(delta)
	_handle_interact()
	move_and_slide()
	_update_anim()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += BASE_GRAVITY * gravity_multiplier * delta
	elif velocity.y < 0:
		velocity.y = 0.0

func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		var force := jump_force_override if jump_force_override > 0 else JUMP_FORCE
		velocity.y = force

func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var is_running := Input.is_action_pressed("run")
	var speed := RUN_SPEED if is_running else BASE_SPEED
	var cam_basis := camera_arm.global_transform.basis
	var direction := (cam_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction.y = 0
	# Ветер
	velocity += wind_force * delta
	if direction.length() > 0.05:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		var target_y := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_y, 12.0 * delta)
	else:
		var friction := 14.0 * delta
		velocity.x = move_toward(velocity.x, 0, speed * friction)
		velocity.z = move_toward(velocity.z, 0, speed * friction)

func _handle_interact() -> void:
	if Input.is_action_just_pressed("interact") and ray.is_colliding():
		var target := ray.get_collider()
		if target and target.has_method("interact"):
			target.interact(self)

func _update_anim() -> void:
	var h_spd := Vector2(velocity.x, velocity.z).length()
	var new_anim: String
	if not is_on_floor():
		new_anim = "jump"
	elif h_spd > 7.0:
		new_anim = "run"
	elif h_spd > 0.5:
		new_anim = "walk"
	else:
		new_anim = "idle"
	if new_anim != current_anim:
		current_anim = new_anim
		if anim_player.has_animation(current_anim):
			anim_player.play(current_anim)

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event is InputEventKey and event.pressed:
		if event.physical_keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.physical_keycode == KEY_F:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func set_gravity_multiplier(val: float) -> void:
	gravity_multiplier = val

func set_jump_force(val: float) -> void:
	jump_force_override = val

func apply_wind(force: Vector3) -> void:
	wind_force = force

func _apply_color(color: Color) -> void:
	if not body_mesh:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	body_mesh.material_override = mat
