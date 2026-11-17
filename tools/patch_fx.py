"""Rewires weapon / class / enemy visuals to the sprite-based FX kit."""

import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FX = 'const FXKit := preload("res://scripts/fx/fx_kit.gd")\n'


def load(p):
    return open(os.path.join(ROOT, p), encoding="utf-8").read()


def save(p, s):
    open(os.path.join(ROOT, p), "w", encoding="utf-8", newline="\n").write(s)


def add_preload(s, after):
    if "fx_kit.gd" in s:
        return s
    return s.replace(after, after + "\n" + FX, 1)


def patch(p, pairs, after=None):
    s = load(p)
    if after:
        s = add_preload(s, after)
    for old, new in pairs:
        if old not in s:
            print("  !! pattern not found in", p, "->", old.strip().splitlines()[0][:70])
            continue
        s = s.replace(old, new, 1)
    save(p, s)
    print("patched", p)


patch("scripts/weapons/arcane_orbs.gd", [(
    '''		var visual := ColorRect.new()
		visual.size = Vector2(orb_size * 2, orb_size * 2)
		visual.position = Vector2(-orb_size, -orb_size)
		visual.color = Color(0.9, 0.1, 0.9, 0.95) if is_evolved else Color(0.5, 0.2, 1.0, 0.9)
		orb.add_child(visual)''',
    '''		var visual := FXKit.orb(orb_size * 2.3, is_evolved)
		orb.add_child(visual)''',
)], after="class_name ArcaneOrbs")

patch("scripts/weapons/shadow_daggers.gd", [(
    '''	var visual := ColorRect.new()
	visual.size = Vector2(12, 4)
	visual.position = Vector2(-6, -2)
	visual.color = Color(0.2, 0.0, 0.3, 0.9)
	dagger.add_child(visual)''',
    '''	var visual := FXKit.dagger(34.0)
	dagger.add_child(visual)''',
)], after="class_name ShadowDaggers")

patch("scripts/weapons/lightning_chain.gd", [
    ('''func _draw_lightning(from: Vector2, to: Vector2) -> void:
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = Color(0.6, 0.8, 1.0, 1.0)
	
	var points: PackedVector2Array = []
	points.append(from)
	var segments: int = 6
	for i in range(1, segments):
		var t: float = float(i) / float(segments)
		var mid: Vector2 = from.lerp(to, t)
		mid += Vector2(randf_range(-8, 8), randf_range(-8, 8))
		points.append(mid)
	points.append(to)
	line.points = points
	
	get_tree().root.add_child(line)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.15)
	tween.tween_callback(line.queue_free)''',
     '''func _draw_lightning(from: Vector2, to: Vector2) -> void:
	var tint: Color = Color(1.0, 0.55, 0.85) if is_evolved else Color(0.55, 0.86, 1.0)
	FXKit.lightning(get_tree().root, from, to, tint, 3.4)
	FXKit.hit_spark(get_tree().root, to, tint)'''),
    ('''	var visual := ColorRect.new()
	visual.size = Vector2(80, 80)
	visual.position = Vector2(-40, -40)
	visual.color = Color(0.4, 0.6, 1.0, 0.3)
	zone.add_child(visual)''',
     '''	var visual := FXKit.sprite(FXKit.TEX_RING, 76.0, Color(0.55, 0.88, 1.0, 0.55))
	FXKit.additive(visual)
	FXKit.pulse(visual, 0.10, 5.0)
	zone.add_child(visual)
	var core := FXKit.glow_sprite(70.0, Color(0.45, 0.75, 1.0, 0.30))
	zone.add_child(core)'''),
    ('''	_storm_cloud = Node2D.new()
	var cloud_visual := ColorRect.new()
	cloud_visual.size = Vector2(80, 30)
	cloud_visual.position = Vector2(-40, -60)
	cloud_visual.color = Color(0.3, 0.3, 0.6, 0.6)
	_storm_cloud.add_child(cloud_visual)''',
     '''	_storm_cloud = FXKit.storm_cloud()'''),
], after="class_name LightningChain")

patch("scripts/weapons/blade_aura.gd", [
    ("var _enemies_hit_this_cycle: Array = []",
     "var _enemies_hit_this_cycle: Array = []\nvar _visual: Node2D = null"),
    ('''		"Shockwaves on critical hits — ready to evolve!",
	]''',
     '''		"Shockwaves on critical hits — ready to evolve!",
	]
	call_deferred("_build_visual")'''),
    ("	var interval: float = get_attack_interval()",
     '''	if _visual and is_instance_valid(_visual) and _player and is_instance_valid(_player):
		_visual.global_position = _player.global_position
		_visual.rotation = _aura_rotation

	var interval: float = get_attack_interval()'''),
    ('''	var visual := ColorRect.new()
	visual.size = Vector2(160, 160)
	visual.position = Vector2(-80, -80)
	visual.color = Color(1, 0.8, 0.2, 0.5)
	sw.add_child(visual)''',
     '''	FXKit.shockwave(get_tree().root, pos, 170.0, Color(1.0, 0.82, 0.36, 0.9))'''),
    ('''	var tween := sw.create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, 0.3)
	tween.tween_callback(sw.queue_free)''',
     '''	var tween := sw.create_tween()
	tween.tween_interval(0.1)
	tween.tween_callback(sw.queue_free)'''),
    ("func _on_upgrade() -> void:",
     '''func _build_visual() -> void:
	if not _player or not is_instance_valid(_player):
		call_deferred("_build_visual")
		return
	if _visual and is_instance_valid(_visual):
		_visual.queue_free()
	_visual = Node2D.new()
	_visual.z_index = 6
	var ring := FXKit.sprite(FXKit.TEX_RING, radius * 2.0, Color(1.0, 0.78, 0.36, 0.22))
	FXKit.additive(ring)
	_visual.add_child(ring)
	var blade_px: float = 40.0 if not is_evolved else 58.0
	for i in range(blade_count):
		var b: Sprite2D = FXKit.blade(blade_px)
		var a: float = TAU / float(blade_count) * float(i)
		b.position = Vector2(cos(a), sin(a)) * radius
		b.rotation = a + PI * 0.5
		_visual.add_child(b)
	_player.add_child(_visual)
	_visual.global_position = _player.global_position


func _on_upgrade() -> void:'''),
    ('''		5: shockwave_on_crit = true


func _on_evolve()''',
     '''		5: shockwave_on_crit = true
	_build_visual()


func _on_evolve()'''),
    ('''	shockwave_on_crit = true
	crit_chance = 0.3''',
     '''	shockwave_on_crit = true
	crit_chance = 0.3
	_build_visual()'''),
], after="class_name BladeAura")

