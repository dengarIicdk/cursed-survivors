extends Node

## Registry for all items and weapons, plus class-specific upgrade pools.
##
## Every survivor has their own arsenal: the knight never rolls a wizard's
## spellbook, and the mage never rolls a warhammer. Passives stay shared, but
## each class leans toward the trinkets that suit it.

const PASSIVE_ITEMS: Dictionary = {
	"Bloodstone": "res://scripts/items/bloodstone.gd",
	"Iron Heart": "res://scripts/items/iron_heart.gd",
	"Quicksilver Boots": "res://scripts/items/quicksilver_boots.gd",
	"Grimoire": "res://scripts/items/grimoire.gd",
	"Shadow Cloak": "res://scripts/items/shadow_cloak.gd",
	"Soul Lantern": "res://scripts/items/soul_lantern.gd",
	"Cursed Ring": "res://scripts/items/cursed_ring.gd",
	"Phoenix Feather": "res://scripts/items/phoenix_feather.gd",
	"Time Shard": "res://scripts/items/time_shard.gd",
	"Leech Crown": "res://scripts/items/leech_crown.gd",
}

const WEAPON_SCENES: Dictionary = {
	"Arcane Orbs": "res://scenes/weapons/arcane_orbs.tscn",
	"Chaos Bolt": "res://scenes/weapons/chaos_bolt.tscn",
	"Blade Aura": "res://scenes/weapons/blade_aura.tscn",
	"Sword Splash": "res://scenes/weapons/sword_splash.tscn",
	"Shield Bash": "res://scenes/weapons/shield_bash.tscn",
	"Shadow Daggers": "res://scenes/weapons/shadow_daggers.tscn",
	"Fan of Knives": "res://scenes/weapons/fan_of_knives.tscn",
	"Lightning Chain": "res://scenes/weapons/lightning_chain.tscn",
	"Frost Nova": "res://scenes/weapons/frost_nova.tscn",
}

## Arsenal offered to each survivor as the run progresses.
const CLASS_WEAPONS: Dictionary = {
	"Hexblade": ["Arcane Orbs", "Chaos Bolt", "Shadow Daggers"],
	"Ironclad": ["Sword Splash", "Shield Bash", "Blade Aura"],
	"Wraithborn": ["Shadow Daggers", "Fan of Knives", "Blade Aura"],
	"Stormcaller": ["Lightning Chain", "Frost Nova", "Arcane Orbs"],
}

## Signature weapon: heavily favoured early, so a run always feels like the class.
const CLASS_SIGNATURE: Dictionary = {
	"Hexblade": "Arcane Orbs",
	"Ironclad": "Sword Splash",
	"Wraithborn": "Shadow Daggers",
	"Stormcaller": "Lightning Chain",
}

## Passives each class is drawn to (extra weight on those entries).
const CLASS_PASSIVE_BIAS: Dictionary = {
	"Hexblade": ["Grimoire", "Shadow Cloak", "Soul Lantern"],
	"Ironclad": ["Iron Heart", "Bloodstone", "Phoenix Feather"],
	"Wraithborn": ["Quicksilver Boots", "Shadow Cloak", "Cursed Ring"],
	"Stormcaller": ["Time Shard", "Soul Lantern", "Grimoire"],
}

const WEAPON_DESCRIPTIONS: Dictionary = {
	"Arcane Orbs": "Orbs orbit you, shredding anything they touch",
	"Chaos Bolt": "Homing bolts that burst into violet fire",
	"Blade Aura": "Orbiting blades that fly out and come back",
	"Sword Splash": "Heavy cleave that carves a wide arc ahead",
	"Shield Bash": "Slam the ground and blast the crowd away",
	"Shadow Daggers": "Homing daggers hunt down the nearest wretches",
	"Fan of Knives": "A ring of knives thrown in every direction",
	"Lightning Chain": "Arcs that leap from victim to victim",
	"Frost Nova": "Frost ring that freezes the ring around you",
}

