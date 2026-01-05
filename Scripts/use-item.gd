extends Node

@export var item: ItemData

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("The item name: " + item.item_name)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
