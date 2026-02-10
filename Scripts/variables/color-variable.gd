@icon("res://icons/ColorVariable.svg")
extends Resource
class_name ColorVariable

signal value_changed(new_value: Color)

@export var initial_value: Color = Color.WHITE:
	set(new_val):
		initial_value = new_val
		_value = new_val
		VariableRuntimeReporter.report(self, _value)
		Debug.log("ColorVariable: " + resource_path.get_basename() + " loaded initial_value: " + str(initial_value))

var _value: Color = Color.WHITE

func set_value(new_val: Color, caller: Object = null) -> void:
	_set_value(new_val, caller)

func _set_value(new_val: Color, caller: Object = null) -> void:
	if _value != new_val:
		_value = new_val
		value_changed.emit(_value)
		VariableRuntimeReporter.report(self, _value)
		Debug.log("ColorVariable: " + resource_path.get_basename() + " runtime value changed to: " + str(_value), true, 12, caller)

var value: Color:
	get:
		return _value
	set(new_val):
		_set_value(new_val, null)

