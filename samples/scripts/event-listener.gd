extends Node

@export var event: Event

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	event.event_raised.connect(_on_event_raised)

func _on_event_raised() -> void:
	print("Event was raised!")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