const ITEM_DESCRIPTIONS: Dictionary = {
	"Bloodstone": "Lifesteal 2% of damage dealt (max 6%)",
	"Iron Heart": "+50 maximum HP",
	"Quicksilver Boots": "+20% movement speed",
	"Grimoire": "+15% all damage",
	"Shadow Cloak": "8% dodge chance",
	"Soul Lantern": "Double XP radius",
	"Cursed Ring": "+50% damage, -20% HP",
	"Phoenix Feather": "Revive once with 50% HP",
	"Time Shard": "-15% all cooldowns",
	"Leech Crown": "Lifesteal grows with kills (max 6%)",
}


func get_item(id: String) -> Resource:
	if not PASSIVE_ITEMS.has(id):
		return null
	var script: GDScript = load(PASSIVE_ITEMS[id])
	if not script:
		return null
	return script.new()


func get_weapon_scene(weapon_name: String) -> PackedScene:
	if not WEAPON_SCENES.has(weapon_name):
		return null
	return load(WEAPON_SCENES[weapon_name])


func get_class_weapons(class_id: String) -> Array:
	return CLASS_WEAPONS.get(class_id, ["Arcane Orbs"])


func get_upgrade_choices(player: Node) -> Array[Dictionary]:
	var wm: Node = player.get_node_or_null("WeaponManager")
	var pm: Node = player.get_node_or_null("PassiveManager")

	var class_id: String = GameManager.selected_class
	var arsenal: Array = get_class_weapons(class_id)
	var signature: String = CLASS_SIGNATURE.get(class_id, "")
	var biased: Array = CLASS_PASSIVE_BIAS.get(class_id, [])

	var pool: Array[Dictionary] = []

	# 1. Upgrades for weapons you already carry
	if wm and "equipped_weapons" in wm:
		for weapon in wm.equipped_weapons:
			if weapon.weapon_level < weapon.max_level and not weapon.is_evolved:
				pool.append({
					"name": weapon.weapon_name,
					"type": "weapon_upgrade",
					"level": weapon.weapon_level + 1,
					"max_level": weapon.max_level,
					"description": weapon.upgrade_descriptions[
						clampi(weapon.weapon_level, 0, weapon.upgrade_descriptions.size() - 1)],
					"weight": 5 if weapon.weapon_name == signature else 4,
				})

	# 2. New weapons from this class's own arsenal
	if wm and wm.has_method("can_add_weapon") and wm.can_add_weapon():
		for w_name in arsenal:
			if wm.has_weapon(w_name):
				continue
			var weight: int = 3
			if w_name == signature:
				weight = 4
			pool.append({
				"name": w_name,
				"type": "new_weapon",
				"level": 1,
				"max_level": 5,
				"description": WEAPON_DESCRIPTIONS.get(w_name, "Add to your arsenal"),
				"weight": weight,
			})

	# 3. Passives — shared, with a nudge toward the class's favourites
	for item_name in PASSIVE_ITEMS:
		if pm and pm.has_method("has_passive") and not pm.has_passive(item_name):
			pool.append({
				"name": item_name,
				"type": "passive",
				"level": 0,
				"max_level": 1,
				"description": ITEM_DESCRIPTIONS.get(item_name, ""),
				"weight": 3 if item_name in biased else 1,
			})

	if pool.is_empty():
		return []

	var selected: Array[Dictionary] = []
	var remaining := pool.duplicate()

	for _i in range(3):
		if remaining.is_empty():
			break
		var total_weight: int = 0
		for entry in remaining:
			total_weight += entry.get("weight", 1)
		var roll: int = randi() % maxi(total_weight, 1)
		var cumulative: int = 0
		var picked: bool = false
		for j in range(remaining.size()):
			cumulative += remaining[j].get("weight", 1)
			if roll < cumulative:
				selected.append(remaining[j])
				remaining.remove_at(j)
				picked = true
				break
		if not picked:
			selected.append(remaining.pop_back())

	return selected