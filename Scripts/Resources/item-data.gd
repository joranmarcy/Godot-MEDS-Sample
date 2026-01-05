# item_data.gd
extends Resource
class_name ItemData

@export var item_name: String = "New Item"
@export var icon: Texture2D
@export var power_level: int = 10

func use_item():
	print("Used " + item_name)
	
