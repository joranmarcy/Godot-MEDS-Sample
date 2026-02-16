@icon("res://icons/BaseVariable.svg")
extends Resource
class_name BaseVariable

@export var debug_logs: bool = false
@export var stack_trace_logs: bool = false
@export var listeners_logs: bool = false

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

func _object_node_path_or_name(obj: Object) -> String:
	if obj == null:
		return "<null>"
	if obj is Node:
		var node := obj as Node
		if node.is_inside_tree():
			return String(node.get_path())
		return String(node.name)
	# Fallback: best-effort readable identifier.
	return str(obj)

func _format_runtime_node_link(node: Node) -> String:
	if node == null:
		return "<null>"
	if not node.is_inside_tree():
		return String(node.name)

	var tree := node.get_tree()
	if tree == null:
		return String(node.name)

	var current_scene := tree.current_scene
	if current_scene == null:
		return String(node.name)

	var scene_path := String(current_scene.scene_file_path)
	if scene_path == "":
		# Unsaved/unknown scene; fall back to plain text.
		return _object_node_path_or_name(node)

	var node_path := String(node.get_path())
	# Convert absolute tree path (/root/Scene/...) to logged path (/Scene/...) expected by the editor plugin.
	if node_path.begins_with("/root"):
		node_path = node_path.substr(5)

	var url := "//open_node?scene=" + scene_path.uri_encode() + "&node=" + node_path.uri_encode()
	return "[url=%s]%s[/url]" % [url, node_path]

func _log_listener_reacted_to_value_change(cb: Callable, caller: Object) -> void:
	var target_obj: Object = cb.get_object()
	var target_str := _object_node_path_or_name(target_obj)
	if target_obj is Node:
		target_str = _format_runtime_node_link(target_obj as Node)

	var caller_str := _object_node_path_or_name(caller)
	if caller is Node:
		caller_str = _format_runtime_node_link(caller as Node)

	print_rich(target_str + " reacted to value change from " + resource_path.get_basename() + " (caller: " + caller_str + ")")

func _set_value_variant(new_val: Variant, caller: Object = null) -> void:
	if _value != new_val:
		_value = new_val
		if has_signal("value_changed"):
			emit_signal("value_changed", _value)
			if listeners_logs:
				for c in get_signal_connection_list("value_changed"):
					var cb: Callable = c["callable"]
					_log_listener_reacted_to_value_change(cb, caller)
		VariableRuntimeReporter.report(self , _value)
		if (debug_logs):
			Debug.log("%s: %s runtime value changed to: %s" % [get_class(), resource_path.get_basename(), str(_value)], stack_trace_logs, 12, caller)

func _get_value_variant() -> Variant:
	return _value
