extends Area2D

## Homing projectile used by Chaos Bolt. Steers toward its victim, then bursts.

const FXKit := preload("res://scripts/fx/fx_kit.gd")

var target: Node = null
var speed: float = 400.0
var damage: float = 20.0
var turn_rate: float = 4.5
var explode_radius: float = 54.0
var lifetime: float = 2.6
var tint: Color = Color(0.78, 0.42, 1.0, 1.0)
var weapon: Node = null

var _direction: Vector2 = Vector2.RIGHT
var _spent: bool = false


func _ready() -> void:
	collision_layer = 8
	collision_mask = 12
	monitoring = true
	add_to_group("player_projectiles")

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	shape.shape = circle
	add_child(shape)

	var core := FXKit.orb(30.0, true)
	add_child(core)
	var glow := FXKit.glow_sprite(64.0, tint)
	add_child(glow)
	FXKit.pulse(core, 0.16, 9.0)

	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if _spent:
		return
	lifetime -= delta
	if lifetime <= 0.0:
		_burst(global_position)
		return

	if is_instance_valid(target) and target.get("is_active"):
		var wanted: Vector2 = global_position.direction_to(target.global_position)
		_direction = _direction.slerp(wanted, clampf(turn_rate * delta, 0.0, 1.0)).normalized()
	elif target != null and not is_instance_valid(target):
		target = null

	global_position += _direction * speed * delta
	rotation = _direction.angle()


func _on_area_entered(area: Area2D) -> void:
	var enemy := area.get_parent()
	if not enemy or not enemy.has_method("take_damage"):
		return
	_burst(enemy.global_position, enemy)


func _burst(at: Vector2, direct_hit: Node = null) -> void:
	if _spent:
		return
	_spent = true

	if direct_hit:
		direct_hit.take_damage(damage, _direction * 60.0)

	if explode_radius > 0.0 and weapon and is_instance_valid(weapon) and weapon.has_method("get_enemies_in_radius"):
		for enemy in weapon.get_enemies_in_radius(at, explode_radius):
			if enemy == direct_hit or not is_instance_valid(enemy):
				continue
			enemy.take_damage(damage * 0.6)

	FXKit.shockwave(get_tree().root, at, explode_radius * 1.6, Color(0.85, 0.5, 1.0, 0.8))
	FXKit.flash(get_tree().root, at, explode_radius, Color(0.8, 0.45, 1.0, 0.6))
	FXKit.hit_spark(get_tree().root, at, Color(0.9, 0.7, 1.0))
	AudioManager.play_sfx("orb_hit", 0.55, 0.9)
	queue_free()