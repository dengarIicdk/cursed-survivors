extends Control
class_name MainMenu

## Title screen. Built in code so the gothic styling stays consistent.

const UIKit := preload("res://scripts/ui/ui_kit.gd")

const BG := "res://assets/ui/menu_background.png"
const SHADE := "res://assets/ui/menu_shade.png"
const SHADER := "res://shaders/atmosphere.gdshader"

const CLASSES := [
	{"id": "Hexblade", "role": "Dark Mage", "weapon": "Arcane Orbs", "art": "res://assets/sprites/heroes/hexblade.png"},
	{"id": "Ironclad", "role": "Warrior", "weapon": "Sword Splash", "art": "res://assets/sprites/heroes/ironclad.png"},
	{"id": "Wraithborn", "role": "Rogue", "weapon": "Shadow Daggers", "art": "res://assets/sprites/heroes/wraithborn.png"},
	{"id": "Stormcaller", "role": "Shaman", "weapon": "Lightning Chain", "art": "res://assets/sprites/heroes/stormcaller.png"},
]
const MAPS := ["Cursed Graveyard", "Infernal Depths"]

var _selected_class: String = "Hexblade"
var _selected_map: String = "Cursed Graveyard"

var _class_cards: Dictionary = {}
var _map_buttons: Dictionary = {}
var _start_button: Button
var _coin_label: Label
var _reset_overlay: Control = null


func _ready() -> void:
	theme = load("res://assets/ui/theme_cursed.tres")
	_selected_class = GameManager.selected_class
	_selected_map = GameManager.selected_map
	_build()
	_refresh()
	AudioManager.crossfade_music("menu", 2.0)


