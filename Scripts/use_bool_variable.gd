extends Node

@export var bool_variable: BoolVariable

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("The bool variable value: " + str(bool_variable.value))
	bool_variable.value = !bool_variable.value
