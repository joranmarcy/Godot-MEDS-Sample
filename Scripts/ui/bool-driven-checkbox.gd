extends CheckBox

@export var bool_var: BoolVariable

func _ready():
	# To check the box
	button_pressed = bool_var.value
	toggled.connect(_on_toggled)
	bool_var.value_changed.connect(_on_value_changed)

func _on_toggled(pressed: bool):	
	bool_var.set_value(pressed, self)

func _on_value_changed(new_value: bool):
	button_pressed = new_value	
