extends BaseWeapon
class_name FanOfKnives
const FXKit := preload("res://scripts/fx/fx_kit.gd")

## Wraithborn's area attack: a ring of knives thrown in every direction.

var knife_count: int = 6
var volley_interval: float = 2.0
var pierce: int = 1
var knife_speed: float = 330.0
var poison_stacks: int = 0
var spin_offset: float = 0.0
var _timer: float = 0.0


func _ready() -> void:
	super._ready()
	weapon_name = "Fan of Knives"
	base_damage = 16.0
	attack_speed = 1.0
	required_passive = "Leech Crown"
	upgrade_descriptions = [
		"6 knives thrown in every direction",
		"8 knives per volley",
		"Knives pierce 2 enemies",
		"Faster volleys (1.5s)",
		"Knives carry poison — ready to evolve!",
	]


func _weapon_process(delta: float) -> void:
	if not _player or not is_instance_valid(_player):
		return
	var wm: Node = _player.get_node_or_null("WeaponManager")
	var cd_mult: float = wm.get_cooldown_multiplier() if wm else 1.0

	_timer += delta
	if _timer < volley_interval * cd_mult:
		return
	_timer = 0.0
	_throw_volley()


func _throw_volley() -> void:
	spin_offset += 0.42
	for i in range(knife_count):
		var angle: float = spin_offset + TAU * float(i) / float(knife_count)
		_spawn_knife(Vector2.from_angle(angle))
	AudioManager.play_sfx("blink", 0.35, 1.4)


func _spawn_knife(direction: Vector2) -> void:
	var knife := Area2D.new()
	knife.collision_layer = 8
	knife.collision_mask = 12
	knife.add_to_group("player_projectiles")

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 5)
	shape.shape = rect
	knife.add_child(shape)

	var visual := FXKit.dagger(30.0)
	knife.add_child(visual)
	FXKit.additive(visual)

	knife.global_position = _player.global_position
	knife.rotation = direction.angle()
	get_tree().root.add_child(knife)

	var hits_left := [pierce]
	var already_hit: Array = []
	var damage_value: float = get_damage()

	knife.area_entered.connect(func(area: Area2D):
		var enemy := area.get_parent()
		if not enemy or not enemy.has_method("take_damage") or enemy in already_hit:
			return
		already_hit.append(enemy)
		enemy.take_damage(damage_value, direction * 40.0)
		if poison_stacks > 0 and enemy.has_method("apply_poison"):
			enemy.apply_poison(4.0, poison_stacks, 3.0)
		FXKit.hit_spark(get_tree().root, enemy.global_position, Color(0.7, 1.0, 0.8))
		hits_left[0] -= 1
		if hits_left[0] <= 0:
			knife.queue_free()
	)

	var travel_time: float = 380.0 / knife_speed
	var tween := knife.create_tween()
	tween.tween_property(knife, "global_position",
		knife.global_position + direction * 380.0, travel_time)
	tween.tween_callback(knife.queue_free)


func _on_upgrade() -> void:
	match weapon_level:
		2:
			knife_count = 8
		3:
			pierce = 2
			base_damage = 20.0
		4:
			volley_interval = 1.5
		5:
			poison_stacks = 2


func _on_evolve() -> void:
	weapon_name = "Crimson Waltz"
	base_damage *= 1.8
	knife_count = 12
	pierce = 4
	poison_stacks = 4
	volley_interval = 1.2
	knife_speed = 400.0