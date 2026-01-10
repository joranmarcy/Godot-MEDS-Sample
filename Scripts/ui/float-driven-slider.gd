extends Slider

@export var float_variable: FloatVariable

func _ready():	
	self.value = float_variable.value
	float_variable.value_changed.connect(_on_value_changed)
	value_changed.connect(_on_slider_value_changed)

func _on_slider_value_changed(new_value: float):	
	float_variable.value = new_value

func _on_value_changed(new_value: float):	
	self.value = new_value
	
