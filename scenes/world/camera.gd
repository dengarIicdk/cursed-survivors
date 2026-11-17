extends Camera2D
class_name GameCamera

## Smooth follow camera with screen shake support.

var _shake_intensity: float = 0.0
var _shake_timer: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 8.0


func shake(intensity: float, duration: float) -> void:
	_shake_intensity = maxf(_shake_intensity, intensity)
	_shake_timer = maxf(_shake_timer, duration)


func _process(delta: float) -> void:
	if _shake_timer > 0.0:
		_shake_timer -= delta
		_shake_intensity = lerpf(_shake_intensity, 0.0, delta * 10.0)
		_shake_offset = Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
		offset = _shake_offset
	else:
		_shake_intensity = 0.0
		offset = Vector2.ZERO
