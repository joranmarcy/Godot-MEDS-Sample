extends Node

@export var item: ItemData

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("The item name: " + item.item_name)
