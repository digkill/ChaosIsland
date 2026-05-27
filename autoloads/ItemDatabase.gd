extends Node

# Полная база данных предметов и рецептов крафта

const items: Dictionary = {
	# Ресурсы
	"wood": {
		"name": "Wood", "icon": "🌲", "max_stack": 99,
		"category": "resource", "description": "Tropical wood. Smells like chaos."
	},
	"stone": {
		"name": "Stone", "icon": "🪨", "max_stack": 99,
		"category": "resource", "description": "Heavy. Great for throwing."
	},
	"coconut": {
		"name": "Coconut", "icon": "🥥", "max_stack": 20,
		"category": "resource", "description": "Mmm. Or a weapon. Both."
	},
	"banana": {
		"name": "Banana", "icon": "🍌", "max_stack": 20,
		"category": "food", "description": "Eat it. Or slip on it.",
		"heal": 10, "feed": 15
	},
	"fish": {
		"name": "Fish", "icon": "🐟", "max_stack": 10,
		"category": "food", "description": "Tastes like the sea.",
		"heal": 20, "feed": 25
	},
	"feather": {
		"name": "Feather", "icon": "🪶", "max_stack": 50,
		"category": "resource", "description": "From a very confused chicken."
	},
	"pumpkin": {
		"name": "Pumpkin", "icon": "🎃", "max_stack": 5,
		"category": "resource", "description": "For science."
	},
	# Крафтовые предметы
	"coconut_rocket": {
		"name": "Coconut Rocket", "icon": "🚀", "max_stack": 3,
		"category": "weapon", "description": "YEET into orbit.",
		"damage": 50, "blast_radius": 8.0
	},
	"banana_costume": {
		"name": "Banana Costume", "icon": "🍌", "max_stack": 1,
		"category": "armor", "description": "Slippery. Very slippery.",
		"slip_chance": 0.3
	},
	"pumpkin_cannon": {
		"name": "Pumpkin Cannon", "icon": "💥", "max_stack": 1,
		"category": "weapon", "description": "Pew pew gourd.",
		"damage": 35, "fire_rate": 1.5
	},
	"bounce_pad": {
		"name": "Bounce Pad", "icon": "⬆️", "max_stack": 5,
		"category": "buildable", "description": "BOING",
		"scene": "res://scenes/building/prefabs/BouncePad.tscn"
	},
	"wood_wall": {
		"name": "Wood Wall", "icon": "🪵", "max_stack": 20,
		"category": "buildable", "description": "For your epic base.",
		"scene": "res://scenes/building/prefabs/WoodWall.tscn"
	},
	"wood_floor": {
		"name": "Wood Floor", "icon": "🟫", "max_stack": 20,
		"category": "buildable", "description": "Stand on it.",
		"scene": "res://scenes/building/prefabs/WoodFloor.tscn"
	},
	"coconut_trap": {
		"name": "Coconut Trap", "icon": "🥥", "max_stack": 5,
		"category": "buildable", "description": "Troll your friends.",
		"scene": "res://scenes/building/prefabs/CoconutTrap.tscn"
	},
}

const recipes: Dictionary = {
	"coconut_rocket": {"coconut": 3, "wood": 5, "feather": 2},
	"banana_costume": {"banana": 5, "feather": 10},
	"pumpkin_cannon": {"pumpkin": 2, "stone": 8, "wood": 4},
	"bounce_pad": {"wood": 4, "feather": 6},
	"wood_wall": {"wood": 4},
	"wood_floor": {"wood": 3},
	"coconut_trap": {"coconut": 2, "wood": 2},
}

func get_item(id: String) -> Dictionary:
	return items.get(id, {})

func can_craft(item_id: String, inventory: Dictionary) -> bool:
	if not recipes.has(item_id):
		return false
	var cost: Dictionary = recipes[item_id]
	for ingredient in cost:
		if inventory.get(ingredient, 0) < int(cost[ingredient]):
			return false
	return true

func get_craft_cost(item_id: String) -> Dictionary:
	return recipes.get(item_id, {})

func get_buildable_items() -> Array:
	var result: Array[String] = []
	for id in items:
		if items[id].get("category") == "buildable":
			result.append(id)
	return result
