extends BasePassiveItem
class_name Grimoire

func _init() -> void:
	item_name = "Grimoire"
	description = "+15% damage to all attacks."

func apply(player: Node) -> void:
	var pm: PassiveManager = player.get_node_or_null("PassiveManager")
	if pm:
		pm.add_stat_bonus("damage", 0.15)
