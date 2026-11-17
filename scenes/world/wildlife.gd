extends Node2D
class_name Wildlife

## Ambient life: crows scatter from the hero, rats scurry between graves,
## moths drift around the glow pools and lost souls wander through the fog.
## Purely cosmetic — no collision, no damage, no groups.

const TEX_CROW_PERCHED: Texture2D = preload("res://assets/sprites/wildlife/crow_perched.png")
const TEX_CROW_FLYING: Texture2D = preload("res://assets/sprites/wildlife/crow_flying.png")
const TEX_RAT: Texture2D = preload("res://assets/sprites/wildlife/rat.png")
const TEX_MOTH: Texture2D = preload("res://assets/sprites/wildlife/moth.png")
const TEX_WISP: Texture2D = preload("res://assets/sprites/wildlife/wisp.png")

const MAX_CRITTERS: int = 16
const SPAWN_MIN: float = 190.0
const SPAWN_MAX: float = 820.0
const DESPAWN_DISTANCE: float = 1500.0
const FLEE_DISTANCE: float = 115.0

enum Kind { CROW, RAT, MOTH, WISP }


class Critter:
	var node: Node2D
	var sprite: Sprite2D
	var kind: int = Kind.CROW
	var timer: float = 0.0
	var direction: Vector2 = Vector2.RIGHT
	var home: Vector2 = Vector2.ZERO
	var speed: float = 40.0
	var phase: float = 0.0
	var fleeing: bool = false
	var life: float = 0.0


var _critters: Array[Critter] = []
var _rng := RandomNumberGenerator.new()
var _spawn_timer: float = 0.0


func _ready() -> void:
	z_index = -3
	_rng.randomize()
	# The hero does not exist yet while the world is initialising.
	call_deferred("_initial_spawn")


func _initial_spawn() -> void:
	for i in range(10):
		_spawn(true)


func _process(delta: float) -> void:
	var player: Node2D = GameManager.player
	if not player or not is_instance_valid(player):
		return
	var player_pos: Vector2 = player.global_position

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = 0.35
		if _critters.size() < MAX_CRITTERS:
			_spawn(false)

	for critter in _critters:
		_update_critter(critter, delta, player_pos)

	_prune(player_pos)


func _spawn(anywhere: bool) -> void:
	var player: Node2D = GameManager.player
	if not player or not is_instance_valid(player):
		return
	var angle: float = _rng.randf() * TAU
	var dist: float = _rng.randf_range(SPAWN_MIN, SPAWN_MAX)
	if anywhere:
		dist = _rng.randf_range(120.0, SPAWN_MAX)
	var pos: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * dist

	var roll: float = _rng.randf()
	var critter := Critter.new()
	critter.home = pos
	critter.phase = _rng.randf() * TAU

	var holder := Node2D.new()
	holder.position = pos
	var sprite := Sprite2D.new()
	holder.add_child(sprite)
	add_child(holder)
	critter.node = holder
	critter.sprite = sprite

	if roll < 0.34:
		critter.kind = Kind.CROW
		sprite.texture = TEX_CROW_PERCHED
		sprite.scale = Vector2(0.52, 0.52)
		critter.speed = 0.0
		critter.timer = _rng.randf_range(0.6, 2.2)
		critter.node.z_index = -2
	elif roll < 0.62:
		critter.kind = Kind.RAT
		sprite.texture = TEX_RAT
		sprite.scale = Vector2(0.6, 0.6)
		critter.speed = _rng.randf_range(56.0, 96.0)
		critter.direction = Vector2.from_angle(_rng.randf() * TAU)
	elif roll < 0.86:
		critter.kind = Kind.MOTH
		sprite.texture = TEX_MOTH
		sprite.scale = Vector2(0.7, 0.7)
		critter.speed = 18.0
		critter.node.z_index = 1
		_add_glow(sprite, Color(1.0, 0.9, 0.55, 0.35), 1.8)
	else:
		critter.kind = Kind.WISP
		sprite.texture = TEX_WISP
		sprite.scale = Vector2(0.5, 0.5)
		sprite.modulate = Color(0.72, 1.0, 0.92, 0.55)
		critter.speed = 26.0
		critter.node.z_index = 1
		critter.direction = Vector2.from_angle(_rng.randf() * TAU)
		_add_glow(sprite, Color(0.55, 1.0, 0.9, 0.30), 1.6)

	_critters.append(critter)


