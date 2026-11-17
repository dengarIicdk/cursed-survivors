extends BaseWeapon
class_name FrostNova
const FXKit := preload("res://scripts/fx/fx_kit.gd")

## Stormcaller's chilling answer to being surrounded: a ring of frost that
## rolls outward, freezing whatever it touches.

var radius: float = 120.0
var nova_interval: float = 2.4
var stun_duration: float = 0.5
var chill_slow: float = 0.45
var double_ring: bool = false
var _timer: float = 0.0


func _ready() -> void:
	super._ready()
	weapon_name = "Frost Nova"
	base_damage = 20.0
	attack_speed = 1.0
	required_passive = "Shadow Cloak"
	upgrade_descriptions = [
		"A ring of frost that freezes nearby enemies",
		"Wider ring (150px)",
		"Freeze lasts longer (0.9s)",
		"Two rings erupt at once",
		"Ring damage up — ready to evolve!",
	]


func _weapon_process(delta: float) -> void:
	if not _player or not is_instance_valid(_player):
		return
	var wm: Node = _player.get_node_or_null("WeaponManager")
	var cd_mult: float = wm.get_cooldown_multiplier() if wm else 1.0

	_timer += delta
	if _timer < nova_interval * cd_mult:
		return
	_timer = 0.0
	_cast_nova()
	if double_ring:
		var t := create_tween()
		t.tween_interval(0.28)
		t.tween_callback(_cast_nova)


func _cast_nova() -> void:
	if not _player or not is_instance_valid(_player):
		return
	var origin: Vector2 = _player.global_position

	_ring_visual(origin)
	# damage lands as the front of the ring sweeps outward
	var t := create_tween()
	t.tween_interval(0.14)
	t.tween_callback(func(): _apply_damage(origin))


func _apply_damage(origin: Vector2) -> void:
	var damage_value: float = get_damage()
	for enemy in get_enemies_in_radius(origin, radius):
		if not is_instance_valid(enemy):
			continue
		enemy.take_damage(damage_value)
		if enemy.has_method("apply_stun"):
			enemy.apply_stun(stun_duration)
		if enemy.has_method("apply_chill"):
			enemy.apply_chill(chill_slow)
		FXKit.hit_spark(get_tree().root, enemy.global_position, Color(0.6, 0.92, 1.0))
	AudioManager.play_sfx("lightning", 0.35, 1.25)


func _ring_visual(origin: Vector2) -> void:
	FXKit.shockwave(get_tree().root, origin, radius * 1.75, Color(0.62, 0.88, 1.0, 0.85))
	FXKit.flash(get_tree().root, origin, radius * 0.55, Color(0.5, 0.85, 1.0, 0.35))
	var crystals := 8
	for i in range(crystals):
		var a: float = TAU * float(i) / float(crystals) + randf() * 0.2
		var pos: Vector2 = origin + Vector2.from_angle(a) * radius * randf_range(0.45, 0.95)
		var shard := FXKit.glow_sprite(26.0, Color(0.7, 0.95, 1.0, 0.75))
		shard.global_position = pos
		shard.z_index = 5
		get_tree().root.add_child(shard)
		var t := shard.create_tween()
		t.set_parallel(true)
		t.tween_property(shard, "scale", shard.scale * 1.7, 0.3)
		t.tween_property(shard, "modulate:a", 0.0, 0.3)
		t.chain().tween_callback(shard.queue_free)


func _on_upgrade() -> void:
	match weapon_level:
		2:
			radius = 150.0
			base_damage = 26.0
		3:
			stun_duration = 0.9
		4:
			double_ring = true
		5:
			base_damage = 34.0
			radius = 166.0


func _on_evolve() -> void:
	weapon_name = "Absolute Zero"
	base_damage *= 1.9
	radius = 210.0
	stun_duration = 1.4
	nova_interval = 1.8
	double_ring = true