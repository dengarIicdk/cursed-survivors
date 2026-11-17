extends BaseWeapon
class_name ShieldBash
const FXKit := preload("res://scripts/fx/fx_kit.gd")

## Ironclad's crowd control: slam the shield into the ground, blasting
## everything around you away and leaving it dazed.

var radius: float = 104.0
var bash_interval: float = 2.3
var stun_duration: float = 0.4
var knockback_force: float = 300.0
var heal_per_hit: float = 0.0
var double_pulse: bool = false
var _timer: float = 0.0

## Ready ring: dim while the slam recharges, bright and pulsing when it is up.
var _indicator: Sprite2D


func _ready() -> void:
	super._ready()
	weapon_name = "Shield Bash"
	base_damage = 22.0
	attack_speed = 1.0
	required_passive = "Iron Heart"
	upgrade_descriptions = [
		"Shockwave slam that staggers nearby enemies",
		"Larger blast (130px)",
		"Longer stagger (0.7s)",
		"Two slams per cast",
		"Slams heal you a little — ready to evolve!",
	]
	_add_indicator()


func _add_indicator() -> void:
	if _indicator and is_instance_valid(_indicator):
		return
	_indicator = Sprite2D.new()
	_indicator.name = "BashReady"
	_indicator.texture = load("res://assets/sprites/fx/ring.png")
	_indicator.z_index = -2
	_indicator.modulate = Color(1.0, 0.62, 0.28, 0.0)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_indicator.material = mat
	add_child(_indicator)
	_update_indicator_scale()


func _update_indicator_scale() -> void:
	if not _indicator or not is_instance_valid(_indicator):
		return
	# ring.png is 128px wide, so this maps the sprite onto the actual blast radius
	_indicator.scale = Vector2.ONE * (radius / 62.0)


func _indicator_progress() -> float:
	var wm: Node = _player.get_node_or_null("WeaponManager") if _player else null
	var cd_mult: float = wm.get_cooldown_multiplier() if wm else 1.0
	var full: float = bash_interval * cd_mult
	return clampf(_timer / maxf(full, 0.01), 0.0, 1.0)


func _weapon_process(delta: float) -> void:
	if not _player or not is_instance_valid(_player):
		return
	var wm: Node = _player.get_node_or_null("WeaponManager")
	var cd_mult: float = wm.get_cooldown_multiplier() if wm else 1.0

	_timer += delta
	_animate_indicator(delta)
	if _timer < bash_interval * cd_mult:
		return
	_timer = 0.0
	_slam()
	if double_pulse:
		var t := create_tween()
		t.tween_interval(0.2)
		t.tween_callback(_slam)


func _flash_indicator() -> void:
	if not _indicator or not is_instance_valid(_indicator):
		return
	var t := create_tween()
	_indicator.modulate.a = 0.95
	t.tween_property(_indicator, "modulate:a", 0.0, 0.35)


func _animate_indicator(delta: float) -> void:
	if not _indicator or not is_instance_valid(_indicator):
		_add_indicator()
		return
	if _indicator.scale.x < radius / 62.0 - 0.01:
		_update_indicator_scale()
	var ready: float = _indicator_progress()
	if ready >= 0.999:
		# ready: slow warm pulse instead of a static ring
		var phase: float = fmod(Time.get_ticks_msec() / 1000.0, 1.6) / 1.6
		var pulse: float = 0.42 + 0.18 * sin(phase * TAU)
		_indicator.modulate.a = pulse
		_indicator.scale = Vector2.ONE * (radius / 62.0) * (1.0 + 0.02 * sin(phase * TAU))
	else:
		_indicator.modulate.a = 0.10 + 0.30 * ready
		_indicator.scale = Vector2.ONE * (radius / 62.0) * lerpf(0.82, 1.0, ready)


func _slam() -> void:
	if not _player or not is_instance_valid(_player):
		return

	var origin: Vector2 = _player.global_position
	_flash_indicator()
	var enemies := get_enemies_in_radius(origin, radius)
	var damage_value: float = get_damage()

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var push: Vector2 = origin.direction_to(enemy.global_position)
		enemy.take_damage(damage_value, push * knockback_force)
		if enemy.has_method("apply_stun"):
			enemy.apply_stun(stun_duration)
		FXKit.hit_spark(get_tree().root, enemy.global_position, Color(0.8, 0.92, 1.0))
		if heal_per_hit > 0.0:
			var hc: HealthComponent = _player.get_node_or_null("HealthComponent")
			if hc:
				hc.heal(heal_per_hit)

	FXKit.shockwave(get_tree().root, origin, radius * 1.9, Color(0.85, 0.9, 1.0, 0.75))
	FXKit.flash(get_tree().root, origin, radius * 0.7, Color(0.8, 0.88, 1.0, 0.5))
	AudioManager.play_sfx("hit_heavy", 0.9, 0.82)


func _on_upgrade() -> void:
	match weapon_level:
		2:
			radius = 130.0
			base_damage = 28.0
		3:
			stun_duration = 0.7
		4:
			double_pulse = true
			base_damage = 34.0
		5:
			heal_per_hit = 0.4


func _on_evolve() -> void:
	weapon_name = "Bulwark Eclipse"
	base_damage *= 2.0
	radius = 180.0
	stun_duration = 0.9
	knockback_force = 460.0
	heal_per_hit = 0.8
	bash_interval = 1.9