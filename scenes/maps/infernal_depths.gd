extends Node2D
class_name InfernalDepthsMap

## Infernal Depths Map Controller with periodic lava surge

var ambient_color: Color = Color(0.25, 0.08, 0.04)
var lava_surge_interval: float = 30.0
var _surge_timer: float = 0.0


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	_surge_timer += delta
	if _surge_timer >= lava_surge_interval:
		_surge_timer = 0.0
		_trigger_lava_surge()


func _trigger_lava_surge() -> void:
	# Flash warning
	var player = GameManager.player
	if player and is_instance_valid(player):
		var dist = player.global_position.length()
		if dist > 600.0:
			var hc = player.get_node_or_null("HealthComponent")
			if hc:
				hc.take_damage(20.0)
