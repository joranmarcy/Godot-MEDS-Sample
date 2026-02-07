extends Node

@export var bool_variable: BoolVariable
@export var target_node: Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	target_node.visible = bool_variable.value
	bool_variable.value_changed.connect(_on_bool_variable_changed)

func _on_bool_variable_changed(new_value: bool) -> void:
	target_node.visible = new_value
