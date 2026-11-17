extends BasePassiveItem
class_name PhoenixFeather

func _init() -> void:
	item_name = "Phoenix Feather"
	description = "Revive once per run with 50% HP upon death."

func apply(player: Node) -> void:
	player.has_revive = true
