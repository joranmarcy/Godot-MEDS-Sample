@icon("res://addons/godot_meds_core/icons/FloatVariable.png")
extends BaseVariable
class_name FloatVariable

@warning_ignore("unused_signal")
signal value_changed(new_value: float)

@export var clamp_value: bool = false:
	set(new_val):
		clamp_value = new_val
		_sync_clamped_values()

@export var min_value: float = 0.0:
	set(new_val):
		min_value = new_val
		_sync_clamped_values()

@export var max_value: float = 1.0:
	set(new_val):
		max_value = new_val
		_sync_clamped_values()

## The starting value for this variable. This is the value that will be used if there is no saved value to load from a previous session.
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

func _apply_initial_value(new_val: Variant) -> void:
	super._apply_initial_value(_sanitize_value(new_val))

func _set_value_variant(new_val: Variant, caller: Object = null) -> void:
	super._set_value_variant(_sanitize_value(new_val), caller)

func _sanitize_value(new_val: Variant) -> float:
	var float_value := float(new_val)
	if not clamp_value:
		return float_value

	var clamped_min := min_value
	var clamped_max := max_value
	if clamped_min > clamped_max:
		var temp := clamped_min
		clamped_min = clamped_max
		clamped_max = temp

	return clampf(float_value, clamped_min, clamped_max)

func _sync_clamped_values() -> void:
	initial_value = _sanitize_value(initial_value)
	_apply_initial_value(initial_value)
	if _value != null:
		_set_value_variant(_value, null)

