extends BaseWeapon
class_name LightningChain
const FXKit := preload("res://scripts/fx/fx_kit.gd")


## Stormcaller's starting weapon. Lightning that chains between nearby enemies.

var chain_range: float = 150.0
var max_jumps: int = 3
var stun_chance: float = 0.0
var electrified_zones: bool = false

## _attack_timer lives in BaseWeapon - redeclaring it is a parse error.
var _storm_cloud: Node = null


func _ready() -> void:
	super._ready()
	weapon_name = "Lightning Chain"
	base_damage = 20.0
	attack_speed = 1.25
	required_passive = "Time Shard"
	upgrade_descriptions = [
		"Lightning chains between 3 enemies",
		"Chains to 5 enemies",
		"Chain range +50px",
		"25% chance to stun enemies",
		"Leaves electrified zones — ready to evolve!",
	]


func _weapon_process(delta: float) -> void:
	_attack_timer += delta
	var interval: float = get_attack_interval()
	if _attack_timer >= interval:
		_attack_timer = 0.0
		_fire_chain()


func _fire_chain() -> void:
	if not _player or not is_instance_valid(_player):
		return
	
	var first_target := find_nearest_enemy(_player.global_position, 600.0)
	if not first_target:
		return
	
	var chain_targets: Array[Node] = []
	chain_targets.append(first_target)
	
	var last_pos: Vector2 = first_target.global_position
	for _i in range(max_jumps - 1):
		var nearest: Node = null
		var nearest_dist: float = chain_range * chain_range
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy in chain_targets or not is_instance_valid(enemy) or not enemy.is_active:
				continue
			var d: float = last_pos.distance_squared_to(enemy.global_position)
			if d < nearest_dist:
				nearest_dist = d
				nearest = enemy
		if nearest:
			chain_targets.append(nearest)
			last_pos = nearest.global_position
		else:
			break
	
	var prev_pos: Vector2 = _player.global_position
	for target in chain_targets:
		var dmg: float = get_damage()
		target.take_damage(dmg)
		
		if stun_chance > 0.0 and randf() < stun_chance:
			if target.has_method("apply_stun"):
				target.apply_stun(1.5)
		
		if electrified_zones:
			_spawn_electrified_zone(target.global_position)
		
		_draw_lightning(prev_pos, target.global_position)
		prev_pos = target.global_position
		
		if _player and is_instance_valid(_player):
			var hc: HealthComponent = _player.get_node_or_null("HealthComponent")
			if hc and hc.lifesteal > 0.0:
				hc.heal_from_lifesteal(dmg, hc.lifesteal)


func _draw_lightning(from: Vector2, to: Vector2) -> void:
	var tint: Color = Color(1.0, 0.55, 0.85) if is_evolved else Color(0.55, 0.86, 1.0)
	FXKit.lightning(get_tree().root, from, to, tint, 3.4)
	FXKit.hit_spark(get_tree().root, to, tint)
	AudioManager.play_sfx("lightning", 0.55)


func _spawn_electrified_zone(pos: Vector2) -> void:
	var zone := Area2D.new()
	zone.collision_layer = 8
	zone.collision_mask = 4
	
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 40.0
	shape.shape = circle
	zone.add_child(shape)
	
	var visual := FXKit.sprite(FXKit.TEX_RING, 76.0, Color(0.55, 0.88, 1.0, 0.55))
	FXKit.additive(visual)
	FXKit.pulse(visual, 0.10, 5.0)
	zone.add_child(visual)
	var core := FXKit.glow_sprite(70.0, Color(0.45, 0.75, 1.0, 0.30))
	zone.add_child(core)
	
	zone.global_position = pos
	get_tree().root.add_child(zone)
	
	var lifetime: float = 3.0
	var elapsed_ref := [0.0]
	
	var timer := Timer.new()
	timer.wait_time = 0.5
	timer.timeout.connect(func():
		elapsed_ref[0] += 0.5
		if elapsed_ref[0] >= lifetime:
			zone.queue_free()
			timer.queue_free()
			return
		var enemies := get_enemies_in_radius(pos, 40.0)
		for e in enemies:
			e.take_damage(get_damage() * 0.3)
	)
	zone.add_child(timer)
	timer.start()


func _on_upgrade() -> void:
	match weapon_level:
		2: max_jumps = 5
		3: chain_range = 200.0
		4: stun_chance = 0.25
		5: electrified_zones = true


func _on_evolve() -> void:
	weapon_name = "Thunderstorm"
	base_damage *= 2.5
	max_jumps = 10
	chain_range = 300.0
	stun_chance = 0.5
	electrified_zones = true
	_spawn_storm_cloud()


func _spawn_storm_cloud() -> void:
	if _storm_cloud:
		return
	_storm_cloud = FXKit.storm_cloud()
	
	if _player and is_instance_valid(_player):
		_player.add_child(_storm_cloud)
	
	var strike_timer := Timer.new()
	strike_timer.wait_time = 1.0
	strike_timer.timeout.connect(_do_storm_strike)
	_storm_cloud.add_child(strike_timer)
	strike_timer.start()


func _do_storm_strike() -> void:
	if not _player or not is_instance_valid(_player):
		return
	var enemies_on_screen := get_tree().get_nodes_in_group("enemies")
	var target: Node = null
	var nearest_dist: float = 500.0 * 500.0
	for e in enemies_on_screen:
		if not is_instance_valid(e) or not e.is_active:
			continue
		var d: float = _player.global_position.distance_squared_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			target = e
	if target:
		target.take_damage(get_damage())
		_draw_lightning(_storm_cloud.global_position, target.global_position)
