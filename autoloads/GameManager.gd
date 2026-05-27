extends Node

signal game_state_changed(state: String)
signal player_count_changed(count: int)

enum State { MENU, LOBBY, PLAYING, PAUSED }

var current_state: State = State.MENU
var local_player_name: String = "Player"
var local_player_color: Color = Color.CYAN
var game_world: Node = null
var session_seed: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func set_state(new_state: State) -> void:
	current_state = new_state
	game_state_changed.emit(State.keys()[new_state] as String)

func get_world() -> Node:
	return game_world

func register_world(world: Node) -> void:
	game_world = world
	EventManager.set_world(world)

func unregister_world() -> void:
	game_world = null

func generate_seed() -> int:
	session_seed = randi()
	return session_seed
