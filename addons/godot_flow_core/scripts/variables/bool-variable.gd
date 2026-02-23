@icon("res://icons/BoolVariable.svg")
extends BaseVariable
class_name BoolVariable

@warning_ignore("unused_signal")
signal value_changed(new_value: bool)

@export var initial_value: bool = false:
	set(new_val):
		initial_value = new_val
		_apply_initial_value(new_val)

func set_value(new_val: bool, caller: Object = null) -> void:
	_set_value_variant(new_val, caller)

var value: bool:
	get:
		return _get_value_variant()
	set(new_val):
		_set_value_variant(new_val, null)

