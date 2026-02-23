@tool
extends EditorDebuggerPlugin

# When godot_flow_extensions is disabled, the running game can still send
# custom debugger messages (e.g. "variable_values:update"). Without an
# EditorDebuggerPlugin capture, the editor logs:
# "Unknown message: variable_values:update".
#
# This plugin consumes those messages to silence the warnings.

const _CAPTURES: Array[String] = [
	"variable_values",
	"events",
]


func _has_capture(capture: String) -> bool:
	return capture in _CAPTURES


func _capture(message: String, _data: Array, _session_id: int) -> bool:
	# Consume any messages in our capture namespaces.
	for cap in _CAPTURES:
		if message.begins_with(cap + ":"):
			return true
	return false
