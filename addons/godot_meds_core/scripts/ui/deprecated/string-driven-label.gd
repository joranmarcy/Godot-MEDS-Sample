extends "res://addons/godot_meds_core/scripts/ui/variable-driven-label.gd"

static var _deprecation_reported: bool = false

@export var string_variable: StringVariable:
	set(new_value):
		string_variable = new_value
		variable = new_value

func _ready() -> void:
	if variable == null and string_variable != null:
		variable = string_variable
	_report_deprecation_once()
	super._ready()

func _report_deprecation_once() -> void:
	if _deprecation_reported:
		return
	_deprecation_reported = true
	var message := "[DEPRECATED] string-driven-label.gd is deprecated. Use variable-driven-label.gd instead."
	push_warning(message)
	printerr(message)
