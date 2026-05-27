extends Control

@onready var message_list: RichTextLabel = $Panel/VBox/MessageList
@onready var input_line: LineEdit        = $Panel/VBox/InputRow/InputLine
@onready var input_row: HBoxContainer   = $Panel/VBox/InputRow
@onready var panel: PanelContainer      = $Panel

var _is_open: bool = false
var _messages: Array[String] = []
const MAX_MESSAGES := 50

func _ready() -> void:
	input_row.visible = false
	panel.modulate.a = 0.85

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("chat_open") and event.is_pressed() and not event.is_echo() and not _is_open:
		_open_chat()
	elif event is InputEventKey and event.keycode == KEY_ESCAPE and _is_open:
		_close_chat()
	elif event is InputEventKey and event.keycode == KEY_ENTER and _is_open:
		_send_message()

func _open_chat() -> void:
	_is_open = true
	input_row.visible = true
	input_line.grab_focus()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _close_chat() -> void:
	_is_open = false
	input_row.visible = false
	input_line.clear()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _send_message() -> void:
	var text := input_line.text.strip_edges()
	if text.is_empty():
		_close_chat()
		return
	var my_id := multiplayer.get_unique_id()
	var info: Dictionary = NetworkManager.players_info.get(my_id, {})
	var display: String = info.get("name", "Player")
	_receive_message.rpc(display, text)
	input_line.clear()
	_close_chat()

@rpc("any_peer", "call_local", "reliable")
func _receive_message(sender_name: String, text: String) -> void:
	var safe_name: String = sender_name.replace("[", "").replace("]", "").left(32)
	var safe_text: String = text.replace("[", "").replace("]", "").left(200)
	var formatted: String = "[b]%s[/b]: %s" % [safe_name, safe_text]
	_messages.append(formatted)
	if _messages.size() > MAX_MESSAGES:
		_messages.pop_front()
	_rebuild_list()

func add_system_message(text: String) -> void:
	var safe: String = text.replace("[", "").replace("]", "").left(300)
	_messages.append("[color=yellow][i]%s[/i][/color]" % safe)
	if _messages.size() > MAX_MESSAGES:
		_messages.pop_front()
	_rebuild_list()

func _rebuild_list() -> void:
	message_list.clear()
	for msg in _messages:
		message_list.append_text(msg + "\n")
