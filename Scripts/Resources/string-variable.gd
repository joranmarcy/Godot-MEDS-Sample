extends Resource
class_name StringVariable

signal value_changed(new_value: String)

@export var initial_value: String = "":
	set(new_val):
		initial_value = new_val
		_value = new_val
		print("Resource loaded initial_value:", initial_value)

var _value: String = ""

var value: String:
	get:
		return _value
	set(new_val):
		if _value != new_val:
			_value = new_val
			value_changed.emit(_value)
			print("Runtime value changed to:", _value)

