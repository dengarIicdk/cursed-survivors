extends BaseEnemy
class_name BatSwarm

var _time: float = 0.0
var _zigzag_timer: float = 0.0
var _zigzag_direction: float = 1.0

func _ready() -> void:
	max_hp = 15.0
	base_speed = 120.0
	base_damage = 2.5
	xp_value = 1
	current_hp = max_hp
	speed = base_speed
	damage = base_damage
	attack_cooldown = 3.2
	attack_range = 110.0


## Bats do not bite hard, they screech: a small ring that slows the hero so
## the swarm can catch up. It is the reason a flock is dangerous, not the dps.
func _begin_attack() -> void:
	_telegraph(0.3, Color(0.75, 0.55, 1.0))


func _release_attack() -> void:
	FXKit.shockwave(get_tree().root, global_position, 110.0, Color(0.8, 0.6, 1.0, 0.9))
	_aoe_damage(110.0, 0.35, "slow")
	AudioManager.play_sfx("hit", 0.3)

func _move_toward_target(delta: float) -> void:
	_time += delta
	_zigzag_timer -= delta
	if _zigzag_timer <= 0.0:
		_zigzag_timer = 0.5
		_zigzag_direction *= -1.0
	
	if not _target or not is_instance_valid(_target):
		velocity = Vector2.ZERO
		return
	
	var direction: Vector2 = global_position.direction_to(_target.global_position)
	var perp: Vector2 = direction.rotated(PI / 2.0) * _zigzag_direction
	var sine_offset: float = sin(_time * 4.0) * 60.0
	velocity = (direction + perp.normalized() * 0.5) * speed
	velocity += perp * sine_offset * delta
	velocity = velocity.normalized() * speed
