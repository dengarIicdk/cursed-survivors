extends CharacterBody2D
class_name BaseEnemy
const FXKit := preload("res://scripts/fx/fx_kit.gd")


## Base class for all enemies. Extended by specific enemy types.

signal died(enemy: Node, position: Vector2)

@export var max_hp: float = 50.0
@export var base_speed: float = 80.0
@export var base_damage: float = 10.0
@export var xp_value: int = 2

## Inside this radius the ring is spent and its members simply charge.
const END_RING_RADIUS: float = 44.0

var current_hp: float = 50.0
var speed: float = 80.0
var damage: float = 10.0
var is_elite: bool = false
var is_pooled: bool = true
var is_active: bool = false

var knockback_velocity: Vector2 = Vector2.ZERO
var _stun_timer: float = 0.0
var _knock_timer: float = 0.0
var _chill_timer: float = 0.0
var _chill_factor: float = 1.0
var _poison_timer: float = 0.0
var _poison_dps: float = 0.0
var _poison_duration: float = 0.0

var _target: Node = null
var _stop_distance: float = 22.0
var _orbit_angle: float = 0.0
var _elite_modulate: Color = Color(1.5, 1.2, 0.3, 1.0)

# --- closing-ring membership -------------------------------------------------
var ring_tint: bool = false
var is_ring_member: bool = false
var ring_center: Vector2 = Vector2.ZERO
var ring_angle: float = 0.0
var ring_radius: float = 0.0
var _ring_aura: Sprite2D = null
var _damage_label: Node2D = null

# --- telegraphed signature attack (overridden by each enemy type) ---
## Seconds between attacks; subclasses override in _ready().
var attack_cooldown: float = 6.0
## How close the target must be for the attack to start.
var attack_range: float = 220.0
var _attack_timer: float = 0.0
var _windup: float = 0.0
var _windup_color: Color = Color(1.0, 0.35, 0.3)


func setup(target: Node, elite: bool = false) -> void:
	# A body coming back from the pool must forget the closing ring it may
	# have belonged to, or it would fly to a circle that no longer exists.
	_clear_ring_state()
	_target = target
	is_elite = elite
	current_hp = max_hp
	speed = base_speed
	damage = base_damage
	is_active = true
	visible = true
	_stop_distance = randf_range(2.0, 18.0)
	_orbit_angle = randf() * TAU
	_stun_timer = 0.0
	_knock_timer = 0.0
	_chill_timer = 0.0
	_chill_factor = 1.0
	_windup = 0.0
	_contact_cd = 0.0
	_attack_timer = attack_cooldown * randf_range(0.4, 1.0)
	
	if elite:
		current_hp *= 1.5
		max_hp = current_hp
		speed *= 1.1
		damage *= 1.35
		modulate = _elite_modulate
	else:
		modulate = Color.WHITE
	if ring_tint:
		modulate = _elite_modulate if is_elite else Color(1.0, 0.62, 0.62, 1.0)

	# The night grows crueller: ordinary wretches gain power as the run drags on.
	# Bosses (very large HP pools) keep their hand-authored stats.
	if max_hp < 600.0:
		var minutes: float = minf(GameManager.run_time / 60.0, 12.0)
		var hp_mult: float = 1.0 + minutes * 0.42
		var dmg_mult: float = 1.0 + minutes * 0.36
		var spd_mult: float = minf(1.0 + GameManager.run_time / 600.0 * 0.30, 1.32)
		current_hp *= hp_mult
		max_hp = current_hp
		damage *= dmg_mult
		speed *= spd_mult
	
	set_physics_process(true)
	set_process(true)


func _physics_process(delta: float) -> void:
	if not is_active:
		return
	
	if _chill_timer > 0.0:
		_chill_timer -= delta
		if _chill_timer <= 0.0:
			_chill_factor = 1.0
			modulate = _elite_modulate if is_elite else Color.WHITE

	if _stun_timer > 0.0:
		_stun_timer -= delta
		return
	
	if _windup > 0.0:
		# Frozen while telegraphing: the player can read the attack and react.
		velocity = Vector2.ZERO
		_apply_spacing(delta)
		move_and_slide()
		return

	if _knock_timer > 0.0:
		# A short impulse, never a permanent shove: once it runs out the wretch
		# closes in again instead of drifting forever.
		_knock_timer -= delta
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, minf(delta * 14.0, 1.0))
		velocity = knockback_velocity
	else:
		knockback_velocity = Vector2.ZERO
		_move(delta)
	if not is_ring_member:
		_apply_spacing(delta)

	move_and_slide()


func _process(delta: float) -> void:
	if not is_active:
		return
	if _contact_cd > 0.0:
		_contact_cd -= delta
	_update_poison(delta)
	_tick_attack(delta)
	_enemy_process(delta)


