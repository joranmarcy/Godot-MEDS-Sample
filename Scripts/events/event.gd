@icon("res://icons/BaseVariable.svg")
extends Resource
class_name Event

signal event_raised()


func _init() -> void:
	# Only register during game runtime (avoid editor-time resource browsing noise).
	if Engine.is_editor_hint():
		return
	EventRuntimeReporter.register_event(self)

func raise_event() -> void:
	EventRuntimeReporter.report_raised(self)
	emit_signal("event_raised")

