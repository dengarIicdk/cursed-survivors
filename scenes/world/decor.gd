extends Node2D
class_name WorldDecor

## Streams gothic props in chunks around the player so the arena never feels
## empty, plus floating dust and ember motes for depth.

const CHUNK: float = 384.0
const RADIUS: int = 2

const TEX_GRAVESTONE: Array[Texture2D] = [
	preload("res://assets/sprites/props/gravestone_0.png"),
	preload("res://assets/sprites/props/gravestone_1.png"),
	preload("res://assets/sprites/props/gravestone_2.png"),
	preload("res://assets/sprites/props/gravestone_3.png"),
]
const TEX_TREE: Texture2D = preload("res://assets/sprites/props/dead_tree.png")
const TEX_BONES: Texture2D = preload("res://assets/sprites/props/bones.png")
const TEX_CANDLES: Texture2D = preload("res://assets/sprites/props/candles.png")
const TEX_FENCE: Texture2D = preload("res://assets/sprites/props/fence.png")
const TEX_URN: Texture2D = preload("res://assets/sprites/props/urn.png")
const TEX_CRYSTAL: Array[Texture2D] = [
	preload("res://assets/sprites/props/depths/crystal_0.png"),
	preload("res://assets/sprites/props/depths/crystal_1.png"),
	preload("res://assets/sprites/props/depths/crystal_2.png"),
]
const TEX_STALAGMITE: Texture2D = preload("res://assets/sprites/props/depths/stalagmite.png")
const TEX_MAGMA: Texture2D = preload("res://assets/sprites/props/depths/magma_vent.png")
const TEX_ICE_BONES: Texture2D = preload("res://assets/sprites/props/depths/ice_bones.png")
const TEX_SHADOW: Texture2D = preload("res://assets/sprites/fx/shadow.png")
const TEX_GLOW: Texture2D = preload("res://assets/sprites/fx/glow.png")

var global_light_color: Color = Color(0.55, 0.35, 0.85)
var _theme: String = "graveyard"

var _chunks: Dictionary = {}
var _motes: Node2D


func _ready() -> void:
	z_index = -5
	_build_motes()
	call_deferred("_refresh")


func setup(light_color: Color, theme: String = "graveyard") -> void:
	global_light_color = light_color
	if theme != _theme:
		_theme = theme
		for key in _chunks.keys():
			_chunks[key].queue_free()
		_chunks.clear()
	if _motes:
		for child in _motes.get_children():
			if child is CPUParticles2D:
				child.color = light_color.lightened(0.45)


func _process(_delta: float) -> void:
	if GameManager.player and is_instance_valid(GameManager.player):
		_refresh()
		_motes.global_position = GameManager.player.global_position


func _refresh() -> void:
	var player: Node2D = GameManager.player
	if not player:
		return
	var center := Vector2i(floor(player.global_position.x / CHUNK), floor(player.global_position.y / CHUNK))
	for ox in range(-RADIUS, RADIUS + 1):
		for oy in range(-RADIUS, RADIUS + 1):
			var key := center + Vector2i(ox, oy)
			if not _chunks.has(key):
				_chunks[key] = _build_chunk(key)
	for key in _chunks.keys():
		if abs(key.x - center.x) > RADIUS + 1 or abs(key.y - center.y) > RADIUS + 1:
			_chunks[key].queue_free()
			_chunks.erase(key)


func _build_chunk(key: Vector2i) -> Node2D:
	var holder := Node2D.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key) + 0x9E3779B9
	holder.position = Vector2(key.x * CHUNK, key.y * CHUNK)
	add_child(holder)

	var count := rng.randi_range(3, 6)
	for i in range(count):
		var pos := Vector2(rng.randf_range(20, CHUNK - 20), rng.randf_range(20, CHUNK - 20))
		_place_prop(holder, pos, rng)

	# Soft pools of contaminated light.
	if rng.randf() < 0.6:
		var light := Sprite2D.new()
		light.texture = TEX_GLOW
		light.modulate = Color(global_light_color.r, global_light_color.g, global_light_color.b, 0.10)
		light.scale = Vector2(rng.randf_range(3.0, 6.0), rng.randf_range(2.0, 4.0))
		light.position = Vector2(rng.randf_range(0, CHUNK), rng.randf_range(0, CHUNK))
		light.z_index = -2
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		light.material = mat
		holder.add_child(light)
	return holder


