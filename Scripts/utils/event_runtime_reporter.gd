extends Object
class_name EventRuntimeReporter


const CAPTURE_NAME := "events"
const MSG_UPDATE := "events:update"
const MSG_LIST := "events:list"


class _DebuggerReceiver:
	extends Object

	func _capture(message: String, data: Array) -> bool:
		return EventRuntimeReporter._handle_debugger_message(message, data)


static var _receiver: _DebuggerReceiver = null
static var _capture_registered := false

# id -> state dict
# {
#   id, path, name, type,
#   raised_count, last_raised_ticks
# }
static var _state_by_id: Dictionary = {}


static func register_event(event: Resource) -> void:
	if event == null:
		return
	if not EngineDebugger.is_active():
		return

	_ensure_capture_registered()

	var path := ""
	if event.resource_path != null:
		path = String(event.resource_path)

	var id := path
	if id == "":
		id = str(event.get_instance_id())

	var name := ""
	if path != "":
		name = path.get_file()
	else:
		name = String(event.resource_name)
		if name == "":
			name = id

	var state: Dictionary = {}
	if _state_by_id.has(id) and typeof(_state_by_id[id]) == TYPE_DICTIONARY:
		state = _state_by_id[id] as Dictionary

	state["id"] = id
	state["path"] = path
	state["name"] = name
	state["type"] = event.get_class()
	state["listener_count"] = _get_listener_count(event)
	state["raised_count"] = int(state.get("raised_count", 0))
	state["last_raised_ticks"] = state.get("last_raised_ticks", null)
	_state_by_id[id] = state

	_send_update_state(state)


static func report_raised(event: Resource) -> void:
	if event == null:
		return
	if not EngineDebugger.is_active():
		return

	_ensure_capture_registered()

	var path := ""
	if event.resource_path != null:
		path = String(event.resource_path)

	var id := path
	if id == "":
		id = str(event.get_instance_id())

	# Ensure it's registered at least once.
	if not _state_by_id.has(id):
		register_event(event)

	var state: Dictionary = {}
	if _state_by_id.has(id) and typeof(_state_by_id[id]) == TYPE_DICTIONARY:
		state = _state_by_id[id] as Dictionary

	state["id"] = id
	state["path"] = path
	state["type"] = event.get_class()
	state["listener_count"] = _get_listener_count(event)

	var name := str(state.get("name", ""))
	if name == "":
		if path != "":
			name = path.get_file()
		else:
			name = String(event.resource_name)
			if name == "":
				name = id
		state["name"] = name

	state["raised_count"] = int(state.get("raised_count", 0)) + 1
	state["last_raised_ticks"] = Time.get_ticks_msec()
	_state_by_id[id] = state

	_send_update_state(state)


static func _send_update_state(state: Dictionary) -> void:
	var payload: Dictionary = {
		"id": str(state.get("id", "")),
		"path": str(state.get("path", "")),
		"name": str(state.get("name", "")),
		"type": str(state.get("type", "")),
		"listener_count": int(state.get("listener_count", 0)),
		"raised_count": int(state.get("raised_count", 0)),
		"last_raised_ticks": state.get("last_raised_ticks", null),
		"ticks_msec": Time.get_ticks_msec(),
	}
	EngineDebugger.send_message(MSG_UPDATE, [payload])


static func _get_listener_count(event: Object) -> int:
	if event == null:
		return 0
	# Best effort across Godot versions.
	if event.has_method("get_signal_connection_list"):
		var conns: Variant = event.call("get_signal_connection_list", "event_raised")
		if typeof(conns) == TYPE_ARRAY:
			return (conns as Array).size()
	return 0


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


static func _handle_debugger_message(message: String, _data: Array) -> bool:
	# Depending on engine version, the capture callback may receive either
	# - the full message ("events:list")
	# - or just the command part ("list")
	var msg := message
	if msg == "list":
		msg = MSG_LIST
	elif not msg.begins_with(CAPTURE_NAME + ":") and msg.find(":") == -1:
		msg = CAPTURE_NAME + ":" + msg

	if msg != MSG_LIST:
		return false

	# Respond by sending the current state for every known event.
	for id in _state_by_id.keys():
		var state: Variant = _state_by_id.get(id)
		if typeof(state) != TYPE_DICTIONARY:
			continue
		_send_update_state(state as Dictionary)
	return true
