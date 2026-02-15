@icon("res://icons/StringVariable.svg")
extends BaseVariable
class_name StringVariable

signal value_changed(new_value: String)

@export var initial_value: String = "":
	set(new_val):
		initial_value = new_val
		_apply_initial_value(new_val)

func set_value(new_val: String, caller: Object = null) -> void:
	_set_value_variant(new_val, caller)

var value: String:
	get:
		return str(_get_value_variant())
	set(new_val):
		_set_value_variant(new_val, null)

