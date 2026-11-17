extends BasePassiveItem
class_name TimeShard

func _init() -> void:
	item_name = "Time Shard"
	description = "-15% all weapon cooldowns."

func apply(player: Node) -> void:
	var pm: PassiveManager = player.get_node_or_null("PassiveManager")
	if pm:
		pm.add_stat_bonus("cooldown", 0.15)
