extends BaseWeapon
class_name BladeAura
const FXKit := preload("res://scripts/fx/fx_kit.gd")
const BOOMERANG := preload("res://scripts/weapons/boomerang_blade.gd")


## Ironclad's blade aura: a spinning ring of swords that also flings blades out
## and pulls them back. The orbit tickles whatever stands next to you, while the
## boomerangs are the real damage - they cut on the way out AND on the way home.

var radius: float = 60.0
var rotation_speed: float = 3.0
var blade_count: int = 4
var knockback_force: float = 50.0
var shockwave_on_crit: bool = false
var crit_chance: float = 0.15
## Boomerang flight: how often a blade is thrown, how many at once, how far.
var boomerang_interval: float = 1.7
var boomerang_count: int = 1
var boomerang_reach: float = 150.0
var boomerang_damage_mult: float = 1.15

var _throw_timer: float = 0.0
var _throw_index: int = 0

var _aura_rotation: float = 0.0
var _damage_timer: float = 0.0
var _enemies_hit_this_cycle: Array = []
var _visual: Node2D = null


func _ready() -> void:
	super._ready()
	weapon_name = "Blade Aura"
	base_damage = 12.0
	attack_speed = 1.5
	required_passive = "Phoenix Feather"
	upgrade_descriptions = [
		"Blades orbit you and fly out as boomerangs",
		"Wider orbit (80px) and longer flights",
		"+2 blades (6 total)",
		"Two boomerangs launched at once",
		"Boomerangs detonate on crits — ready to evolve!",
	]
	call_deferred("_build_visual")


func _weapon_process(delta: float) -> void:
	_aura_rotation += rotation_speed * delta
	_damage_timer += delta
	_throw_timer += delta

	if _visual and is_instance_valid(_visual) and _player and is_instance_valid(_player):
		_visual.global_position = _player.global_position
		_visual.rotation = _aura_rotation

	var wm: Node = _player.get_node_or_null("WeaponManager") if _player else null
	var cd_mult: float = wm.get_cooldown_multiplier() if wm else 1.0
	if _throw_timer >= boomerang_interval * cd_mult:
		_throw_timer = 0.0
		_throw_boomerangs()

	var interval: float = get_attack_interval()
	if _damage_timer >= interval:
		_damage_timer = 0.0
		_enemies_hit_this_cycle.clear()
		_deal_aura_damage()


func _deal_aura_damage() -> void:
	if not _player or not is_instance_valid(_player):
		return
	var enemies := get_enemies_in_radius(_player.global_position, radius)
	for enemy in enemies:
		if enemy in _enemies_hit_this_cycle:
			continue
		_enemies_hit_this_cycle.append(enemy)
		
		var dmg: float = get_damage()
		var is_crit: bool = randf() < crit_chance
		if is_crit:
			dmg *= 2.0
		
		var knockback_dir: Vector2 = (enemy.global_position - _player.global_position).normalized()
		enemy.take_damage(dmg, knockback_dir * knockback_force)
		
		if is_crit and shockwave_on_crit:
			_spawn_shockwave(enemy.global_position)
		
		if _player and is_instance_valid(_player):
			var hc: HealthComponent = _player.get_node_or_null("HealthComponent")
			if hc and hc.lifesteal > 0.0:
				hc.heal_from_lifesteal(dmg, hc.lifesteal)


func _throw_boomerangs() -> void:
	if not _player or not is_instance_valid(_player):
		return
	for i in range(boomerang_count):
		var slot: int = (_throw_index + i) % maxi(blade_count, 1)
		_throw_index = (_throw_index + 1) % maxi(blade_count, 1)
		var angle: float = _aura_rotation + TAU / float(maxi(blade_count, 1)) * float(slot)
		var start: Vector2 = _player.global_position + Vector2.from_angle(angle) * radius * 0.5
		var blade: Node2D = BOOMERANG.new()
		blade.setup(_player, self, get_damage() * boomerang_damage_mult,
			boomerang_reach, Vector2.from_angle(angle), crit_chance)
		get_tree().root.add_child(blade)
		blade.global_position = start


func _spawn_shockwave(pos: Vector2) -> void:
	var sw := Area2D.new()
	sw.collision_layer = 8
	sw.collision_mask = 4
	
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 80.0
	shape.shape = circle
	sw.add_child(shape)
	
	FXKit.shockwave(get_tree().root, pos, 170.0, Color(1.0, 0.82, 0.36, 0.9))
	
	sw.global_position = pos
	get_tree().root.add_child(sw)
	
	var enemies := get_enemies_in_radius(pos, 80.0)
	for enemy in enemies:
		enemy.take_damage(get_damage() * 0.5)
	
	var tween := sw.create_tween()
	tween.tween_interval(0.1)
	tween.tween_callback(sw.queue_free)


func _build_visual() -> void:
	if not _player or not is_instance_valid(_player):
		call_deferred("_build_visual")
		return
	if _visual and is_instance_valid(_visual):
		_visual.queue_free()
	_visual = Node2D.new()
	_visual.z_index = 6
	var ring := FXKit.sprite(FXKit.TEX_RING, radius * 2.0, Color(1.0, 0.78, 0.36, 0.22))
	FXKit.additive(ring)
	_visual.add_child(ring)
	var blade_px: float = 40.0 if not is_evolved else 58.0
	for i in range(blade_count):
		var b: Sprite2D = FXKit.blade(blade_px)
		var a: float = TAU / float(blade_count) * float(i)
		b.position = Vector2(cos(a), sin(a)) * radius
		b.rotation = a + PI * 0.5
		_visual.add_child(b)
	_player.add_child(_visual)
	_visual.global_position = _player.global_position


func _on_upgrade() -> void:
	match weapon_level:
		2:
			radius = 80.0
			boomerang_reach = 190.0
		3: blade_count = 6
		4: boomerang_count = 2
		5: shockwave_on_crit = true
	_build_visual()


func _on_evolve() -> void:
	weapon_name = "Juggernaut Spin"
	radius *= 2.0
	base_damage *= 1.8
	rotation_speed *= 1.5
	shockwave_on_crit = true
	boomerang_count = 3
	boomerang_reach *= 1.35
	crit_chance = 0.3
	_build_visual()
