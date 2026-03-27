extends Slider

@export var float_variable: FloatVariable

var _default_min_value: float
var _default_max_value: float

func _ready():	
	_default_min_value = min_value
	_default_max_value = max_value
	_sync_slider_range()
	self.value = float_variable.value
	float_variable.value_changed.connect(_on_variable_value_changed)
	float_variable.range_changed.connect(_on_variable_range_changed)
	value_changed.connect(_on_slider_value_changed)

func _on_slider_value_changed(new_value: float):	
	float_variable.set_value(new_value, self)

func _on_variable_value_changed(new_value: float):	
	self.value = new_value

func _on_variable_range_changed(clamp_enabled: bool, new_min_value: float, new_max_value: float) -> void:
	_sync_slider_range(clamp_enabled, new_min_value, new_max_value)

func _sync_slider_range(clamp_enabled: bool = float_variable.clamp_value, new_min_value: float = float_variable.min_value, new_max_value: float = float_variable.max_value) -> void:
	if clamp_enabled:
		min_value = new_min_value
		max_value = new_max_value
	else:
		min_value = _default_min_value
		max_value = _default_max_value
	
