extends Resource
class_name BasePassiveItem

## Base class for all passive items.

@export var item_name: String = "Item"
@export var description: String = "A passive item."
@export var icon_path: String = ""
@export var stack_count: int = 1
@export var max_stacks: int = 1


func apply(_player: Node) -> void:
	pass


func remove(_player: Node) -> void:
	pass


func on_level_up(_player: Node) -> void:
	pass
