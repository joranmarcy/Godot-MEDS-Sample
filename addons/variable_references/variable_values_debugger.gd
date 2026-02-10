@tool
extends EditorDebuggerPlugin


signal variable_value_updated(payload: Dictionary)


const CAPTURE_NAME := "variable_values"
const MSG_UPDATE := "variable_values:update"


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
