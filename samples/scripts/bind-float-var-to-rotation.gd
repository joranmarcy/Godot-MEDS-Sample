extends Node

@export var float_variable: FloatVariable
@export var target_node: Node3D

func _ready():
	target_node.rotation_degrees.y = float_variable.value
	float_variable.value_changed.connect(_on_float_variable_changed)

func _on_float_variable_changed(new_value: float) -> void:
	target_node.rotation_degrees.y = new_value
