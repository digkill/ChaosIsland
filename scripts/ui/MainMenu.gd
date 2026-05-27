extends Control

@onready var name_input: LineEdit = $Center/VBox/NameInput
@onready var ip_input: LineEdit   = $Center/VBox/JoinBox/IPInput
@onready var host_btn: Button     = $Center/VBox/HostBtn
@onready var join_btn: Button     = $Center/VBox/JoinBox/JoinBtn
@onready var status_label: Label  = $Center/VBox/StatusLabel
@onready var color_btn: ColorPickerButton = $Center/VBox/ColorPicker

func _ready() -> void:
	host_btn.pressed.connect(_on_host)
	join_btn.pressed.connect(_on_join)
	NetworkManager.connection_failed.connect(_on_conn_failed)
	NetworkManager.server_disconnected.connect(_on_server_disc)
	name_input.text = "Player" + str(randi() % 999)
	color_btn.color = Color.from_hsv(randf(), 0.7, 0.9)

func _on_host() -> void:
	if name_input.text.strip_edges().is_empty():
		status_label.text = "Enter a name first!"
		return
	GameManager.local_player_color = color_btn.color
	status_label.text = "Starting server..."
	NetworkManager.host_game(name_input.text.strip_edges())

func _on_join() -> void:
	if name_input.text.strip_edges().is_empty():
		status_label.text = "Enter a name first!"
		return
	var ip := ip_input.text.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1"
	GameManager.local_player_color = color_btn.color
	status_label.text = "Connecting to %s..." % ip
	host_btn.disabled = true
	join_btn.disabled = true
	NetworkManager.join_game(ip, name_input.text.strip_edges())

func _on_conn_failed() -> void:
	status_label.text = "Connection failed!"
	host_btn.disabled = false
	join_btn.disabled = false

func _on_server_disc() -> void:
	status_label.text = "Disconnected from server."
