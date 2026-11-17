extends Area2D
class_name XPGem

const FXKit := preload("res://scripts/fx/fx_kit.gd")

## Pooled XP pickup gem.

var xp_value: int = 1
var is_active: bool = false
var _being_attracted: bool = false
var _attract_speed: float = 300.0
var _bob: Tween = null


func _ready() -> void:
	add_to_group("xp_gems")
	collision_layer = 16
	collision_mask = 2
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	visible = false
	var glow: Sprite2D = get_node_or_null("Glow")
	if glow:
		FXKit.additive(glow)


func activate(value: int, pos: Vector2) -> void:
	xp_value = value
	global_position = pos
	is_active = true
	visible = true
	_being_attracted = false
	_apply_tier()


func _apply_tier() -> void:
	var visual: Sprite2D = get_node_or_null("Visual")
	var glow: Sprite2D = get_node_or_null("Glow")
	if not visual:
		return
	var tint: Color = Color(0.55, 0.85, 1.0)
	var size: float = 1.0
	if xp_value >= 20:
		tint = Color(1.0, 0.55, 0.95)
		size = 1.7
	elif xp_value >= 5:
		tint = Color(0.6, 1.0, 0.6)
		size = 1.3
	visual.modulate = tint
	visual.scale = Vector2(0.32, 0.32) * size
	if glow:
		glow.modulate = Color(tint.r, tint.g, tint.b, 0.5)
		glow.scale = Vector2(0.34, 0.34) * size
	if _bob and _bob.is_valid():
		_bob.kill()
	visual.position = Vector2.ZERO
	_bob = create_tween()
	_bob.set_loops()
	_bob.tween_property(visual, "position:y", -3.0 * size, 0.7).as_relative()
	_bob.tween_property(visual, "position:y", 3.0 * size, 0.7).as_relative()


func deactivate() -> void:
	is_active = false
	visible = false
	_being_attracted = false
	global_position = Vector2(-9999, -9999)


func attract() -> void:
	_being_attracted = true


func _physics_process(delta: float) -> void:
	if not is_active or not _being_attracted:
		return
	var player: Node = GameManager.player
	if not player or not is_instance_valid(player):
		return
	var direction: Vector2 = global_position.direction_to(player.global_position)
	global_position += direction * _attract_speed * delta
	
	if global_position.distance_to(player.global_position) < 16.0:
		_collect()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurt_box"):
		_collect()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect()


func _collect() -> void:
	if not is_active:
		return
	EventBus.xp_collected.emit(xp_value)
	AudioManager.play_sfx("xp_pickup", 0.8)
	if is_instance_valid(GameManager.player):
		FXKit.hit_spark(get_tree().root, global_position, Color(0.7, 0.9, 1.0))
	deactivate()
