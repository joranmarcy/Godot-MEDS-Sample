extends ProgressBar

@export var variable: NumericVariable

var _default_min_value: float
var _default_max_value: float
var _default_step: float

func _ready() -> void:
	_default_min_value = min_value
	_default_max_value = max_value
	_default_step = step
	if variable == null:
		return

	_sync_progress_range()
	_sync_progress_step()
	value = float(variable._get_value_variant())
 
	if variable.has_signal("value_changed"):
		variable.connect("value_changed", Callable(self, "_on_variable_value_changed"))
	if variable.has_signal("range_changed"):
		variable.connect("range_changed", Callable(self, "_on_variable_range_changed"))

func _on_variable_value_changed(new_value: Variant) -> void:
	value = float(new_value)

func _on_variable_range_changed(clamp_enabled: bool, new_min_value: Variant, new_max_value: Variant) -> void:
	_sync_progress_range(clamp_enabled, new_min_value, new_max_value)

func _sync_progress_range(clamp_enabled: Variant = null, new_min_value: Variant = null, new_max_value: Variant = null) -> void:
	if variable == null:
		return

	var should_clamp := variable.clamp_value if clamp_enabled == null else bool(clamp_enabled)
	var range_min := float(variable.get("min_value")) if new_min_value == null else float(new_min_value)
	var range_max := float(variable.get("max_value")) if new_max_value == null else float(new_max_value)

	if should_clamp:
		min_value = range_min
		max_value = range_max
	else:
		min_value = _default_min_value
		max_value = _default_max_value

func _sync_progress_step() -> void:
	if variable is IntVariable:
		step = 1.0
		return
	step = _default_step