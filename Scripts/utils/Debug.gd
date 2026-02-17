extends Node
class_name Debug

static var debug_mode: bool = true

static func _log(msg: String, include_stack: bool = false, max_frames: int = 12, caller: Object = null) -> void:
	if not debug_mode:
		return

	if caller is Node:
		msg += "\nCaller node: " + String(_format_runtime_node_link(caller))

	if not include_stack:
		print(msg)
		return

	var stack: Array = get_stack()
	# Skip this function and any internal frames.
	var stack_str := _format_stack(stack, 2, max_frames)
	if stack_str == "":
		print(msg)
	else:
		print(msg + "\n" + stack_str)

static func log_value_change(variable: BaseVariable, caller: Object = null) -> void:
	print("")
	print("--- Debug: Value Change Detected ---")
	print("")
	var msg := "%s: %s runtime value changed to: %s" % [variable.get_class(), variable.resource_path.get_basename(), str(variable._value)]
	Debug._log(msg, true, 12, caller)
	print("")
	Debug._log_signal_listeners_reacted(variable, "value_changed")
	print("")
	print("--- End of Debug ---")	

static func _log_signal_listeners_reacted(emitter: Object, signal_name: String) -> void:
	if not debug_mode:
		return
	if emitter == null:
		return
	if not emitter.has_signal(signal_name):
		return

	for c in emitter.get_signal_connection_list(signal_name):
		if typeof(c) != TYPE_DICTIONARY:
			continue
		var d := c as Dictionary
		var cb: Callable = d.get("callable", Callable())
		if cb.is_null():
			continue
		_log_listener_reacted_to_value_change(cb)


static func _object_node_path_or_name(obj: Object) -> String:
	if obj == null:
		return "<null>"
	if obj is Node:
		var node := obj as Node
		if node.is_inside_tree():
			return String(node.get_path())
		return String(node.name)
	return str(obj)


static func _format_runtime_node_link(node: Node) -> String:
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
		return _object_node_path_or_name(node)

	var node_path := String(node.get_path())
	if node_path.begins_with("/root"):
		node_path = node_path.substr(5)

	var url := "//open_node?scene=" + scene_path.uri_encode() + "&node=" + node_path.uri_encode()
	return "[url=%s]%s[/url]" % [url, node_path]


static func _log_listener_reacted_to_value_change(cb: Callable) -> void:
	var target_obj: Object = cb.get_object()
	var target_str := _object_node_path_or_name(target_obj)
	if target_obj is Node:
		target_str = _format_runtime_node_link(target_obj as Node)

	print_rich("- " + target_str + " reacted to value change")


static func _format_stack(stack: Array, skip: int, max_frames: int) -> String:
	if stack == null or stack.is_empty():
		return ""

	var start := clampi(skip, 0, stack.size())
	var end := clampi(start + maxi(max_frames, 1), start, stack.size())

	var lines: PackedStringArray = []
	lines.append("Stack trace:")
	for i in range(start, end):
		if typeof(stack[i]) != TYPE_DICTIONARY:
			continue
		var frame := stack[i] as Dictionary
		var src := str(frame.get("source", ""))
		var line := str(frame.get("line", "?"))
		var fn := str(frame.get("function", ""))
		if fn != "":
			lines.append("  at %s:%s (%s)" % [src, line, fn])
		else:
			lines.append("  at %s:%s" % [src, line])
	return "\n".join(lines)
