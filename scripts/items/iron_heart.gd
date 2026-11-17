extends BasePassiveItem
class_name IronHeart

func _init() -> void:
	item_name = "Iron Heart"
	description = "+50 maximum HP."

func apply(player: Node) -> void:
	var hc: HealthComponent = player.get_node_or_null("HealthComponent")
	if hc:
		hc.add_max_hp(50.0)
