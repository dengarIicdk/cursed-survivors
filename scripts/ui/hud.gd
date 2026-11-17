extends CanvasLayer
class_name HUD

## In-game HUD: XP bar across the top, health + timer + kills below it,
## and a boss bar that fades in for boss fights.

const UIKit := preload("res://scripts/ui/ui_kit.gd")
const ICON_SKULL := "res://assets/ui/hud/skull.png"
const ICON_CLOCK := "res://assets/ui/hud/clock.png"
const ICON_STAR := "res://assets/ui/hud/star.png"

var health_bar: TextureProgressBar
var xp_bar: TextureProgressBar
var hp_label: Label
var timer_label: Label
var kill_label: Label
var level_label: Label
var boss_bar_container: Control
var boss_bar: TextureProgressBar
var boss_name_label: Label
var _boss_tween: Tween = null
var warning_label: Label
var ring_label: Label
var _ring_node: Node = null
var _warning_tween: Tween = null
var _root: Control


func _ready() -> void:
	if not Loc.language_changed.is_connected(_refresh_language):
		Loc.language_changed.connect(_refresh_language)
	_build()
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.player_healed.connect(_on_player_healed)
	EventBus.xp_changed.connect(_on_xp_changed)
	EventBus.level_up.connect(_on_level_up)
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_killed.connect(_on_boss_killed)
	EventBus.boss_health_changed.connect(_on_boss_health_changed)
	EventBus.ring_event_started.connect(_on_ring_started)
	EventBus.ring_event_ended.connect(_on_ring_ended)
	boss_bar_container.visible = false
	_refresh_health()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# ---- XP bar: full width strip at the very top
	xp_bar = _make_bar("res://assets/ui/bar_back.png", "res://assets/ui/bar_xp.png")
	xp_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	xp_bar.offset_left = 0
	xp_bar.offset_right = 0
	xp_bar.offset_top = 0
	xp_bar.offset_bottom = 18
	xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(xp_bar)

	level_label = UIKit.label(Loc.f("LV {n}", {"n": 1}), 15, Color(1, 0.94, 0.76))
	level_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	level_label.offset_left = -30
	level_label.offset_right = 30
	level_label.offset_top = 2
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	level_label.add_theme_constant_override("shadow_offset_x", 1)
	level_label.add_theme_constant_override("shadow_offset_y", 1)
	_root.add_child(level_label)

	# ---- left cluster: health
	var left := HBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.position = Vector2(16, 26)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(left)

	var skull := UIKit.icon(ICON_SKULL, 26)
	left.add_child(skull)

	var hp_stack := Control.new()
	hp_stack.custom_minimum_size = Vector2(236, 30)
	hp_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(hp_stack)

	health_bar = _make_bar("res://assets/ui/bar_back.png", "res://assets/ui/bar_hp.png")
	health_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	health_bar.offset_bottom = -4
	hp_stack.add_child(health_bar)

	hp_label = UIKit.label("100 / 100", 13, Color(1, 0.94, 0.9))
	hp_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	hp_label.offset_bottom = -4
	hp_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	hp_label.add_theme_constant_override("shadow_offset_x", 1)
	hp_label.add_theme_constant_override("shadow_offset_y", 1)
	hp_stack.add_child(hp_label)

	# ---- centre: timer
	var centre := VBoxContainer.new()
	centre.set_anchors_preset(Control.PRESET_CENTER_TOP)
	centre.offset_left = -110
	centre.offset_right = 110
	centre.offset_top = 24
	centre.add_theme_constant_override("separation", -6)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(centre)

	var clock_row := HBoxContainer.new()
	clock_row.alignment = BoxContainer.ALIGNMENT_CENTER
	clock_row.add_theme_constant_override("separation", 6)
	clock_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(clock_row)
	clock_row.add_child(UIKit.icon(ICON_CLOCK, 18))
	timer_label = UIKit.title("00:00", 32, Color(1, 0.9, 0.7))
	clock_row.add_child(timer_label)

	# ---- countdown to the next closing ring, right under the clock.
	# The clock row starts with an icon, which pushes the time text right, so
	# the countdown gets a matching nudge to sit dead centre with it.
	ring_label = UIKit.label("", 15, Color(0.86, 0.42, 0.38))
	ring_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ring_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring_label.modulate.a = 0.0
	var ring_row := MarginContainer.new()
	ring_row.add_theme_constant_override("margin_left", 24)
	ring_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring_row.add_child(ring_label)
	centre.add_child(ring_row)

	# ---- right cluster: kills
	var right := HBoxContainer.new()
	right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right.offset_left = -170
	right.offset_right = -18
	right.offset_top = 30
	right.add_theme_constant_override("separation", 8)
	right.alignment = BoxContainer.ALIGNMENT_END
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(right)
	right.add_child(UIKit.icon(ICON_SKULL, 22))
	kill_label = UIKit.label("0", 22, UIKit.BONE, HORIZONTAL_ALIGNMENT_RIGHT)
	right.add_child(kill_label)

	# ---- event warning: one line, centred, fades away by itself
	warning_label = UIKit.title("", 30, Color(1, 0.46, 0.4))
	warning_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	warning_label.offset_left = -300
	warning_label.offset_right = 300
	warning_label.offset_top = 74
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	warning_label.modulate.a = 0.0
	_root.add_child(warning_label)

	# ---- boss bar
	boss_bar_container = VBoxContainer.new()
	boss_bar_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_bar_container.offset_left = -280
	boss_bar_container.offset_right = 280
	boss_bar_container.offset_top = 92
	boss_bar_container.add_theme_constant_override("separation", 2)
	boss_bar_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(boss_bar_container)

	boss_name_label = UIKit.title(Loc.s("BOSS"), 22, Color(1, 0.55, 0.55))
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_bar_container.add_child(boss_name_label)

	boss_bar = _make_bar("res://assets/ui/bar_back.png", "res://assets/ui/bar_boss.png")
	boss_bar.custom_minimum_size = Vector2(560, 20)
	boss_bar_container.add_child(boss_bar)


