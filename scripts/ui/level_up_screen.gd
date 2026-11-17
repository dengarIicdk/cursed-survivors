extends CanvasLayer
class_name LevelUpScreen

## Pauses the run and offers three upgrade cards.

const UIKit := preload("res://scripts/ui/ui_kit.gd")
const Card := preload("res://scenes/ui/upgrade_card.tscn")

var _card_row: HBoxContainer
var _root: Control
var _current_choices: Array = []


func _ready() -> void:
	visible = false
	_build()
	EventBus.show_level_up_screen.connect(show_choices)


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.03, 0.01, 0.05, 0.82)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(shade)

	var centre := VBoxContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.add_theme_constant_override("separation", 14)
	_root.add_child(centre)

	var head := VBoxContainer.new()
	head.add_theme_constant_override("separation", -8)
	centre.add_child(head)

	var title := UIKit.title(Loc.s("LEVEL UP"), 66, Color(1, 0.82, 0.42))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(title)

	var sub := UIKit.label(Loc.s("CHOOSE YOUR CURSE"), 16, UIKit.MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(sub)

	_card_row = HBoxContainer.new()
	_card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_card_row.add_theme_constant_override("separation", 26)
	centre.add_child(_card_row)

	var hint := UIKit.label(Loc.s("press  1  ·  2  ·  3"), 14, Color(0.55, 0.48, 0.6))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centre.add_child(hint)


func show_choices(choices: Array) -> void:
	_current_choices = choices

	for child in _card_row.get_children():
		child.queue_free()

	for i in range(mini(choices.size(), 3)):
		var card: UpgradeCard = Card.instantiate()
		_card_row.add_child(card)
		card.setup(choices[i])
		card.card_key_number = i + 1
		card.card_selected.connect(_on_card_selected)
		card.modulate.a = 0.0
		var start_y := card.position.y + 26.0
		card.position.y = start_y
		var tween := card.create_tween()
		tween.set_parallel(true)
		tween.tween_property(card, "position:y", start_y - 26.0, 0.3) \
			.set_delay(i * 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(card, "modulate:a", 1.0, 0.25).set_delay(i * 0.07)

	visible = true


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("select_card_1") and _current_choices.size() >= 1:
		_on_card_selected(_current_choices[0])
	elif event.is_action_pressed("select_card_2") and _current_choices.size() >= 2:
		_on_card_selected(_current_choices[1])
	elif event.is_action_pressed("select_card_3") and _current_choices.size() >= 3:
		_on_card_selected(_current_choices[2])


func _on_card_selected(choice: Dictionary) -> void:
	_apply_choice(choice)
	visible = false
	GameManager.resume_game()


func _apply_choice(choice: Dictionary) -> void:
	var player: Node = GameManager.player
	if not player:
		return

	var choice_type: String = choice.get("type", "")
	var item_name: String = choice.get("name", "")

	match choice_type:
		"weapon_upgrade":
			var wm: WeaponManager = player.get_node_or_null("WeaponManager")
			if wm:
				wm.upgrade_weapon(item_name)
		"new_weapon":
			var wm: WeaponManager = player.get_node_or_null("WeaponManager")
			if wm:
				var scene: PackedScene = ItemDatabase.get_weapon_scene(item_name)
				if scene:
					wm.add_weapon(scene)
		"passive":
			var pm: PassiveManager = player.get_node_or_null("PassiveManager")
			if pm:
				var item_res: Resource = ItemDatabase.get_item(item_name)
				if item_res:
					pm.add_passive(item_res)

	EventBus.item_picked.emit(item_name)