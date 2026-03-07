@icon("res://addons/godot_meds_core/icons/StringVariable.png")
extends BaseVariable
class_name StringVariable

@warning_ignore("unused_signal")
signal value_changed(new_value: String)

## The starting value for this variable. This is the value that will be used if there is no saved value to load from a previous session.
@export var initial_value: String = "":
	set(new_val):
		initial_value = new_val
		_apply_initial_value(new_val)

func set_value(new_val: String, caller: Object = null) -> void:
	_set_value_variant(new_val, caller)

var value: String:
	get:
		return _get_value_variant()
	set(new_val):
		_set_value_variant(new_val, null)

