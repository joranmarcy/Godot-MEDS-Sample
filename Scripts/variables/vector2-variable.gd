@icon("res://icons/Vector2Variable.svg")
extends Resource
class_name Vector2Variable

signal value_changed(new_value: Vector2)

@export var initial_value: Vector2 = Vector2.ZERO:
	set(new_val):
		initial_value = new_val
		_value = new_val
		VariableRuntimeReporter.report(self, _value)
		Debug.log("Vector2Variable: " + resource_path.get_basename() + " loaded initial_value: " + str(initial_value))

var _value: Vector2 = Vector2.ZERO

func set_value(new_val: Vector2, caller: Object = null) -> void:
	_set_value(new_val, caller)

func _set_value(new_val: Vector2, caller: Object = null) -> void:
	if _value != new_val:
		_value = new_val
		value_changed.emit(_value)
		VariableRuntimeReporter.report(self, _value)
		Debug.log("Vector2Variable: " + resource_path.get_basename() + " runtime value changed to: " + str(_value), true, 12, caller)

var value: Vector2:
	get:
		return _value
	set(new_val):
		_set_value(new_val, null)