patch("scripts/enemies/base_enemy.gd", [
    ('''	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(2, 2, 2, 1), 0.05)''',
     '''	if randf() < 0.45:
		FXKit.hit_spark(get_tree().root, global_position, Color(1.0, 0.82, 0.5))
		if amount >= 40.0:
			FXKit.slash(get_tree().root, global_position, Color(1, 1, 1, 0.8), 54.0)

	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(2, 2, 2, 1), 0.05)'''),
    ('''	_on_die()
	
	if is_pooled:''',
     '''	if is_elite:
		FXKit.shockwave(get_tree().root, global_position, 200.0, Color(1.0, 0.7, 0.35, 0.9))
	else:
		FXKit.death_burst(get_tree().root, global_position, _death_tint())
	FXKit.blood_decal(get_tree().root, global_position)
	FXKit.hit_spark(get_tree().root, global_position, _death_tint())

	_on_die()
	
	if is_pooled:'''),
    ('''func _on_die() -> void:
	pass''',
     '''func _on_die() -> void:
	pass


func _death_tint() -> Color:
	return Color(1.0, 0.55, 0.55) if not is_elite else Color(1.0, 0.8, 0.3)'''),
], after="class_name BaseEnemy")

patch("scripts/classes/hexblade.gd", [(
    '''	var visual := ColorRect.new()
	visual.size = Vector2(16, 24)
	visual.position = Vector2(-8, -12)
	visual.color = Color(0.5, 0.2, 0.9, 0.6)
	clone.add_child(visual)''',
    '''	var visual := Sprite2D.new()
	visual.texture = preload("res://assets/sprites/heroes/hexblade.png")
	visual.scale = Vector2(0.42, 0.42)
	visual.modulate = Color(0.75, 0.45, 1.0, 0.62)
	clone.add_child(visual)
	var halo := FXKit.glow_sprite(70.0, Color(0.7, 0.35, 1.0, 0.45))
	clone.add_child(halo)''',
)], after="class_name Hexblade")

patch("scripts/classes/ironclad.gd", [(
    '''	_aura_visual = ColorRect.new()
	_aura_visual.size = Vector2(48, 48)
	_aura_visual.position = Vector2(-24, -24)
	_aura_visual.color = Color(1.0, 0.8, 0.0, 0.3)
	add_child(_aura_visual)''',
    '''	_aura_visual = FXKit.glow_sprite(150.0, Color(1.0, 0.72, 0.25, 0.55))
	add_child(_aura_visual)
	FXKit.pulse(_aura_visual, 0.12, 3.0)''',
)], after="class_name Ironclad")

patch("scripts/classes/wraithborn.gd", [(
    '''	var flash := ColorRect.new()
	flash.size = Vector2(100, 100)
	flash.position = blink_pos - Vector2(50, 50)
	flash.color = Color(0.2, 0.0, 0.3, 0.7)
	get_tree().root.add_child(flash)
	var tween := flash.create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)''',
    '''	FXKit.flash(get_tree().root, blink_pos, 150.0, Color(0.55, 0.25, 0.85, 0.85))
	FXKit.shockwave(get_tree().root, blink_pos, 120.0, Color(0.65, 0.35, 0.95, 0.85))''',
)], after="class_name Wraithborn")

patch("scripts/classes/stormcaller.gd", [(
    '''	var flash := ColorRect.new()
	flash.anchors_preset = Control.PRESET_FULL_RECT
	flash.color = Color(1, 1, 1, 0.8)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 100
	hud_layer.add_child(flash)
	get_tree().root.add_child(hud_layer)
	var tween := flash.create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.5)
	tween.tween_callback(hud_layer.queue_free)''',
    '''	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 100
	get_tree().root.add_child(hud_layer)
	var flash := ColorRect.new()
	flash.anchors_preset = Control.PRESET_FULL_RECT
	flash.color = Color(0.65, 0.9, 1.0, 0.55)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(flash)
	var tween := flash.create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.45)
	tween.tween_callback(hud_layer.queue_free)
	for i in range(14):
		var strike_pos: Vector2 = global_position + Vector2(randf_range(-420, 420), randf_range(-260, 260))
		FXKit.lightning(get_tree().root, strike_pos + Vector2(0, -180), strike_pos,
			Color(0.6, 0.9, 1.0), 3.0)''',
)], after="class_name Stormcaller")