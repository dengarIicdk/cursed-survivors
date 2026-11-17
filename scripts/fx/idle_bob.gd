extends Sprite2D
class_name IdleBob

## Procedural breathing + walk animation. Sprites in this game are single still
## images, so motion comes from cheap transforms: a bob, a squash-and-stretch
## cycle that speeds up while the owner moves, a waddle lean and a facing flip.
##
## Works for both the player and every enemy, because it only reads the parent's
## `velocity` / `speed` when those exist.

@export var bob_amplitude: float = 1.8
@export var bob_speed: float = 3.2
@export var sway: float = 0.022
@export var squash: float = 0.035
## Extra bob speed while walking, so crowds visibly hustle.
@export var walk_bob_boost: float = 8.0
## Extra squash / waddle strength while walking.
@export var walk_energy: float = 1.0
@export var flip_on_move: bool = true

var _t: float = 0.0
var _base_pos: Vector2 = Vector2.ZERO
var _base_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	_base_pos = position
	_base_scale = scale
	_t = randf() * 12.0


func _process(delta: float) -> void:
	var host := get_parent()
	var active: Variant = host.get("is_active") if host else null
	if active != null and not bool(active):
		return

	# Unsafe lookups on purpose: player and enemies both have `velocity`/`speed`,
	# but a plain Sprite2D parent does not, and null must not reach a conversion.
	var velocity := Vector2.ZERO
	var speed_value: float = 0.0
	if host:
		var raw_velocity: Variant = host.get("velocity")
		if raw_velocity is Vector2:
			velocity = raw_velocity
		var raw_speed: Variant = host.get("speed")
		if raw_speed is float:
			speed_value = raw_speed
		elif raw_speed is int:
			speed_value = float(raw_speed)
	var moving: float = 0.0
	if speed_value > 1.0:
		moving = clampf(velocity.length() / speed_value, 0.0, 1.0)

	_t += delta * (bob_speed + walk_bob_boost * moving)
	var energy: float = walk_energy * moving

	position = _base_pos + Vector2(0.0, sin(_t) * bob_amplitude * (1.0 + 0.8 * energy))
	# idle sway, plus a faster waddle while walking
	rotation = sin(_t * 0.5) * sway + sin(_t * 2.0) * 0.035 * energy

	# squash on each step, stretch between steps
	var step: float = sin(_t * 2.0)
	var stretch: float = 1.0 + (squash + 0.035 * energy) * step
	scale = Vector2(_base_scale.x * (2.0 - stretch), _base_scale.y * stretch)

	if flip_on_move and absf(velocity.x) > 4.0:
		flip_h = velocity.x < 0.0