func _move(delta: float) -> void:
	# Ring members hold the wall: they ride the shrinking circle instead of
	# chasing the hero, so the only way out is through them.
	if is_ring_member and ring_radius > END_RING_RADIUS:
		var target: Vector2 = ring_center + Vector2.from_angle(ring_angle) * ring_radius
		var gap: float = global_position.distance_to(target)
		if gap > 4.0:
			velocity = global_position.direction_to(target) * minf(speed * 2.6, gap * 7.0)
		else:
			velocity = Vector2.ZERO
		return
	_move_toward_target(delta)


func _move_toward_target(_delta: float) -> void:
	if not _target or not is_instance_valid(_target):
		velocity = Vector2.ZERO
		return
	var direction: Vector2 = global_position.direction_to(_target.global_position)
	velocity = direction * speed * _chill_factor


## Keeps a personal ring slot so a crowd surrounds the player instead of
## stacking up into one invisible pile. Works for every subclass.
func _apply_spacing(delta: float) -> void:
	if not _target or not is_instance_valid(_target):
		return
	var to_target: Vector2 = _target.global_position - global_position
	var distance: float = to_target.length()
	if distance > _stop_distance + 6.0:
		return
	var direction: Vector2 = to_target / maxf(distance, 0.001)
	var inward: float = velocity.dot(direction)
	if inward > 0.0:
		velocity -= direction * inward
	_orbit_angle += delta * 0.8
	velocity += direction.orthogonal() * speed * 0.22
	if distance < _stop_distance - 12.0:
		velocity -= direction * speed * 0.8


func _enemy_process(_delta: float) -> void:
	pass


# ---------------------------------------------------------------- attacks

func _tick_attack(delta: float) -> void:
	if _windup > 0.0:
		_windup -= delta
		if _windup <= 0.0:
			_release_attack()
		return
	if not _target or not is_instance_valid(_target):
		return
	_attack_timer -= delta
	if _attack_timer > 0.0:
		return
	if global_position.distance_to(_target.global_position) > attack_range:
		_attack_timer = 0.2
		return
	_attack_timer = attack_cooldown * randf_range(0.85, 1.2)
	_begin_attack()


## Starts a readable wind-up: the body glows in the attack colour and a ring
## shrinks onto it, so a crowd telegraphs instead of silently deleting HP.
func _telegraph(duration: float, color: Color) -> void:
	_windup = duration
	_windup_color = color
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(color.r * 2.0, color.g * 2.0, color.b * 2.0, 1.0), duration * 0.8)
	tween.tween_property(self, "modulate", _elite_modulate if is_elite else Color.WHITE, 0.18)
	FXKit.hit_spark(get_tree().root, global_position, color)


func _begin_attack() -> void:
	_release_attack()


func _release_attack() -> void:
	pass


## Fires a damaging projectile at the target. Returns the spawned node.
func _shoot(at: Vector2, damage_scale: float, speed: float, color: Color, radius: float = 9.0) -> Node2D:
	var Scene: PackedScene = preload("res://scenes/enemies/enemy_projectile.tscn")
	var bolt: Node2D = Scene.instantiate()
	bolt.setup(global_position, at, damage * damage_scale, speed, color, radius)
	get_tree().root.add_child(bolt)
	return bolt


## Damage everything of the player's inside a circle. Returns true on a hit.
func _aoe_damage(radius: float, damage_scale: float, effect: String = "") -> bool:
	if not _target or not is_instance_valid(_target):
		return false
	var player: Node = _target
	if player.global_position.distance_to(global_position) > radius + 14.0:
		return false
	if not player.has_method("get_node_or_null"):
		return false
	var hc: HealthComponent = player.get_node_or_null("HealthComponent")
	if not hc:
		return false
	hc.take_damage(damage * damage_scale)
	if effect == "slow" and player.has_method("apply_slow"):
		player.apply_slow(0.35, 1.6)
	elif effect == "chill" and player.has_method("apply_slow"):
		player.apply_slow(0.28, 1.2)
	return true


## Per-body contact throttle. Being surrounded must hurt from every side, so
## the limiter lives on the enemy: each wretch can bite once per cooldown, but
## twenty wretches mean twenty bites.
var contact_cooldown: float = 1.1
var _contact_cd: float = 0.0


func try_contact_hit() -> bool:
	if _contact_cd > 0.0:
		return false
	_contact_cd = contact_cooldown
	return true


## Called by the player when this body lands a contact hit.
func on_contact_hit(_victim: Node) -> void:
	pass


func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO, silent: bool = false) -> void:
	if not is_active:
		return
	current_hp -= amount
	if not silent and amount >= 1.0:
		_show_damage(amount)
	if knockback.length_squared() > 0.01:
		knockback_velocity += knockback
		_knock_timer = 0.30
	
	AudioManager.play_sfx("hit" if amount < 40.0 else "hit_heavy", 0.55 if amount < 40.0 else 0.8)
	if randf() < 0.45:
		FXKit.hit_spark(get_tree().root, global_position, Color(1.0, 0.82, 0.5))
		if amount >= 40.0:
			FXKit.slash(get_tree().root, global_position, Color(1, 1, 1, 0.8), 54.0)

	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(2, 2, 2, 1), 0.05)
	var base_color: Color = _elite_modulate if is_elite else Color.WHITE
	tween.tween_property(self, "modulate", base_color, 0.1)
	
	if current_hp <= 0.0:
		die()


