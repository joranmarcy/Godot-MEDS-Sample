extends Node

@export var event: Event

func raise_event() -> void:
	event.raise_event()
