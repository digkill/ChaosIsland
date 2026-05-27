extends Node

@onready var scene_container: Node = $SceneContainer
@onready var loading_bg: ColorRect  = $LoadingOverlay/LoadingBG
@onready var loading_lbl: Label     = $LoadingOverlay/LoadingBG/LoadingLabel

var _current_scene: Node = null

# Preload core scenes for safety (avoids null instantiate crashes)
const LOBBY_SCENE: PackedScene = preload("res://scenes/main/Lobby.tscn")
const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/main/GameWorld.tscn")

func _ready() -> void:
	NetworkManager.game_started.connect(_on_game_started)
	NetworkManager.server_disconnected.connect(_on_server_disconnected)
	_show_lobby()

func _show_lobby() -> void:
	if not LOBBY_SCENE:
		push_error("LOBBY_SCENE is null! This should never happen with preload.")
		return
	_swap_scene(LOBBY_SCENE.instantiate())

func load_game_world(seed_val: int) -> void:
	loading_bg.visible = true
	loading_lbl.text = "Generating chaos island..."
	await get_tree().process_frame
	await get_tree().process_frame
	if not GAME_WORLD_SCENE:
		push_error("GAME_WORLD_SCENE is null!")
		loading_bg.visible = false
		return
	var world: Node = GAME_WORLD_SCENE.instantiate()
	world.set_meta("island_seed", seed_val)
	_swap_scene(world)
	GameManager.register_world(world)
	loading_bg.visible = false

func _swap_scene(new_scene: Node) -> void:
	if _current_scene:
		_current_scene.queue_free()
		await get_tree().process_frame
	_current_scene = new_scene
	scene_container.add_child(new_scene)

func _on_game_started() -> void:
	pass  # load_game_world вызывается напрямую из NetworkManager

func _on_server_disconnected() -> void:
	if _current_scene and _current_scene.name == "GameWorld":
		GameManager.unregister_world()
		EventManager.stop()
		_show_lobby()
