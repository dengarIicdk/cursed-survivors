extends Node
class_name BaseWeapon

## Base class for all weapons. Handles upgrade/evolve logic and damage scaling.

signal weapon_upgraded_signal(weapon_name: String, new_level: int)

@export var weapon_name: String = "Base Weapon"
@export var weapon_level: int = 1
@export var max_level: int = 5
@export var base_damage: float = 10.0
@export var attack_speed: float = 1.0
@export var required_passive: String = ""

var is_evolved: bool = false
var attack_speed_bonus: float = 0.0

var upgrade_descriptions: Array[String] = [
	"Level 1: Base weapon",
	"Level 2: Upgrade",
	"Level 3: Upgrade",
	"Level 4: Upgrade",
	"Level 5: Max level — ready to evolve!",
]

var _player: Node = null
var _attack_timer: float = 0.0


func _ready() -> void:
	if get_parent() and get_parent().get_parent():
		_player = get_parent().get_parent()


func set_player(p: Node) -> void:
	_player = p


func _process(delta: float) -> void:
	if not _player:
		return
	_weapon_process(delta)


func _weapon_process(_delta: float) -> void:
	pass


func get_attack_interval() -> float:
	var base_interval: float = 1.0 / maxf(attack_speed, 0.1)
	var multiplier: float = 1.0
	if _player and _player.has_method("get_node"):
		var wm: Node = _player.get_node_or_null("WeaponManager")
		if wm and wm.has_method("get_cooldown_multiplier"):
			multiplier = wm.get_cooldown_multiplier()
	multiplier *= (1.0 / maxf(1.0 + attack_speed_bonus, 0.1))
	return base_interval * multiplier


func get_damage() -> float:
	var multiplier: float = 1.0
	if _player and _player.has_method("get_damage_multiplier"):
		multiplier = _player.get_damage_multiplier()
	return base_damage * multiplier


func upgrade() -> void:
	if weapon_level >= max_level:
		return
	weapon_level += 1
	_on_upgrade()
	EventBus.weapon_upgraded.emit(weapon_name, weapon_level)


func evolve(_passive_name: String) -> void:
	if is_evolved:
		return
	is_evolved = true
	_on_evolve()
	EventBus.weapon_evolved.emit(weapon_name, weapon_name + " (Evolved)")


func _on_upgrade() -> void:
	pass


func _on_evolve() -> void:
	pass


func get_upgrade_description() -> String:
	var idx: int = clampi(weapon_level - 1, 0, upgrade_descriptions.size() - 1)
	return upgrade_descriptions[idx]


func get_enemies_in_radius(center: Vector2, radius: float) -> Array:
	var enemies: Array = []
	var space_state := get_viewport().find_world_2d().direct_space_state
	var params := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	params.shape = circle
	params.transform = Transform2D(0.0, center)
	params.collision_mask = 4
	var results := space_state.intersect_shape(params, 64)
	for r in results:
		if r.collider and r.collider.has_method("take_damage"):
			enemies.append(r.collider)
	return enemies


func find_nearest_enemy(from_pos: Vector2, max_range: float = 9999.0) -> Node:
	var nearest: Node = null
	var nearest_dist: float = max_range * max_range
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if not is_instance_valid(e) or not e.is_active:
			continue
		var d: float = from_pos.distance_squared_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	return nearest
