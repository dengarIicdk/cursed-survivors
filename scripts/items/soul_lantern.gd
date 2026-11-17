extends BasePassiveItem
class_name SoulLantern

func _init() -> void:
	item_name = "Soul Lantern"
	description = "Doubles XP collection radius."

func apply(player: Node) -> void:
	player.magnet_radius *= 2.0
	if player.has_method("_update_magnet_radius"):
		player._update_magnet_radius()
