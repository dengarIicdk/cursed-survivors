extends RefCounted
class_name UIKit

## Small helpers that keep every screen visually consistent.

const TITLE_FONT := "res://assets/fonts/PirataOne-Regular.ttf"
const BODY_FONT := "res://assets/fonts/Almendra-Bold.ttf"
const FRAME_CARD := "res://assets/ui/frames/card.png"
const FRAME_PANEL := "res://assets/ui/frames/panel.png"

const GOLD := Color(1.0, 0.847, 0.435)
const BONE := Color(0.929, 0.894, 0.827)
const MUTED := Color(0.62, 0.56, 0.68)
const MAGENTA := Color(1.0, 0.361, 0.545)
const TEAL := Color(0.34, 0.88, 0.81)


static func font(path: String, size: int) -> FontFile:
	var f: FontFile = load(path)
	if f and size > 0:
		return f
	return null


static func style(tex_path: String, margin: float = 20.0, tint: Color = Color.WHITE,
		content: float = 0.0) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load(tex_path)
	sb.texture_margin_left = margin
	sb.texture_margin_top = margin
	sb.texture_margin_right = margin
	sb.texture_margin_bottom = margin
	sb.modulate_color = tint
	if content > 0.0:
		sb.content_margin_left = content
		sb.content_margin_top = content
		sb.content_margin_right = content
		sb.content_margin_bottom = content
	return sb


static func label(text: String, size: int = 17, color: Color = BONE,
		align: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


static func title(text: String, size: int = 72, color: Color = MAGENTA) -> Label:
	var l := label(text, size, color)
	l.add_theme_font_override("font", load(TITLE_FONT))
	l.add_theme_color_override("font_shadow_color", Color(0.1, 0.02, 0.1, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 4)
	l.add_theme_constant_override("shadow_offset_y", 5)
	l.add_theme_constant_override("shadow_outline_size", 6)
	return l


static func body(text: String, size: int = 17, color: Color = BONE) -> Label:
	var l := label(text, size, color)
	l.add_theme_font_override("font", load(BODY_FONT))
	return l


static func icon(path: String, px: int) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(path)
	t.custom_minimum_size = Vector2(px, px)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return t


static func panel(size: Vector2 = Vector2.ZERO) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(FRAME_PANEL, 22.0, Color.WHITE, 26.0))
	if size != Vector2.ZERO:
		p.custom_minimum_size = size
	return p


static func _hover_ping() -> void:
	AudioManager.play_sfx("ui_hover", 0.5)


static func _click_ping() -> void:
	AudioManager.play_sfx("ui_click", 0.9)


## Every interactive piece goes through here so the UI has one voice.
static func wire_sfx(b: Button) -> Button:
	if not b.mouse_entered.is_connected(_hover_ping):
		b.mouse_entered.connect(_hover_ping)
	if not b.pressed.is_connected(_click_ping):
		b.pressed.connect(_click_ping)
	return b


static func card_button(size: Vector2) -> Button:
	var b := Button.new()
	b.custom_minimum_size = size
	b.add_theme_stylebox_override("normal", style(FRAME_CARD, 20.0, Color(0.86, 0.86, 0.9), 18.0))
	b.add_theme_stylebox_override("hover", style(FRAME_CARD, 20.0, Color(1.25, 1.12, 0.92), 18.0))
	b.add_theme_stylebox_override("pressed", style(FRAME_CARD, 20.0, Color(1.1, 0.95, 0.85), 18.0))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return wire_sfx(b)


static func glow_button(text: String, size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_color_override("font_color", Color(1.0, 0.93, 0.75))
	b.add_theme_stylebox_override("normal", style("res://assets/ui/frames/button.png", 18.0,
		Color(1.35, 1.1, 0.75), 22.0))
	b.add_theme_stylebox_override("hover", style("res://assets/ui/frames/button_hover.png", 18.0,
		Color(1.45, 1.3, 1.0), 22.0))
	b.add_theme_stylebox_override("pressed", style("res://assets/ui/frames/button_active.png", 18.0,
		Color.WHITE, 22.0))
	return wire_sfx(b)


static func bar(texture: String, height: int) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(0, height)
	b.show_percentage = false
	b.add_theme_stylebox_override("background", style("res://assets/ui/bar_back.png", 12.0))
	b.add_theme_stylebox_override("fill", style(texture, 10.0))
	return b


## Adds a soft drop shadow sprite behind a Control so panels pop off the scene.
static func shadow_of(holder: Control, radius: float = 18.0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.55)
	sb.corner_radius_top_left = int(radius)
	sb.corner_radius_top_right = int(radius)
	sb.corner_radius_bottom_left = int(radius)
	sb.corner_radius_bottom_right = int(radius)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 18
	holder.add_theme_stylebox_override("panel", sb)