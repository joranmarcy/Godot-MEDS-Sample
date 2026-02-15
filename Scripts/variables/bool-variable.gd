@icon("res://icons/BoolVariable.svg")
extends Resource
class_name BoolVariable

signal value_changed(new_value: bool)

func _init() -> void:
	call_deferred("_report_next_frame", _value)

func _report_next_frame(value_to_report: bool) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		await tree.process_frame
	VariableRuntimeReporter.report(self, value_to_report)

@export var initial_value: bool = false:
	set(new_val):
		initial_value = new_val
		_value = new_val
		Debug.log("BoolVariable: " + resource_path.get_basename() + " loaded initial_value: " + str(initial_value))

var _value: bool = false

func set_value(new_val: bool, caller: Object = null) -> void:
	_set_value(new_val, caller)

func _set_value(new_val: bool, caller: Object = null) -> void:
	if _value != new_val:
		_value = new_val
		value_changed.emit(_value)
		VariableRuntimeReporter.report(self, _value)
		Debug.log("BoolVariable: " + resource_path.get_basename() + " runtime value changed to: " + str(_value), true, 12, caller)

var value: bool:
	get:
		return _value
	set(new_val):
		_set_value(new_val, null)

