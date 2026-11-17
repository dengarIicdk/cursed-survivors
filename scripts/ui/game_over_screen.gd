extends CanvasLayer
class_name GameOverScreen

## End-of-run summary.

const UIKit := preload("res://scripts/ui/ui_kit.gd")

var _root: Control
var _title: Label
var _stats: VBoxContainer
var _coins: Label
var _retry: Button
var _menu: Button
var _won: bool = false


func _ready() -> void:
	visible = false
	_build()
	EventBus.run_ended.connect(_on_run_ended)


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.05, 0.01, 0.04, 0.86)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(shade)

	var centre := VBoxContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.add_theme_constant_override("separation", 16)
	_root.add_child(centre)

	_title = UIKit.title(Loc.s("YOU DIED"), 96, Color(0.92, 0.22, 0.28))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centre.add_child(_title)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", UIKit.style(UIKit.FRAME_PANEL, 26.0,
		Color.WHITE, 22.0))
	centre.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	_stats = VBoxContainer.new()
	_stats.add_theme_constant_override("separation", 6)
	box.add_child(_stats)

	_coins = UIKit.title(Loc.f("+{n} SOULS", {"n": 0}), 26, Color(1, 0.84, 0.4))
	_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_coins)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 18)
	centre.add_child(buttons)

	_retry = UIKit.glow_button(Loc.s("PLAY AGAIN"), Vector2(210, 56))
	_retry.name = "RetryButton"
	_retry.pressed.connect(_on_retry)
	buttons.add_child(_retry)

	_menu = UIKit.glow_button(Loc.s("MAIN MENU"), Vector2(190, 56))
	_menu.name = "MenuButton"
	_menu.pressed.connect(_on_menu)
	buttons.add_child(_menu)


func _stat_row(label_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	_stats.add_child(row)

	var l := UIKit.label(label_text, 17, UIKit.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)

	var v := UIKit.label(value_text, 19, UIKit.BONE, HORIZONTAL_ALIGNMENT_RIGHT)
	row.add_child(v)


func _on_run_ended(stats: Dictionary) -> void:
	visible = true
	# A level-up card may still be open when the killing blow lands.
	for sibling in ["LevelUpScreen", "PauseMenu"]:
		var other := get_parent().get_node_or_null(sibling)
		if other:
			other.visible = false
	get_tree().paused = true
	_won = stats.get("won", false)
	_title.text = Loc.s("NIGHT SURVIVED") if _won else Loc.s("YOU DIED")
	_title.modulate = Color(1, 0.85, 0.35) if _won else Color(1, 1, 1)

	for child in _stats.get_children():
		child.queue_free()

	var time_val: float = stats.get("time", 0.0)
	var minutes: int = int(time_val) / 60
	var seconds: int = int(time_val) % 60
	_stat_row(Loc.s("TIME SURVIVED"), "%02d:%02d" % [minutes, seconds])
	_stat_row(Loc.s("SOULS HARVESTED"), str(stats.get("kills", 0)))
	_stat_row(Loc.s("LEVEL REACHED"), str(stats.get("level", 1)))
	_coins.text = Loc.f("+{n} SOULS", {"n": int(stats.get("soul_coins", 0))})

	_title.scale = Vector2(0.82, 0.82)
	var t := create_tween()
	t.tween_property(_title, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_retry() -> void:
	visible = false
	get_tree().paused = false
	GameManager.start_run(GameManager.selected_class, GameManager.selected_map)
	get_tree().change_scene_to_file("res://scenes/world/world.tscn")


func _on_menu() -> void:
	visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")