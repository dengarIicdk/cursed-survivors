extends Control
class_name CursedShop

## Soul-coin shop: unlock survivors and buy permanent blessings.

const UIKit := preload("res://scripts/ui/ui_kit.gd")
const HERO_DIR := "res://assets/sprites/heroes/"
const ICON_DIR := "res://assets/ui/icons/"

var coins_label: Label
var back_button: Button

var _class_buttons: Dictionary = {}
var _upgrade_buttons: Dictionary = {}
var _upgrade_pips: Dictionary = {}


func _ready() -> void:
	_build()
	AudioManager.crossfade_music("menu", 2.0)
	_refresh_display()


func _build() -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://assets/ui/menu_background.png")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)

	var shade := TextureRect.new()
	shade.texture = load("res://assets/ui/menu_shade_h.png")
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(shade)

	var centre := VBoxContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.add_theme_constant_override("separation", 16)
	add_child(centre)

	var title := UIKit.title(Loc.s("THE CURSED SHOP"), 60, Color(1, 0.55, 0.75))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centre.add_child(title)

	var coins_row := HBoxContainer.new()
	coins_row.alignment = BoxContainer.ALIGNMENT_CENTER
	coins_row.add_theme_constant_override("separation", 8)
	centre.add_child(coins_row)
	coins_row.add_child(UIKit.icon("res://assets/sprites/fx/soul_coin.png", 24))
	coins_label = UIKit.label(Loc.f("{n} SOULS", {"n": 0}), 20, Color(1, 0.84, 0.42))
	coins_row.add_child(coins_label)

	var columns := HBoxContainer.new()
	columns.alignment = BoxContainer.ALIGNMENT_CENTER
	columns.add_theme_constant_override("separation", 26)
	centre.add_child(columns)

	columns.add_child(_make_column(Loc.s("UNLOCK SURVIVORS")))

	var left_box: VBoxContainer = _active_column
	left_box.add_child(_make_class_row("Ironclad", Loc.s("BRAWLER  •  Shield Aura"),
		"ironclad", SaveManager.class_price("Ironclad")))
	left_box.add_child(_make_class_row("Wraithborn", Loc.s("REAPER  •  Shadow Step"),
		"wraithborn", SaveManager.class_price("Wraithborn")))
	left_box.add_child(_make_class_row("Stormcaller", Loc.s("ARCANIST  •  Chain Lightning"),
		"stormcaller", SaveManager.class_price("Stormcaller")))

	columns.add_child(_make_column(Loc.s("ETERNAL BLESSINGS")))
	var right_box: VBoxContainer = _active_column
	right_box.add_child(_make_upgrade_row("hp", Loc.s("Max HP"), "iron_heart",
		Loc.s("+25 maximum life"), SaveManager.upgrade_price("hp"), SaveManager.MAX_HP_PURCHASES))
	right_box.add_child(_make_upgrade_row("damage", Loc.s("Damage"), "bloodstone",
		Loc.s("+5% all damage"), SaveManager.upgrade_price("damage"), SaveManager.MAX_DAMAGE_PURCHASES))
	right_box.add_child(_make_upgrade_row("speed", Loc.s("Move Speed"), "quicksilver_boots",
		Loc.s("+3% movement speed"), SaveManager.upgrade_price("speed"), SaveManager.MAX_SPEED_PURCHASES))

	centre.add_child(_make_map_row("Infernal Depths",
		Loc.s("Frozen halls beneath the earth — deadlier foes, richer souls"),
		"soul_lantern", SaveManager.map_price("Infernal Depths")))

	back_button = UIKit.glow_button(Loc.s("RETURN"), Vector2(240, 52))
	back_button.name = "BackButton"
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(_on_back)
	centre.add_child(back_button)


var _active_column: VBoxContainer = null
var _map_buttons: Dictionary = {}


func _make_map_row(map_name_str: String, subtitle: String, icon: String,
		price: int) -> Control:
	var holder := PanelContainer.new()
	holder.custom_minimum_size = Vector2(886, 0)
	holder.add_theme_stylebox_override("panel", UIKit.style("res://assets/ui/frames/button.png",
		18.0, Color(1.02, 0.95, 1.1), 10.0))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	holder.add_child(h)

	var ic := TextureRect.new()
	ic.texture = load(ICON_DIR + icon + ".png")
	ic.custom_minimum_size = Vector2(48, 48)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	h.add_child(ic)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", -2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	var n := UIKit.label(Loc.s("MAPS") + "  •  " + Loc.s(map_name_str), 18, UIKit.BONE,
		HORIZONTAL_ALIGNMENT_LEFT)
	n.add_theme_font_override("font", load(UIKit.TITLE_FONT))
	info.add_child(n)
	info.add_child(UIKit.label(subtitle, 12, UIKit.MUTED, HORIZONTAL_ALIGNMENT_LEFT))

	var btn := UIKit.glow_button(Loc.f("{n} SOULS", {"n": price}), Vector2(140, 40))
	btn.name = map_name_str.replace(" ", "") + "Btn"
	btn.pressed.connect(func(): purchase_map(map_name_str))
	UIKit.wire_sfx(btn)
	h.add_child(btn)
	_map_buttons[map_name_str] = btn
	return holder


func _make_column(header: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(430, 0)
	panel.add_theme_stylebox_override("panel", UIKit.style(UIKit.FRAME_PANEL, 26.0,
		Color.WHITE, 20.0))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var head := UIKit.label(header, 16, UIKit.GOLD)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(head)
	_active_column = box
	return panel


func _row_shell() -> HBoxContainer:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", UIKit.style("res://assets/ui/frames/button.png",
		18.0, Color(1.05, 1.05, 1.1), 10.0))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	row.add_child(h)
	return h


