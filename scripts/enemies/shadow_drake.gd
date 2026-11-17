extends BaseEnemy
class_name ShadowDrake

## Fast flying enemy. Circles player and dive-attacks.

enum DrakeState { CIRCLE, DIVE, PULLUP }

var _state: int = DrakeState.CIRCLE
var circle_radius: float = 150.0
var _circle_angle: float = 0.0
var dive_cooldown: float = 5.0
var dive_speed: float = 300.0
var _dive_timer: float = 2.0
var _dive_target_pos: Vector2 = Vector2.ZERO
var _dive_elapsed: float = 0.0
var _dive_duration: float = 0.4


func _ready() -> void:
	max_hp = 120.0
	base_speed = 160.0
	base_damage = 8.0
	xp_value = 12
	current_hp = max_hp
	speed = base_speed
	collision_mask = 2


func _enemy_process(delta: float) -> void:
	match _state:
		DrakeState.CIRCLE:
			_dive_timer -= delta
			if _dive_timer <= 0.0:
				_dive_timer = dive_cooldown
				_enter_dive()
		DrakeState.DIVE:
			_dive_elapsed += delta
			if _dive_elapsed >= _dive_duration:
				_state = DrakeState.PULLUP
		DrakeState.PULLUP:
			_dive_elapsed += delta
			if _dive_elapsed >= 0.5:
				_state = DrakeState.CIRCLE
				_dive_elapsed = 0.0


func _move_toward_target(delta: float) -> void:
	match _state:
		DrakeState.CIRCLE:
			if not _target or not is_instance_valid(_target):
				velocity = Vector2.ZERO
				return
			_circle_angle += delta * 1.5
			var target_pos: Vector2 = _target.global_position + Vector2(cos(_circle_angle), sin(_circle_angle)) * circle_radius
			velocity = global_position.direction_to(target_pos) * speed
		
		DrakeState.DIVE:
			velocity = global_position.direction_to(_dive_target_pos) * dive_speed
		
		DrakeState.PULLUP:
			velocity = Vector2(0, -1) * speed


func _enter_dive() -> void:
	if not _target or not is_instance_valid(_target):
		return
	_state = DrakeState.DIVE
	_dive_target_pos = _target.global_position
	_dive_elapsed = 0.0
