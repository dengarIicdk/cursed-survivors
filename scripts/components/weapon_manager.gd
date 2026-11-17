extends Node
class_name WeaponManager

## Manages all equipped weapons. Max 6 weapons at once.

const MAX_WEAPONS: int = 6

var equipped_weapons: Array[Node] = []
var _passive_manager: Node = null
var _player: Node = null


func _ready() -> void:
	_player = get_parent()
	_passive_manager = _player.get_node_or_null("PassiveManager")


func add_weapon(weapon_scene: PackedScene) -> bool:
	if equipped_weapons.size() >= MAX_WEAPONS:
		return false
	var weapon := weapon_scene.instantiate()
	add_child(weapon)
	equipped_weapons.append(weapon)
	if weapon.has_method("set_player"):
		weapon.set_player(_player)
	return true


func upgrade_weapon(weapon_name: String) -> bool:
	for weapon in equipped_weapons:
		if weapon.weapon_name == weapon_name:
			if weapon.weapon_level < weapon.max_level:
				weapon.upgrade()
				return true
	return false


func can_add_weapon() -> bool:
	return equipped_weapons.size() < MAX_WEAPONS


func has_weapon(weapon_name: String) -> bool:
	for weapon in equipped_weapons:
		if weapon.weapon_name == weapon_name:
			return true
	return false


func get_weapon(weapon_name: String) -> Node:
	for weapon in equipped_weapons:
		if weapon.weapon_name == weapon_name:
			return weapon
	return null


func check_evolutions(passive_name: String) -> void:
	for weapon in equipped_weapons:
		if weapon.required_passive == passive_name and weapon.weapon_level >= weapon.max_level and not weapon.is_evolved:
			weapon.evolve(passive_name)


func get_damage_multiplier() -> float:
	var base: float = 1.0 + SaveManager.get_bonus("damage")
	if _passive_manager:
		base += _passive_manager.get_total_bonus("damage")
	return base


func get_cooldown_multiplier() -> float:
	var reduction: float = 0.0
	if _passive_manager:
		reduction = _passive_manager.get_total_bonus("cooldown")
	return clampf(1.0 - reduction, 0.3, 1.0)


func apply_lifesteal(damage_dealt: float, lifesteal_fraction: float) -> void:
	if lifesteal_fraction <= 0.0:
		return
	var heal_amount: float = damage_dealt * lifesteal_fraction
	var health: HealthComponent = _player.get_node_or_null("HealthComponent")
	if health:
		health.heal(heal_amount)


func apply_attack_speed_bonus(bonus: float) -> void:
	for weapon in equipped_weapons:
		if "attack_speed_bonus" in weapon:
			weapon.attack_speed_bonus = bonus