func _make_class_row(class_name_str: String, subtitle: String, slug: String,
		price: int) -> Control:
	var holder := PanelContainer.new()
	holder.add_theme_stylebox_override("panel", UIKit.style("res://assets/ui/frames/button.png",
		18.0, Color(1.02, 1.02, 1.08), 10.0))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	holder.add_child(h)

	var portrait := TextureRect.new()
	portrait.texture = load(HERO_DIR + slug + ".png")
	portrait.custom_minimum_size = Vector2(54, 54)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	h.add_child(portrait)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", -4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	var n := UIKit.label(Loc.s(class_name_str).to_upper(), 19, UIKit.BONE, HORIZONTAL_ALIGNMENT_LEFT)
	n.add_theme_font_override("font", load(UIKit.TITLE_FONT))
	info.add_child(n)
	info.add_child(UIKit.label(subtitle, 12, UIKit.MUTED, HORIZONTAL_ALIGNMENT_LEFT))

	var btn := UIKit.glow_button(Loc.f("{n} SOULS", {"n": price}), Vector2(120, 40))
	btn.name = slug.capitalize() + "Btn"
	btn.pressed.connect(func(): purchase_class(class_name_str))
	h.add_child(btn)
	_class_buttons[class_name_str] = btn
	return holder


func _make_upgrade_row(key: String, title: String, icon: String, desc: String,
		price: int, max_level: int) -> Control:
	var holder := PanelContainer.new()
	holder.add_theme_stylebox_override("panel", UIKit.style("res://assets/ui/frames/button.png",
		18.0, Color(1.02, 1.02, 1.08), 10.0))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	holder.add_child(h)

	var ic := TextureRect.new()
	ic.texture = load(ICON_DIR + icon + ".png")
	ic.custom_minimum_size = Vector2(48, 48)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	h.add_child(ic)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 1)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	var n := UIKit.label(title.to_upper(), 18, UIKit.BONE, HORIZONTAL_ALIGNMENT_LEFT)
	n.add_theme_font_override("font", load(UIKit.TITLE_FONT))
	info.add_child(n)
	info.add_child(UIKit.label(desc, 12, Color(0.78, 0.72, 0.84), HORIZONTAL_ALIGNMENT_LEFT))
	var pips := HBoxContainer.new()
	pips.add_theme_constant_override("separation", 3)
	pips.custom_minimum_size = Vector2(0, 9)
	info.add_child(pips)
	_upgrade_pips[key] = pips

	var btn := UIKit.glow_button("%d" % price, Vector2(92, 40))
	btn.name = key + "Btn"
	btn.pressed.connect(func(): _buy_upgrade(key))
	h.add_child(btn)
	_upgrade_buttons[key] = btn
	return holder


func _buy_upgrade(key: String) -> void:
	match key:
		"hp": purchase_hp_upgrade()
		"damage": purchase_damage_upgrade()
		"speed": purchase_speed_upgrade()


func _refresh_display() -> void:
	coins_label.text = Loc.f("{n} SOULS", {"n": SaveManager.soul_coins_total})

	for m_name in _map_buttons:
		var map_btn: Button = _map_buttons[m_name]
		var map_owned: bool = SaveManager.is_map_unlocked(m_name)
		map_btn.text = Loc.s("OWNED") if map_owned else Loc.f("{n} SOULS", {"n": SaveManager.map_price(m_name)})
		map_btn.disabled = map_owned

	for c_name in _class_buttons:
		var btn: Button = _class_buttons[c_name]
		var owned: bool = SaveManager.is_class_unlocked(c_name)
		btn.text = Loc.s("OWNED") if owned else Loc.f("{n} SOULS", {"n": SaveManager.class_price(c_name)})
		btn.disabled = owned

	var max_levels := {
		"hp": SaveManager.MAX_HP_PURCHASES,
		"damage": SaveManager.MAX_DAMAGE_PURCHASES,
		"speed": SaveManager.MAX_SPEED_PURCHASES,
	}
	for key in _upgrade_buttons:
		var btn: Button = _upgrade_buttons[key]
		var count: int = int(SaveManager.upgrade_purchase_counts.get(key, 0))
		var max_level: int = int(max_levels[key])
		btn.text = Loc.s("MAX") if count >= max_level else str(SaveManager.upgrade_price(key))
		btn.disabled = count >= max_level
		var pips: HBoxContainer = _upgrade_pips[key]
		for child in pips.get_children():
			child.queue_free()
		for i in range(max_level):
			var dot := ColorRect.new()
			dot.custom_minimum_size = Vector2(11, 5)
			dot.color = Color(1, 0.82, 0.42) if i < count else Color(0.3, 0.24, 0.36)
			pips.add_child(dot)


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func purchase_class(c_name: String) -> void:
	if SaveManager.is_class_unlocked(c_name):
		return
	if SaveManager.spend_coins(SaveManager.class_price(c_name)):
		SaveManager.unlock_class(c_name)
		_refresh_display()


func purchase_map(map_name_str: String) -> void:
	if SaveManager.is_map_unlocked(map_name_str):
		return
	if SaveManager.spend_coins(SaveManager.map_price(map_name_str)):
		SaveManager.unlock_map(map_name_str)
		AudioManager.play_sfx("coin", 1.0, 1.0)
		_refresh_display()


func purchase_hp_upgrade() -> void:
	if SaveManager.purchase_hp_upgrade():
		_refresh_display()


func purchase_damage_upgrade() -> void:
	if SaveManager.purchase_damage_upgrade():
		_refresh_display()


func purchase_speed_upgrade() -> void:
	if SaveManager.purchase_speed_upgrade():
		_refresh_display()