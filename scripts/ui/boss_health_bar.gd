extends ProgressBar
class_name BossHealthBar

## Tracks and displays a specific boss's health.

@export var boss_name: String = ""


func _ready() -> void:
	EventBus.boss_health_changed.connect(_on_boss_health_changed)
	EventBus.boss_killed.connect(_on_boss_killed)
	visible = false


func _on_boss_health_changed(b_name: String, current: float, maximum: float) -> void:
	if boss_name == "" or boss_name == b_name:
		visible = true
		max_value = maximum
		value = current


func _on_boss_killed(b_name: String) -> void:
	if boss_name == "" or boss_name == b_name:
		visible = false
