@icon("res://icons/Vector2Variable.svg")
extends BaseVariable
class_name Vector2Variable

signal value_changed(new_value: Vector2)

@export var initial_value: Vector2 = Vector2.ZERO:
	set(new_val):
		initial_value = new_val
		_apply_initial_value(new_val)

func set_value(new_val: Vector2, caller: Object = null) -> void:
	_set_value_variant(new_val, caller)

var value: Vector2:
	get:
		var v: Variant = _get_value_variant()
		return v if v is Vector2 else Vector2.ZERO
	set(new_val):
		_set_value_variant(new_val, null)

