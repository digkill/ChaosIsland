extends Control

@onready var health_bar: ProgressBar  = $Bars/HealthBar
@onready var hunger_bar: ProgressBar  = $Bars/HungerBar
@onready var time_label: Label        = $TopBar/TimeLabel
@onready var player_count: Label      = $TopBar/PlayerCount
@onready var hotbar: HBoxContainer    = $Hotbar
@onready var build_hint: Label        = $BuildHint
@onready var day_night_label: Label   = $TopBar/DayNight

var _local_stats: PlayerStats = null
var _inventory: PlayerInventory = null
var _day_night: DayNightCycle = null

func _ready() -> void:
	# AutoLoads доступны глобально после открытия проекта в Godot Editor
	EventManager.event_started.connect(_on_event)
	NetworkManager.player_joined.connect(_update_player_count)
	NetworkManager.player_left.connect(_update_player_count)
	build_hint.visible = false
	call_deferred("_connect_local_player")

func _connect_local_player() -> void:
	await get_tree().create_timer(1.5).timeout
	var container: Node = get_node_or_null("/root/Main/SceneContainer/GameWorld/PlayersContainer")
	if not container:
		return
	var my_id: String = str(multiplayer.get_unique_id())
	var player: Node = container.get_node_or_null(my_id)
	if not player:
		return
	_local_stats = player.get_node_or_null("PlayerStats") as PlayerStats
	_inventory = player.get_node_or_null("PlayerInventory") as PlayerInventory
	if _local_stats:
		_local_stats.health_changed.connect(func(v: float): health_bar.value = v)
		_local_stats.hunger_changed.connect(func(v: float): hunger_bar.value = v)
		health_bar.max_value = _local_stats.max_health
		hunger_bar.max_value = _local_stats.max_hunger
		health_bar.value = _local_stats.health
		hunger_bar.value = _local_stats.hunger
	if _inventory:
		_inventory.inventory_changed.connect(_refresh_hotbar)
		_refresh_hotbar()
	_day_night = get_node_or_null("/root/Main/SceneContainer/GameWorld/DayNightCycle") as DayNightCycle

func _process(_delta: float) -> void:
	if _day_night:
		time_label.text = _day_night.get_time_string()
		day_night_label.text = "☀️" if _day_night.is_daytime() else "🌙"

func _on_event(_ev_name: String, _desc: String, _icon: String) -> void:
	pass  # EventAnnouncer handles display

func _update_player_count(_id: int = 0, _name: String = "") -> void:
	player_count.text = "👥 %d" % NetworkManager.get_player_count()

func _refresh_hotbar() -> void:
	if not _inventory:
		return
	for child in hotbar.get_children():
		child.queue_free()
	var slots: Array[String] = ["wood", "stone", "coconut", "banana", "coconut_rocket"]
	for slot_id in slots:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(52, 52)
		var vbox := VBoxContainer.new()
		panel.add_child(vbox)
		var icon_lbl := Label.new()
		var data: Dictionary = ItemDatabase.get_item(slot_id)
		icon_lbl.text = data.get("icon", "?")
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_font_size_override("font_size", 22)
		var count_lbl := Label.new()
		var cnt: int = _inventory.get_count(slot_id)
		count_lbl.text = str(cnt) if cnt > 0 else ""
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_lbl.add_theme_font_size_override("font_size", 12)
		vbox.add_child(icon_lbl)
		vbox.add_child(count_lbl)
		hotbar.add_child(panel)

func show_build_hint(enabled: bool) -> void:
	build_hint.visible = enabled