func _build() -> void:
	var bg := TextureRect.new()
	bg.texture = load(BG)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)

	var shade := TextureRect.new()
	shade.texture = load(SHADE)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(shade)

	var fog := ColorRect.new()
	fog.set_anchors_preset(Control.PRESET_FULL_RECT)
	fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER)
	mat.set_shader_parameter("fog_amount", 0.20)
	mat.set_shader_parameter("fog_color", Color(0.46, 0.28, 0.62))
	mat.set_shader_parameter("vignette_strength", 0.95)
	mat.set_shader_parameter("vignette_radius", 0.62)
	fog.material = mat
	add_child(fog)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_top = 14
	root.alignment = BoxContainer.ALIGNMENT_BEGIN
	root.add_theme_constant_override("separation", 6)
	add_child(root)

	var title: Label = UIKit.title(Loc.s("CURSED SURVIVORS"), 82)
	title.custom_minimum_size = Vector2(0, 96)
	root.add_child(title)
	var subtitle := UIKit.label(Loc.s("SURVIVE THE NIGHT   ✦   HARVEST SOULS"), 17,
		Color(0.78, 0.72, 0.88))
	subtitle.name = "Subtitle"
	root.add_child(subtitle)
	root.add_child(_spacer(14))

	var class_row := HBoxContainer.new()
	class_row.alignment = BoxContainer.ALIGNMENT_CENTER
	class_row.add_theme_constant_override("separation", 16)
	for c in CLASSES:
		var card := _make_class_card(c)
		_class_cards[c["id"]] = card
		class_row.add_child(card)
	root.add_child(class_row)

	root.add_child(_spacer(10))

	var map_row := HBoxContainer.new()
	map_row.alignment = BoxContainer.ALIGNMENT_CENTER
	map_row.add_theme_constant_override("separation", 18)
	for m in MAPS:
		var b := Button.new()
		b.text = m
		b.name = "Map_" + str(m).replace(" ", "")
		b.custom_minimum_size = Vector2(250, 46)
		b.add_theme_font_size_override("font_size", 17)
		b.pressed.connect(func(): _select_map(m))
		UIKit.wire_sfx(b)
		_map_buttons[m] = b
		map_row.add_child(b)
	root.add_child(map_row)

	root.add_child(_spacer(14))

	var start_center := CenterContainer.new()
	_start_button = UIKit.glow_button(Loc.s("BEGIN THE HUNT"), Vector2(380, 66))
	_start_button.add_theme_font_override("font", load(UIKit.TITLE_FONT))
	_start_button.add_theme_font_size_override("font_size", 30)
	_start_button.name = "StartButton"
	_start_button.pressed.connect(_on_start_pressed)
	start_center.add_child(_start_button)
	root.add_child(start_center)

	var push := Control.new()
	push.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(push)

	# footer
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 14)
	footer.offset_left = 26
	footer.offset_right = -26
	root.add_child(footer)

	var coin_icon: TextureRect = UIKit.icon("res://assets/sprites/fx/soul_coin.png", 26)
	footer.add_child(coin_icon)
	_coin_label = UIKit.label(Loc.f("SOULS  {n}", {"n": SaveManager.soul_coins_total}), 19,
		UIKit.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	footer.add_child(_coin_label)

	var stretch := Control.new()
	stretch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(stretch)

	var settings_button := Button.new()
	settings_button.text = Loc.s("SETTINGS")
	settings_button.custom_minimum_size = Vector2(170, 44)
	settings_button.name = "SettingsButton"
	settings_button.pressed.connect(_on_settings_pressed)
	UIKit.wire_sfx(settings_button)
	footer.add_child(settings_button)

	var shop := Button.new()
	shop.text = Loc.s("CURSED SHOP")
	shop.custom_minimum_size = Vector2(190, 44)
	shop.name = "ShopButton"
	shop.pressed.connect(_on_shop_pressed)
	UIKit.wire_sfx(shop)
	footer.add_child(shop)

	var reset := Button.new()
	reset.text = Loc.s("RESET")
	reset.custom_minimum_size = Vector2(120, 44)
	reset.name = "ResetButton"
	reset.add_theme_color_override("font_color", Color(0.78, 0.52, 0.55))
	reset.pressed.connect(_on_reset_pressed)
	UIKit.wire_sfx(reset)
	footer.add_child(reset)

	var quit := Button.new()
	quit.text = Loc.s("QUIT")
	quit.custom_minimum_size = Vector2(120, 44)
	quit.name = "QuitButton"
	quit.pressed.connect(_on_quit_pressed)
	UIKit.wire_sfx(quit)
	footer.add_child(quit)


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _make_class_card(data: Dictionary) -> Button:
	var b := UIKit.card_button(Vector2(212, 250))
	b.name = "Card_" + str(data["id"])
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 10
	box.offset_right = -10
	box.offset_top = 8
	box.offset_bottom = -8
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 2)
	b.add_child(box)

	var portrait := TextureRect.new()
	portrait.texture = load(data["art"])
	portrait.custom_minimum_size = Vector2(0, 132)
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(portrait)

	var name_label: Label = UIKit.label(Loc.s(data["id"]), 21, UIKit.BONE)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_label)

	var role: Label = UIKit.label(Loc.s(data["role"]) + "  •  " + Loc.s(data["weapon"]), 14,
		Color(0.74, 0.68, 0.82))
	role.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(role)

	var status: Label = UIKit.label("", 14, UIKit.GOLD)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.name = "Status"
	box.add_child(status)

	b.set_meta("status", status)
	b.set_meta("portrait", portrait)
	b.pressed.connect(func(): _select_class(data["id"]))
	b.mouse_entered.connect(func(): _hover_card(b, true))
	b.mouse_exited.connect(func(): _hover_card(b, false))
	return b


func _hover_card(card: Button, on: bool) -> void:
	var t := card.create_tween()
	t.tween_property(card, "scale", Vector2(1.035, 1.035) if on else Vector2(1.0, 1.0), 0.1)


func _select_class(c_name: String) -> void:
	if not SaveManager.is_class_unlocked(c_name):
		_shake(_class_cards[c_name])
		return
	_selected_class = c_name
	_refresh()


func _select_map(m_name: String) -> void:
	if not SaveManager.is_map_unlocked(m_name):
		_shake(_map_buttons[m_name])
		return
	_selected_map = m_name
	_refresh()


func _shake(node: Control) -> void:
	var base := node.position
	var t := node.create_tween()
	for i in range(3):
		t.tween_property(node, "position", base + Vector2(6 - i * 4, 0), 0.04)
	t.tween_property(node, "position", base, 0.04)


