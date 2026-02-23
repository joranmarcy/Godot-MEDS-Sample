extends Button

@export var bool_event: BoolEvent
@export var checkbox: CheckBox

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	bool_event.raise_event(true)
