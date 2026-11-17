extends Button
class_name UpgradeCard

## Level-up choice card. Builds itself from the choice dictionary.

signal card_selected(choice_data: Dictionary)

const UIKit := preload("res://scripts/ui/ui_kit.gd")
const ICON_DIR := "res://assets/ui/icons/"

var card_key_number: int = 0

var _choice: Dictionary = {}
var _type_label: Label
var _name_label: Label
var _desc_label: Label
var _pips: HBoxContainer
var _icon: TextureRect
var _glow: TextureRect
var _base_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	UIKit.wire_sfx(self)
	custom_minimum_size = Vector2(286, 356)
	text = ""
	flat = false
	focus_mode = Control.FOCUS_ALL
	add_theme_stylebox_override("normal", UIKit.style(UIKit.FRAME_CARD, 26.0, Color.WHITE, 18.0))
	add_theme_stylebox_override("hover", UIKit.style(UIKit.FRAME_CARD, 26.0, Color(1.25, 1.1, 1.05), 18.0))
	add_theme_stylebox_override("pressed", UIKit.style(UIKit.FRAME_CARD, 26.0, Color(0.85, 0.8, 0.9), 18.0))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_build()
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)
	pressed.connect(_on_pressed)


func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(box)

	var icon_holder := Control.new()
	icon_holder.custom_minimum_size = Vector2(0, 122)
	icon_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon_holder)

	_glow = TextureRect.new()
	_glow.texture = load("res://assets/sprites/fx/glow.png")
	_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_glow.stretch_mode = TextureRect.STRETCH_SCALE
	_glow.set_anchors_preset(Control.PRESET_CENTER)
	_glow.offset_left = -62
	_glow.offset_right = 62
	_glow.offset_top = -62
	_glow.offset_bottom = 62
	_glow.modulate = Color(0.9, 0.4, 0.7, 0.35)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_holder.add_child(_glow)

	_icon = TextureRect.new()
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.custom_minimum_size = Vector2(110, 110)
	_icon.set_anchors_preset(Control.PRESET_CENTER)
	_icon.offset_left = -55
	_icon.offset_right = 55
	_icon.offset_top = -55
	_icon.offset_bottom = 55
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_holder.add_child(_icon)

	_type_label = UIKit.label(Loc.s("PASSIVE"), 12, Color(0.72, 0.62, 0.85))
	box.add_child(_type_label)

	_name_label = UIKit.title("Upgrade", 30, Color(1, 0.9, 0.75))
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.custom_minimum_size = Vector2(0, 52)
	box.add_child(_name_label)

	_desc_label = UIKit.body("", 16, UIKit.BONE)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_desc_label.add_theme_color_override("font_color", Color(0.86, 0.82, 0.9))
	_desc_label.custom_minimum_size = Vector2(0, 64)
	box.add_child(_desc_label)

	_pips = HBoxContainer.new()
	_pips.alignment = BoxContainer.ALIGNMENT_CENTER
	_pips.add_theme_constant_override("separation", 5)
	_pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_pips)


func setup(choice_data: Dictionary) -> void:
	_choice = choice_data
	if not _name_label:
		_build()

	var item_name: String = choice_data.get("name", "Unknown")
	_name_label.text = Loc.s(item_name)
	_desc_label.text = Loc.s(String(choice_data.get("description", "")))
	_icon.texture = _texture_for(item_name)

	var type: String = choice_data.get("type", "passive")
	match type:
		"weapon_upgrade":
			_type_label.text = Loc.s("WEAPON  •  UPGRADE")
			_type_label.add_theme_color_override("font_color", Color(0.9, 0.55, 0.72))
			_glow.modulate = Color(0.95, 0.35, 0.6, 0.42)
		"new_weapon":
			_type_label.text = Loc.s("NEW  WEAPON")
			_type_label.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
			_glow.modulate = Color(0.4, 0.7, 1.0, 0.42)
		_:
			_type_label.text = Loc.s("PASSIVE")
			_type_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.45))
			_glow.modulate = Color(1.0, 0.72, 0.3, 0.38)

	var level: int = int(choice_data.get("level", 0))
	var max_lv: int = int(choice_data.get("max_level", 5))
	if max_lv > 1:
		for i in range(max_lv):
			var star := TextureRect.new()
			star.texture = load("res://assets/ui/hud/star.png")
			star.custom_minimum_size = Vector2(15, 15)
			star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			star.modulate = Color(1, 0.85, 0.45) if i < level else Color(0.35, 0.3, 0.42, 0.85)
			_pips.add_child(star)
	else:
		var tag := UIKit.label(Loc.s("UNLOCK"), 12, Color(1, 0.85, 0.5))
		_pips.add_child(tag)


func _texture_for(item_name: String) -> Texture2D:
	var slug: String = item_name.to_lower().replace(" ", "_").replace("-", "_")
	var path: String = ICON_DIR + slug + ".png"
	if ResourceLoader.exists(path):
		return load(path)
	return null


func _on_hover() -> void:
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(1.045, 1.045), 0.12) \
		.set_trans(Tween.TRANS_SINE)
	var gt := create_tween()
	gt.tween_property(_glow, "modulate:a", 0.85, 0.15)


func _on_unhover() -> void:
	var t := create_tween()
	t.tween_property(self, "scale", Vector2.ONE, 0.12)
	var gt := create_tween()
	gt.tween_property(_glow, "modulate:a", 0.42, 0.15)


func _on_pressed() -> void:
	card_selected.emit(_choice)