func make_ring_member(center: Vector2, radius: float, angle: float) -> void:
	is_ring_member = true
	ring_center = center
	ring_radius = radius
	ring_angle = angle
	attack_cooldown = 2.4
	_attack_timer = randf_range(0.3, 1.2)


func set_ring_radius(radius: float) -> void:
	ring_radius = radius


func _clear_ring_state() -> void:
	is_ring_member = false
	ring_tint = false
	ring_radius = 0.0
	if _ring_aura and is_instance_valid(_ring_aura):
		_ring_aura.queue_free()
	_ring_aura = null


func release_ring() -> void:
	is_ring_member = false


func add_ring_aura() -> void:
	if _ring_aura and is_instance_valid(_ring_aura):
		return
	_ring_aura = Sprite2D.new()
	_ring_aura.texture = preload("res://assets/sprites/fx/glow.png")
	_ring_aura.modulate = Color(1.0, 0.28, 0.24, 0.38)
	_ring_aura.scale = Vector2(1.5, 1.5)
	_ring_aura.z_index = -1
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_ring_aura.material = mat
	add_child(_ring_aura)
	var t := _ring_aura.create_tween()
	t.set_loops()
	t.tween_property(_ring_aura, "modulate:a", 0.18, 0.7)
	t.tween_property(_ring_aura, "modulate:a", 0.42, 0.7)


## Dissolves a ring member that the hero escaped from: no XP, no damage.
func fade_away() -> void:
	if _ring_aura and is_instance_valid(_ring_aura):
		_ring_aura.queue_free()
		_ring_aura = null
	set_physics_process(false)
	set_process(false)
	is_active = false
	var spawner: Node = get_tree().get_first_node_in_group("enemy_spawner")
	if spawner and spawner.has_method("forget_enemy"):
		spawner.call("forget_enemy", self)
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.7)
	t.tween_callback(queue_free)


## One floating number per body: extra hits merge into the one already on
## screen, so a bullet-hell build does not paint the arena with digits.
func _show_damage(amount: float) -> void:
	if is_instance_valid(_damage_label) and _damage_label.is_inside_tree():
		var age: float = float(_damage_label.get("_life"))
		if age < 0.28:
			_damage_label.call("add_amount", amount)
			return
	_damage_label = FXKit.damage_number(get_tree().root, global_position + Vector2(0, -24), amount)


func get_damage() -> float:
	return damage


func apply_stun(duration: float) -> void:
	_stun_timer = maxf(_stun_timer, duration)
	velocity = Vector2.ZERO


func apply_chill(slow_fraction: float, duration: float = 2.0) -> void:
	_chill_factor = minf(_chill_factor, clampf(1.0 - slow_fraction, 0.2, 1.0))
	_chill_timer = maxf(_chill_timer, duration)
	modulate = modulate.lerp(Color(0.72, 0.9, 1.15, 1.0), 0.6)


func apply_poison(dps: float, _stacks: int, duration: float) -> void:
	_poison_dps = maxf(_poison_dps, dps * _stacks)
	_poison_duration = maxf(_poison_duration, duration)
	_poison_timer = _poison_duration


func _update_poison(delta: float) -> void:
	if _poison_timer > 0.0:
		_poison_timer -= delta
		take_damage(_poison_dps * delta, Vector2.ZERO, true)


func die() -> void:
	if not is_active:
		return
	is_active = false
	# A pooled corpse keeps its fields: never leave a stale wind-up behind, or
	# debug tools and future AI read a frozen telegraph off a dead body.
	_windup = 0.0
	_attack_timer = attack_cooldown
	EventBus.enemy_killed.emit(self, global_position)
	
	var world: Node = get_tree().get_first_node_in_group("world")
	if world and world.has_method("spawn_xp_gem"):
		world.spawn_xp_gem(global_position, xp_value)
	
	if is_elite:
		EventBus.elite_enemy_killed.emit(self, global_position)
	
	if is_elite:
		FXKit.shockwave(get_tree().root, global_position, 200.0, Color(1.0, 0.7, 0.35, 0.9))
	else:
		FXKit.death_burst(get_tree().root, global_position, _death_tint())
	FXKit.blood_decal(get_tree().root, global_position)
	FXKit.hit_spark(get_tree().root, global_position, _death_tint())

	_on_die()
	
	if is_pooled:
		visible = false
		set_physics_process(false)
		set_process(false)
		global_position = Vector2(-9999, -9999)
	else:
		queue_free()


func _on_die() -> void:
	pass


func _death_tint() -> Color:
	return Color(1.0, 0.55, 0.55) if not is_elite else Color(1.0, 0.8, 0.3)
