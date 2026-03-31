@icon("res://addons/godot_meds_core/icons/FloatVariable.png")
extends ClampedNumericVariable
class_name FloatVariable

@warning_ignore("unused_signal")
signal value_changed(new_value: float)
@warning_ignore("unused_signal")
signal range_changed(clamp_enabled: bool, min_value: float, max_value: float)

@export var min_value: float = 0.0:
	set(new_val):
		min_value = new_val
		_sync_clamped_values()
		_emit_range_changed()

@export var max_value: float = 1.0:
	set(new_val):
		max_value = new_val
		_sync_clamped_values()
		_emit_range_changed()

## The starting value for this variable. This is the value that will be used if there is no saved value to load from a previous session.
@export var initial_value: float = 0.0:
	set(new_val):
		var sanitized_value := _sanitize_value(new_val)
		initial_value = sanitized_value
		_apply_initial_value(sanitized_value)

func set_value(new_val: float, caller: Object = null) -> void:
	_set_value_variant(new_val, caller)

var value: float:
	get:
		return _get_value_variant()
	set(new_val):
		_set_value_variant(new_val, null)

func _sanitize_value(new_val: Variant) -> float:
	var float_value := float(new_val)
	if not clamp_value:
		return float_value

	var range_values := _get_sorted_range_values()
	return clampf(float_value, float(range_values[0]), float(range_values[1]))

