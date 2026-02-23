extends Label
@export var float_variable: FloatVariable

func _ready():
	self.text = str(float_variable.value)
	float_variable.value_changed.connect(_on_value_changed)

func _on_value_changed(new_value: float):
	self.text = str(new_value)
