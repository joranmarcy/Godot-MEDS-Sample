@tool
extends EditorDebuggerPlugin


signal event_updated(payload: Dictionary)
signal debug_session_ended(session_id: int)


const CAPTURE_NAME := "events"
const MSG_UPDATE := "events:update"
const MSG_LIST := "events:list"
const MSG_RAISE := "events:raise"
const MSG_SET_DEBUG_LOGS := "events:set_debug_logs"


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
	event_updated.emit(dict)
	return true


func request_list(session_id: int) -> void:
	if session_id <= 0:
		_send_to_all_sessions(MSG_LIST, [])
		return
	_send_to_session(session_id, MSG_LIST, [])


func request_raise(session_id: int, event_id: String, path: String) -> void:
	var payload: Dictionary = {
		"id": event_id,
		"path": path,
	}
	if session_id <= 0:
		_send_to_all_sessions(MSG_RAISE, [payload])
		return
	_send_to_session(session_id, MSG_RAISE, [payload])


func request_set_debug_logs(session_id: int, event_id: String, path: String, enabled: bool) -> void:
	var payload: Dictionary = {
		"id": event_id,
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

	push_warning("Events: unable to send debugger message to running game (no compatible send API found).")


# Session lifecycle hooks (Godot versions differ in naming).
func _setup_session(session_id: int) -> void:
	# No-op; present for compatibility.
	pass


func _end_session(session_id: int) -> void:
	debug_session_ended.emit(session_id)


func _session_stopped(session_id: int) -> void:
	debug_session_ended.emit(session_id)


func _stop_session(session_id: int) -> void:
	debug_session_ended.emit(session_id)


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

	push_warning("Events: unable to send debugger message to running game (no compatible send API found).")
