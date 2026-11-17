extends Node2D
class_name BoomerangBlade

## A single blade that flies out from the blade aura, spirals to its maximum
## reach and then curves back to the player, cutting anything on the way out and
## on the way home. This is what separates Blade Aura from orbiting spells: the
## damage happens along a path, not in a circle.

const FXKit := preload("res://scripts/fx/fx_kit.gd")

var player: Node = null
var source_weapon: Node = null
var damage: float = 12.0
var reach: float = 150.0
var speed: float = 420.0
var crit_chance: float = 0.15
var direction: Vector2 = Vector2.RIGHT
## Extra spin added over the flight: lower = straighter, higher = wide swirl.
var spiral: float = 1.3

var _returning: bool = false
var _hit_cooldown: Dictionary = {}
var _sprite: Sprite2D


func setup(owner_player: Node, source: Node, dmg: float, reach_px: float,
		fly_dir: Vector2, crit: float) -> BoomerangBlade:
	player = owner_player
	source_weapon = source
	damage = dmg
	reach = reach_px
	direction = fly_dir.normalized()
	crit_chance = crit
	return self


func _ready() -> void:
	z_index = 6
	_sprite = FXKit.blade(38.0)
	_sprite.position = Vector2.ZERO
	add_child(_sprite)
	var glow: Sprite2D = FXKit.glow_sprite(64.0, Color(1.0, 0.6, 0.2, 0.35))
	add_child(glow)


func _process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		queue_free()
		return

	_sprite.rotation += 16.0 * delta
	var center: Vector2 = player.global_position
	var distance: float = global_position.distance_to(center)

	if not _returning:
		# spiral outward, slowing as it nears its maximum reach
		var ratio: float = clampf(distance / maxf(reach, 1.0), 0.0, 1.0)
		direction = direction.rotated(spiral * delta)
		global_position += direction * speed * (1.0 - ratio * 0.45) * delta
		if distance >= reach:
			_returning = true
	else:
		var back: Vector2 = center - global_position
		if back.length() < 16.0:
			queue_free()
			return
		global_position += back.normalized() * speed * 1.25 * delta
		_sprite.rotation += 20.0 * delta

	_tick_cooldowns(delta)
	_damage_along_path()


func _tick_cooldowns(delta: float) -> void:
	for key in _hit_cooldown.keys():
		var value: float = float(_hit_cooldown[key]) - delta
		if value <= 0.0:
			_hit_cooldown.erase(key)
		else:
			_hit_cooldown[key] = value


func _damage_along_path() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if enemy.get("is_active") == false:
			continue
		if enemy.global_position.distance_to(global_position) > 30.0:
			continue
		var key: int = enemy.get_instance_id()
		if _hit_cooldown.has(key):
			continue
		_hit_cooldown[key] = 0.3

		var dealt: float = damage
		var is_crit: bool = randf() < crit_chance
		if is_crit:
			dealt *= 2.0
		enemy.take_damage(dealt, direction * 90.0)
		FXKit.hit_spark(get_tree().root, enemy.global_position, Color(1.0, 0.78, 0.42))
		AudioManager.play_sfx("orb_hit", 0.55, randf_range(1.15, 1.35))
		if is_crit and source_weapon and is_instance_valid(source_weapon):
			if source_weapon.get("shockwave_on_crit") == true:
				source_weapon._spawn_shockwave(enemy.global_position)
