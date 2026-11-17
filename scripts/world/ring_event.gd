extends Node2D
class_name RingEvent

## The closing ring: every so often a circle of elite enemies appears around the
## hero and contracts. Break a hole in it (or outrun the shrink) and you live;
## if your build cannot clear a gap, the wall lands on top of you.

const FXKit := preload("res://scripts/fx/fx_kit.gd")

## First ring and the gap between rings, in run-time seconds.
const FIRST_DELAY: float = 80.0
const INTERVAL: float = 85.0
## Ring shape.
const MEMBERS: int = 44
const START_RADIUS: float = 520.0
const END_RADIUS: float = 26.0
const SHRINK_TIME: float = 12.0
## How much tougher ring members are than the ordinary rabble.
const HP_MULT: float = 3.2
const DAMAGE_MULT: float = 1.45
const SPEED_MULT: float = 1.0

var _timer: float = 0.0
var _active: bool = false
var _center: Vector2 = Vector2.ZERO
var _radius: float = START_RADIUS
var _elapsed: float = 0.0
var _members: Array[Node] = []


func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)


## Seconds until the next ring; used by the HUD countdown.
func time_to_next() -> float:
	if _active:
		return 0.0
	var target: float = FIRST_DELAY if _first_pending else INTERVAL
	return maxf(target - _timer, 0.0)


func is_active() -> bool:
	return _active


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return
	if not _active:
		_timer += delta
		if _timer >= (FIRST_DELAY if _first_pending else INTERVAL):
			_timer = 0.0
			_first_pending = false
			_start()
		return

	_elapsed += delta
	var t: float = clampf(_elapsed / SHRINK_TIME, 0.0, 1.0)
	_radius = lerpf(START_RADIUS, END_RADIUS, t * t * (3.0 - 2.0 * t))

	for member in _members.duplicate():
		if not is_instance_valid(member) or not member.get("is_active"):
			continue
		member.call("set_ring_radius", _radius)

	var player: Node2D = GameManager.player
	if player and is_instance_valid(player):
		var dist: float = player.global_position.distance_to(_center)
		if dist > _radius + 46.0:
			_finish(true)
			return
	if _elapsed >= SHRINK_TIME:
		_finish(false)


var _first_pending: bool = true


func _start() -> void:
	var player: Node2D = GameManager.player
	if not player or not is_instance_valid(player):
		return
	_active = true
	_elapsed = 0.0
	_radius = START_RADIUS
	_center = player.global_position
	_members.clear()

	var world: Node = get_tree().get_first_node_in_group("world")
	if not world or not world.has_method("spawn_enemy_at"):
		return

	var pool: Array = _pick_types()
	for i in range(MEMBERS):
		var angle: float = float(i) / float(MEMBERS) * TAU
		var pos: Vector2 = _center + Vector2.from_angle(angle) * START_RADIUS
		var type: String = pool[i % pool.size()]
		var enemy: Node = world.spawn_enemy_at(type, pos)
		if not enemy:
			continue
		_members.append(enemy)
		enemy.call("make_ring_member", _center, START_RADIUS, angle)
		_toughen(enemy)

	# No drawn boundary: the wall of bodies is the boundary. One ground pulse
	# marks the moment it appears, then the ring reads purely through the mobs.
	FXKit.shockwave(get_tree().root, _center, START_RADIUS * 0.55, Color(0.95, 0.28, 0.24, 0.55))
	EventBus.ring_event_started.emit()
	AudioManager.play_sfx("boss_spawn", 0.7)


func _pick_types() -> Array:
	var minutes: float = GameManager.run_time / 60.0
	var types: Array = ["shambling_corpse"]
	if minutes > 1.5:
		types.append_array(["armored_knight", "ghost"])
	if minutes > 4.0:
		types.append_array(["shadow_drake", "exploding_imp"])
	return types


func _toughen(enemy: Node) -> void:
	var hp: float = float(enemy.get("max_hp")) * HP_MULT
	enemy.set("max_hp", hp)
	enemy.set("current_hp", hp)
	enemy.set("damage", float(enemy.get("damage")) * DAMAGE_MULT)
	enemy.set("speed", float(enemy.get("speed")) * SPEED_MULT)
	enemy.set("xp_value", int(int(enemy.get("xp_value")) * 2.5))
	enemy.set("ring_tint", true)
	enemy.call("add_ring_aura")


func _finish(escaped: bool) -> void:
	_active = false
	if escaped:
		EventBus.ring_event_ended.emit(true)
		AudioManager.play_sfx("level_up", 0.7)
		FXKit.shockwave(get_tree().root, _center, _radius + 80.0, Color(1.0, 0.85, 0.45, 0.9))
		var world: Node = get_tree().get_first_node_in_group("world")
		if world and world.has_method("spawn_xp_gem"):
			for i in range(8):
				var pos: Vector2 = _center + Vector2.from_angle(randf() * TAU) * randf_range(30.0, 160.0)
				world.spawn_xp_gem(pos, 12)
	else:
		EventBus.ring_event_ended.emit(false)
		AudioManager.play_sfx("boss_spawn", 0.4)

	for member in _members:
		if not is_instance_valid(member):
			continue
		member.call("release_ring")
		if escaped:
			member.call("fade_away")
	_members.clear()


func _on_enemy_killed(enemy: Node, _pos: Vector2) -> void:
	if not _active:
		return
	var index: int = _members.find(enemy)
	if index >= 0:
		_members.remove_at(index)
	# Cutting a way out is a win: the ring no longer surrounds the hero.
	if _members.is_empty():
		_finish(true)
