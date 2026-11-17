extends Node2D
class_name DamageNumber

## Floating damage text. Deliberately quiet: small, semi-transparent, short
## lived, and it accumulates while it lives so a burst of hits reads as one
## number instead of a stream of flickering digits.

const FONT_PATH := "res://assets/fonts/Almendra-Bold.ttf"

var _label: Label
var _amount: float = 0.0
var _life: float = 0.0
var _lifetime: float = 0.6
var _drift: Vector2 = Vector2.ZERO
var _crit: bool = false


func setup(pos: Vector2, amount: float, crit: bool = false) -> void:
	global_position = pos
	_amount = amount
	_crit = crit
	_drift = Vector2(randf_range(-9.0, 9.0), -30.0)
	_refresh()


func _ready() -> void:
	z_index = 40
	if not _label:
		_build()


func _build() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font: FontFile = load(FONT_PATH)
	_label.add_theme_font_override("font", font)
	_label.add_theme_font_size_override("font_size", 15)
	_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.74, 0.88))
	_label.add_theme_color_override("font_outline_color", Color(0.08, 0.02, 0.06, 0.65))
	_label.add_theme_constant_override("outline_size", 4)
	_label.size = Vector2(90, 22)
	_label.position = Vector2(-45, -11)
	add_child(_label)


## Adds to the run-of-the-mill number while it is still on screen.
func add_amount(amount: float) -> void:
	_amount += amount
	_life = 0.0
	_scale_pop()
	_refresh()


func _refresh() -> void:
	if not _label:
		_build()
	var value: float = _amount
	var text: String
	if value >= 1000.0:
		text = str(int(roundf(value / 100.0))) + "00"
	elif value >= 100.0:
		text = str(int(roundf(value)))
	elif value >= 10.0:
		text = str(int(roundf(value)))
	else:
		text = "%.1f" % value
	_label.text = text
	_label.add_theme_font_size_override("font_size", 19 if _crit else 15)
	_label.add_theme_color_override("font_color",
		Color(1.0, 0.78, 0.45, 0.92) if _crit else Color(1.0, 0.92, 0.74, 0.88))


func _scale_pop() -> void:
	scale = Vector2.ONE * 1.18
	var t := create_tween()
	t.tween_property(self, "scale", Vector2.ONE, 0.12)


func _process(delta: float) -> void:
	_life += delta
	var t: float = clampf(_life / _lifetime, 0.0, 1.0)
	position += _drift * delta * (1.0 - t * 0.55)
	modulate.a = 1.0 - t * t
	if _label:
		_label.modulate.a = 1.0 - t * t
	if _life >= _lifetime:
		queue_free()
