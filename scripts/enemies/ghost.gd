extends BaseEnemy
class_name Ghost

var _phase_timer: float = 0.0
var _phase_interval: float = 3.0
var _is_phased: bool = false
var _phase_duration: float = 0.5
var _wave_time: float = 0.0

func _ready() -> void:
	max_hp = 60.0
	base_speed = 90.0
	base_damage = 5.5
	xp_value = 4
	current_hp = max_hp
	speed = base_speed
	damage = base_damage
	collision_mask = 2
	attack_cooldown = 4.0
	attack_range = 120.0


## The cold of a grave: touching a ghost chills the hero's legs.
func on_contact_hit(victim: Node) -> void:
	if victim.has_method("apply_slow"):
		victim.apply_slow(0.22, 1.1)


func _begin_attack() -> void:
	_telegraph(0.45, Color(0.55, 0.85, 1.0))


func _release_attack() -> void:
	_aoe_damage(120.0, 0.6, "chill")
	FXKit.shockwave(get_tree().root, global_position, 120.0, Color(0.6, 0.9, 1.0, 0.75))


func _move_toward_target(delta: float) -> void:
	_wave_time += delta
	if not _target or not is_instance_valid(_target):
		velocity = Vector2.ZERO
		return
	var direction: Vector2 = global_position.direction_to(_target.global_position)
	var wave_offset: Vector2 = direction.rotated(PI / 2.0) * sin(_wave_time * 2.0) * 30.0
	velocity = direction * speed + wave_offset

func _enemy_process(delta: float) -> void:
	if _is_phased:
		_phase_duration -= delta
		if _phase_duration <= 0.0:
			_is_phased = false
			modulate.a = 0.9 if is_elite else 0.7
	else:
		_phase_timer -= delta
		if _phase_timer <= 0.0:
			_phase_timer = _phase_interval
			_start_phase()

func _start_phase() -> void:
	_is_phased = true
	_phase_duration = 0.5
	modulate.a = 0.3

func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO, silent: bool = false) -> void:
	if _is_phased:
		return
	super.take_damage(amount, knockback, silent)
