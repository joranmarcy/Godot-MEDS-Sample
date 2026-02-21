extends Node

@export var event: Event

signal event_raised()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	event.event_raised.connect(_on_event_raised)

func _on_event_raised() -> void:
	emit_signal("event_raised")	
	