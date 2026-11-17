extends Player
class_name Hexblade
const FXKit := preload("res://scripts/fx/fx_kit.gd")


## Dark Mage class. Orbiting arcane orbs, spectral clones on kill.

var passive_bonus_per_level: float = 0.15
var spectral_clone_chance: float = 0.10


func _on_ready_class_specific() -> void:
	var orbs_scene: PackedScene = preload("res://scenes/weapons/arcane_orbs.tscn")
	weapon_manager.add_weapon(orbs_scene)
	EventBus.enemy_killed.connect(_on_enemy_killed_hexblade)
	EventBus.level_up.connect(on_level_up)


func _on_enemy_killed_hexblade(_enemy: Node, position: Vector2) -> void:
	if randf() < spectral_clone_chance:
		_spawn_spectral_clone(position)


func _spawn_spectral_clone(pos: Vector2) -> void:
	var clone := Node2D.new()
	clone.global_position = pos
	
	var visual := Sprite2D.new()
	visual.texture = preload("res://assets/sprites/heroes/hexblade.png")
	visual.scale = Vector2(0.42, 0.42)
	visual.modulate = Color(0.75, 0.45, 1.0, 0.62)
	clone.add_child(visual)
	var halo := FXKit.glow_sprite(70.0, Color(0.7, 0.35, 1.0, 0.45))
	clone.add_child(halo)
	
	get_tree().root.add_child(clone)
	
	var lifetime: float = 3.0
	var elapsed: float = 0.0
	
	var echo_damage: float = get_damage_multiplier() * 10.0
	var scene_tree: SceneTree = get_tree()
	var timer := Timer.new()
	timer.wait_time = 0.5
	timer.timeout.connect(func():
		# The echo outlives a scene swap, so never touch a freed hero or tree.
		if not is_instance_valid(clone) or not clone.is_inside_tree():
			timer.queue_free()
			return
		elapsed += 0.5
		if elapsed >= lifetime:
			clone.queue_free()
			timer.queue_free()
			return
		if not is_instance_valid(scene_tree):
			timer.queue_free()
			return
		for e in scene_tree.get_nodes_in_group("enemies"):
			if not is_instance_valid(e):
				continue
			if clone.global_position.distance_to(e.global_position) < 80.0:
				e.take_damage(echo_damage)
				break
	)
	clone.add_child(timer)
	timer.start()
	
	var tween := clone.create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(visual, "modulate:a", 0.0, 0.5)


func _on_level_up_class_specific(_new_level: int) -> void:
	_level_damage_bonus += passive_bonus_per_level
