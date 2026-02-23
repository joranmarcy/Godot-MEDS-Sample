@icon("res://icons/BaseVariable.svg")
extends Resource
class_name BoolEvent

@export var debug_logs: bool = false

signal event_raised(value: bool)

func _init() -> void:
	# Only register during game runtime (avoid editor-time resource browsing noise).
	if Engine.is_editor_hint():
		return
	call_deferred("_report_next_frame")

func _report_next_frame() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		await tree.process_frame
	EventRuntimeReporter.register_event(self)	

func raise_event(value: bool) -> void:
	EventRuntimeReporter.report_raised(self)
	emit_signal("event_raised", value)
	if debug_logs:
		pass
