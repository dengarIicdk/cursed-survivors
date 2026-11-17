extends BaseEnemy
class_name Necromancer

var summon_cooldown: float = 5.0
var max_minions: int = 3
var preferred_distance: float = 200.0
var _summon_timer: float = 2.0
var _minion_count: int = 0

func _ready() -> void:
	max_hp = 80.0
	base_speed = 50.0
	base_damage = 5.0
	xp_value = 10
	current_hp = max_hp
	speed = base_speed
	damage = base_damage
	attack_cooldown = 2.8
	attack_range = 340.0


## Shadow bolt: the necromancer is the only enemy that hits from range, so it
## forces the player to break line pressure instead of turtling.
func _begin_attack() -> void:
	if not _target or not is_instance_valid(_target):
		return
	_telegraph(0.35, Color(0.6, 0.3, 0.95))


func _release_attack() -> void:
	if not _target or not is_instance_valid(_target):
		return
	_shoot(_target.global_position, 1.0, 210.0, Color(0.65, 0.35, 1.0), 9.0)

func _move_toward_target(_delta: float) -> void:
	if not _target or not is_instance_valid(_target):
		velocity = Vector2.ZERO
		return
	var dist: float = global_position.distance_to(_target.global_position)
	if dist < preferred_distance:
		var direction: Vector2 = _target.global_position.direction_to(global_position)
		velocity = direction * speed
	elif dist > preferred_distance + 50.0:
		var direction: Vector2 = global_position.direction_to(_target.global_position)
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

func _enemy_process(delta: float) -> void:
	_summon_timer -= delta
	if _summon_timer <= 0.0:
		_summon_timer = summon_cooldown
		_try_summon()

func _try_summon() -> void:
	if _minion_count >= max_minions:
		return
	var world: Node = get_tree().get_first_node_in_group("world")
	if world and world.has_method("spawn_enemy_at"):
		world.spawn_enemy_at("shambling_corpse", global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40)))
		_minion_count += 1
