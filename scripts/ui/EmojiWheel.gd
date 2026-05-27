extends Control

signal emote_selected(emote_id: String)

const EMOTES: Array[Dictionary] = [
	{"id": "wave",   "icon": "👋", "label": "Wave"},
	{"id": "dance",  "icon": "💃", "label": "Dance"},
	{"id": "laugh",  "icon": "😂", "label": "LOL"},
	{"id": "cry",    "icon": "😭", "label": "Cry"},
	{"id": "angry",  "icon": "😤", "label": "Mad"},
	{"id": "cool",   "icon": "😎", "label": "Cool"},
	{"id": "shocked","icon": "😱", "label": "OMG"},
	{"id": "thumb",  "icon": "👍", "label": "GG"},
]

var _open: bool = false

func _ready() -> void:
	visible = false
	_build_wheel()

func _build_wheel() -> void:
	var radius := 110.0
	var center := Vector2(200, 200)
	custom_minimum_size = Vector2(400, 400)
	# Фон
	var bg := ColorRect.new()
	bg.size = Vector2(400, 400)
	bg.color = Color(0, 0, 0, 0.5)
	add_child(bg)
	for i in EMOTES.size():
		var angle: float = (TAU / EMOTES.size()) * i - PI * 0.5
		var pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius
		var btn: Button = Button.new()
		var data: Dictionary = EMOTES[i]
		btn.text = data.get("icon", "?")
		btn.tooltip_text = data.get("label", "")
		btn.custom_minimum_size = Vector2(54, 54)
		btn.position = pos - Vector2(27, 27)
		btn.add_theme_font_size_override("font_size", 28)
		var emote_id: String = EMOTES[i]["id"]
		btn.pressed.connect(func(): _on_emote(emote_id))
		add_child(btn)

func toggle() -> void:
	_open = not _open
	visible = _open
	if _open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("emote_wheel") and event.is_pressed() and not event.is_echo():
		toggle()
	elif event.is_action("build_cancel") and event.is_pressed() and not event.is_echo() and _open:
		toggle()

func _on_emote(emote_id: String) -> void:
	emote_selected.emit(emote_id)
	toggle()
