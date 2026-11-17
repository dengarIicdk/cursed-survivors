extends Control

## In-game settings: audio mix, display mode/resolution, language.
##
## Opened either as a full scene (from the title screen) or instanced as an
## overlay above the pause menu, where `overlay` keeps the run paused.

const UIKit := preload("res://scripts/ui/ui_kit.gd")

const BG := "res://assets/ui/menu_background.png"
const SHADE := "res://assets/ui/menu_shade.png"

@export var overlay: bool = false

var _rows: VBoxContainer
var _root_box: VBoxContainer


func _ready() -> void:
	theme = load("res://assets/ui/theme_cursed.tres")
	if not overlay:
		AudioManager.crossfade_music("menu", 1.2)
	_setup_root()
	_rebuild()
	Loc.language_changed.connect(_rebuild)


func _setup_root() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := TextureRect.new()
	bg.texture = load(BG)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.55, 0.5, 0.62)
	add_child(bg)

	var shade := TextureRect.new()
	shade.texture = load(SHADE)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(shade)

	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centre)

	_root_box = VBoxContainer.new()
	_root_box.add_theme_constant_override("separation", 10)
	_root_box.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.add_child(_root_box)


func _rebuild() -> void:
	for child in _root_box.get_children():
		# remove immediately so reused node names (BackButton, Lang_ru...) stay stable
		_root_box.remove_child(child)
		child.queue_free()

	var title: Label = UIKit.title(Loc.s("SETTINGS"), 44, Color(1, 0.82, 0.55))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root_box.add_child(title)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIKit.style(
		"res://assets/ui/frames/panel.png", 20.0, Color(0.65, 0.5, 0.78)))
	panel.custom_minimum_size = Vector2(660, 0)
	_root_box.add_child(panel)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 9)
	panel.add_child(_rows)

	_add_section(Loc.s("AUDIO"))
	_add_volume_row(Loc.s("Master"), Settings.master_volume,
		Settings.set_master_volume, "Slider_Master")
	_add_volume_row(Loc.s("Music"), Settings.music_volume,
		Settings.set_music_volume, "Slider_Music")
	_add_volume_row(Loc.s("SFX"), Settings.sfx_volume,
		Settings.set_sfx_volume, "Slider_SFX")

	_add_gap()
	_add_section(Loc.s("DISPLAY"))
	_add_cycle_row(Loc.s("Resolution"), _resolution_text(), _cycle_resolution, "ResButton")
	_add_cycle_row(Loc.s("Window Mode"),
		Loc.s(Settings.MODE_LABELS[Settings.window_mode]), _cycle_mode, "ModeButton")

	_add_gap()
	_add_section(Loc.s("LANGUAGE"))
	_add_language_row()

	var back := UIKit.glow_button(Loc.s("BACK"), Vector2(240, 52))
	back.name = "BackButton"
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_close)
	UIKit.wire_sfx(back)
	_root_box.add_child(back)


func _add_section(text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var line_l := ColorRect.new()
	line_l.color = Color(0.55, 0.42, 0.65, 0.55)
	line_l.custom_minimum_size = Vector2(0, 1)
	line_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var label: Label = UIKit.title(text, 16, Color(1, 0.78, 0.5))
	label.add_theme_constant_override("outline_size", 3)
	var line_r := ColorRect.new()
	line_r.color = line_l.color
	line_r.custom_minimum_size = Vector2(0, 1)
	line_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(line_l)
	row.add_child(label)
	row.add_child(line_r)
	_rows.add_child(row)


func _add_gap() -> void:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 1)
	_rows.add_child(gap)


func _add_volume_row(label_text: String, value: float,
		setter: Callable, node_name: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var name_label := UIKit.label(label_text, 18, UIKit.BONE)
	name_label.custom_minimum_size = Vector2(200, 0)
	row.add_child(name_label)

	var slider := HSlider.new()
	slider.name = node_name
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = value
	slider.custom_minimum_size = Vector2(320, 22)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.add_theme_stylebox_override("slider", _track_style(false))
	slider.add_theme_stylebox_override("grabber_area", _track_style(true))
	slider.add_theme_stylebox_override("grabber_area_highlight", _track_style(true))
	row.add_child(slider)

	var pct := UIKit.label("%d%%" % int(round(value * 100.0)), 17, UIKit.GOLD,
		HORIZONTAL_ALIGNMENT_RIGHT)
	pct.custom_minimum_size = Vector2(52, 0)
	row.add_child(pct)

	slider.value_changed.connect(func(v: float) -> void:
		pct.text = "%d%%" % int(round(v * 100.0))
		setter.call(v)
	)
	_rows.add_child(row)


func _track_style(filled: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.62, 0.34, 0.52) if filled else Color(0.13, 0.1, 0.17)
	sb.border_color = Color(0.45, 0.33, 0.55)
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	return sb


func _add_cycle_row(label_text: String, value_text: String,
		on_press: Callable, node_name: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var name_label := UIKit.label(label_text, 18, UIKit.BONE)
	name_label.custom_minimum_size = Vector2(200, 0)
	row.add_child(name_label)

	var value_button := UIKit.glow_button("%s  ›" % value_text, Vector2(320, 42))
	value_button.name = node_name
	value_button.add_theme_font_size_override("font_size", 16)
	value_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_button.pressed.connect(func() -> void:
		on_press.call()
		_rebuild()
	)
	UIKit.wire_sfx(value_button)
	row.add_child(value_button)
	_rows.add_child(row)


func _add_language_row() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for code in Loc.LANGS:
		var selected: bool = Loc.language == code
		var button := UIKit.glow_button(Loc.LANG_LABELS[code], Vector2(200, 46))
		button.name = "Lang_" + code
		if selected:
			button.add_theme_color_override("font_color", Color(1, 0.86, 0.45))
			button.modulate = Color(1.0, 1.0, 1.0)
		else:
			button.modulate = Color(0.72, 0.68, 0.78)
		var target: String = code
		button.pressed.connect(func() -> void:
			Settings.set_language(target)
			_rebuild()
		)
		UIKit.wire_sfx(button)
		row.add_child(button)
	_rows.add_child(row)


func _resolution_text() -> String:
	return "%d × %d" % [Settings.resolution.x, Settings.resolution.y]


func _cycle_resolution() -> void:
	var list: Array[Vector2i] = Settings.RESOLUTIONS.duplicate()
	var index: int = list.find(Settings.resolution)
	var next: Vector2i = list[(index + 1) % list.size()]
	Settings.set_resolution(next)


func _cycle_mode() -> void:
	var modes: Array[int] = Settings.MODES.duplicate()
	var index: int = modes.find(Settings.window_mode)
	Settings.set_window_mode(modes[(index + 1) % modes.size()])


func _close() -> void:
	if overlay:
		queue_free()
	else:
		get_tree().change_scene_to_file("res://scenes/main/main.tscn")
