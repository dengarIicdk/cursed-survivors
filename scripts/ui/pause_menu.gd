extends CanvasLayer
class_name PauseMenu

## Pause overlay with run stats.

const UIKit := preload("res://scripts/ui/ui_kit.gd")

var _root: Control
var _stats: VBoxContainer
var _resume: Button
var _restart: Button
var _menu: Button
var _settings: Button
var _settings_layer: CanvasLayer


func _ready() -> void:
	visible = false
	_build()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.03, 0.01, 0.05, 0.8)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(shade)

	var centre := VBoxContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.add_theme_constant_override("separation", 18)
	_root.add_child(centre)

	var title := UIKit.title(Loc.s("PAUSED"), 80, Color(1, 0.86, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centre.add_child(title)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", UIKit.style(UIKit.FRAME_PANEL, 24.0,
		Color.WHITE, 20.0))
	centre.add_child(panel)

	_stats = VBoxContainer.new()
	_stats.add_theme_constant_override("separation", 6)
	panel.add_child(_stats)

	var buttons_wrap := CenterContainer.new()
	centre.add_child(buttons_wrap)
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	buttons_wrap.add_child(buttons)

	_resume = UIKit.glow_button(Loc.s("RESUME"), Vector2(320, 56))
	_resume.name = "ResumeButton"
	_resume.pressed.connect(_on_resume)
	UIKit.wire_sfx(_resume)
	buttons.add_child(_resume)

	_settings = UIKit.glow_button(Loc.s("SETTINGS"), Vector2(300, 50))
	_settings.name = "SettingsButton"
	_settings.pressed.connect(_on_settings)
	UIKit.wire_sfx(_settings)
	buttons.add_child(_settings)

	_restart = UIKit.glow_button(Loc.s("RESTART"), Vector2(300, 50))
	_restart.name = "RestartButton"
	_restart.pressed.connect(_on_restart)
	UIKit.wire_sfx(_restart)
	buttons.add_child(_restart)

	_menu = UIKit.glow_button(Loc.s("MAIN MENU"), Vector2(300, 50))
	_menu.name = "MenuButton"
	_menu.pressed.connect(_on_menu)
	UIKit.wire_sfx(_menu)
	buttons.add_child(_menu)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if visible:
			_on_resume()
		elif GameManager.current_state == GameManager.State.PLAYING:
			_show()


func _show() -> void:
	visible = true
	GameManager.pause_game()
	for child in _stats.get_children():
		child.queue_free()
	_stat_row(Loc.s("TIME"), GameManager.get_run_time_formatted())
	_stat_row(Loc.s("SOULS"), str(GameManager.kill_count))
	_stat_row(Loc.s("LEVEL"), str(GameManager.current_level))


func _stat_row(label_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	_stats.add_child(row)
	var l := UIKit.label(label_text, 17, UIKit.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var v := UIKit.label(value_text, 20, UIKit.BONE, HORIZONTAL_ALIGNMENT_RIGHT)
	row.add_child(v)


func _clear_settings() -> void:
	if is_instance_valid(_settings_layer):
		_settings_layer.queue_free()
		_settings_layer = null


func _on_settings() -> void:
	if is_instance_valid(_settings_layer):
		return
	var scene: PackedScene = load("res://scenes/ui/settings_menu.tscn")
	if scene == null:
		return
	_settings_layer = CanvasLayer.new()
	_settings_layer.layer = 30
	_settings_layer.name = "SettingsLayer"
	var panel: Control = scene.instantiate()
	panel.overlay = true
	_settings_layer.add_child(panel)
	add_child(_settings_layer)


func _on_resume() -> void:
	visible = false
	GameManager.resume_game()


func _on_restart() -> void:
	visible = false
	_clear_settings()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _on_menu() -> void:
	visible = false
	_clear_settings()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")