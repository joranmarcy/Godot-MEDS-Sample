@icon("res://addons/godot_meds_core/icons/IntVariable.png")
extends NumericVariable
class_name IntVariable

@warning_ignore("unused_signal")
signal value_changed(new_value: int)
@warning_ignore("unused_signal")
signal range_changed(clamp_enabled: bool, min_value: int, max_value: int)

@export var min_value: int = 0:
	set(new_val):
		min_value = new_val
		_sync_clamped_values()
		_emit_range_changed()

@export var max_value: int = 1:
	set(new_val):
		max_value = new_val
		_sync_clamped_values()
		_emit_range_changed()

## The starting value for this variable. This is the value that will be used if there is no saved value to load from a previous session.
@export var initial_value: int = 0:
	set(new_val):
		var sanitized_value := _sanitize_value(new_val)
		initial_value = sanitized_value
		_apply_initial_value(sanitized_value)

func set_value(new_val: int, caller: Object = null) -> void:
	_set_value_variant(new_val, caller)

var value: int:
	get:
		return _get_value_variant()
	set(new_val):
		_set_value_variant(new_val, null)

func _sanitize_value(new_val: Variant) -> int:
	var int_value := int(new_val)
	if not clamp_value:
		return int_value

	var range_values := _get_sorted_range_values()
	return clampi(int_value, int(range_values[0]), int(range_values[1]))

