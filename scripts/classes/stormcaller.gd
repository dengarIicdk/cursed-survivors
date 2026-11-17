extends Player
class_name Stormcaller
const FXKit := preload("res://scripts/fx/fx_kit.gd")


## Shaman class. Lightning chain, attack speed scaling, Surge ability.

var attack_speed_per_level: float = 0.10
var surge_kill_count: int = 0
var surge_threshold: int = 50
var _total_attack_speed_bonus: float = 0.0


func _on_ready_class_specific() -> void:
	var lightning_scene: PackedScene = preload("res://scenes/weapons/lightning_chain.tscn")
	weapon_manager.add_weapon(lightning_scene)
	EventBus.enemy_killed.connect(_on_enemy_killed_storm)
	EventBus.level_up.connect(on_level_up)


func _on_enemy_killed_storm(_enemy: Node, _position: Vector2) -> void:
	surge_kill_count += 1
	if surge_kill_count >= surge_threshold:
		surge_kill_count = 0
		_trigger_surge()


func _trigger_surge() -> void:
	EventBus.surge_triggered.emit()
	
	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 100
	get_tree().root.add_child(hud_layer)
	var flash := ColorRect.new()
	flash.anchors_preset = Control.PRESET_FULL_RECT
	flash.color = Color(0.65, 0.9, 1.0, 0.55)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(flash)
	var tween := flash.create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.45)
	tween.tween_callback(hud_layer.queue_free)
	for i in range(14):
		var strike_pos: Vector2 = global_position + Vector2(randf_range(-420, 420), randf_range(-260, 260))
		FXKit.lightning(get_tree().root, strike_pos + Vector2(0, -180), strike_pos,
			Color(0.6, 0.9, 1.0), 3.0)
	
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		enemy.take_damage(100.0)


func _on_level_up_class_specific(_new_level: int) -> void:
	_total_attack_speed_bonus += attack_speed_per_level
	weapon_manager.apply_attack_speed_bonus(_total_attack_speed_bonus)
