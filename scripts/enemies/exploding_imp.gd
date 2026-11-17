extends BaseEnemy
class_name ExplodingImp

var explosion_radius: float = 60.0
var fuse_distance: float = 40.0
var _fuse_active: bool = false
var _fuse_timer: float = 1.0
var _exploded: bool = false

func _ready() -> void:
	max_hp = 20.0
	base_speed = 140.0
	base_damage = 16.0
	xp_value = 3
	current_hp = max_hp
	speed = base_speed
	damage = base_damage

func _enemy_process(delta: float) -> void:
	if _exploded:
		return
	if not _target or not is_instance_valid(_target):
		return
	
	var dist: float = global_position.distance_to(_target.global_position)
	
	if _fuse_active:
		_fuse_timer -= delta
		modulate = Color(1.5, 0.3, 0.3, 1.0) if int(_fuse_timer * 8) % 2 == 0 else Color.WHITE
		if _fuse_timer <= 0.0:
			_explode()
	elif dist < fuse_distance:
		_fuse_active = true
		_fuse_timer = 1.0
		# A shrinking red ring is the only warning the player gets.
		FXKit.shockwave(get_tree().root, global_position, explosion_radius, Color(1.0, 0.4, 0.2, 0.9))
		AudioManager.play_sfx("hit", 0.4)

func _explode() -> void:
	if _exploded:
		return
	_exploded = true
	
	var space_state := get_viewport().find_world_2d().direct_space_state
	var params := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = explosion_radius
	params.shape = circle
	params.transform = Transform2D(0.0, global_position)
	params.collision_mask = 2
	var results := space_state.intersect_shape(params, 8)
	for r in results:
		if r.collider and r.collider.has_method("get_node"):
			var hc: HealthComponent = r.collider.get_node_or_null("HealthComponent")
			if hc:
				hc.take_damage(damage)
	
	FXKit.shockwave(get_tree().root, global_position, explosion_radius, Color(1.0, 0.55, 0.2, 1.0))
	FXKit.flash(get_tree().root, global_position, explosion_radius, Color(1.0, 0.6, 0.25, 0.6))
	AudioManager.play_sfx("hit_heavy", 0.9)
	die()
