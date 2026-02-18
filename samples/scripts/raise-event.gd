extends Node

@export var event: Event

func raise_event() -> void:
	print("Raising event...")
	event.raise_event()
