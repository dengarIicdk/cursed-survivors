extends Player
class_name Wraithborn
const FXKit := preload("res://scripts/fx/fx_kit.gd")


## Rogue class. Shadow daggers, speed scaling, auto-blink mechanic.

var speed_per_level: float = 0.10
var crit_per_level: float = 0.05
var blink_cooldown: float = 8.0
## A blink is a dodge, not a ride across the map: it never moves further than
## this, and never lands inside the crowd it is escaping.
const BLINK_MAX_DISTANCE: float = 260.0
var _blink_timer: float = 0.0


func _on_ready_class_specific() -> void:
	var daggers_scene: PackedScene = preload("res://scenes/weapons/shadow_daggers.tscn")
	weapon_manager.add_weapon(daggers_scene)
	EventBus.level_up.connect(on_level_up)


func _process(delta: float) -> void:
	_blink_timer += delta
	if _blink_timer >= blink_cooldown:
		_blink_timer = 0.0
		_do_blink()


func _do_blink() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
	
	enemies.sort_custom(func(a, b):
		return global_position.distance_squared_to(a.global_position) < \
			   global_position.distance_squared_to(b.global_position)
	)
	
	var count: int = mini(5, enemies.size())
	var centroid: Vector2 = Vector2.ZERO
	for i in range(count):
		centroid += enemies[i].global_position
	centroid /= float(count)
	
	var from_player: Vector2 = (centroid - global_position).normalized()
	if from_player == Vector2.ZERO:
		from_player = Vector2.RIGHT
	# Step away from the crowd, not into its middle: the point of the blink is
	# to break the surround. The offset is derived from the hero, not the mobs.
	var blink_pos: Vector2 = global_position - from_player * minf(
		global_position.distance_to(centroid) + 70.0, BLINK_MAX_DISTANCE)
	blink_pos.y += randf_range(-20.0, 20.0)
	
	var old_pos: Vector2 = global_position
	global_position = blink_pos
	
	EventBus.player_blinked.emit(old_pos, blink_pos)
	
	var space_state := get_world_2d().direct_space_state
	var params := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 50.0
	params.shape = circle
	params.transform = Transform2D(0.0, blink_pos)
	params.collision_mask = 4
	var results := space_state.intersect_shape(params, 20)
	for r in results:
		if r.collider and r.collider.has_method("take_damage"):
			r.collider.take_damage(get_damage_multiplier() * 25.0)
	
	FXKit.flash(get_tree().root, blink_pos, 150.0, Color(0.55, 0.25, 0.85, 0.85))
	FXKit.shockwave(get_tree().root, blink_pos, 120.0, Color(0.65, 0.35, 0.95, 0.85))


func _on_level_up_class_specific(_new_level: int) -> void:
	_level_speed_bonus += speed_per_level
	_level_crit_bonus += crit_per_level
