extends Node
class_name PassiveManager

## Manages passive items and their stat bonuses.

const MAX_PASSIVES: int = 6

var equipped_passives: Dictionary = {}

var stat_bonuses: Dictionary = {
	"damage": 0.0,
	"speed": 0.0,
	"cooldown": 0.0,
	"xp_radius": 0.0,
	"lifesteal": 0.0,
}

var _player: Node = null


func _ready() -> void:
	_player = get_parent()


func add_passive(item_res: Resource) -> bool:
	var item_name: String = item_res.item_name
	if equipped_passives.size() >= MAX_PASSIVES and item_name not in equipped_passives:
		return false
	equipped_passives[item_name] = item_res
	item_res.apply(_player)
	var weapon_manager: WeaponManager = _player.get_node_or_null("WeaponManager")
	if weapon_manager:
		weapon_manager.check_evolutions(item_name)
	return true


func get_total_bonus(stat: String) -> float:
	return stat_bonuses.get(stat, 0.0)


func add_stat_bonus(stat: String, amount: float) -> void:
	stat_bonuses[stat] = stat_bonuses.get(stat, 0.0) + amount


func has_passive(item_name: String) -> bool:
	return item_name in equipped_passives
