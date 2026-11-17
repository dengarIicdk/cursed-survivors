extends Node2D
class_name World

## Main game world. Manages player, enemies, gems, and map loading.

@onready var enemy_spawner: EnemySpawner = $EnemySpawner
@onready var xp_gems_container: Node2D = $XPGems
@onready var hud: HUD = $HUD
@onready var level_up_screen: LevelUpScreen = $LevelUpScreen
@onready var game_over_screen: GameOverScreen = $GameOverScreen
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var decor: Node2D = $Decor
@onready var atmosphere: Node = $Atmosphere

const XP_GEM_POOL_SIZE: int = 200

var _xp_gem_scene: PackedScene = preload("res://scenes/world/xp_gem.tscn")
var _xp_gem_pool: Array[XPGem] = []
var player: Player = null

var _music_base: String = "graveyard"
var _music_intense: bool = false
var _boss_active: bool = false

var _map_configs: Dictionary = {
	"Cursed Graveyard": {
		"ambient_color": Color(0.92, 0.90, 1.0),
		"light_color": Color(0.60, 0.40, 0.95),
		"enemy_theme": ["shambling_corpse", "bat_swarm", "ghost", "necromancer"],
	},
	"Infernal Depths": {
		"ambient_color": Color(0.74, 0.86, 1.0),
		"light_color": Color(0.32, 0.72, 1.0),
		"enemy_theme": ["exploding_imp", "armored_knight", "shadow_drake", "necromancer"],
		"theme": "depths",
		# frozen cavern palette for the procedural ground shader
		"ground": {
			"c_dirt": Color(0.10, 0.13, 0.21),
			"c_moss": Color(0.13, 0.22, 0.30),
			"c_moss_lt": Color(0.22, 0.40, 0.52),
			"c_stone": Color(0.30, 0.40, 0.52),
			"c_stone_dk": Color(0.08, 0.11, 0.18),
			"c_blood": Color(0.20, 0.10, 0.28),
			"c_bone": Color(0.56, 0.66, 0.74),
			"c_ember": Color(0.95, 0.55, 0.25),
			"c_grass": Color(0.18, 0.34, 0.40),
		},
	},
}


func _ready() -> void:
	add_to_group("world")
	_prewarm_gem_pool()
	_load_player()
	_apply_map_config()
	_start_music()
	
	var boss_timer := Timer.new()
	boss_timer.wait_time = 600.0  # 10 minutes
	boss_timer.one_shot = true
	boss_timer.timeout.connect(_spawn_final_boss)
	add_child(boss_timer)
	boss_timer.start()


func _start_music() -> void:
	_music_base = "depths" if GameManager.selected_map == "Infernal Depths" else "graveyard"
	AudioManager.crossfade_music(_music_base + "_calm", 3.0)
	EventBus.boss_spawned.connect(_on_boss_spawned_for_music)
	EventBus.boss_killed.connect(_on_boss_killed_for_music)

	var intensity_timer := Timer.new()
	intensity_timer.wait_time = 2.5
	intensity_timer.timeout.connect(_update_music_intensity)
	add_child(intensity_timer)
	intensity_timer.start()


func _on_boss_spawned_for_music(_boss_name: String) -> void:
	_boss_active = true
	AudioManager.crossfade_music("boss", 2.0)


func _on_boss_killed_for_music(_boss_name: String) -> void:
	_boss_active = false
	_music_intense = true
	AudioManager.crossfade_music(_music_base + "_intense", 3.0)


func _update_music_intensity() -> void:
	if _boss_active:
		return
	var crowd: int = get_tree().get_nodes_in_group("enemies").size()
	var wanted: bool = crowd >= 20 or GameManager.run_time > 240.0
	if wanted == _music_intense:
		return
	_music_intense = wanted
	AudioManager.crossfade_music(_music_base + ("_intense" if wanted else "_calm"), 2.5)


func _prewarm_gem_pool() -> void:
	for _i in range(XP_GEM_POOL_SIZE):
		var gem: XPGem = _xp_gem_scene.instantiate()
		xp_gems_container.add_child(gem)
		gem.deactivate()
		_xp_gem_pool.append(gem)


func _load_player() -> void:
	var class_name_id: String = GameManager.selected_class
	var player_scene_path: String = "res://scenes/player/player.tscn"
	
	match class_name_id:
		"Hexblade": player_scene_path = "res://scenes/player/hexblade.tscn"
		"Ironclad": player_scene_path = "res://scenes/player/ironclad.tscn"
		"Wraithborn": player_scene_path = "res://scenes/player/wraithborn.tscn"
		"Stormcaller": player_scene_path = "res://scenes/player/stormcaller.tscn"
	
	var player_scene: PackedScene = load(player_scene_path)
	if not player_scene:
		player_scene = preload("res://scenes/player/player.tscn")
	
	player = player_scene.instantiate()
	add_child(player)
	player.global_position = Vector2(640, 360)
	enemy_spawner.set_player(player)
	GameManager.player = player
	GameManager.world = self


func _apply_map_config() -> void:
	var map_name: String = GameManager.selected_map
	var config: Dictionary = _map_configs.get(map_name, _map_configs["Cursed Graveyard"])

	var modulate_node := CanvasModulate.new()
	modulate_node.color = config["ambient_color"]
	add_child(modulate_node)

	atmosphere.set_map(map_name)
	decor.setup(config["light_color"], config.get("theme", "graveyard"))

	var ground_config: Dictionary = config.get("ground", {})
	if not ground_config.is_empty():
		var ground := get_node_or_null("Ground")
		if ground and ground.material is ShaderMaterial:
			var mat: ShaderMaterial = ground.material
			for key in ground_config.keys():
				mat.set_shader_parameter(key, ground_config[key])
	EventBus.player_damaged.connect(_on_player_damaged)


func _on_player_damaged(_amount: float, new_hp: float) -> void:
	atmosphere.damage_flash(0.9)
	var p: Node = GameManager.player
	if p and is_instance_valid(p):
		var hc = p.get_node_or_null("HealthComponent")
		if hc:
			atmosphere.low_health(new_hp < hc.max_hp * 0.3)


func spawn_xp_gem(pos: Vector2, value: int) -> void:
	var gem: XPGem = _get_gem_from_pool()
	if gem:
		gem.activate(value, pos)


func _get_gem_from_pool() -> XPGem:
	for gem in _xp_gem_pool:
		if not gem.is_active:
			return gem
	return null


func spawn_enemy_at(type: String, pos: Vector2) -> Node:
	return enemy_spawner.spawn_enemy_at(type, pos)


func spawn_rare_drop(pos: Vector2) -> void:
	spawn_xp_gem(pos, 25)


func _spawn_final_boss() -> void:
	var boss := preload("res://scenes/enemies/lich_king.tscn").instantiate()
	var spawn_pos: Vector2 = Vector2.ZERO
	if player:
		spawn_pos = player.global_position + Vector2(500, 0)
	boss.global_position = spawn_pos
	add_child(boss)
	boss.setup(player, false)
	EventBus.boss_spawned.emit("Lich King")