func _place_prop(holder: Node2D, pos: Vector2, rng: RandomNumberGenerator) -> void:
	var roll := rng.randf()
	var tex: Texture2D
	var scale_range := Vector2(0.5, 0.75)
	var glow := false

	if _theme == "depths":
		# Frozen cavern: shards of ice, basalt teeth and glowing magma seams.
		if roll < 0.40:
			tex = TEX_CRYSTAL[rng.randi_range(0, 2)]
			scale_range = Vector2(0.5, 0.85)
			glow = true
		elif roll < 0.62:
			tex = TEX_STALAGMITE
			scale_range = Vector2(0.55, 0.9)
		elif roll < 0.80:
			tex = TEX_MAGMA
			scale_range = Vector2(0.55, 0.8)
			glow = true
		elif roll < 0.92:
			tex = TEX_ICE_BONES
			scale_range = Vector2(0.5, 0.8)
		else:
			tex = TEX_CRYSTAL[0]
			scale_range = Vector2(0.35, 0.5)
			glow = true
	elif roll < 0.36:
		tex = TEX_GRAVESTONE[rng.randi_range(0, 3)]
		scale_range = Vector2(0.55, 0.8)
	elif roll < 0.50:
		tex = TEX_TREE
		scale_range = Vector2(0.55, 0.85)
	elif roll < 0.66:
		tex = TEX_BONES
		scale_range = Vector2(0.5, 0.85)
	elif roll < 0.80:
		tex = TEX_CANDLES
		scale_range = Vector2(0.6, 0.9)
		glow = true
	elif roll < 0.92:
		tex = TEX_FENCE
		scale_range = Vector2(0.5, 0.8)
	else:
		tex = TEX_URN
		scale_range = Vector2(0.6, 0.9)

	var sprite := Sprite2D.new()
	sprite.texture = tex
	var s := rng.randf_range(scale_range.x, scale_range.y)
	sprite.scale = Vector2(s * (1.0 if rng.randf() > 0.5 else -1.0), s)
	sprite.position = pos
	sprite.modulate = Color(1, 1, 1, rng.randf_range(0.8, 1.0))
	holder.add_child(sprite)

	var shadow := Sprite2D.new()
	shadow.texture = TEX_SHADOW
	shadow.position = pos + Vector2(0, tex.get_height() * s * 0.34)
	shadow.scale = Vector2(s * 1.1, s * 0.8)
	shadow.modulate = Color(1, 1, 1, 0.55)
	shadow.z_index = -1
	holder.add_child(shadow)

	if glow:
		var halo := Sprite2D.new()
		halo.texture = TEX_GLOW
		halo.position = pos + Vector2(0, -18 * s)
		halo.scale = Vector2.ONE * s * 1.6
		var halo_color: Color = Color(0.35, 0.75, 1.0, 0.35) if _theme == "depths" else Color(1.0, 0.62, 0.25, 0.35)
		halo.modulate = halo_color
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		halo.material = mat
		holder.add_child(halo)
		var flicker := halo.create_tween()
		flicker.set_loops()
		flicker.tween_property(halo, "modulate:a", halo_color.a * 0.5, rng.randf_range(0.5, 0.9))
		flicker.tween_property(halo, "modulate:a", halo_color.a * 1.15, rng.randf_range(0.5, 0.9))


func _build_motes() -> void:
	_motes = Node2D.new()
	_motes.z_index = 15
	add_child(_motes)

	var dust := CPUParticles2D.new()
	dust.texture = TEX_GLOW
	dust.amount = 34
	dust.lifetime = 9.0
	dust.preprocess = 6.0
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(700, 420)
	dust.direction = Vector2(0.2, -1)
	dust.spread = 40.0
	dust.initial_velocity_min = 6.0
	dust.initial_velocity_max = 22.0
	dust.gravity = Vector2(0, 2)
	dust.scale_amount_min = 0.05
	dust.scale_amount_max = 0.16
	dust.color = Color(0.85, 0.75, 1.0, 0.13)
	var m1 := CanvasItemMaterial.new()
	m1.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	dust.material = m1
	_motes.add_child(dust)

	var embers := CPUParticles2D.new()
	embers.texture = TEX_GLOW
	embers.amount = 14
	embers.lifetime = 6.0
	embers.preprocess = 4.0
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(620, 380)
	embers.direction = Vector2(0.4, -1)
	embers.spread = 30.0
	embers.initial_velocity_min = 12.0
	embers.initial_velocity_max = 34.0
	embers.gravity = Vector2(3, -4)
	embers.scale_amount_min = 0.05
	embers.scale_amount_max = 0.13
	embers.color = Color(1.0, 0.58, 0.28, 0.26)
	var m2 := CanvasItemMaterial.new()
	m2.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	embers.material = m2
	_motes.add_child(embers)