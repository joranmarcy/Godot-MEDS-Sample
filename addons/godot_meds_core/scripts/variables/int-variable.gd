@icon("res://addons/godot_meds_core/icons/IntVariable.png")
extends BaseVariable
class_name IntVariable

@warning_ignore("unused_signal")
signal value_changed(new_value: int)
@warning_ignore("unused_signal")
signal range_changed(clamp_enabled: bool, min_value: int, max_value: int)

@export var clamp_value: bool = false:
	set(new_val):
		clamp_value = new_val
		_sync_clamped_values()
		_emit_range_changed()

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

func _apply_initial_value(new_val: Variant) -> void:
	super._apply_initial_value(_sanitize_value(new_val))

func _set_value_variant(new_val: Variant, caller: Object = null) -> void:
	super._set_value_variant(_sanitize_value(new_val), caller)

func _sanitize_value(new_val: Variant) -> int:
	var int_value := int(new_val)
	if not clamp_value:
		return int_value

	var clamped_min := min_value
	var clamped_max := max_value
	if clamped_min > clamped_max:
		var temp := clamped_min
		clamped_min = clamped_max
		clamped_max = temp

	return clampi(int_value, clamped_min, clamped_max)

func _sync_clamped_values() -> void:
	initial_value = _sanitize_value(initial_value)
	_apply_initial_value(initial_value)
	if _value != null:
		_set_value_variant(_value, null)

func _emit_range_changed() -> void:
	var range_min := min_value
	var range_max := max_value
	if range_min > range_max:
		var temp := range_min
		range_min = range_max
		range_max = temp

	emit_signal("range_changed", clamp_value, range_min, range_max)

