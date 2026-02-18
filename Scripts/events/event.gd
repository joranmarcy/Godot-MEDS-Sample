@icon("res://icons/BaseVariable.svg")
extends Resource
class_name Event

signal event_raised()

func raise_event() -> void:
	emit_signal("event_raised")

