@icon("res://addons/godot_flow_core/icons/FloatVariable.svg")
extends BaseVariable
class_name FloatVariable

@warning_ignore("unused_signal")
signal value_changed(new_value: float)

@export var initial_value: float = 0.0:
	set(new_val):
		initial_value = new_val
		_apply_initial_value(new_val)

func set_value(new_val: float, caller: Object = null) -> void:
	_set_value_variant(new_val, caller)

var value: float:
	get:
		return _get_value_variant()
	set(new_val):
		_set_value_variant(new_val, null)

