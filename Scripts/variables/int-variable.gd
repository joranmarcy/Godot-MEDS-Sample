@icon("res://icons/IntVariable.svg")
extends Resource
class_name IntVariable

signal value_changed(new_value: int)

@export var initial_value: int = 0:
	set(new_val):
		initial_value = new_val
		_value = new_val
		VariableRuntimeReporter.report(self, _value)
		Debug.log("IntVariable: " + resource_path.get_basename() + " loaded initial_value: " + str(initial_value))

var _value: int = 0

var value: int:
	get:
		return _value
	set(new_val):
		if _value != new_val:
			_value = new_val
			value_changed.emit(_value)
			VariableRuntimeReporter.report(self, _value)
			Debug.log("IntVariable: " + resource_path.get_basename() + " runtime value changed to: " + str(_value))

