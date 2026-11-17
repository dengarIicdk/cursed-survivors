extends Player
class_name Ironclad
const FXKit := preload("res://scripts/fx/fx_kit.gd")


## Warrior class. Blade aura, bonus HP/level, Last Stand mechanic.

var hp_per_level: float = 20.0
var last_stand_active: bool = false
var last_stand_cooldown: float = 60.0
var _last_stand_timer: float = 0.0
var _last_stand_duration: float = 5.0
var _last_stand_elapsed: float = 0.0
var _aura_visual: Node = null


func _on_ready_class_specific() -> void:
	var cleave_scene: PackedScene = preload("res://scenes/weapons/sword_splash.tscn")
	weapon_manager.add_weapon(cleave_scene)
	health_component.armor += 0.10
	EventBus.level_up.connect(on_level_up)


func _process(delta: float) -> void:
	if last_stand_active:
		_last_stand_elapsed += delta
		if _last_stand_elapsed >= _last_stand_duration:
			_deactivate_last_stand()
	elif _last_stand_timer > 0.0:
		_last_stand_timer -= delta


func _check_last_stand_condition(current: float, maximum: float) -> void:
	if last_stand_active:
		return
	if _last_stand_timer > 0.0:
		return
	if maximum > 0.0 and (current / maximum) < 0.25:
		_activate_last_stand()


func _activate_last_stand() -> void:
	last_stand_active = true
	_last_stand_elapsed = 0.0
	_last_stand_timer = last_stand_cooldown
	_level_damage_bonus += 1.0
	base_speed *= 2.0
	EventBus.last_stand_activated.emit()
	
	_aura_visual = FXKit.glow_sprite(150.0, Color(1.0, 0.72, 0.25, 0.55))
	add_child(_aura_visual)
	FXKit.pulse(_aura_visual, 0.12, 3.0)
	
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(_aura_visual, "modulate:a", 0.1, 0.4)
	tween.tween_property(_aura_visual, "modulate:a", 1.0, 0.4)


func _deactivate_last_stand() -> void:
	last_stand_active = false
	_level_damage_bonus -= 1.0
	base_speed /= 2.0
	if _aura_visual:
		_aura_visual.queue_free()
		_aura_visual = null


func _on_level_up_class_specific(_new_level: int) -> void:
	health_component.add_max_hp(hp_per_level)
