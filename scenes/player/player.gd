extends CharacterBody2D
class_name Player

## Base player controller. Extended by each character class.

@export var base_speed: float = 200.0

## Hard ceiling on how far physics may shove the body in a single step.
## A pile of 150 bodies can otherwise resolve as a huge depenetration jump.
const MAX_STEP_PER_FRAME: float = 18.0
## How often the hurt box is swept for bodies that may bite right now.
const CONTACT_INTERVAL: float = 0.1

var current_speed: float = 200.0
var is_invincible: bool = false
var invincibility_duration: float = 0.75
var _invincibility_timer: float = 0.0
var _contact_timer: float = 0.0
var _slow_timer: float = 0.0
var _slow_factor: float = 1.0

var has_revive: bool = false
var magnet_radius: float = 80.0

# Stat modifiers applied by class scripts
var _level_damage_bonus: float = 0.0
var _level_speed_bonus: float = 0.0
var _level_crit_bonus: float = 0.0

@onready var health_component: HealthComponent = $HealthComponent
@onready var weapon_manager: WeaponManager = $WeaponManager
@onready var passive_manager: PassiveManager = $PassiveManager
@onready var sprite: Node2D = $Sprite2D
@onready var hurt_box: Area2D = $HurtBox
@onready var magnet_area: Area2D = $MagnetArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera: Camera2D = $Camera2D

var _move_direction: Vector2 = Vector2.ZERO
## Last direction the player actually moved in; weapons aim with it.
var facing: Vector2 = Vector2.RIGHT
var _hit_flash_tween: Tween = null


func _ready() -> void:
	add_to_group("player")
	health_component.initialize(100.0)
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)
	hurt_box.area_entered.connect(_on_hurt_box_area_entered)
	magnet_area.area_entered.connect(_on_magnet_area_entered)
	_update_magnet_radius()
	_setup_camera()
	_add_aura()
	GameManager.player = self
	_on_ready_class_specific()


func _on_ready_class_specific() -> void:
	pass  # Override in subclasses


func _add_aura() -> void:
	var glow := Sprite2D.new()
	glow.texture = preload("res://assets/sprites/fx/glow.png")
	glow.scale = Vector2(1.75, 1.35)
	glow.modulate = Color(0.92, 0.62, 1.0, 0.30)
	glow.z_index = -1
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	add_child(glow)

	# Bright rim behind the hero so he never sinks into the ground.
	var rim := Sprite2D.new()
	rim.texture = sprite.texture if sprite is Sprite2D else null
	if rim.texture:
		rim.scale = (sprite as Sprite2D).scale * 1.12
		rim.modulate = Color(1.35, 1.1, 1.6, 0.55)
		rim.z_index = 2
		var rim_mat := CanvasItemMaterial.new()
		rim_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		rim.material = rim_mat
		add_child(rim)


