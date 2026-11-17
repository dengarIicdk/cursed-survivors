extends BasePassiveItem
class_name CursedRing

func _init() -> void:
	item_name = "Cursed Ring"
	description = "+50% damage, but -20% max HP."

func apply(player: Node) -> void:
	var pm: PassiveManager = player.get_node_or_null("PassiveManager")
	if pm:
		pm.add_stat_bonus("damage", 0.50)
	var hc: HealthComponent = player.get_node_or_null("HealthComponent")
	if hc:
		var hp_loss: float = hc.max_hp * 0.20
		hc.max_hp -= hp_loss
		hc.current_hp = minf(hc.current_hp, hc.max_hp)
		hc.health_changed.emit(hc.current_hp, hc.max_hp)
