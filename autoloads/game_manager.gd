extends Node

## Global game state manager. Singleton accessible as GameManager from any script.

enum State {
	MENU,
	PLAYING,
	PAUSED,
	LEVEL_UP,
	GAME_OVER,
	WIN
}

# Current state
var current_state: int = State.MENU

# Run data
var run_time: float = 0.0
var kill_count: int = 0
var current_level: int = 1
var xp_current: float = 0.0
var xp_to_next: float = 10.0

# Class and map selection
var selected_class: String = "Hexblade"
var selected_map: String = "Cursed Graveyard"

# Soul coins earned this run
var soul_coins_this_run: int = 0

# Reference to current player node
var player: Node = null

# World reference
var world: Node = null


func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.xp_collected.connect(_on_xp_collected)
	EventBus.player_died.connect(_on_player_died)


func _process(delta: float) -> void:
	if current_state == State.PLAYING:
		run_time += delta
		_check_level_up()


func start_run(c_name: String, map_name: String) -> void:
	selected_class = c_name
	selected_map = map_name
	run_time = 0.0
	kill_count = 0
	current_level = 1
	xp_current = 0.0
	xp_to_next = _calc_xp_to_next(1)
	soul_coins_this_run = 0
	current_state = State.PLAYING
	EventBus.run_started.emit(c_name, map_name)


func end_run(won: bool) -> void:
	current_state = State.WIN if won else State.GAME_OVER
	var coins_earned: int = _calculate_soul_coins()
	soul_coins_this_run = coins_earned
	SaveManager.add_soul_coins(coins_earned)
	SaveManager.save()
	var stats: Dictionary = {
		"time": run_time,
		"kills": kill_count,
		"level": current_level,
		"soul_coins": coins_earned,
		"won": won
	}
	EventBus.run_ended.emit(stats)
	EventBus.soul_coins_earned.emit(coins_earned)


func pause_game() -> void:
	if current_state == State.PLAYING:
		current_state = State.PAUSED
		get_tree().paused = true
		EventBus.game_paused.emit()


func resume_game() -> void:
	if current_state == State.PAUSED or current_state == State.LEVEL_UP:
		current_state = State.PLAYING
		get_tree().paused = false
		EventBus.game_resumed.emit()


func enter_level_up_state() -> void:
	current_state = State.LEVEL_UP
	get_tree().paused = true


func _check_level_up() -> void:
	if xp_current >= xp_to_next:
		xp_current -= xp_to_next
		current_level += 1
		xp_to_next = _calc_xp_to_next(current_level)
		EventBus.level_up.emit(current_level)
		if player and player.has_method("get_upgrade_choices"):
			var choices: Array = player.get_upgrade_choices()
			enter_level_up_state()
			EventBus.show_level_up_screen.emit(choices)


func _calc_xp_to_next(level: int) -> float:
	return 10.0 * pow(1.45, level - 1)


func _calculate_soul_coins() -> int:
	var time_bonus: float = run_time * 0.5
	var kill_bonus: float = kill_count * 0.1
	return int(time_bonus + kill_bonus)


func _on_enemy_killed(_enemy: Node, _position: Vector2) -> void:
	kill_count += 1


func _on_xp_collected(amount: int) -> void:
	xp_current += float(amount)
	EventBus.xp_changed.emit(xp_current, xp_to_next)


func _on_player_died() -> void:
	end_run(false)


func get_run_time_formatted() -> String:
	var minutes: int = int(run_time) / 60
	var seconds: int = int(run_time) % 60
	return "%02d:%02d" % [minutes, seconds]
