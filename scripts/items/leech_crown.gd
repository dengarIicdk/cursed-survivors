extends BasePassiveItem
class_name LeechCrown

## Lifesteal scales with kill count. Updates each time an enemy dies.

var _player_ref: Node = null

func _init() -> void:
	item_name = "Leech Crown"
	description = "Lifesteal scales with kill count (kill more = heal more)."

func apply(player: Node) -> void:
	_player_ref = player
	EventBus.enemy_killed.connect(_on_enemy_killed)
	_update_lifesteal()

func _on_enemy_killed(_enemy: Node, _pos: Vector2) -> void:
	_update_lifesteal()

func _update_lifesteal() -> void:
	if not _player_ref or not is_instance_valid(_player_ref):
		return
	var hc: HealthComponent = _player_ref.get_node_or_null("HealthComponent")
	if hc:
		# 1% at the start, +1% per 400 kills, never above the 6% cap
		hc.lifesteal = minf(0.01 + GameManager.kill_count * 0.000025, 0.06)
