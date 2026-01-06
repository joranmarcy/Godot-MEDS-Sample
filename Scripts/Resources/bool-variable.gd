extends Resource
class_name BoolVariable

signal value_changed(new_value: bool)

@export var initial_value: bool = false:
	set(new_val):
		initial_value = new_val
		value = new_val # Automatically syncs 'value' when 'initial_value' is loaded
		print("Resource loaded/updated initial_value to: " + str(initial_value))

var value: bool:
	set(new_val):
		if value != new_val:
			value = new_val
			value_changed.emit(value)
