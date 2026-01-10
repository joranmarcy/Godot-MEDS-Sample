extends Resource
class_name FloatVariable

signal value_changed(new_value: float)

@export var initial_value: float = 0.0:
	set(new_val):
		initial_value = new_val
		_value = new_val
		print("Resource loaded initial_value:", initial_value)

var _value: float = 0.0

var value: float:
	get:
		return _value
	set(new_val):
		if _value != new_val:
			_value = new_val
			value_changed.emit(_value)
			print("Runtime value changed to:", _value)

