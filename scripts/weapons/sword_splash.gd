extends BaseWeapon
class_name SwordSplash
const FXKit := preload("res://scripts/fx/fx_kit.gd")

## Ironclad's signature attack: a wide two-handed cleave that carves through
## everything in front of the knight.

var swing_interval: float = 1.05
var reach: float = 132.0
var arc_degrees: float = 110.0
var knockback_force: float = 190.0
var lifesteal_fraction: float = 0.0
var extra_cut: bool = false
var _timer: float = 0.0


func _ready() -> void:
	super._ready()
	weapon_name = "Sword Splash"
	base_damage = 26.0
	attack_speed = 1.0
	required_passive = "Bloodstone"
	upgrade_descriptions = [
		"Wide cleave in the facing direction",
		"Longer reach (160px) and heavier blow",
		"Wider arc (150 degrees)",
		"Second cut follows the first",
		"Cleaves heal a little — ready to evolve!",
	]


func _weapon_process(delta: float) -> void:
	if not _player or not is_instance_valid(_player):
		return

	var wm: Node = _player.get_node_or_null("WeaponManager")
	var cd_mult: float = wm.get_cooldown_multiplier() if wm else 1.0

	_timer += delta
	if _timer < swing_interval * cd_mult:
		return
	_timer = 0.0
	_swing()


func _swing() -> void:
	var dir: Vector2 = _aim_direction()
	_cut(dir)
	if extra_cut:
		var t := create_tween()
		t.tween_interval(0.16)
		t.tween_callback(func(): _cut(dir.rotated(0.5)))


func _aim_direction() -> Vector2:
	var target := find_nearest_enemy(_player.global_position, reach * 2.2)
	if target and is_instance_valid(target):
		return _player.global_position.direction_to(target.global_position)
	var facing = _player.get("facing")
	if facing is Vector2 and (facing as Vector2).length() > 0.1:
		return (facing as Vector2).normalized()
	return Vector2.RIGHT


func _cut(dir: Vector2) -> void:
	if not _player or not is_instance_valid(_player):
		return

	var origin: Vector2 = _player.global_position
	var half_arc: float = deg_to_rad(arc_degrees) * 0.5
	var enemies := get_tree().get_nodes_in_group("enemies")
	var hits: int = 0

	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.is_active:
			continue
		var offset: Vector2 = enemy.global_position - origin
		var dist: float = offset.length()
		if dist > reach + 26.0:
			continue
		if dist > 1.0 and absf(dir.angle_to(offset.normalized())) > half_arc:
			continue
		enemy.take_damage(get_damage(), dir * knockback_force)
		if enemy.has_method("apply_stun"):
			enemy.apply_stun(0.12)
		FXKit.hit_spark(get_tree().root, enemy.global_position, Color(1.0, 0.72, 0.5))
		hits += 1

	if hits > 0:
		# Lifesteal is paid once per swing and capped at 1.5% max HP, so a wide
		# cleave through twenty corpses cannot out-heal the crowd.
		if lifesteal_fraction > 0.0 and _player and is_instance_valid(_player):
			var hc: HealthComponent = _player.get_node_or_null("HealthComponent")
			if hc:
				var heal_sum: float = get_damage() * lifesteal_fraction * float(hits)
				hc.heal(minf(heal_sum, hc.max_hp * 0.015))
		AudioManager.play_sfx("hit_heavy", 0.7, randf_range(0.9, 1.05))
	_swing_visual(dir, hits)


func _swing_visual(dir: Vector2, hits: int) -> void:
	var pivot := Node2D.new()
	pivot.global_position = _player.global_position
	pivot.z_index = 6
	get_tree().root.add_child(pivot)

	var blade := FXKit.blade(74.0)
	blade.position = Vector2(reach * 0.55, 0.0)
	blade.modulate = Color(1.15, 1.05, 1.35, 0.9)
	FXKit.additive(blade)
	pivot.add_child(blade)

	var half_arc: float = deg_to_rad(arc_degrees) * 0.5
	pivot.rotation = dir.angle() - half_arc
	var t := pivot.create_tween()
	t.tween_property(pivot, "rotation", dir.angle() + half_arc, 0.17) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_callback(pivot.queue_free)

	FXKit.slash(get_tree().root, _player.global_position + dir * reach * 0.55,
		Color(1.0, 0.85, 0.95, 0.95), reach * 1.15, dir.angle())
	if hits >= 3:
		FXKit.shockwave(get_tree().root, _player.global_position, reach * 0.9,
			Color(1.0, 0.6, 0.5, 0.5))


func _on_upgrade() -> void:
	match weapon_level:
		2:
			reach = 160.0
			base_damage = 32.0
		3:
			arc_degrees = 150.0
			base_damage = 38.0
		4:
			extra_cut = true
		5:
			lifesteal_fraction = 0.02
			base_damage = 44.0


func _on_evolve() -> void:
	weapon_name = "Bloodreaver"
	base_damage *= 1.9
	reach = 185.0
	arc_degrees = 360.0
	swing_interval = 0.85
	lifesteal_fraction = 0.03
	extra_cut = true