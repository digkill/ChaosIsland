extends Node3D

const PLACE_SNAP := 1.0  # сетка размещения

var _catalog: Dictionary[String, PackedScene] = {}
var _ghost: Node3D = null
var _current_id: String = ""
var _valid: bool = false
var _ghost_rot_y: float = 0.0
var _active: bool = false

var _mat_ok: StandardMaterial3D
var _mat_bad: StandardMaterial3D

func _ready() -> void:
	_mat_ok = StandardMaterial3D.new()
	_mat_ok.albedo_color = Color(0.0, 1.0, 0.0, 0.4)
	_mat_ok.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_ok.no_depth_test = true
	_mat_bad = StandardMaterial3D.new()
	_mat_bad.albedo_color = Color(1.0, 0.0, 0.0, 0.4)
	_mat_bad.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_bad.no_depth_test = true
	_load_catalog()

func _load_catalog() -> void:
	# Каталог строений по item_id
	var buildable_items: Array[String] = ItemDatabase.get_buildable_items()
	for id in buildable_items:
		var data: Dictionary = ItemDatabase.get_item(id)
		var scene_path: String = data.get("scene", "")
		if not scene_path.is_empty() and ResourceLoader.exists(scene_path):
			var scene: PackedScene = load(scene_path) as PackedScene
			if scene:
				_catalog[id] = scene

func activate(item_id: String) -> void:
	if _ghost:
		_ghost.queue_free()
	_current_id = item_id
	_active = true
	if _catalog.has(item_id):
		_ghost = _catalog[item_id].instantiate() as Node3D
	else:
		_ghost = _make_fallback_ghost()
	_apply_ghost_mat(_ghost, _mat_ok)
	add_child(_ghost)

func deactivate() -> void:
	_active = false
	_current_id = ""
	if _ghost:
		_ghost.queue_free()
		_ghost = null

func _physics_process(_delta: float) -> void:
	if not _active or not _ghost:
		return
	var player: Node3D = _get_local_player()
	if not player:
		return
	var cam: Camera3D = get_viewport().get_camera_3d()
	if not cam:
		return
	var center: Vector2 = get_viewport().get_visible_rect().size * 0.5
	var ray_o: Vector3 = cam.project_ray_origin(center)
	var ray_d: Vector3 = cam.project_ray_normal(center)
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var q: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_o, ray_o + ray_d * 20.0)
	q.exclude = [player]
	var hit: Dictionary = space.intersect_ray(q)
	if hit:
		var pos: Vector3 = hit.get("position", Vector3.ZERO)
		var normal: Vector3 = hit.get("normal", Vector3.UP)
		var snapped: Vector3 = pos.snapped(Vector3(PLACE_SNAP, 0.001, PLACE_SNAP))
		_ghost.global_position = snapped
		_ghost.rotation.y = _ghost_rot_y
		_valid = normal.y > 0.55
	else:
		_valid = false
	_apply_ghost_mat(_ghost, _mat_ok if _valid else _mat_bad)

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action("build_place") and event.is_pressed() and not event.is_echo() and _valid:
		_do_place()
	elif event.is_action("build_rotate") and event.is_pressed() and not event.is_echo():
		_ghost_rot_y += PI * 0.5
	elif event.is_action("build_cancel") and event.is_pressed() and not event.is_echo():
		deactivate()

func _do_place() -> void:
	if not _ghost:
		return
	# Проверить что у игрока есть предмет
	var player := _get_local_player()
	if not player:
		return
	var inv: PlayerInventory = player.get_node_or_null("PlayerInventory") as PlayerInventory
	if inv and not inv.has_item(_current_id):
		return
	if inv:
		inv.remove_item(_current_id)
	_place_rpc.rpc_id(1, _current_id, _ghost.global_position, _ghost_rot_y)

@rpc("any_peer", "call_remote", "reliable")
func _place_rpc(item_id: String, pos: Vector3, rot_y: float) -> void:
	if not multiplayer.is_server():
		return
	var scene_path: String = ItemDatabase.get_item(item_id).get("scene", "")
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		_place_fallback_rpc(item_id, pos, rot_y)
		return
	var building_scene: PackedScene = load(scene_path) as PackedScene
	if not building_scene:
		push_error("Failed to load building scene: " + scene_path)
		_place_fallback_rpc(item_id, pos, rot_y)
		return
	var building: Node = building_scene.instantiate()
	building.global_position = pos
	building.rotation.y = rot_y
	var buildings: Node = get_node_or_null("/root/GameWorld/BuildingsContainer")
	if buildings:
		buildings.add_child(building, true)

func _place_fallback_rpc(item_id: String, pos: Vector3, rot_y: float) -> void:
	var building := _make_fallback_ghost()
	building.global_position = pos
	building.rotation.y = rot_y
	var buildings: Node = get_node_or_null("/root/GameWorld/BuildingsContainer")
	if buildings:
		buildings.add_child(building, true)

func _make_fallback_ghost() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.0, 2.0, 0.3)
	mi.mesh = bm
	return mi

func _apply_ghost_mat(node: Node3D, mat: StandardMaterial3D) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			child.material_override = mat
	if node is MeshInstance3D:
		node.material_override = mat

func _get_local_player() -> Node3D:
	var container: Node = get_node_or_null("/root/GameWorld/PlayersContainer")
	if not container:
		return null
	var my_id: String = str(multiplayer.get_unique_id())
	var player: Node3D = container.get_node_or_null(my_id) as Node3D
	return player
