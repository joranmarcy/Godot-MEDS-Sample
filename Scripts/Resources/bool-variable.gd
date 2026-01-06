extends Resource
class_name BoolVariable

@export var initial_value: bool = false:
	set(new_val):
		initial_value = new_val
		value = new_val # Automatically syncs 'value' when 'initial_value' is loaded
		print("Resource loaded/updated initial_value to: " + str(initial_value))

var value: bool
