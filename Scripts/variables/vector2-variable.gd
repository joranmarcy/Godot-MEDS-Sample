extends Resource
class_name Vector2Variable

signal value_changed(new_value: Vector2)

@export var initial_value: Vector2 = Vector2.ZERO:
	set(new_val):
		initial_value = new_val
		_value = new_val
		print("Resource loaded initial_value:", initial_value)

var _value: Vector2 = Vector2.ZERO

var value: Vector2:
	get:
		return _value
	set(new_val):
		if _value != new_val:
			_value = new_val
			value_changed.emit(_value)
			print("Runtime value changed to:", _value)
