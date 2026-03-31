extends BaseVariable
class_name NumericVariable

@export var clamp_value: bool = false:
	set(new_val):
		clamp_value = new_val
		_sync_clamped_values()
		_emit_range_changed()

func _apply_initial_value(new_val: Variant) -> void:
	super._apply_initial_value(_sanitize_value(new_val))

func _set_value_variant(new_val: Variant, caller: Object = null) -> void:
	super._set_value_variant(_sanitize_value(new_val), caller)

func _sanitize_value(new_val: Variant) -> Variant:
	return new_val

func _sync_clamped_values() -> void:
	if _has_property_named("initial_value"):
		set("initial_value", _sanitize_value(get("initial_value")))
	if _value != null:
		_set_value_variant(_value, null)

func _emit_range_changed() -> void:
	if not has_signal("range_changed"):
		return

	var range_values := _get_sorted_range_values()
	emit_signal("range_changed", clamp_value, range_values[0], range_values[1])

func _get_sorted_range_values() -> Array:
	var range_min = get("min_value")
	var range_max = get("max_value")
	if range_min > range_max:
		var temp = range_min
		range_min = range_max
		range_max = temp

	return [range_min, range_max]