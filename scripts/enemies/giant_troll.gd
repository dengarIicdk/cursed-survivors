extends BaseEnemy
class_name GiantTroll

## Miniboss. 3-phase state machine with slam and charge attacks.

enum TrollState { WALK, SLAM_WINDUP, SLAM, CHARGE, ENRAGE }

var _state: int = TrollState.WALK
var slam_cooldown: float = 4.0
var slam_radius: float = 100.0
var charge_cooldown: float = 8.0
var _slam_timer: float = 4.0
var _charge_timer: float = 8.0
var _slam_windup: float = 0.0
var _is_enraged: bool = false
var _charge_direction: Vector2 = Vector2.ZERO
var _charge_duration: float = 0.6
var _charge_elapsed: float = 0.0


func _ready() -> void:
	max_hp = 800.0
	base_speed = 55.0
	base_damage = 20.0
	xp_value = 50
	is_pooled = false
	add_to_group("enemies")


func _enemy_process(delta: float) -> void:
	if not _is_enraged and current_hp < max_hp * 0.5:
		_enter_enrage()
	
	match _state:
		TrollState.WALK:
			_slam_timer -= delta
			_charge_timer -= delta
			if _slam_timer <= 0.0:
				_slam_timer = slam_cooldown
				_enter_slam_windup()
			elif _charge_timer <= 0.0:
				_charge_timer = charge_cooldown
				_enter_charge()
		
		TrollState.SLAM_WINDUP:
			_slam_windup -= delta
			velocity = Vector2.ZERO
			if _slam_windup <= 0.0:
				_do_slam()
		
		TrollState.CHARGE:
			_charge_elapsed += delta
			velocity = _charge_direction * speed * 3.0
			if _charge_elapsed >= _charge_duration:
				_state = TrollState.WALK
	
	EventBus.boss_health_changed.emit("Giant Troll", current_hp, max_hp)


func _move_toward_target(_delta: float) -> void:
	if _state != TrollState.WALK:
		return
	if not _target or not is_instance_valid(_target):
		velocity = Vector2.ZERO
		return
	velocity = global_position.direction_to(_target.global_position) * speed


func _enter_slam_windup() -> void:
	_state = TrollState.SLAM_WINDUP
	_slam_windup = 1.0
	FXKit.shockwave(get_tree().root, global_position, slam_radius * 0.8, Color(1.0, 0.4, 0.2, 0.6))
	velocity = Vector2.ZERO


func _do_slam() -> void:
	_state = TrollState.WALK
	
	var space_state := get_viewport().find_world_2d().direct_space_state
	var params := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = slam_radius
	params.shape = circle
	params.transform = Transform2D(0.0, global_position)
	params.collision_mask = 2
	var results := space_state.intersect_shape(params, 4)
	for r in results:
		if r.collider and r.collider.is_in_group("player"):
			var hc: HealthComponent = r.collider.get_node_or_null("HealthComponent")
			if hc:
				hc.take_damage(base_damage * 1.5)
			var cam: Camera2D = r.collider.get_node_or_null("Camera2D")
			if cam and cam.has_method("shake"):
				cam.shake(8.0, 0.5)
	
	FXKit.shockwave(get_tree().root, global_position, slam_radius, Color(1.0, 0.72, 0.25, 0.95))
	FXKit.hit_spark(get_tree().root, global_position, Color(1.0, 0.6, 0.2))


## Between slams the troll hurls a boulder at range.
func _begin_attack() -> void:
	_telegraph(0.5, Color(1.0, 0.6, 0.25))


func _release_attack() -> void:
	if not _target or not is_instance_valid(_target):
		return
	_shoot(_target.global_position, 0.7, 260.0, Color(0.85, 0.6, 0.35), 14.0)


func _enter_charge() -> void:
	if not _target or not is_instance_valid(_target):
		return
	_state = TrollState.CHARGE
	_charge_elapsed = 0.0
	_charge_direction = global_position.direction_to(_target.global_position)


func _enter_enrage() -> void:
	_is_enraged = true
	speed = base_speed * 1.5
	slam_cooldown /= 2.0
	_slam_timer = 1.0
	modulate = Color(1.5, 0.5, 0.5, 1.0)
	EventBus.boss_phase_changed.emit("Giant Troll", 2)


func _on_die() -> void:
	EventBus.boss_killed.emit("Giant Troll")
	var world: Node = get_tree().get_first_node_in_group("world")
	if world and world.has_method("spawn_rare_drop"):
		world.spawn_rare_drop(global_position)
