class_name BaseEvent
extends RefCounted

var event_name: String = "???"
var description: String = "Something weird is happening!"
var icon: String = "🌀"
var duration: float = 30.0

func activate(_world: Node) -> void:
	pass

func deactivate(_world: Node) -> void:
	pass

func _get_players(world: Node) -> Array:
	var container: Node = world.get_node_or_null("PlayersContainer")
	if container:
		return container.get_children()
	return []
