extends Label
@export var string_variable: StringVariable
@export var prefix: String = ""
@export var suffix: String = ""

func _ready():
	_update_text(string_variable.value)
	string_variable.value_changed.connect(_on_value_changed)

func _on_value_changed(new_value: String):
	_update_text(new_value)

func _update_text(value: String) -> void:
	self.text = prefix + value + suffix
