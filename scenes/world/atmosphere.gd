extends CanvasLayer
class_name Atmosphere

## Screen-space fog, vignette and damage feedback for the world.

@onready var overlay: ColorRect = $Overlay

var _damage: float = 0.0
var _damage_tween: Tween


func _ready() -> void:
	layer = 2
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_map(mode: String) -> void:
	var mat: ShaderMaterial = overlay.material
	if not mat:
		return
	if mode == "Infernal Depths":
		mat.set_shader_parameter("fog_color", Color(0.30, 0.62, 0.92))
		mat.set_shader_parameter("fog_amount", 0.16)
		mat.set_shader_parameter("vignette_strength", 0.58)
	else:
		mat.set_shader_parameter("fog_color", Color(0.52, 0.34, 0.72))
		mat.set_shader_parameter("fog_amount", 0.14)
		mat.set_shader_parameter("vignette_strength", 0.50)


func damage_flash(amount: float = 0.85) -> void:
	if _damage_tween:
		_damage_tween.kill()
	_damage = amount
	_damage_tween = create_tween()
	_damage_tween.tween_method(_set_damage, amount, 0.0, 0.55)


func low_health(on: bool) -> void:
	var mat: ShaderMaterial = overlay.material
	if mat:
		mat.set_shader_parameter("pulse", 1.0 if on else 0.0)


func _set_damage(v: float) -> void:
	_damage = v
	var mat: ShaderMaterial = overlay.material
	if mat:
		mat.set_shader_parameter("damage", v)