@tool
@icon("res://icons/BaseVariable.svg")
extends Resource
class_name Event


const _CAPTURE_NAME := "events"
const _MSG_RAISE := "events:raise"


class _DebuggerReceiver:
	extends Object

	func _capture(message: String, data: Array) -> bool:
		return Event._handle_debugger_message(message, data)


static var _receiver: _DebuggerReceiver = null
static var _capture_registered := false


func _init() -> void:
	# Only relevant for running game instances launched with the editor debugger attached.
	if Engine.is_editor_hint():
		return
	_ensure_capture_registered()


static func _ensure_capture_registered() -> void:
	if _capture_registered:
		return
	if _receiver == null:
		_receiver = _DebuggerReceiver.new()

	# Use dynamic calls so this stays compatible across minor engine API changes.
	if EngineDebugger.has_method("register_message_capture"):
		EngineDebugger.call("register_message_capture", _CAPTURE_NAME, Callable(_receiver, "_capture"))
		_capture_registered = true
	elif EngineDebugger.has_method("register_capture"):
		EngineDebugger.call("register_capture", _CAPTURE_NAME, Callable(_receiver, "_capture"))
		_capture_registered = true


static func _handle_debugger_message(message: String, data: Array) -> bool:
	var msg := message
	# Depending on engine version, the capture callback may receive either
	# - the full message ("events:raise")
	# - or just the command part ("raise")
	if msg == "raise":
		msg = _MSG_RAISE
	elif not msg.begins_with(_CAPTURE_NAME + ":") and msg.find(":") == -1:
		msg = _CAPTURE_NAME + ":" + msg

	if msg != _MSG_RAISE:
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
	if res.has_method("raise_event"):
		res.call("raise_event")
	return true

signal event_raised()

func raise_event() -> void:
	emit_signal("event_raised")

