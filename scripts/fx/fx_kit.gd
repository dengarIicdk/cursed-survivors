extends RefCounted
class_name FXKit

## Shared visual effects: glowing orbs, blades, lightning, hit sparks,
## death bursts and ground decals. Everything is sprite based so it stays
## cheap enough for several hundred enemies on screen.

const TEX_GLOW := preload("res://assets/sprites/fx/glow.png")
const TEX_SPARK := preload("res://assets/sprites/fx/spark.png")
const TEX_DUST := preload("res://assets/sprites/fx/dust.png")
const TEX_RING := preload("res://assets/sprites/fx/ring.png")
const TEX_BLOOD := preload("res://assets/sprites/fx/blood.png")
const TEX_SLASH := preload("res://assets/sprites/fx/slash.png")
const TEX_ORB := preload("res://assets/sprites/fx/orb.png")
const TEX_ORB_CHAOS := preload("res://assets/sprites/fx/orb_chaos.png")
const TEX_DAGGER := preload("res://assets/sprites/fx/dagger.png")
const TEX_BLADE := preload("res://assets/sprites/fx/blade.png")
const TEX_BOLT := preload("res://assets/sprites/fx/bolt.png")
const TEX_CLOUD := preload("res://assets/sprites/fx/cloud.png")
const DamageNumberScene := preload("res://scripts/fx/damage_number.gd")


static func additive(item: CanvasItem) -> void:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	item.material = mat


static func sprite(tex: Texture2D, px: float, tint: Color = Color.WHITE) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.scale = Vector2(px / tex.get_width(), px / tex.get_width())
	s.modulate = tint
	return s


static func glow_sprite(px: float, tint: Color) -> Sprite2D:
	var s := sprite(TEX_GLOW, px, tint)
	additive(s)
	return s


## Floating combat text. Kept small and short lived on purpose: it should read
## as feedback, not as UI noise.
static func damage_number(parent: Node, pos: Vector2, amount: float, crit: bool = false) -> Node2D:
	var num: Node2D = DamageNumberScene.new()
	parent.add_child(num)
	num.setup(pos, amount, crit)
	return num


static func pulse(item: Node2D, amount: float = 0.12, speed: float = 4.0) -> void:
	var t := item.create_tween()
	t.set_loops()
	var base := item.scale
	t.tween_property(item, "scale", base * (1.0 + amount), 1.0 / speed)
	t.tween_property(item, "scale", base, 1.0 / speed)


## Arcane orb: bright core plus additive halo.
static func orb(px: float, evolved: bool = false) -> Node2D:
	var holder := Node2D.new()
	var halo := glow_sprite(px * 2.0, Color(0.86, 0.42, 1.0, 0.75) if not evolved
		else Color(1.0, 0.35, 0.75, 0.85))
	holder.add_child(halo)
	var core := sprite(TEX_ORB_CHAOS if evolved else TEX_ORB, px)
	holder.add_child(core)
	pulse(core, 0.08, 6.0)
	var spin := holder.create_tween()
	spin.set_loops()
	spin.tween_property(holder, "rotation", TAU, 6.0)
	return holder


static func blade(px: float) -> Sprite2D:
	var s := sprite(TEX_BLADE, px)
	return s


static func dagger(px: float) -> Sprite2D:
	return sprite(TEX_DAGGER, px)


## Expanding shockwave ring centred on a world position.
static func shockwave(parent: Node, pos: Vector2, radius: float, tint: Color) -> void:
	var ring := sprite(TEX_RING, radius * 0.4, tint)
	ring.z_index = 6
	additive(ring)
	ring.global_position = pos
	parent.add_child(ring)
	var t := ring.create_tween()
	t.set_parallel(true)
	t.tween_property(ring, "scale", Vector2.ONE * (radius / 64.0), 0.36) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(ring, "modulate:a", 0.0, 0.36)
	t.chain().tween_callback(ring.queue_free)


static func hit_spark(parent: Node, pos: Vector2, tint: Color = Color(1.0, 0.86, 0.55)) -> void:
	var s := sprite(TEX_SPARK, randf_range(14.0, 22.0), tint)
	s.z_index = 8
	additive(s)
	s.global_position = pos + Vector2(randf_range(-6, 6), randf_range(-8, 4))
	parent.add_child(s)
	var t := s.create_tween()
	t.set_parallel(true)
	t.tween_property(s, "scale", s.scale * 1.8, 0.18)
	t.tween_property(s, "modulate:a", 0.0, 0.18)
	t.chain().tween_callback(s.queue_free)


