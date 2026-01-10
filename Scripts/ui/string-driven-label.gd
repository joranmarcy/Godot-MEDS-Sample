extends Label
@export var string_variable: StringVariable

func _ready():
	self.text = string_variable.value
	string_variable.value_changed.connect(_on_value_changed)

func _on_value_changed(new_value: String):
	self.text = new_value
