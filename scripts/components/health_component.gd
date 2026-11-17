extends Node
class_name HealthComponent

## Handles all HP, armor, lifesteal, and dodge logic.

signal health_changed(current: float, maximum: float)
signal died()

@export var max_hp: float = 100.0
var current_hp: float = 100.0

## 0.0 = no reduction, 1.0 = immune (clamped to 0.9 max)
var armor: float = 0.0
## 0.0–1.0 fraction of damage dealt returned as healing.
## Capped hard: sustain must not out-heal contact damage, or a player can idle.
const LIFESTEAL_CAP := 0.06
var lifesteal: float = 0.0:

	set(value):
		lifesteal = clampf(value, 0.0, LIFESTEAL_CAP)
## 0.0–1.0 chance to completely dodge a hit
var dodge_chance: float = 0.0

var _base_max_hp: float = 100.0


func _ready() -> void:
	_base_max_hp = max_hp
	current_hp = max_hp


func initialize(base_max: float) -> void:
	_base_max_hp = base_max
	max_hp = base_max + SaveManager.get_bonus("hp")
	current_hp = max_hp
	health_changed.emit(current_hp, max_hp)


## Returns actual damage dealt after dodge and armor.
func take_damage(amount: float) -> float:
	if randf() < dodge_chance:
		return 0.0
	
	var effective_armor: float = clampf(armor, 0.0, 0.9)
	var actual_damage: float = amount * (1.0 - effective_armor)
	
	current_hp = maxf(0.0, current_hp - actual_damage)
	health_changed.emit(current_hp, max_hp)
	
	EventBus.player_damaged.emit(actual_damage, current_hp)
	
	if current_hp <= 0.0:
		died.emit()
	
	return actual_damage


## Single entry point for weapon lifesteal, so the cap is always applied.
func heal_from_lifesteal(damage_dealt: float, fraction: float) -> void:
	if damage_dealt <= 0.0 or fraction <= 0.0:
		return
	heal(damage_dealt * minf(fraction, LIFESTEAL_CAP))


func heal(amount: float) -> void:
	current_hp = minf(max_hp, current_hp + amount)
	health_changed.emit(current_hp, max_hp)
	EventBus.player_healed.emit(amount, current_hp)


func add_max_hp(amount: float) -> void:
	max_hp += amount
	current_hp += amount
	health_changed.emit(current_hp, max_hp)


func is_dead() -> bool:
	return current_hp <= 0.0


func get_hp_percent() -> float:
	if max_hp <= 0.0:
		return 0.0
	return current_hp / max_hp
