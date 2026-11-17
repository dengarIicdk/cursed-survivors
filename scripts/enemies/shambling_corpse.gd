extends BaseEnemy
class_name ShamblingCorpse

var _jitter_timer: float = 0.0
var _jitter_offset: Vector2 = Vector2.ZERO
var _lunge_timer: float = 0.0
var _lunge_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	max_hp = 30.0
	base_speed = 60.0
	base_damage = 3.5
	xp_value = 2
	current_hp = max_hp
	speed = base_speed
	damage = base_damage
	attack_cooldown = 5.5
	attack_range = 130.0
	base_damage = 8.0


## A shambler that gets close grabs at you: short wind-up, then it throws
## itself forward and hits harder than a touch.
func _begin_attack() -> void:
	if not _target or not is_instance_valid(_target):
		return
	_telegraph(0.4, Color(0.9, 0.45, 0.35))
	_lunge_direction = global_position.direction_to(_target.global_position)


func _release_attack() -> void:
	_lunge_timer = 0.22
	damage = base_damage * 1.6
	FXKit.slash(get_tree().root, global_position, Color(1.0, 0.55, 0.45, 0.85), 40.0,
		_lunge_direction.angle())


func _enemy_process(delta: float) -> void:
	if _lunge_timer > 0.0:
		_lunge_timer -= delta
		if _lunge_timer <= 0.0:
			damage = base_damage

func _move_toward_target(delta: float) -> void:
	_jitter_timer -= delta
	if _jitter_timer <= 0.0:
		_jitter_timer = 2.0
		_jitter_offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
	
	if not _target or not is_instance_valid(_target):
		velocity = Vector2.ZERO
		return
	if _lunge_timer > 0.0:
		velocity = _lunge_direction * speed * 3.4
		return
	var direction: Vector2 = global_position.direction_to(_target.global_position + _jitter_offset)
	velocity = direction * speed
