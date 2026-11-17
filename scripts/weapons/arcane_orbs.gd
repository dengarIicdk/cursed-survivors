extends BaseWeapon
class_name ArcaneOrbs
const FXKit := preload("res://scripts/fx/fx_kit.gd")


## Hexblade's starting weapon. Orbiting arcane orbs that damage on contact.

var orb_count: int = 1
var orb_radius: float = 40.0
var orb_speed: float = 2.6
var orb_size: float = 10.0
var homing: bool = false

var _orbs: Array[Node] = []
var _angle_offset: float = 0.0
var _hit_cooldowns: Dictionary = {}


func _ready() -> void:
	super._ready()
	weapon_name = "Arcane Orbs"
	base_damage = 22.0
	attack_speed = 1.0
	required_passive = "Grimoire"
	upgrade_descriptions = [
		"1 orbiting arcane orb",
		"2 orbiting arcane orbs",
		"3 orbiting arcane orbs",
		"Orbs grow larger (+4px radius)",
		"Orbs gain homing — ready to evolve!",
	]
	call_deferred("_spawn_orbs")


func _weapon_process(delta: float) -> void:
	_angle_offset += orb_speed * delta
	_update_orb_positions()
	_tick_hit_cooldowns(delta)


func _spawn_orbs() -> void:
	for orb in _orbs:
		if is_instance_valid(orb):
			orb.queue_free()
	_orbs.clear()
	
	for i in range(orb_count):
		var orb := Area2D.new()
		orb.collision_layer = 8
		orb.collision_mask = 12
		orb.add_to_group("player_projectiles")
		
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = orb_size * 1.8
		shape.shape = circle
		orb.add_child(shape)
		
		var visual := FXKit.orb(orb_size * 2.3, is_evolved)
		orb.add_child(visual)
		
		orb.area_entered.connect(_on_orb_hit.bind(orb))
		get_tree().root.add_child(orb)
		_orbs.append(orb)


func _update_orb_positions() -> void:
	if not _player or not is_instance_valid(_player):
		return
	for i in range(_orbs.size()):
		var orb := _orbs[i]
		if not is_instance_valid(orb):
			continue
		var angle: float = _angle_offset + (TAU / _orbs.size()) * i
		orb.global_position = _player.global_position + Vector2(cos(angle), sin(angle)) * orb_radius


func _on_orb_hit(area: Area2D, _orb: Area2D) -> void:
	var enemy := area.get_parent()
	if not enemy or not enemy.has_method("take_damage"):
		return
	if _hit_cooldowns.get(enemy, 0.0) > 0.0:
		return
	enemy.take_damage(get_damage())
	AudioManager.play_sfx("orb_hit", 0.6)
	_hit_cooldowns[enemy] = 0.4
	
	if _player and is_instance_valid(_player):
		var hc: HealthComponent = _player.get_node_or_null("HealthComponent")
		if hc and hc.lifesteal > 0.0:
			hc.heal_from_lifesteal(get_damage(), hc.lifesteal)


func _tick_hit_cooldowns(delta: float) -> void:
	var to_remove: Array = []
	for enemy in _hit_cooldowns:
		_hit_cooldowns[enemy] -= delta
		if _hit_cooldowns[enemy] <= 0.0:
			to_remove.append(enemy)
	for e in to_remove:
		_hit_cooldowns.erase(e)


func _exit_tree() -> void:
	for orb in _orbs:
		if is_instance_valid(orb):
			orb.queue_free()
	_orbs.clear()


func _on_upgrade() -> void:
	match weapon_level:
		2: orb_count = 2
		3:
			orb_count = 3
			orb_radius = 50.0
		4: orb_size += 4.0
		5: homing = true
	_spawn_orbs()


func _on_evolve() -> void:
	weapon_name = "Chaos Vortex"
	orb_count = 6
	orb_radius = 120.0
	orb_size = 14.0
	orb_speed = 3.5
	base_damage *= 2.0
	_spawn_orbs()
