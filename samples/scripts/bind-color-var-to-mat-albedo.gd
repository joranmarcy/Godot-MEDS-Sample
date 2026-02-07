extends Node

@export var color_variable: ColorVariable
@export var material: StandardMaterial3D

func _ready():
	material.albedo_color = color_variable.value
	color_variable.value_changed.connect(_on_color_variable_changed)

func _on_color_variable_changed(new_color: Color) -> void:
	material.albedo_color = new_color
	
