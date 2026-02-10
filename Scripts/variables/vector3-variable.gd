@icon("res://icons/Vector3Variable.svg")
extends Resource
class_name Vector3Variable

signal value_changed(new_value: Vector3)

@export var initial_value: Vector3 = Vector3.ZERO:
	set(new_val):
		initial_value = new_val
		_value = new_val
		VariableRuntimeReporter.report(self, _value)
		Debug.log("Vector3Variable: " + resource_path.get_basename() + " loaded initial_value: " + str(initial_value))

var _value: Vector3 = Vector3.ZERO

var value: Vector3:
	get:
		return _value
	set(new_val):
		if _value != new_val:
			_value = new_val
			value_changed.emit(_value)
			VariableRuntimeReporter.report(self, _value)
			Debug.log("Vector3Variable: " + resource_path.get_basename() + " runtime value changed to: " + str(_value))

