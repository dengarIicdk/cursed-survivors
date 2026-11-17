extends BaseWeapon
class_name ChaosBolt
const FXKit := preload("res://scripts/fx/fx_kit.gd")
const ProjectileScript := preload("res://scripts/weapons/chaos_bolt_projectile.gd")

## Hexblade's ranged bite: unstable bolts that hunt the nearest wretch and
## detonate into a small warp of violet fire.

var bolt_count: int = 1
var cast_interval: float = 1.7
var bolt_damage_scale: float = 1.0
var explode_radius: float = 54.0
var _timer: float = 0.0
var _spread: float = 0.0


func _ready() -> void:
	super._ready()
	weapon_name = "Chaos Bolt"
	base_damage = 24.0
	attack_speed = 1.0
	required_passive = "Soul Lantern"
	upgrade_descriptions = [
		"A homing bolt that bursts on impact",
		"Two bolts per cast",
		"Burst radius and damage up",
		"Three bolts, faster casting",
		"Bolts pierce and warp space — ready to evolve!",
	]


func _weapon_process(delta: float) -> void:
	if not _player or not is_instance_valid(_player):
		return
	var wm: Node = _player.get_node_or_null("WeaponManager")
	var cd_mult: float = wm.get_cooldown_multiplier() if wm else 1.0

	_timer += delta
	if _timer < cast_interval * cd_mult:
		return
	_timer = 0.0
	_cast()


func _cast() -> void:
	var targets := _nearest_targets(bolt_count)
	if targets.is_empty():
		return

	_spread += 0.6
	for i in range(bolt_count):
		var target: Node = targets[i % targets.size()]
		_spawn_bolt(target, i, targets.size())


func _nearest_targets(count: int) -> Array:
	var all_enemies := get_tree().get_nodes_in_group("enemies")
	var alive: Array = []
	for e in all_enemies:
		if is_instance_valid(e) and e.is_active:
			alive.append(e)
	alive.sort_custom(func(a, b):
		return _player.global_position.distance_squared_to(a.global_position) < \
			_player.global_position.distance_squared_to(b.global_position))
	if alive.size() > count:
		alive.resize(count)
	return alive


func _spawn_bolt(target: Node, index: int, total: int) -> void:
	var bolt := Area2D.new()
	bolt.set_script(ProjectileScript)
	bolt.target = target
	bolt.damage = get_damage() * bolt_damage_scale
	bolt.explode_radius = explode_radius
	bolt.speed = 380.0 + weapon_level * 24.0
	bolt.turn_rate = 4.0 + weapon_level * 0.5
	bolt.weapon = self
	bolt.global_position = _player.global_position + Vector2.UP * 6.0

	var offset: float = 0.0
	if total > 1:
		offset = (float(index) / float(total) - 0.5) * 0.7
	var aim: Vector2 = Vector2.RIGHT
	if is_instance_valid(target):
		aim = _player.global_position.direction_to(target.global_position)
	bolt._direction = aim.rotated(offset + sin(_spread) * 0.12)

	get_tree().root.add_child(bolt)


func _on_upgrade() -> void:
	match weapon_level:
		2:
			bolt_count = 2
		3:
			explode_radius = 76.0
			base_damage = 30.0
		4:
			bolt_count = 3
			cast_interval = 1.35
		5:
			bolt_damage_scale = 1.25
			base_damage = 36.0


func _on_evolve() -> void:
	weapon_name = "Void Requiem"
	base_damage *= 1.8
	bolt_count = 5
	explode_radius = 104.0
	cast_interval = 1.0
	bolt_damage_scale = 1.4