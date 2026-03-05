@icon("res://addons/godot_meds_core/icons/ColorVariable.svg")
extends BaseVariable
class_name ColorVariable

@warning_ignore("unused_signal")
signal value_changed(new_value: Color)

@export var initial_value: Color = Color.WHITE:
	set(new_val):
		initial_value = new_val
		_apply_initial_value(new_val)

func set_value(new_val: Color, caller: Object = null) -> void:
	_set_value_variant(new_val, caller)

var value: Color:
	get:
		return _get_value_variant()
	set(new_val):
		_set_value_variant(new_val, null)

