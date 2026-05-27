extends Control

signal closed()

var _inventory: PlayerInventory = null

func _ready() -> void:
	visible = false

func open_for_player(inventory: PlayerInventory) -> void:
	_inventory = inventory
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_rebuild()

func close() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()

func _rebuild() -> void:
	for child in $ScrollContainer/VBox.get_children():
		child.queue_free()
	var craftable: Array[String] = ["coconut_rocket", "banana_costume", "pumpkin_cannon",
					  "bounce_pad", "wood_wall", "wood_floor", "coconut_trap"]
	for item_id in craftable:
		var data: Dictionary = ItemDatabase.get_item(item_id)
		if data.is_empty():
			continue
		var can_craft: bool = ItemDatabase.can_craft(item_id,
			_inventory.items if _inventory else {})
		var row := HBoxContainer.new()
		row.theme_override_constants_separation = 10
		var icon := Label.new()
		icon.text = data.get("icon", "?")
		icon.add_theme_font_size_override("font_size", 28)
		icon.custom_minimum_size = Vector2(40, 40)
		row.add_child(icon)
		var name_lbl := Label.new()
		name_lbl.text = data.get("name", item_id)
		name_lbl.custom_minimum_size = Vector2(150, 0)
		row.add_child(name_lbl)
		var cost_lbl := Label.new()
		var cost: Dictionary = ItemDatabase.get_craft_cost(item_id)
		var cost_parts: Array[String] = []
		for ing in cost:
			var ing_data: Dictionary = ItemDatabase.get_item(ing)
			cost_parts.append("%s%s x%d" % [
				ing_data.get("icon", ""),
				ing_data.get("name", ing),
				cost[ing]])
		cost_lbl.text = ", ".join(cost_parts)
		cost_lbl.modulate = Color.WHITE if can_craft else Color(0.6, 0.6, 0.6)
		cost_lbl.custom_minimum_size = Vector2(250, 0)
		row.add_child(cost_lbl)
		var craft_btn := Button.new()
		craft_btn.text = "Craft"
		craft_btn.disabled = not can_craft
		craft_btn.custom_minimum_size = Vector2(70, 0)
		craft_btn.pressed.connect(func(): _do_craft(item_id))
		row.add_child(craft_btn)
		$ScrollContainer/VBox.add_child(row)

func _do_craft(item_id: String) -> void:
	if _inventory and _inventory.try_craft(item_id):
		_rebuild()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action("build_cancel") and event.is_pressed() and not event.is_echo():
		close()
