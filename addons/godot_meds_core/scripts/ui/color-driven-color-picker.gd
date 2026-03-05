extends ColorPickerButton

@export var color_variable: ColorVariable

func _ready():	
	self.color = color_variable.value
	color_variable.value_changed.connect(_on_color_variable_value_changed)
	connect("color_changed", _on_color_picker_value_changed)

func _on_color_picker_value_changed(new_value: Color):	
	color_variable.set_value(new_value, self)

func _on_color_variable_value_changed(new_value: Color):	
	self.color = new_value
	
