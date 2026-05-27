extends SpringArm3D

@export var mouse_sensitivity: float = 0.003
@export var zoom_speed: float = 2.0
@export var min_zoom: float = 2.5
@export var max_zoom: float = 14.0
@export var zoom_smooth: float = 12.0

var _target_length: float = 5.5
var _pitch: float = -0.2  # радианы

func _ready() -> void:
	if not get_parent().is_multiplayer_authority():
		set_process(false)
		set_process_unhandled_input(false)
		return
	spring_length = _target_length
	rotation.x = _pitch

func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		get_parent().rotate_y(-event.relative.x * mouse_sensitivity)
		_pitch = clamp(
			_pitch - event.relative.y * mouse_sensitivity,
			deg_to_rad(-75.0),
			deg_to_rad(25.0))
		rotation.x = _pitch
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_target_length = clamp(_target_length - zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_target_length = clamp(_target_length + zoom_speed, min_zoom, max_zoom)

func _process(delta: float) -> void:
	spring_length = lerp(spring_length, _target_length, zoom_smooth * delta)
