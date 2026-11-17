extends BasePassiveItem
class_name ShadowCloak

func _init() -> void:
	item_name = "Shadow Cloak"
	description = "8% chance to dodge any hit."

func apply(player: Node) -> void:
	var hc: HealthComponent = player.get_node_or_null("HealthComponent")
	if hc:
		hc.dodge_chance += 0.08
