extends Node

const PORT = 4433
const MAX_PEERS = 16

const PLAYER_SCENE = preload("res://scenes/player/Player.tscn")
const GAME_WORLD_SCENE = preload("res://scenes/main/GameWorld.tscn")

signal player_joined(id: int, name: String)
signal player_left(id: int)
signal connection_failed()
signal server_disconnected()
signal game_started()

var players_info: Dictionary = {}  # id -> {name, color}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game(player_name: String) -> void:
	GameManager.local_player_name = player_name
	var peer := _create_peer()
	if peer is ENetMultiplayerPeer:
		peer.create_server(PORT, MAX_PEERS)
	else:
		peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	# Регистрируем хоста в списке
	players_info[1] = {
		"name": player_name,
		"color": GameManager.local_player_color
	}
	_load_game_world()

func join_game(address: String, player_name: String) -> void:
	GameManager.local_player_name = player_name
	var peer := _create_peer()
	if peer is ENetMultiplayerPeer:
		peer.create_client(address, PORT)
	else:
		peer.create_client("ws://%s:%d" % [address, PORT])
	multiplayer.multiplayer_peer = peer

func disconnect_game() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	players_info.clear()

func is_server() -> bool:
	return multiplayer.is_server()

func get_player_count() -> int:
	return players_info.size()

func _create_peer() -> MultiplayerPeer:
	if OS.get_name() == "Web":
		return WebSocketMultiplayerPeer.new()
	return ENetMultiplayerPeer.new()

func _load_game_world() -> void:
	var seed_val: int = GameManager.generate_seed()
	GameManager.set_state(GameManager.State.PLAYING)
	var main: Node = get_tree().root.get_node("Main")
	main.load_game_world(seed_val)
	game_started.emit()

func _on_peer_connected(id: int) -> void:
	if multiplayer.is_server():
		# Отправить новому игроку информацию об уже подключённых
		for pid in players_info:
			var info: Dictionary = players_info[pid]
			_rpc_receive_player_info.rpc_id(id, pid, info.get("name", ""), info.get("color", Color.CYAN))
		# Отправить seed мира
		_rpc_load_world.rpc_id(id, GameManager.session_seed)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_send_player_info(p_name: String, p_color: Color) -> void:
	var sender := multiplayer.get_remote_sender_id()
	players_info[sender] = {"name": p_name, "color": p_color}
	player_joined.emit(sender, p_name)
	if multiplayer.is_server():
		_rpc_receive_player_info.rpc(sender, p_name, p_color)
		_spawn_player_on_all(sender)

@rpc("authority", "call_remote", "reliable")
func _rpc_receive_player_info(id: int, p_name: String, p_color: Color) -> void:
	players_info[id] = {"name": p_name, "color": p_color}

@rpc("authority", "call_remote", "reliable")
func _rpc_load_world(seed_val: int) -> void:
	GameManager.session_seed = seed_val
	GameManager.set_state(GameManager.State.PLAYING)
	var main: Node = get_tree().root.get_node("Main")
	main.load_game_world(seed_val)

func _spawn_player_on_all(id: int) -> void:
	if not multiplayer.is_server():
		return
	var container: Node3D = GameManager.game_world.get_node_or_null("PlayersContainer") as Node3D
	if not container:
		return
	var player: Node = PLAYER_SCENE.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id)
	container.add_child(player, true)

func _on_connected_to_server() -> void:
	var my_id := multiplayer.get_unique_id()
	players_info[my_id] = {
		"name": GameManager.local_player_name,
		"color": GameManager.local_player_color
	}
	_rpc_send_player_info.rpc_id(1,
		GameManager.local_player_name,
		GameManager.local_player_color)

func _on_peer_disconnected(id: int) -> void:
	players_info.erase(id)
	player_left.emit(id)
	var container: Node3D = (GameManager.game_world.get_node_or_null("PlayersContainer") as Node3D) if GameManager.game_world else null
	if container:
		var p: Node = container.get_node_or_null(str(id))
		if p:
			p.queue_free()

func _on_connection_failed() -> void:
	multiplayer.multiplayer_peer = null
	connection_failed.emit()

func _on_server_disconnected() -> void:
	multiplayer.multiplayer_peer = null
	players_info.clear()
	server_disconnected.emit()
