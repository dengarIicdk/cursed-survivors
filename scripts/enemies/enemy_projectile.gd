extends Node2D
class_name EnemyProjectile

## Shared hostile projectile: bone shards, shadow bolts, drake fire.
## Uses a plain distance check against the hero, so it can never be dodged by
## accident through a physics-layer mismatch.

const FXKit := preload("res://scripts/fx/fx_kit.gd")

var direction: Vector2 = Vector2.RIGHT
var speed: float = 220.0
var damage: float = 10.0
var radius: float = 9.0
var lifetime: float = 4.0
var _sprite: Sprite2D
var _trail_timer: float = 0.0


func setup(from: Vector2, to: Vector2, dmg: float, spd: float, color: Color, size: float) -> void:
	global_position = from
	direction = from.direction_to(to)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	damage = dmg
	speed = spd
	color_hint = color
	radius = size


var color_hint: Color = Color(0.7, 0.35, 1.0)


func _ready() -> void:
	z_index = 6
	var orb := Sprite2D.new()
	orb.texture = preload("res://assets/sprites/fx/orb_chaos.png")
	orb.modulate = color_hint
	orb.scale = Vector2.ONE * clampf(radius / 14.0, 0.5, 1.6)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	orb.material = mat
	add_child(orb)

	var glow := Sprite2D.new()
	glow.texture = preload("res://assets/sprites/fx/glow.png")
	glow.modulate = Color(color_hint.r, color_hint.g, color_hint.b, 0.55)
	glow.scale = Vector2.ONE * 1.6
	var gmat := CanvasItemMaterial.new()
	gmat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = gmat
	add_child(glow)
	_sprite = orb
	rotation = direction.angle()


func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	global_position += direction * speed * delta

	if _sprite:
		var pulse: float = 1.0 + sin(lifetime * 26.0) * 0.12
		_sprite.scale = _sprite.scale.lerp(Vector2.ONE * pulse * clampf(radius / 14.0, 0.5, 1.6), 0.2)

	_trail_timer -= delta
	if _trail_timer <= 0.0:
		_trail_timer = 0.08
		FXKit.hit_spark(get_parent(), global_position, color_hint)

	var player: Node = GameManager.player
	if player and is_instance_valid(player):
		if player.global_position.distance_to(global_position) < radius + 16.0:
			_hit(player)


func _hit(player: Node) -> void:
	var hc: HealthComponent = player.get_node_or_null("HealthComponent")
	if hc and not player.get("is_invincible"):
		hc.take_damage(damage)
		if player.has_method("_trigger_invincibility"):
			player.call("_trigger_invincibility")
			player.call("_flash_hit")
		var cam: Node = player.get_node_or_null("Camera2D")
		if cam and cam.has_method("shake"):
			cam.shake(4.0, 0.2)
	FXKit.hit_spark(get_parent(), global_position, color_hint)
	FXKit.flash(get_parent(), global_position, 26.0, color_hint)
	queue_free()
