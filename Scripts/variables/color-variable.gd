@icon("res://icons/ColorVariable.svg")
extends BaseVariable
class_name ColorVariable

signal value_changed(new_value: Color)

@export var initial_value: Color = Color.WHITE:
	set(new_val):
		initial_value = new_val
		_apply_initial_value(new_val)

func set_value(new_val: Color, caller: Object = null) -> void:
	_set_value_variant(new_val, caller)

var value: Color:
	get:
		var v: Variant = _get_value_variant()
		return v if v is Color else Color.WHITE
	set(new_val):
		_set_value_variant(new_val, null)

