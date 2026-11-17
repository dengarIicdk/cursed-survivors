extends BasePassiveItem
class_name QuicksilverBoots

func _init() -> void:
	item_name = "Quicksilver Boots"
	description = "+20% movement speed."

func apply(player: Node) -> void:
	var pm: PassiveManager = player.get_node_or_null("PassiveManager")
	if pm:
		pm.add_stat_bonus("speed", 0.20)
