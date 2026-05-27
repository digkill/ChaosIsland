extends StaticBody3D

var _triggered: bool = false
var _trigger_area: Area3D

func _ready() -> void:
	_trigger_area = $TriggerArea
	_trigger_area.body_entered.connect(_on_body_entered)
	# Покрасить кокос
	var mesh: MeshInstance3D = $CoconutMesh
	if mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.45, 0.3, 0.15)
		mat.roughness = 0.85
		mesh.material_override = mat

func _on_body_entered(body: Node) -> void:
	if _triggered:
		return
	if not body is CharacterBody3D:
		return
	_triggered = true
	# Взрыв кокоса — подбросить игрока
	if body.has_method("set_jump_force"):
		body.set_jump_force(22.0)
		body.velocity.y = 22.0
		# Вернуть force через секунду
		await get_tree().create_timer(0.2).timeout
		body.set_jump_force(-1.0)
	# Визуальная вспышка
	var mesh: MeshInstance3D = $CoconutMesh
	if mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.8, 0.0)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.5, 0.0)
		mat.emission_energy_multiplier = 3.0
		mesh.material_override = mat
	await get_tree().create_timer(0.3).timeout
	queue_free()
