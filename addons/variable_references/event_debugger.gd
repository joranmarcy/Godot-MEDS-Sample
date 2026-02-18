@tool
extends EditorDebuggerPlugin


const CAPTURE_NAME := "events"
const MSG_RAISE := "events:raise"


func _has_capture(capture: String) -> bool:
	return capture == CAPTURE_NAME


func request_raise_event(path: String) -> void:
	var payload: Dictionary = {
		"path": path,
	}
	_send_to_all_sessions(MSG_RAISE, [payload])


func _send_to_all_sessions(message: String, data: Array) -> void:
	# Prefer session-based sending when available.
	if has_method("get_sessions"):
		var sessions: Variant = call("get_sessions")
		if typeof(sessions) == TYPE_ARRAY:
			for s in sessions:
				if s != null and s.has_method("send_message"):
					s.call("send_message", message, data)
					continue
			return

	# Fallback: some versions expose send_message(message, data) on the plugin.
	if has_method("send_message"):
		call("send_message", message, data)
		return

	push_warning("Events: unable to send debugger message to running game (no compatible send API found).")