func _refresh() -> void:
	for c in CLASSES:
		var id: String = c["id"]
		var card: Button = _class_cards[id]
		var unlocked := SaveManager.is_class_unlocked(id)
		var selected := id == _selected_class
		var status: Label = card.get_meta("status")
		var portrait: TextureRect = card.get_meta("portrait")

		if not unlocked:
			status.text = Loc.s("LOCKED") + "  •  " + Loc.f("{n} SOULS",
				{"n": SaveManager.class_price(id)})
			status.add_theme_color_override("font_color", Color(0.58, 0.52, 0.62))
			portrait.modulate = Color(0.62, 0.58, 0.72, 0.95)
		elif selected:
			status.text = Loc.s("SELECTED")
			status.add_theme_color_override("font_color", UIKit.GOLD)
			portrait.modulate = Color.WHITE
		else:
			status.text = ""
			portrait.modulate = Color(0.82, 0.82, 0.88)

		card.add_theme_stylebox_override("normal", UIKit.style(UIKit.FRAME_CARD, 20.0,
			Color(1.55, 1.32, 0.78) if selected else Color(0.86, 0.86, 0.9), 18.0))

	for m in MAPS:
		var b: Button = _map_buttons[m]
		var unlocked := SaveManager.is_map_unlocked(m)
		b.disabled = not unlocked
		b.text = Loc.s(m) if unlocked else Loc.s(m) + "  •  " + Loc.s("LOCKED")
		if not unlocked:
			b.add_theme_color_override("font_disabled_color", Color(0.68, 0.6, 0.75))
		if m == _selected_map:
			b.add_theme_stylebox_override("normal", UIKit.style(
				"res://assets/ui/frames/button_hover.png", 18.0, Color(1.3, 1.15, 0.85), 22.0))
		else:
			b.add_theme_stylebox_override("normal", UIKit.style(
				"res://assets/ui/frames/button.png", 18.0, Color.WHITE, 22.0))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_start_pressed()


func _on_settings_pressed() -> void:
	AudioManager.play_sfx("ui_click", 1.0, 0.8)
	get_tree().change_scene_to_file("res://scenes/ui/settings_menu.tscn")


func _on_start_pressed() -> void:
	AudioManager.play_sfx("ui_click", 1.0, 0.8)
	GameManager.start_run(_selected_class, _selected_map)
	get_tree().change_scene_to_file("res://scenes/world/world.tscn")


func _on_shop_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/cursed_shop.tscn")


func _on_reset_pressed() -> void:
	AudioManager.play_sfx("ui_click", 1.0, 0.8)
	if is_instance_valid(_reset_overlay):
		return
	_build_reset_confirm()


## Erasing a save is the one thing here that cannot be undone, so it gets a
## two-step confirmation instead of a single click.
func _build_reset_confirm() -> void:
	_reset_overlay = Control.new()
	_reset_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_reset_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_reset_overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.01, 0.03, 0.82)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_reset_overlay.add_child(shade)

	var centre := VBoxContainer.new()
	centre.set_anchors_preset(Control.PRESET_CENTER)
	centre.offset_left = -300
	centre.offset_right = 300
	centre.offset_top = -140
	centre.offset_bottom = 140
	centre.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.add_theme_constant_override("separation", 18)
	_reset_overlay.add_child(centre)

	var title := UIKit.title(Loc.s("ERASE ALL PROGRESS?"), 44, Color(1, 0.45, 0.45))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centre.add_child(title)

	var body := UIKit.label(Loc.s("Souls, unlocked survivors, blessings and maps will be lost forever."),
		16, UIKit.MUTED)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(520, 0)
	centre.add_child(body)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	centre.add_child(row)

	var cancel := UIKit.glow_button(Loc.s("CANCEL"), Vector2(190, 52))
	cancel.name = "ResetCancelButton"
	cancel.pressed.connect(_close_reset_confirm)
	UIKit.wire_sfx(cancel)
	row.add_child(cancel)

	var confirm := UIKit.glow_button(Loc.s("ERASE EVERYTHING"), Vector2(260, 52))
	confirm.name = "ResetConfirmButton"
	confirm.add_theme_color_override("font_color", Color(1, 0.62, 0.6))
	confirm.pressed.connect(_do_reset)
	UIKit.wire_sfx(confirm)
	row.add_child(confirm)

	_reset_overlay.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_reset_overlay, "modulate:a", 1.0, 0.18)


func _close_reset_confirm() -> void:
	if not is_instance_valid(_reset_overlay):
		return
	var overlay: Control = _reset_overlay
	_reset_overlay = null
	var t := create_tween()
	t.tween_property(overlay, "modulate:a", 0.0, 0.15)
	t.tween_callback(overlay.queue_free)


func _do_reset() -> void:
	SaveManager.reset_progress()
	GameManager.selected_class = "Hexblade"
	GameManager.selected_map = "Cursed Graveyard"
	_selected_class = "Hexblade"
	_selected_map = "Cursed Graveyard"
	AudioManager.play_sfx("boss_die", 0.8, 0.7)
	if is_instance_valid(_coin_label):
		_coin_label.text = Loc.f("SOULS  {n}", {"n": SaveManager.soul_coins_total})
	_refresh()
	_close_reset_confirm()


func _on_quit_pressed() -> void:
	get_tree().quit()