func _make_bar(back: String, fill: String) -> TextureProgressBar:
	var bar := TextureProgressBar.new()
	bar.texture_under = load(back)
	bar.texture_progress = load(fill)
	bar.nine_patch_stretch = true
	bar.stretch_margin_left = 12
	bar.stretch_margin_right = 12
	bar.stretch_margin_top = 6
	bar.stretch_margin_bottom = 6
	bar.max_value = 100
	bar.value = 100
	bar.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
	return bar


func _process(_delta: float) -> void:
	if GameManager.current_state == GameManager.State.PLAYING:
		timer_label.text = GameManager.get_run_time_formatted()
		kill_label.text = "%d" % GameManager.kill_count
		level_label.text = Loc.f("LV {n}", {"n": GameManager.current_level})
		if not boss_bar_container.visible:
			_refresh_health()
		_refresh_ring_countdown()


func _refresh_ring_countdown() -> void:
	if not ring_label:
		return
	if not is_instance_valid(_ring_node):
		_ring_node = get_tree().get_first_node_in_group("world")
		if _ring_node:
			_ring_node = _ring_node.get_node_or_null("RingEvent")
	if not is_instance_valid(_ring_node) or _ring_node.call("is_active"):
		ring_label.modulate.a = 0.0
		return
	var left: float = float(_ring_node.call("time_to_next"))
	ring_label.text = Loc.f("RING {t}", {"t": _clock(left)})
	# Blushes brighter as the wall gets close.
	ring_label.modulate.a = clampf(0.35 + (1.0 - left / 85.0) * 0.65, 0.35, 1.0)


func _clock(seconds: float) -> String:
	var total: int = int(maxf(ceilf(seconds), 0.0))
	return "%d:%02d" % [total / 60, total % 60]


func _refresh_health() -> void:
	var player: Node = GameManager.player
	if not player:
		return
	var hc: HealthComponent = player.get_node_or_null("HealthComponent")
	if not hc:
		return
	_update_health_display(hc.current_hp)


func _on_player_damaged(_amount: float, new_hp: float) -> void:
	_update_health_display(new_hp)
	var t := create_tween()
	health_bar.modulate = Color(1.6, 0.6, 0.6)
	t.tween_property(health_bar, "modulate", Color.WHITE, 0.3)


func _on_player_healed(_amount: float, new_hp: float) -> void:
	_update_health_display(new_hp)


func _update_health_display(current_hp: float) -> void:
	var player: Node = GameManager.player
	if not player:
		return
	var hc: HealthComponent = player.get_node_or_null("HealthComponent")
	if not hc:
		return
	health_bar.max_value = hc.max_hp
	health_bar.value = current_hp
	hp_label.text = "%d / %d" % [int(ceil(current_hp)), int(hc.max_hp)]


func _on_xp_changed(current: float, maximum: float) -> void:
	xp_bar.max_value = maximum
	xp_bar.value = current


func _on_level_up(new_level: int) -> void:
	level_label.text = Loc.f("LV {n}", {"n": new_level})
	var t := create_tween()
	t.tween_property(level_label, "scale", Vector2(1.4, 1.4), 0.12)
	t.tween_property(level_label, "scale", Vector2(1.0, 1.0), 0.24)


func _refresh_language() -> void:
	if level_label:
		level_label.text = Loc.f("LV {n}", {"n": GameManager.current_level})
	if ring_label:
		ring_label.text = Loc.f("RING {t}", {"t": "0:00"})


func show_warning(text: String, hold: float = 2.2) -> void:
	if not warning_label:
		return
	warning_label.text = Loc.s(text)
	warning_label.modulate.a = 1.0
	if _warning_tween and _warning_tween.is_valid():
		_warning_tween.kill()
	_warning_tween = create_tween()
	_warning_tween.tween_interval(hold)
	_warning_tween.tween_property(warning_label, "modulate:a", 0.0, 0.7)


func _on_ring_started() -> void:
	show_warning("THE RING CLOSES", 2.6)


func _on_ring_ended(escaped: bool) -> void:
	show_warning("The ring broke" if escaped else "No way out", 1.8)


func _on_boss_spawned(boss_name: String) -> void:
	boss_bar_container.visible = true
	boss_name_label.text = Loc.s(boss_name).to_upper()
	boss_bar.max_value = 100
	boss_bar.value = 100
	boss_bar_container.modulate.a = 0.0
	if _boss_tween and _boss_tween.is_valid():
		_boss_tween.kill()
	_boss_tween = create_tween()
	_boss_tween.tween_property(boss_bar_container, "modulate:a", 1.0, 0.4)


func _on_boss_killed(_boss_name: String) -> void:
	if _boss_tween and _boss_tween.is_valid():
		_boss_tween.kill()
	_boss_tween = create_tween()
	_boss_tween.tween_property(boss_bar_container, "modulate:a", 0.0, 0.4)
	_boss_tween.tween_callback(func(): boss_bar_container.visible = false)


func _on_boss_health_changed(_boss_name: String, current_hp: float, max_hp: float) -> void:
	boss_bar.max_value = max_hp
	boss_bar.value = current_hp