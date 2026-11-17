extends BaseEnemy
class_name LichKing

## Final boss. 3 phases with unique mechanics.

enum LichState { WALK, SUMMON, AOE, DEATH_ZONES }

var _state: int = LichState.WALK
var phase: int = 1
var summon_cooldown: float = 8.0
var aoe_cooldown: float = 12.0
var death_zone_interval: float = 20.0
var _summon_timer: float = 4.0
var _aoe_timer: float = 10.0
var _death_zone_timer: float = 0.0
var _active_death_zones: Array[Node] = []
var _is_enraged: bool = false


func _ready() -> void:
	max_hp = 5000.0
	base_speed = 40.0
	base_damage = 18.0
	xp_value = 500
	is_pooled = false
	add_to_group("enemies")
	add_to_group("bosses")


func _enemy_process(delta: float) -> void:
	_check_phase_transition()
	
	_summon_timer -= delta
	_aoe_timer -= delta
	
	if phase >= 3:
		_death_zone_timer -= delta
	
	if _summon_timer <= 0.0:
		_summon_timer = summon_cooldown
		_do_summon()
	
	if _aoe_timer <= 0.0:
		_aoe_timer = aoe_cooldown
		_do_aoe()
	
	if phase >= 3 and _death_zone_timer <= 0.0:
		_death_zone_timer = death_zone_interval
		_spawn_death_zones()
	
	EventBus.boss_health_changed.emit("Lich King", current_hp, max_hp)


func _check_phase_transition() -> void:
	var hp_percent: float = current_hp / max_hp
	if phase == 1 and hp_percent < 0.6:
		_enter_phase(2)
	elif phase == 2 and hp_percent < 0.3:
		_enter_phase(3)


func _enter_phase(new_phase: int) -> void:
	phase = new_phase
	speed = base_speed * (1.0 + (new_phase - 1) * 0.3)
	summon_cooldown = maxf(2.0, 8.0 - (new_phase - 1) * 2.0)
	aoe_cooldown = maxf(4.0, 12.0 - (new_phase - 1) * 3.0)
	
	if new_phase == 3:
		_is_enraged = true
		modulate = Color(1.5, 0.3, 0.3, 1.0)
		death_zone_interval = 20.0
		_death_zone_timer = 5.0
	
	EventBus.boss_phase_changed.emit("Lich King", new_phase)
	
	var flash := ColorRect.new()
	flash.anchors_preset = Control.PRESET_FULL_RECT
	flash.color = Color(0.8, 0.0, 0.8, 0.6)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.add_child(flash)
	get_tree().root.add_child(layer)
	var tween := flash.create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.5)
	tween.tween_callback(layer.queue_free)


## Bone volley: three shards in a fan, the boss's only ranged pressure.
func _begin_attack() -> void:
	_telegraph(0.4, Color(0.7, 0.35, 1.0))


func _release_attack() -> void:
	if not _target or not is_instance_valid(_target):
		return
	var base_dir: Vector2 = global_position.direction_to(_target.global_position)
	for i in range(3):
		var dir: Vector2 = base_dir.rotated((float(i) - 1.0) * 0.22)
		_shoot(global_position + dir * 300.0, 0.6, 240.0, Color(0.78, 0.45, 1.0), 10.0)


func _do_summon() -> void:
	var world: Node = get_tree().get_first_node_in_group("world")
	if not world:
		return
	match phase:
		1:
			for _i in range(3):
				world.spawn_enemy_at("shambling_corpse", global_position + Vector2(randf_range(-80, 80), randf_range(-80, 80)))
		2:
			for _i in range(2):
				world.spawn_enemy_at("armored_knight", global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100)))
		3:
			world.spawn_enemy_at("shadow_drake", global_position + Vector2(randf_range(-120, 120), randf_range(-120, 120)))


func _do_aoe() -> void:
	var aoe_radius: float = 200.0 if phase == 1 else 300.0
	var space_state := get_viewport().find_world_2d().direct_space_state
	var params := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = aoe_radius
	params.shape = circle
	params.transform = Transform2D(0.0, global_position)
	params.collision_mask = 2
	var results := space_state.intersect_shape(params, 4)
	for r in results:
		if r.collider:
			var hc: HealthComponent = r.collider.get_node_or_null("HealthComponent")
			if hc:
				hc.take_damage(base_damage * 1.5)
	
	FXKit.shockwave(get_tree().root, global_position, aoe_radius, Color(0.65, 0.25, 1.0, 0.95))
	FXKit.flash(get_tree().root, global_position, aoe_radius * 0.7, Color(0.6, 0.2, 0.95, 0.5))


func _spawn_death_zones() -> void:
	for zone in _active_death_zones:
		if is_instance_valid(zone):
			zone.queue_free()
	_active_death_zones.clear()
	
	for _i in range(5):
		var zone_pos: Vector2 = Vector2(randf_range(-300, 300), randf_range(-200, 200))
		if GameManager.player:
			zone_pos += GameManager.player.global_position
		
		var zone := Area2D.new()
		zone.collision_layer = 8
		zone.collision_mask = 2
		zone.global_position = zone_pos
		
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(80, 80)
		shape.shape = rect
		zone.add_child(shape)
		
		var visual := ColorRect.new()
		visual.size = Vector2(80, 80)
		visual.position = Vector2(-40, -40)
		visual.color = Color(0.6, 0.0, 0.0, 0.5)
		zone.add_child(visual)
		
		get_tree().root.add_child(zone)
		_active_death_zones.append(zone)
		
		var timer := Timer.new()
		timer.wait_time = 0.5
		timer.timeout.connect(func():
			if not is_instance_valid(zone):
				return
			var space_state := get_viewport().find_world_2d().direct_space_state
			var params := PhysicsShapeQueryParameters2D.new()
			params.shape = rect
			params.transform = zone.global_transform
			params.collision_mask = 2
			var results := space_state.intersect_shape(params, 4)
			for r in results:
				if r.collider:
					var hc: HealthComponent = r.collider.get_node_or_null("HealthComponent")
					if hc:
						hc.take_damage(50.0 * 0.5)
		)
		zone.add_child(timer)
		timer.start()


func _on_die() -> void:
	for zone in _active_death_zones:
		if is_instance_valid(zone):
			zone.queue_free()
	EventBus.boss_killed.emit("Lich King")
	GameManager.end_run(true)
