@tool
extends EditorDebuggerPlugin


signal variable_value_updated(payload: Dictionary)


const CAPTURE_NAME := "variable_values"
const MSG_UPDATE := "variable_values:update"
const MSG_SET := "variable_values:set"
const MSG_SET_DEBUG_LOGS := "variable_values:set_debug_logs"


func _has_capture(capture: String) -> bool:
	return capture == CAPTURE_NAME


func _capture(message: String, data: Array, session_id: int) -> bool:
	if message != MSG_UPDATE:
		return false

	if data.is_empty():
		return true
	var payload: Variant = data[0]
	if typeof(payload) != TYPE_DICTIONARY:
		return true

	var dict := payload as Dictionary
	dict["session_id"] = session_id
	variable_value_updated.emit(dict)
	return true


func request_set_value(session_id: int, path: String, type_name: String, value_str: String) -> void:
	var payload: Dictionary = {
		"path": path,
		"type": type_name,
		"value_str": value_str,
	}
	_send_to_session(session_id, MSG_SET, [payload])


func request_set_debug_logs(session_id: int, path: String, enabled: bool) -> void:
	var payload: Dictionary = {
		"path": path,
		"debug_logs": enabled,
	}
	if session_id <= 0:
		_send_to_all_sessions(MSG_SET_DEBUG_LOGS, [payload])
		return
	_send_to_session(session_id, MSG_SET_DEBUG_LOGS, [payload])


func _send_to_all_sessions(message: String, data: Array) -> void:
	# Best-effort: try to send to all active debug sessions.
	if has_method("get_sessions"):
		var sessions: Variant = call("get_sessions")
		if typeof(sessions) == TYPE_ARRAY:
			var sent_any := false
			for s in sessions:
				if s != null and s.has_method("send_message"):
					s.call("send_message", message, data)
					sent_any = true
			if sent_any:
				return

	# Fallback: some versions only expose send_message(message, data, session_id).
	if has_method("send_message"):
		call("send_message", message, data, 0)
		return

	push_warning("Variable Values: unable to send debugger message to running game (no compatible send API found).")


func _send_to_session(session_id: int, message: String, data: Array) -> void:
	# Godot's editor debugger APIs have moved around a bit across 4.x.
	# Try the most specific options first, fall back gracefully.
	if has_method("send_message"):
		# Some versions expose send_message(message, data, session_id)
		call("send_message", message, data, session_id)
		return

	if has_method("get_session"):
		var session := call("get_session", session_id)
		if session != null and session.has_method("send_message"):
			session.call("send_message", message, data)
			return

	if has_method("get_sessions"):
		var sessions: Variant = call("get_sessions")
		if typeof(sessions) == TYPE_ARRAY:
			for s in sessions:
				if s != null and s.has_method("get_id") and int(s.call("get_id")) == session_id and s.has_method("send_message"):
					s.call("send_message", message, data)
					return

	push_warning("Variable Values: unable to send debugger message to running game (no compatible send API found).")
