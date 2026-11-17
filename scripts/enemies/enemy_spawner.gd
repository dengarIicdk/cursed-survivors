extends Node2D
class_name EnemySpawner

## Manages enemy waves and object pooling.

const SPAWN_RADIUS: float = 450.0
const MAX_ACTIVE_ENEMIES: int = 500

var spawn_rate: float = 1.5
var _spawn_timer: float = 0.0
var _miniboss_timer: float = 0.0
var _horde_timer: float = 0.0

var active_enemies: Array[Node] = []
var _enemy_pools: Dictionary = {}

var _enemy_scenes: Dictionary = {
	"shambling_corpse": preload("res://scenes/enemies/shambling_corpse.tscn"),
	"bat_swarm": preload("res://scenes/enemies/bat_swarm.tscn"),
	"armored_knight": preload("res://scenes/enemies/armored_knight.tscn"),
	"ghost": preload("res://scenes/enemies/ghost.tscn"),
	"exploding_imp": preload("res://scenes/enemies/exploding_imp.tscn"),
	"necromancer": preload("res://scenes/enemies/necromancer.tscn"),
	"shadow_drake": preload("res://scenes/enemies/shadow_drake.tscn"),
}

var _player: Node = null


func _ready() -> void:
	add_to_group("enemy_spawner")
	EventBus.enemy_killed.connect(_on_enemy_killed)
	for type in _enemy_scenes:
		_enemy_pools[type] = []


func set_player(player: Node) -> void:
	_player = player


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return
	
	_update_wave_parameters()
	
	_spawn_timer += delta
	var interval: float = 1.0 / maxf(spawn_rate, 0.1)
	if _spawn_timer >= interval:
		_spawn_timer = 0.0
		if active_enemies.size() < MAX_ACTIVE_ENEMIES:
			_spawn_enemy()
	
	var t: float = GameManager.run_time
	if t >= 150.0:
		_miniboss_timer += delta
		if _miniboss_timer >= 120.0:
			_miniboss_timer = 0.0
			_spawn_miniboss()

	if t >= 75.0:
		_horde_timer += delta
		if _horde_timer >= 70.0:
			_horde_timer = 0.0
			_spawn_horde()


func _update_wave_parameters() -> void:
	var t: float = GameManager.run_time
	if t < 60.0:
		spawn_rate = lerpf(0.8, 2.0, t / 60.0)
	elif t < 180.0:
		spawn_rate = lerpf(2.0, 4.0, (t - 60.0) / 120.0)
	elif t < 360.0:
		spawn_rate = lerpf(4.0, 6.5, (t - 180.0) / 180.0)
	elif t < 600.0:
		spawn_rate = lerpf(6.5, 9.0, (t - 360.0) / 240.0)
	else:
		spawn_rate = 11.0


func _get_spawn_pool() -> Array[String]:
	var t: float = GameManager.run_time
	var pool: Array[String] = ["shambling_corpse", "bat_swarm"]
	if t >= 60.0:
		pool.append("bat_swarm")
	if t >= 120.0:
		pool.append("armored_knight")
		pool.append("ghost")
	if t >= 180.0:
		pool.append("exploding_imp")
	if t >= 240.0:
		pool.append("necromancer")
	if t >= 360.0:
		pool.append("shadow_drake")
	return pool


func _get_elite_chance() -> float:
	var t: float = GameManager.run_time
	return clampf(0.03 + t / 600.0 * 0.25, 0.0, 0.28)


## A closing ring of wretches: the player cannot simply stand and channel.
func _spawn_horde() -> void:
	if not _player:
		return
	var count: int = clampi(8 + int(GameManager.run_time / 60.0) * 2, 8, 22)
	var pool := _get_spawn_pool()
	var ring_radius: float = SPAWN_RADIUS * 0.9
	var start_angle: float = randf() * TAU
	for i in range(count):
		var angle: float = start_angle + TAU * float(i) / float(count)
		var pos: Vector2 = _player.global_position + Vector2.from_angle(angle) * ring_radius
		var type: String = pool[randi() % pool.size()]
		_spawn_enemy_of_type(type, pos, randf() < 0.15)
	AudioManager.play_sfx("boss_spawn", 0.35, 1.6)


func _spawn_enemy() -> void:
	if not _player:
		return
	var pool := _get_spawn_pool()
	var type: String = pool[randi() % pool.size()]
	var is_elite: bool = randf() < _get_elite_chance()
	var pos: Vector2 = _get_spawn_position()
	_spawn_enemy_of_type(type, pos, is_elite)


func _get_spawn_position() -> Vector2:
	if not _player:
		return Vector2.ZERO
	var angle: float = randf() * TAU
	return _player.global_position + Vector2(cos(angle), sin(angle)) * SPAWN_RADIUS


func _spawn_enemy_of_type(type: String, pos: Vector2, elite: bool = false) -> Node:
	var enemy := _get_from_pool(type)
	if not enemy:
		if not _enemy_scenes.has(type):
			return null
		enemy = _enemy_scenes[type].instantiate()
		get_tree().root.add_child(enemy)
	
	enemy.global_position = pos
	enemy.setup(_player, elite)
	active_enemies.append(enemy)
	enemy.add_to_group("enemies")
	return enemy


func spawn_enemy_at(type: String, pos: Vector2) -> Node:
	return _spawn_enemy_of_type(type, pos, false)


func _get_from_pool(type: String) -> Node:
	if not _enemy_pools.has(type):
		return null
	var pool: Array = _enemy_pools[type]
	for i in range(pool.size()):
		var e = pool[i]
		if is_instance_valid(e) and not e.is_active:
			pool.remove_at(i)
			return e
	return null


func _return_to_pool(enemy: Node) -> void:
	var type: String = ""
	if enemy is ShamblingCorpse: type = "shambling_corpse"
	elif enemy is BatSwarm: type = "bat_swarm"
	elif enemy is ArmoredKnight: type = "armored_knight"
	elif enemy is Ghost: type = "ghost"
	elif enemy is ExplodingImp: type = "exploding_imp"
	elif enemy is Necromancer: type = "necromancer"
	elif enemy is ShadowDrake: type = "shadow_drake"
	else: type = "unknown"
	
	if type != "unknown" and _enemy_pools.has(type):
		_enemy_pools[type].append(enemy)


func _spawn_miniboss() -> void:
	var pos: Vector2 = _get_spawn_position()
	var boss := preload("res://scenes/enemies/giant_troll.tscn").instantiate()
	boss.global_position = pos
	get_tree().root.add_child(boss)
	boss.setup(_player, false)
	EventBus.boss_spawned.emit("Giant Troll")


## Used by the closing ring when it dissolves its own members.
func forget_enemy(enemy: Node) -> void:
	active_enemies.erase(enemy)


func _on_enemy_killed(enemy: Node, _position: Vector2) -> void:
	active_enemies.erase(enemy)
	if enemy.is_pooled:
		_return_to_pool(enemy)