static func slash(parent: Node, pos: Vector2, tint: Color = Color(1, 1, 1, 0.9),
		px: float = 46.0, angle: float = INF) -> void:
	var s := sprite(TEX_SLASH, px, tint)
	s.z_index = 7
	additive(s)
	s.global_position = pos
	s.rotation = angle if angle != INF else randf() * TAU
	parent.add_child(s)
	var t := s.create_tween()
	t.set_parallel(true)
	t.tween_property(s, "scale", s.scale * 1.45, 0.22)
	t.tween_property(s, "modulate:a", 0.0, 0.22)
	t.chain().tween_callback(s.queue_free)


static func blood_decal(parent: Node, pos: Vector2) -> void:
	var s := sprite(TEX_BLOOD, randf_range(20.0, 34.0), Color(1, 1, 1, 0.85))
	s.z_index = -4
	s.global_position = pos + Vector2(randf_range(-4, 4), randf_range(-2, 4))
	s.rotation = randf() * TAU
	s.scale.x *= randf_range(0.8, 1.3)
	parent.add_child(s)
	var t := s.create_tween()
	t.tween_interval(6.0)
	t.tween_property(s, "modulate:a", 0.0, 3.0)
	t.tween_callback(s.queue_free)


static func death_burst(parent: Node, pos: Vector2, tint: Color = Color(0.85, 0.35, 0.45)) -> void:
	var p := CPUParticles2D.new()
	p.texture = TEX_DUST
	p.amount = 9
	p.lifetime = 0.55
	p.one_shot = true
	p.explosiveness = 1.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 5.0
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 90.0
	p.gravity = Vector2(0, 60)
	p.scale_amount_min = 0.1
	p.scale_amount_max = 0.3
	p.color = tint
	p.z_index = 7
	additive(p)
	p.global_position = pos
	parent.add_child(p)
	p.emitting = true
	var t := p.create_tween()
	t.tween_interval(0.75)
	t.tween_callback(p.queue_free)


static func flash(parent: Node, pos: Vector2, radius: float, tint: Color) -> void:
	var s := glow_sprite(radius * 0.6, tint)
	s.z_index = 6
	additive(s)
	s.global_position = pos
	parent.add_child(s)
	var t := s.create_tween()
	t.set_parallel(true)
	t.tween_property(s, "scale", s.scale * (radius / (radius * 0.6)) * 1.4, 0.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(s, "modulate:a", 0.0, 0.4)
	t.chain().tween_callback(s.queue_free)


## Two-layer jagged lightning arc between two world points.
static func lightning(parent: Node, from: Vector2, to: Vector2, tint: Color,
		width: float = 4.0) -> Node2D:
	var holder := Node2D.new()
	holder.z_index = 9
	var jitter: float = from.distance_to(to) * 0.12
	var pts: PackedVector2Array = PackedVector2Array()
	var steps := 10
	for i in range(steps + 1):
		var t := float(i) / steps
		var p := from.lerp(to, t)
		if i > 0 and i < steps:
			var normal := (to - from).normalized().orthogonal()
			p += normal * randf_range(-jitter, jitter)
		pts.append(p - from)
	holder.position = from

	var glow := Line2D.new()
	glow.points = pts
	glow.width = width * 2.6
	glow.default_color = Color(tint.r, tint.g, tint.b, 0.35)
	glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	glow.end_cap_mode = Line2D.LINE_CAP_ROUND
	additive(glow)
	holder.add_child(glow)

	var core := Line2D.new()
	core.points = pts
	core.width = width
	core.default_color = tint.lightened(0.55)
	core.begin_cap_mode = Line2D.LINE_CAP_ROUND
	core.end_cap_mode = Line2D.LINE_CAP_ROUND
	holder.add_child(core)

	parent.add_child(holder)
	var t := holder.create_tween()
	t.tween_property(holder, "modulate:a", 0.0, 0.18)
	t.tween_callback(holder.queue_free)
	return holder


static func storm_cloud() -> Node2D:
	var cloud := Node2D.new()
	cloud.z_index = 12
	for i in range(3):
		var blob := sprite(TEX_CLOUD, randf_range(70.0, 105.0),
			Color(0.42, 0.38, 0.62, 0.55))
		blob.position = Vector2(randf_range(-26, 26), randf_range(-12, 12))
		cloud.add_child(blob)
	for i in range(2):
		var halo := glow_sprite(randf_range(50.0, 80.0), Color(0.35, 0.7, 1.0, 0.25))
		halo.position = Vector2(randf_range(-20, 20), randf_range(-8, 8))
		cloud.add_child(halo)
	cloud.position = Vector2(0, -58)
	var bob := cloud.create_tween()
	bob.set_loops()
	bob.tween_property(cloud, "position:y", -64.0, 1.6).set_trans(Tween.TRANS_SINE)
	bob.tween_property(cloud, "position:y", -54.0, 1.6).set_trans(Tween.TRANS_SINE)
	return cloud