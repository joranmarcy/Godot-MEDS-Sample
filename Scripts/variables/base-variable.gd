@icon("res://icons/BaseVariable.svg")
extends Resource
class_name BaseVariable

@export var debug_logs: bool = false
@export var stack_trace_logs: bool = false

var _value: Variant = null

func _init() -> void:
	# Ensure we have some initial value even when the exported property setter
	# doesn't run (e.g. brand new resources).
	if _value == null and _has_property_named("initial_value"):
		_value = get("initial_value")

	call_deferred("_report_next_frame")

func _has_property_named(prop_name: String) -> bool:
	var plist: Array = get_property_list()
	for p in plist:
		if typeof(p) == TYPE_DICTIONARY and str((p as Dictionary).get("name", "")) == prop_name:
			return true
	return false

func _report_next_frame() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		await tree.process_frame
	VariableRuntimeReporter.report(self , _value)

func _apply_initial_value(new_val: Variant) -> void:
	_value = new_val
	if (debug_logs):
		Debug.log("%s: %s loaded initial_value: %s" % [get_class(), resource_path.get_basename(), str(new_val)])

func _set_value_variant(new_val: Variant, caller: Object = null) -> void:
	if _value != new_val:
		_value = new_val
		if has_signal("value_changed"):
			emit_signal("value_changed", _value)
		VariableRuntimeReporter.report(self , _value)
		if (debug_logs):
			Debug.log("%s: %s runtime value changed to: %s" % [get_class(), resource_path.get_basename(), str(_value)], stack_trace_logs, 12, caller)

func _get_value_variant() -> Variant:
	return _value
