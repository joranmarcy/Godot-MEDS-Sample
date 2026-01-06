extends Node

@export var bool_variable: BoolVariable

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bool_variable.value_changed.connect(_on_bool_value_changed)
	print("The bool variable value: " + str(bool_variable.value))
	bool_variable.value = false
	# Change the value after a delay
	await get_tree().create_timer(2.0).timeout
	bool_variable.value = true
	

func _on_bool_value_changed(new_value: bool):
	print("Bool changed to: ", new_value)
