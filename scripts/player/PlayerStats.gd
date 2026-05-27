class_name PlayerStats
extends Node

signal health_changed(value: float)
signal hunger_changed(value: float)
signal died()

@export var max_health: float = 100.0
@export var max_hunger: float = 100.0
@export var hunger_rate: float = 1.5       # единиц в минуту
@export var hunger_damage_rate: float = 3.0 # урон когда голод = 0

var health: float = 100.0
var hunger: float = 100.0
var is_dead: bool = false

func _ready() -> void:
	health = max_health
	hunger = max_hunger
	if not get_parent().is_multiplayer_authority():
		set_process(false)

func _process(delta: float) -> void:
	if is_dead:
		return
	# Голод уменьшается медленно
	hunger = max(0.0, hunger - hunger_rate * delta / 60.0)
	hunger_changed.emit(hunger)
	# Когда голод кончился — теряем HP
	if hunger <= 0.0:
		take_damage(hunger_damage_rate * delta)

func take_damage(amount: float) -> void:
	if is_dead:
		return
	health = max(0.0, health - amount)
	health_changed.emit(health)
	if health <= 0.0:
		_die()

func heal(amount: float) -> void:
	health = min(max_health, health + amount)
	health_changed.emit(health)

func feed(amount: float) -> void:
	hunger = min(max_hunger, hunger + amount)
	hunger_changed.emit(hunger)

func _die() -> void:
	is_dead = true
	died.emit()
	# Возрождение через 5 секунд
	var t: SceneTreeTimer = get_tree().create_timer(5.0)
	await t.timeout
	health = max_health * 0.5
	hunger = max_hunger * 0.5
	is_dead = false
	health_changed.emit(health)
	# Переместить в точку спавна
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = randi()
	get_parent().position = Vector3(rng.randf_range(-30, 30), 30.0, rng.randf_range(-30, 30))
