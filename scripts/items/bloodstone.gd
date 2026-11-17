extends BasePassiveItem
class_name Bloodstone

func _init() -> void:
	item_name = "Bloodstone"
	description = "Lifesteal: recover 2% of damage dealt as HP (max 6%)."

func apply(player: Node) -> void:
	var hc: HealthComponent = player.get_node_or_null("HealthComponent")
	if hc:
		hc.lifesteal += 0.02