func _physics_process(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			is_invincible = false
			sprite.modulate = Color.WHITE

	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_slow_factor = 1.0

	_read_input()
	_move_direction = _move_direction.normalized()
	if _move_direction.length() > 0.1:
		facing = _move_direction
	current_speed = _calculate_speed()
	velocity = _move_direction * current_speed
	var before: Vector2 = global_position
	move_and_slide()
	_clamp_step(before)

	_poll_contact_damage(delta)

	if absf(_move_direction.x) > 0.15 and sprite:
		sprite.scale.x = -absf(sprite.scale.x) if _move_direction.x < 0.0 else absf(sprite.scale.x)


func _read_input() -> void:
	_move_direction = Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		_move_direction.y -= 1.0
	if Input.is_action_pressed("move_down"):
		_move_direction.y += 1.0
	if Input.is_action_pressed("move_left"):
		_move_direction.x -= 1.0
	if Input.is_action_pressed("move_right"):
		_move_direction.x += 1.0


func _calculate_speed() -> float:
	var speed_mult: float = 1.0 + _level_speed_bonus + passive_manager.get_total_bonus("speed") + SaveManager.get_bonus("speed")
	return base_speed * speed_mult * _slow_factor


## Being buried by a crowd must never teleport the hero: every physics step is
## clamped to a sane distance, so a depenetration burst reads as a nudge.
func _clamp_step(before: Vector2) -> void:
	var moved: Vector2 = global_position - before
	var allowed: float = MAX_STEP_PER_FRAME + current_speed / 60.0
	if moved.length() > allowed:
		global_position = before + moved.normalized() * allowed


## Contact damage used to run only on `area_entered`, so a wretch that touched
## the player during invincibility never hit again while it stayed in range:
## twenty bodies produced one hit. Polling the overlap keeps the pressure real.
func _poll_contact_damage(delta: float) -> void:
	if health_component.is_dead():
		return
	_contact_timer -= delta
	if _contact_timer > 0.0:
		return
	_contact_timer = CONTACT_INTERVAL

	# Every body in reach bites, each on its own cooldown. If twenty wretches
	# surround the hero, twenty wounds land - not one.
	var total: float = 0.0
	var attackers: int = 0
	var heaviest: Node = null
	var heaviest_damage: float = 0.0
	for area in hurt_box.get_overlapping_areas():
		var enemy: Node = area.get_parent()
		if not enemy or not enemy.has_method("get_damage"):
			continue
		if enemy.has_method("try_contact_hit") and not enemy.try_contact_hit():
			continue
		var d: float = enemy.get_damage()
		total += d
		attackers += 1
		if d > heaviest_damage:
			heaviest_damage = d
			heaviest = enemy
	if attackers > 0:
		_take_burst(total, attackers, heaviest)


func _take_burst(total_damage: float, attackers: int, heaviest: Node) -> void:
	if health_component.is_dead():
		return
	# Every body in reach counts, but one tick may never delete a full health
	# bar: the cap keeps a wall of wretches brutal yet survivable for a moment.
	var burst_cap: float = health_component.max_hp * 0.22
	var actual: float = health_component.take_damage(minf(total_damage, burst_cap))
	if actual <= 0.0:
		return
	if heaviest and heaviest.has_method("on_contact_hit"):
		heaviest.on_contact_hit(self)
	if camera and camera.has_method("shake"):
		camera.shake(clampf(2.0 + attackers * 0.9, 2.0, 9.0), 0.22)
	# Visual feedback is rate limited so a wall of bodies does not strobe.
	if _invincibility_timer <= 0.0:
		_flash_hit()
		_trigger_invincibility()


func apply_slow(fraction: float, duration: float = 1.5) -> void:
	_slow_factor = minf(_slow_factor, clampf(1.0 - fraction, 0.35, 1.0))
	_slow_timer = maxf(_slow_timer, duration)
	if sprite:
		sprite.modulate = Color(0.78, 0.9, 1.05, 1.0)


func _on_hurt_box_area_entered(area: Area2D) -> void:
	# Contact is handled only by `_poll_contact_damage`. Reacting to the enter
	# signal as well would bypass the burst cap the moment a crowd touches you.
	if not area.is_queued_for_deletion():
		_contact_timer = 0.0





func _on_magnet_area_entered(area: Area2D) -> void:
	if area.is_in_group("xp_gems") and area.has_method("attract"):
		area.attract()


func _trigger_invincibility() -> void:
	is_invincible = true
	_invincibility_timer = invincibility_duration


func _flash_hit() -> void:
	if _hit_flash_tween:
		_hit_flash_tween.kill()
	_hit_flash_tween = create_tween()
	_hit_flash_tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3, 1), 0.05)
	_hit_flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)


func _on_health_changed(current: float, maximum: float) -> void:
	_check_last_stand_condition(current, maximum)


func _check_last_stand_condition(_current: float, _maximum: float) -> void:
	pass  # Override in Ironclad


func _on_died() -> void:
	if has_revive:
		has_revive = false
		health_component.heal(health_component.max_hp * 0.5)
		EventBus.player_revived.emit()
		return
	EventBus.player_died.emit()
	set_physics_process(false)
	set_process(false)


func _update_magnet_radius() -> void:
	var shape: CollisionShape2D = magnet_area.get_node_or_null("MagnetShape")
	if shape and shape.shape is CircleShape2D:
		shape.shape.radius = magnet_radius


func get_upgrade_choices() -> Array:
	return ItemDatabase.get_upgrade_choices(self)


func get_damage_multiplier() -> float:
	return weapon_manager.get_damage_multiplier() * (1.0 + _level_damage_bonus)


func on_level_up(new_level: int) -> void:
	_on_level_up_class_specific(new_level)


func _on_level_up_class_specific(_new_level: int) -> void:
	pass  # Override in subclasses


func _setup_camera() -> void:
	if camera:
		camera.zoom = Vector2(1.68, 1.68)
