extends BaseWeapon
class_name ShadowDaggers
const FXKit := preload("res://scripts/fx/fx_kit.gd")


## Wraithborn's starting weapon. Burst of homing shadow daggers.

var dagger_count: int = 3
var burst_cooldown: float = 1.5
var pierce: int = 1
var poison_stacks: int = 0
var poison_dps: float = 5.0
var dagger_speed: float = 350.0

var _burst_timer: float = 0.0


func _ready() -> void:
	super._ready()
	weapon_name = "Shadow Daggers"
	base_damage = 18.0
	required_passive = "Cursed Ring"
	upgrade_descriptions = [
		"3 homing shadow daggers per burst",
		"Faster cooldown (1.2s)",
		"5 daggers per burst",
		"Daggers pierce through 2 enemies",
		"3 poison stacks on hit — ready to evolve!",
	]


func _weapon_process(delta: float) -> void:
	_burst_timer += delta
	var wm: Node = _player.get_node_or_null("WeaponManager") if _player else null
	var cd_mult: float = wm.get_cooldown_multiplier() if wm else 1.0
	
	if _burst_timer >= burst_cooldown * cd_mult:
		_burst_timer = 0.0
		_fire_burst()


func _fire_burst() -> void:
	if not _player or not is_instance_valid(_player):
		return
	
	var all_enemies := get_tree().get_nodes_in_group("enemies")
	var active_enemies: Array = []
	for e in all_enemies:
		if is_instance_valid(e) and e.is_active:
			active_enemies.append(e)
			
	active_enemies.sort_custom(func(a, b):
		return _player.global_position.distance_squared_to(a.global_position) < \
			   _player.global_position.distance_squared_to(b.global_position)
	)
	
	for i in range(dagger_count):
		var target: Node = null
		if i < active_enemies.size():
			target = active_enemies[i]
		
		var direction: Vector2 = Vector2.RIGHT
		if target and is_instance_valid(target):
			direction = _player.global_position.direction_to(target.global_position)
		else:
			direction = Vector2.from_angle(randf() * TAU)
		
		_spawn_dagger(direction)


func _spawn_dagger(direction: Vector2) -> void:
	var dagger := Area2D.new()
	dagger.collision_layer = 8
	dagger.collision_mask = 12
	dagger.add_to_group("player_projectiles")
	
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 4)
	shape.shape = rect
	dagger.add_child(shape)
	
	var visual := FXKit.dagger(34.0)
	dagger.add_child(visual)
	
	dagger.global_position = _player.global_position
	dagger.rotation = direction.angle()
	
	get_tree().root.add_child(dagger)
	
	var hits_remaining := [pierce]
	var hit_enemies: Array = []
	
	dagger.area_entered.connect(func(area: Area2D):
		var enemy := area.get_parent()
		if not enemy or not enemy.has_method("take_damage"):
			return
		if enemy in hit_enemies:
			return
		hit_enemies.append(enemy)
		enemy.take_damage(get_damage())
		AudioManager.play_sfx("orb_hit", 0.4, 1.35)
		if poison_stacks > 0 and enemy.has_method("apply_poison"):
			enemy.apply_poison(poison_dps, poison_stacks, 3.0)
		if _player and is_instance_valid(_player):
			var hc: HealthComponent = _player.get_node_or_null("HealthComponent")
			if hc and hc.lifesteal > 0.0:
				hc.heal_from_lifesteal(get_damage(), hc.lifesteal)
		hits_remaining[0] -= 1
		if hits_remaining[0] <= 0:
			dagger.queue_free()
	)
	
	var tween := dagger.create_tween()
	var travel_distance: float = 400.0
	var travel_time: float = travel_distance / dagger_speed
	tween.tween_property(dagger, "global_position",
		dagger.global_position + direction * travel_distance, travel_time)
	tween.tween_callback(dagger.queue_free)


func _on_upgrade() -> void:
	match weapon_level:
		2: burst_cooldown = 1.2
		3: dagger_count = 5
		4: pierce = 2
		5: poison_stacks = 3


func _on_evolve() -> void:
	weapon_name = "Soul Reaper"
	base_damage *= 2.0
	dagger_count = 7
	pierce = 99
	poison_stacks = 5
	poison_dps = 10.0
	burst_cooldown = 1.0
