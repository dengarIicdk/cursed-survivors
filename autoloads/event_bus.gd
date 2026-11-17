extends Node

## Central event bus for decoupled communication between all game systems.
## All game-wide signals are defined here.

# Enemy signals
signal enemy_killed(enemy: Node, position: Vector2)
signal elite_enemy_killed(enemy: Node, position: Vector2)
signal boss_spawned(boss_name: String)
signal boss_killed(boss_name: String)

# Player signals
signal player_damaged(amount: float, new_hp: float)
signal player_healed(amount: float, new_hp: float)
signal player_died()
signal player_revived()
signal player_blinked(from_pos: Vector2, to_pos: Vector2)

# XP and level signals
signal xp_collected(amount: int)
signal level_up(new_level: int)
signal xp_changed(current: float, maximum: float)

# Weapon signals
signal weapon_upgraded(weapon_name: String, new_level: int)
signal weapon_evolved(weapon_name: String, evolved_name: String)
signal weapon_fired(weapon_name: String)

# Item signals
signal item_picked(item_name: String)
signal passive_applied(item_name: String)

# Game state signals
signal game_paused()
signal game_resumed()
signal run_started(c_name: String, map_name: String)
signal run_ended(stats: Dictionary)
signal soul_coins_earned(amount: int)
signal soul_coins_changed(total: int)

# UI signals
signal show_level_up_screen(choices: Array)
signal boss_health_changed(boss_name: String, current_hp: float, max_hp: float)
signal boss_phase_changed(boss_name: String, new_phase: int)
signal surge_triggered()
## The closing ring of elites: started, then ended with escaped = true when the
## hero broke out (or killed a gap) and false when the wall landed on him.
signal ring_event_started()
signal ring_event_ended(escaped: bool)
signal last_stand_activated()
