extends Label

@export var variable: BaseVariable
@export var prefix: String = ""
@export var suffix: String = ""

func _ready() -> void:
	_update_text(_get_variable_value())
	if variable != null and variable.has_signal("value_changed"):
		variable.connect("value_changed", Callable(self, "_on_value_changed"))

func _on_value_changed(new_value: Variant) -> void:
	_update_text(new_value)

func _get_variable_value() -> Variant:
	if variable == null:
		return null
	return variable._get_value_variant()

func _update_text(value: Variant) -> void:
	text = prefix + str(value) + suffix
