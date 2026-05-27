extends Control

@onready var panel: PanelContainer  = $Panel
@onready var icon_label: Label      = $Panel/VBox/Icon
@onready var title_label: Label     = $Panel/VBox/Title
@onready var desc_label: Label      = $Panel/VBox/Desc
@onready var anim: AnimationPlayer  = $AnimationPlayer

var _queue: Array[Dictionary] = []
var _showing: bool = false

func _ready() -> void:
	# AutoLoads доступны после импорта проекта в Godot Editor
	EventManager.event_started.connect(_on_event_started)
	EventManager.event_ended.connect(_on_event_ended)
	panel.visible = false

func _on_event_started(ev_name: String, desc: String, icon: String) -> void:
	var entry: Dictionary = {"name": ev_name, "desc": desc, "icon": icon, "is_end": false}
	_queue.append(entry)
	_try_show_next()

func _on_event_ended(ev_name: String) -> void:
	var entry: Dictionary = {"name": ev_name, "desc": "...hopefully.", "icon": "✅", "is_end": true}
	_queue.append(entry)
	_try_show_next()

func _try_show_next() -> void:
	if _showing or _queue.is_empty():
		return
	_showing = true
	var data: Dictionary = _queue.pop_front()
	icon_label.text  = data["icon"]
	title_label.text = data["name"] if not data["is_end"] else data["name"] + " IS OVER"
	desc_label.text  = data["desc"]
	panel.visible = true
	if anim.has_animation("slide_in"):
		anim.play("slide_in")
	await get_tree().create_timer(3.5).timeout
	if anim.has_animation("slide_out"):
		anim.play("slide_out")
		await anim.animation_finished
	panel.visible = false
	_showing = false
	_try_show_next()
	_post_to_chat(data)

func _post_to_chat(data: Dictionary) -> void:
	var chat: Node = get_tree().root.get_node_or_null(
		"Main/SceneContainer/GameWorld/UI/ChatBox")
	if chat and chat.has_method("add_system_message"):
		chat.add_system_message("%s %s — %s" % [data["icon"], data["name"], data["desc"]])
