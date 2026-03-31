extends "res://addons/godot_meds_core/scripts/ui/variable-driven-slider.gd"

static var _deprecation_reported: bool = false

@export var float_variable: FloatVariable:
	set(new_value):
		float_variable = new_value
		variable = new_value

func _ready() -> void:
	if variable == null and float_variable != null:
		variable = float_variable
	_report_deprecation_once()
	super._ready()

func _report_deprecation_once() -> void:
	if _deprecation_reported:
		return
	_deprecation_reported = true
	var message := "[DEPRECATED] float-driven-slider.gd is deprecated. Use variable-driven-slider.gd instead."
	push_warning(message)
	printerr(message)

