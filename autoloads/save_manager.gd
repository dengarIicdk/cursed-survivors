extends Node

## Handles persistent meta-progression save/load via JSON.

const SAVE_PATH: String = "user://save_data.json"

# Permanent bonus caps
const MAX_HP_BONUS: float = 200.0
const MAX_DAMAGE_BONUS: float = 0.5
const MAX_SPEED_BONUS: float = 0.3

# Save data
var soul_coins_total: int = 0
var unlocked_classes: Array[String] = ["Hexblade"]
var unlocked_weapons: Array[String] = ["Arcane Orbs"]
var unlocked_maps: Array[String] = ["Cursed Graveyard"]

var permanent_bonuses: Dictionary = {
	"hp": 0.0,
	"damage": 0.0,
	"speed": 0.0
}

# Track upgrade purchase counts
var upgrade_purchase_counts: Dictionary = {
	"hp": 0,
	"damage": 0,
	"speed": 0
}

## Prices climb with every level bought, so progress is a real investment
## rather than a shopping spree after two runs.
const UPGRADE_BASE_PRICE: Dictionary = {"hp": 120, "damage": 150, "speed": 130}
const UPGRADE_PRICE_STEP: Dictionary = {"hp": 55, "damage": 70, "speed": 60}
const CLASS_PRICES: Dictionary = {"Ironclad": 450, "Wraithborn": 600, "Stormcaller": 750}
const MAP_PRICES: Dictionary = {"Infernal Depths": 900}

const MAX_HP_PURCHASES: int = 8
const MAX_DAMAGE_PURCHASES: int = 10
const MAX_SPEED_PURCHASES: int = 10


func _ready() -> void:
	load_data()


func save() -> void:
	var data: Dictionary = {
		"soul_coins_total": soul_coins_total,
		"unlocked_classes": unlocked_classes,
		"unlocked_weapons": unlocked_weapons,
		"unlocked_maps": unlocked_maps,
		"permanent_bonuses": permanent_bonuses,
		"upgrade_purchase_counts": upgrade_purchase_counts
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text: String = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary:
		return
	soul_coins_total = parsed.get("soul_coins_total", 0)
	var classes_raw = parsed.get("unlocked_classes", ["Hexblade"])
	unlocked_classes.clear()
	for c in classes_raw:
		unlocked_classes.append(str(c))
	var weapons_raw = parsed.get("unlocked_weapons", ["Arcane Orbs"])
	unlocked_weapons.clear()
	for w in weapons_raw:
		unlocked_weapons.append(str(w))
	var maps_raw = parsed.get("unlocked_maps", ["Cursed Graveyard"])
	unlocked_maps.clear()
	for m in maps_raw:
		unlocked_maps.append(str(m))
	var bonuses = parsed.get("permanent_bonuses", {"hp": 0.0, "damage": 0.0, "speed": 0.0})
	permanent_bonuses = bonuses
	upgrade_purchase_counts = parsed.get("upgrade_purchase_counts", {"hp": 0, "damage": 0, "speed": 0})


func add_soul_coins(amount: int) -> void:
	soul_coins_total += amount


func spend_coins(amount: int) -> bool:
	if soul_coins_total >= amount:
		soul_coins_total -= amount
		save()
		return true
	return false


func get_bonus(stat_name: String) -> float:
	return permanent_bonuses.get(stat_name, 0.0)


func unlock_class(c_name: String) -> bool:
	if c_name not in unlocked_classes:
		unlocked_classes.append(c_name)
		save()
		return true
	return false


func unlock_weapon(w_name: String) -> bool:
	if w_name not in unlocked_weapons:
		unlocked_weapons.append(w_name)
		save()
		return true
	return false


func unlock_map(m_name: String) -> bool:
	if m_name not in unlocked_maps:
		unlocked_maps.append(m_name)
		save()
		return true
	return false


func upgrade_price(key: String) -> int:
	var step: int = int(UPGRADE_PRICE_STEP.get(key, 0))
	return int(UPGRADE_BASE_PRICE.get(key, 0)) + step * int(upgrade_purchase_counts.get(key, 0))


func class_price(c_name: String) -> int:
	return int(CLASS_PRICES.get(c_name, 450))


func map_price(map_name_str: String) -> int:
	return int(MAP_PRICES.get(map_name_str, 900))


func purchase_hp_upgrade() -> bool:
	if upgrade_purchase_counts.get("hp", 0) >= MAX_HP_PURCHASES:
		return false
	if not spend_coins(upgrade_price("hp")):
		return false
	upgrade_purchase_counts["hp"] = upgrade_purchase_counts.get("hp", 0) + 1
	permanent_bonuses["hp"] = minf(permanent_bonuses.get("hp", 0.0) + 25.0, MAX_HP_BONUS)
	save()
	return true


func purchase_damage_upgrade() -> bool:
	if upgrade_purchase_counts.get("damage", 0) >= MAX_DAMAGE_PURCHASES:
		return false
	if not spend_coins(upgrade_price("damage")):
		return false
	upgrade_purchase_counts["damage"] = upgrade_purchase_counts.get("damage", 0) + 1
	permanent_bonuses["damage"] = minf(permanent_bonuses.get("damage", 0.0) + 0.05, MAX_DAMAGE_BONUS)
	save()
	return true


func purchase_speed_upgrade() -> bool:
	if upgrade_purchase_counts.get("speed", 0) >= MAX_SPEED_PURCHASES:
		return false
	if not spend_coins(upgrade_price("speed")):
		return false
	upgrade_purchase_counts["speed"] = upgrade_purchase_counts.get("speed", 0) + 1
	permanent_bonuses["speed"] = minf(permanent_bonuses.get("speed", 0.0) + 0.03, MAX_SPEED_BONUS)
	save()
	return true


## Wipes meta progress back to a brand new save. Run statistics live in the same
## file, so this is a full account reset, not just a shop reset.
func reset_progress() -> void:
	soul_coins_total = 0
	unlocked_classes = ["Hexblade"]
	unlocked_weapons = ["Arcane Orbs"]
	unlocked_maps = ["Cursed Graveyard"]
	permanent_bonuses = {"hp": 0.0, "damage": 0.0, "speed": 0.0}
	upgrade_purchase_counts = {"hp": 0, "damage": 0, "speed": 0}
	save()
	EventBus.soul_coins_changed.emit(soul_coins_total)


func is_class_unlocked(c_name: String) -> bool:
	return c_name in unlocked_classes


func is_weapon_unlocked(weapon_name: String) -> bool:
	return weapon_name in unlocked_weapons


func is_map_unlocked(map_name: String) -> bool:
	return map_name in unlocked_maps
