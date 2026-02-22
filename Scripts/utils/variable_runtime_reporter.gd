extends Object
class_name VariableRuntimeReporter


const CAPTURE_NAME := "variable_values"
const MSG_SET := "variable_values:set"
const MSG_SET_DEBUG_LOGS := "variable_values:set_debug_logs"


class _DebuggerReceiver:
	extends Object

	func _capture(message: String, data: Array) -> bool:
		return VariableRuntimeReporter._handle_debugger_message(message, data)


static var _receiver: _DebuggerReceiver = null
static var _capture_registered := false


static func _get_pretty_runtime_type_name(obj: Object) -> String:
	# `Object.get_class()` returns the native type (often just "Resource").
	# For script-based resources, prefer the script's global class name (from `class_name`).
	if obj == null:
		return ""
	var t := obj.get_class()
	if obj.has_method("get_script"):
		var script: Variant = obj.call("get_script")
		if script != null:
			# Godot 4.x: Script.get_global_name() returns the `class_name` if set.
			if script.has_method("get_global_name"):
				var global_name := str(script.call("get_global_name"))
				if global_name != "":
					return global_name
			# Fallback: derive from script filename.
			if script.has_method("get_path"):
				var p := str(script.call("get_path"))
				if p != "":
					return p.get_file().get_basename()
	return t


static func report(variable: Resource, value: Variant) -> void:
	if variable == null:
		return

	# Only report when running with an active debugger connection.
	if not EngineDebugger.is_active():
		return

	_ensure_capture_registered()

	var path := ""
	if variable.resource_path != null:
		path = String(variable.resource_path)

	var id := path
	if id == "":
		id = str(variable.get_instance_id())

	var name := ""
	if path != "":
		name = path.get_file()
	else:
		name = String(variable.resource_name)
		if name == "":
			name = id

	var payload: Dictionary = {
		"id": id,
		"path": path,
		"name": name,
		"type": _get_pretty_runtime_type_name(variable),
		"value_str": str(value),
		"debug_logs": bool(variable.get("debug_logs") if variable.has_method("get") else false),
		"ticks_msec": Time.get_ticks_msec(),
	}

	EngineDebugger.send_message("variable_values:update", [payload])


static func _ensure_capture_registered() -> void:
	if _capture_registered:
		return
	if not EngineDebugger.is_active():
		return
	if _receiver == null:
		_receiver = _DebuggerReceiver.new()

	# Use dynamic calls so this file stays compatible across minor engine API changes.
	if EngineDebugger.has_method("register_message_capture"):
		EngineDebugger.call("register_message_capture", CAPTURE_NAME, Callable(_receiver, "_capture"))
		_capture_registered = true
	elif EngineDebugger.has_method("register_capture"):
		EngineDebugger.call("register_capture", CAPTURE_NAME, Callable(_receiver, "_capture"))
		_capture_registered = true


static func _handle_debugger_message(message: String, data: Array) -> bool:
	# Depending on engine version, the capture callback may receive either
	# - the full message ("variable_values:set")
	# - or just the command part ("set")
	var msg := message
	if msg == "set":
		msg = MSG_SET
	elif msg == "set_debug_logs":
		msg = MSG_SET_DEBUG_LOGS
	elif not msg.begins_with(CAPTURE_NAME + ":") and msg.find(":") == -1:
		msg = CAPTURE_NAME + ":" + msg

	if msg != MSG_SET and msg != MSG_SET_DEBUG_LOGS:
		return false
	if data.is_empty() or typeof(data[0]) != TYPE_DICTIONARY:
		return true

	var payload := data[0] as Dictionary
	var path := str(payload.get("path", ""))
	if path == "":
		return true
	if not ResourceLoader.exists(path):
		return true

	var res := ResourceLoader.load(path)
	if res == null:
		return true
	if not res.has_method("set") or not res.has_method("get"):
		return true

	if msg == MSG_SET:
		if not _object_has_property(res, "value"):
			return true
		var type_name := str(payload.get("type", res.get_class()))
		var value_str := str(payload.get("value_str", ""))
		var new_val: Variant = _parse_value(type_name, value_str)
		# Apply, then re-report to refresh editor UI.
		print("VariableRuntimeReporter: set ", path, " = ", value_str, " (", type_name, ")")
		res.set("value", new_val)
		report(res, res.get("value"))
		return true

	# MSG_SET_DEBUG_LOGS
	if not _object_has_property(res, "debug_logs"):
		return true
	var enabled := bool(payload.get("debug_logs", false))
	print("VariableRuntimeReporter: debug_logs ", path, " = ", enabled)
	res.set("debug_logs", enabled)
	# Re-report to refresh editor UI.
	var current_value: Variant = null
	if _object_has_property(res, "value"):
		current_value = res.get("value")
	report(res, current_value)
	return true


static func _object_has_property(obj: Object, prop_name: String) -> bool:
	if obj == null:
		return false
	if not obj.has_method("get_property_list"):
		return true # best-effort: allow set attempt
	var plist: Array = obj.get_property_list()
	for p in plist:
		if typeof(p) == TYPE_DICTIONARY and str((p as Dictionary).get("name", "")) == prop_name:
			return true
	return false


static func _parse_value(type_name: String, value_str: String) -> Variant:
	match type_name:
		"BoolVariable":
			var s := value_str.strip_edges().to_lower()
			return s == "true" or s == "1" or s == "yes" or s == "on"
		"IntVariable":
			return int(value_str)
		"FloatVariable":
			return float(value_str)
		"StringVariable":
			return value_str
		"Vector2Variable", "Vector3Variable", "ColorVariable":
			# Best effort: accept Godot's printed forms like Vector2(1, 2) and Color(1, 1, 1, 1)
			# and also allow raw literals supported by str_to_var.
			var v: Variant = str_to_var(value_str)
			if v != null:
				return v
			return value_str
		_:
			# Fallback: try to parse as Variant; if that fails, keep as string.
			var vv: Variant = str_to_var(value_str)
			if vv != null:
				return vv
			return value_str
