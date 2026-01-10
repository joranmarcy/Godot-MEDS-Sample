extends Resource
class_name IntVariable

signal value_changed(new_value: int)

@export var initial_value: int = 0:
	set(new_val):
		initial_value = new_val
		_value = new_val
		print("Resource loaded initial_value:", initial_value)

var _value: int = 0

var value: int:
	get:
		return _value
	set(new_val):
		if _value != new_val:
			_value = new_val
			value_changed.emit(_value)
			print("Runtime value changed to:", _value)