func _add_glow(target: Sprite2D, tint: Color, scale_mult: float) -> void:
	var glow := Sprite2D.new()
	glow.texture = preload("res://assets/sprites/fx/glow.png")
	glow.modulate = tint
	glow.scale = Vector2.ONE * scale_mult
	glow.z_index = -1
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	target.get_parent().add_child(glow)
	glow.position = Vector2.ZERO


func _update_critter(critter: Critter, delta: float, player_pos: Vector2) -> void:
	if not is_instance_valid(critter.node):
		return
	critter.phase += delta
	critter.life += delta
	var pos: Vector2 = critter.node.position
	var to_player: float = pos.distance_to(player_pos)

	match critter.kind:
		Kind.CROW:
			if critter.fleeing:
				critter.speed = maxf(critter.speed, 260.0)
				pos += critter.direction * critter.speed * delta
				critter.sprite.flip_h = critter.direction.x < 0.0
				critter.sprite.position.y = sin(critter.phase * 12.0) * 4.0
				critter.node.modulate.a = clampf(critter.life - 0.0, 0.0, 1.0) * maxf(0.0, 1.0 - (critter.life - 1.4))
			elif to_player < FLEE_DISTANCE:
				critter.fleeing = true
				critter.life = 0.0
				critter.direction = (pos - player_pos).normalized().rotated(
					_rng.randf_range(-0.5, 0.5))
				critter.sprite.texture = TEX_CROW_FLYING
			else:
				critter.timer -= delta
				if critter.timer <= 0.0:
					critter.timer = _rng.randf_range(0.8, 2.4)
					critter.sprite.position = Vector2(_rng.randf_range(-3, 3), -_rng.randf_range(0, 4))
					critter.sprite.flip_h = _rng.randf() > 0.5

		Kind.RAT:
			critter.timer -= delta
			if critter.timer <= 0.0:
				critter.timer = _rng.randf_range(0.5, 1.4)
				critter.direction = Vector2.from_angle(_rng.randf() * TAU)
				if _rng.randf() < 0.25:
					critter.direction = Vector2.ZERO
					critter.speed = 0.0
			var speed_now: float = critter.speed
			if to_player < FLEE_DISTANCE:
				critter.direction = (pos - player_pos).normalized().rotated(
					_rng.randf_range(-0.4, 0.4))
				speed_now = 210.0
			if critter.direction != Vector2.ZERO:
				pos += critter.direction * speed_now * delta
				critter.sprite.flip_h = critter.direction.x < 0.0
				critter.sprite.position.y = absf(sin(critter.phase * 16.0)) * -1.5

		Kind.MOTH:
			var wander: Vector2 = Vector2(
				cos(critter.phase * 1.7 + critter.home.x),
				sin(critter.phase * 1.3 + critter.home.y)) * 34.0
			var target: Vector2 = critter.home + wander
			if to_player < 260.0:
				# Moths are drawn to the hero's aura.
				target = target.lerp(player_pos + Vector2(40.0, -28.0), 0.35)
			pos = pos.lerp(target, clampf(delta * 0.9, 0.0, 1.0))
			critter.sprite.scale = Vector2(0.7, 0.7) * (0.85 + sin(critter.phase * 9.0) * 0.18)

		Kind.WISP:
			pos += critter.direction * critter.speed * delta
			critter.sprite.position.y = sin(critter.phase * 1.4) * 5.0
			var fade: float = minf(critter.life * 1.5, 1.0) * clampf(1.0 - (critter.life - 11.0), 0.0, 1.0)
			critter.node.modulate.a = maxf(fade, 0.0)
			if critter.life > 16.0 or to_player > SPAWN_MAX:
				critter.life = 16.0

	critter.node.position = pos


func _prune(player_pos: Vector2) -> void:
	for i in range(_critters.size() - 1, -1, -1):
		var critter: Critter = _critters[i]
		if not is_instance_valid(critter.node):
			_critters.remove_at(i)
			continue
		var gone: bool = critter.node.position.distance_to(player_pos) > DESPAWN_DISTANCE
		if critter.kind == Kind.CROW and critter.fleeing and critter.life > 2.2:
			gone = true
		if critter.kind == Kind.WISP and critter.life > 16.0:
			gone = true
		if gone:
			critter.node.queue_free()
			_critters.remove_at(i)
