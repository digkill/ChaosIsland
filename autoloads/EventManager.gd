extends Node

signal event_started(ev_name: String, description: String, icon: String)
signal event_ended(ev_name: String)

@export var min_interval: float = 60.0   # 1 мин для дебага (в прод 300)
@export var max_interval: float = 120.0  # 2 мин для дебага (в прод 900)

var _active_event: BaseEvent = null
var _event_timer: float = 0.0
var _next_event_time: float = 0.0
var _world: Node = null
var _all_events: Array[BaseEvent] = []
var _running: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_events()
	_schedule_next()

func _register_events() -> void:
	_all_events = [
		load("res://scripts/events/events/ChickenRainEvent.gd").new(),
		load("res://scripts/events/events/GravityFlipEvent.gd").new(),
		load("res://scripts/events/events/BouncyWorldEvent.gd").new(),
		load("res://scripts/events/events/DancingTreesEvent.gd").new(),
		load("res://scripts/events/events/GiantCrabEvent.gd").new(),
		load("res://scripts/events/events/MegaStormEvent.gd").new(),
	]

func set_world(world: Node) -> void:
	_world = world
	_running = true

func stop() -> void:
	_running = false
	if _active_event and _world:
		_active_event.deactivate(_world)
	_active_event = null

func _process(delta: float) -> void:
	if not _running or not multiplayer.is_server():
		return
	_event_timer += delta
	if _active_event:
		if _event_timer >= _active_event.duration:
			_end_current_event()
	else:
		if _event_timer >= _next_event_time:
			_trigger_random_event()

func _trigger_random_event() -> void:
	if _all_events.is_empty() or not _world:
		return
	_active_event = _all_events.pick_random()
	_event_timer = 0.0
	_active_event.activate(_world)
	_broadcast_event_start.rpc(
		_active_event.event_name,
		_active_event.description,
		_active_event.icon)

func _end_current_event() -> void:
	if not _active_event:
		return
	_active_event.deactivate(_world)
	_broadcast_event_end.rpc(_active_event.event_name)
	_active_event = null
	_schedule_next()

func _schedule_next() -> void:
	_event_timer = 0.0
	_next_event_time = randf_range(min_interval, max_interval)

@rpc("authority", "call_local", "reliable")
func _broadcast_event_start(ev_name: String, desc: String, icon: String) -> void:
	event_started.emit(ev_name, desc, icon)

@rpc("authority", "call_local", "reliable")
func _broadcast_event_end(ev_name: String) -> void:
	event_ended.emit(ev_name)

func trigger_event_by_name(name: String) -> void:
	if not multiplayer.is_server():
		return
	for ev in _all_events:
		if ev.event_name == name:
			if _active_event:
				_end_current_event()
			_active_event = ev
			_event_timer = 0.0
			ev.activate(_world)
			_broadcast_event_start.rpc(ev.event_name, ev.description, ev.icon)
			return
