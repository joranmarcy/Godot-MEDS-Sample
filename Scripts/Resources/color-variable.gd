extends Resource
class_name ColorVariable

signal value_changed(new_value: Color)

@export var initial_value: Color = Color.WHITE:
	set(new_val):
		initial_value = new_val
		_value = new_val
		print("Resource loaded initial_value:", initial_value)

var _value: Color = Color.WHITE

var value: Color:
	get:
		return _value
	set(new_val):
		if _value != new_val:
			_value = new_val
			value_changed.emit(_value)
			print("Runtime value changed to:", _value)
