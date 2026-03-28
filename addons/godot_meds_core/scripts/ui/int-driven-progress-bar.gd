extends ProgressBar

@export var int_variable: IntVariable

var _default_min_value: float
var _default_max_value: float

func _ready() -> void:
	_default_min_value = min_value
	_default_max_value = max_value
	step = 1.0
	_sync_progress_range()
	value = int_variable.value
	int_variable.value_changed.connect(_on_variable_value_changed)
	int_variable.range_changed.connect(_on_variable_range_changed)

func _on_variable_value_changed(new_value: int) -> void:
	value = new_value

func _on_variable_range_changed(clamp_enabled: bool, new_min_value: int, new_max_value: int) -> void:
	_sync_progress_range(clamp_enabled, new_min_value, new_max_value)

func _sync_progress_range(clamp_enabled: bool = int_variable.clamp_value, new_min_value: int = int_variable.min_value, new_max_value: int = int_variable.max_value) -> void:
	if clamp_enabled:
		min_value = new_min_value
		max_value = new_max_value
	else:
		min_value = _default_min_value
		max_value = _default_max_value

