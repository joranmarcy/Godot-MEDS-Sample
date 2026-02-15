@icon("res://icons/IntVariable.svg")
extends BaseVariable
class_name IntVariable

signal value_changed(new_value: int)

@export var initial_value: int = 0:
	set(new_val):
		initial_value = new_val
		_apply_initial_value(new_val)

func set_value(new_val: int, caller: Object = null) -> void:
	_set_value_variant(new_val, caller)

var value: int:
	get:
		return int(_get_value_variant())
	set(new_val):
		_set_value_variant(new_val, null)

