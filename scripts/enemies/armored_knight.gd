extends BaseEnemy
class_name ArmoredKnight

var armor_reduction: float = 0.3
var _charge_timer: float = 4.0
var _is_charging: bool = false
var _charge_duration: float = 0.5
var _charge_timer2: float = 0.0
var _charge_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	max_hp = 150.0
	base_speed = 70.0
	base_damage = 9.0
	xp_value = 8
	current_hp = max_hp
	speed = base_speed
	damage = base_damage
	attack_cooldown = 4.0
	attack_range = 260.0

func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO, silent: bool = false) -> void:
	var reduced: float = amount * (1.0 - armor_reduction)
	super.take_damage(reduced, knockback * 0.3, silent)

func _enemy_process(delta: float) -> void:
	if _is_charging:
		_charge_timer2 -= delta
		if _charge_timer2 <= 0.0:
			_is_charging = false
			speed = base_speed
			if global_position.distance_to(_target.global_position if is_instance_valid(_target) else global_position) < 160.0:
				FXKit.shockwave(get_tree().root, global_position, 130.0, Color(1.0, 0.7, 0.35, 0.85))
				_aoe_damage(130.0, 0.9)
	else:
		_charge_timer -= delta
		if _charge_timer <= 0.0:
			_charge_timer = 4.0
			_start_charge()

## Charge with a visible wind-up, then a shockwave where the armour lands.
func _begin_attack() -> void:
	if not _target or not is_instance_valid(_target):
		return
	_charge_direction = global_position.direction_to(_target.global_position)
	_telegraph(0.45, Color(1.0, 0.75, 0.35))


func _release_attack() -> void:
	_start_charge()
	_charge_timer = 4.0
	FXKit.shockwave(get_tree().root, global_position, 90.0, Color(1.0, 0.8, 0.4, 0.8))


func _start_charge() -> void:
	if not _target or not is_instance_valid(_target):
		return
	_is_charging = true
	_charge_duration = 0.5
	_charge_timer2 = _charge_duration
	_charge_direction = global_position.direction_to(_target.global_position)
	speed = base_speed * 3.0

func _move_toward_target(_delta: float) -> void:
	if not _target or not is_instance_valid(_target):
		velocity = Vector2.ZERO
		return
	if _is_charging:
		velocity = _charge_direction * speed
	else:
		velocity = global_position.direction_to(_target.global_position) * speed
