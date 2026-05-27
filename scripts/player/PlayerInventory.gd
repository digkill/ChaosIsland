class_name PlayerInventory
extends Node

signal inventory_changed()
signal item_equipped(item_id: String)

var items: Dictionary = {}  # item_id -> count
var equipped_item: String = ""
var hotbar: Array = ["", "", "", "", ""]  # 5 слотов

func _ready() -> void:
	if not get_parent().is_multiplayer_authority():
		return
	# Стартовые предметы
	add_item("wood", 10)
	add_item("stone", 5)
	add_item("coconut", 3)
	add_item("banana", 2)

func add_item(item_id: String, count: int = 1) -> bool:
	var data: Dictionary = ItemDatabase.get_item(item_id)
	if data.is_empty():
		return false
	var max_s: int = data.get("max_stack", 99)
	var current: int = items.get(item_id, 0)
	items[item_id] = min(current + count, max_s)
	inventory_changed.emit()
	return true

func remove_item(item_id: String, count: int = 1) -> bool:
	var current: int = items.get(item_id, 0)
	if current < count:
		return false
	items[item_id] = current - count
	if items[item_id] <= 0:
		items.erase(item_id)
	inventory_changed.emit()
	return true

func has_item(item_id: String, count: int = 1) -> bool:
	return items.get(item_id, 0) >= count

func try_craft(item_id: String) -> bool:
	if not ItemDatabase.can_craft(item_id, items):
		return false
	var cost: Dictionary = ItemDatabase.get_craft_cost(item_id)
	for ingredient in cost:
		remove_item(ingredient, cost[ingredient])
	add_item(item_id)
	return true

func equip(item_id: String) -> void:
	equipped_item = item_id
	item_equipped.emit(item_id)

func get_count(item_id: String) -> int:
	return items.get(item_id, 0) as int
