extends CheckBox

@export var bool_var: BoolVariable

func _ready():
	# To check the box
	button_pressed = bool_var.value
	toggled.connect(_on_toggled)
	bool_var.value_changed.connect(_on_value_changed)

func _on_toggled(pressed: bool):	
	print("Checkbox toggled to: " + str(pressed))
	bool_var.set_value(pressed, self)

func _on_value_changed(new_value: bool):
	print("BoolVariable changed to: " + str(new_value))
	button_pressed = new_value	
	
