extends Object
class_name EventRuntimeReporter


const CAPTURE_NAME := "events"
const MSG_UPDATE := "events:update"
const MSG_LIST := "events:list"
const MSG_RAISE := "events:raise"
const MSG_SET_DEBUG_LOGS := "events:set_debug_logs"


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

# id -> WeakRef(Event)
static var _event_ref_by_id: Dictionary = {}


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

	_event_ref_by_id[id] = weakref(event)

	state["id"] = id
	state["path"] = path
	state["name"] = name
	state["type"] = event.get_class()
	state["debug_logs"] = bool(event.get("debug_logs") if event.has_method("get") else false)
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
		"debug_logs": bool(state.get("debug_logs", false)),
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
	elif msg == "raise":
		msg = MSG_RAISE
	elif not msg.begins_with(CAPTURE_NAME + ":") and msg.find(":") == -1:
		msg = CAPTURE_NAME + ":" + msg

	if msg == MSG_LIST:
		# Respond by sending the current state for every known event.
		for id in _state_by_id.keys():
			var state: Variant = _state_by_id.get(id)
			if typeof(state) != TYPE_DICTIONARY:
				continue
			_send_update_state(state as Dictionary)
		return true

	if msg != MSG_RAISE:
		# fall through for other message handlers
		pass

	if msg == MSG_SET_DEBUG_LOGS:
		if _data.is_empty() or typeof(_data[0]) != TYPE_DICTIONARY:
			return true
		var payload := _data[0] as Dictionary
		var id := str(payload.get("id", ""))
		var path := str(payload.get("path", ""))
		var enabled := bool(payload.get("debug_logs", false))

		# Resolve event instance similarly to raise.
		var event_obj: Object = null
		if id != "" and _event_ref_by_id.has(id) and typeof(_event_ref_by_id[id]) == TYPE_OBJECT:
			var wr := _event_ref_by_id[id] as WeakRef
			if wr != null:
				event_obj = wr.get_ref()
		if event_obj == null and path != "" and ResourceLoader.exists(path):
			event_obj = ResourceLoader.load(path)
		if event_obj == null and id.is_valid_int():
			event_obj = instance_from_id(int(id))

		if event_obj != null:
			# Prefer property set (exported var) but keep it generic.
			if event_obj.has_method("set"):
				event_obj.call("set", "debug_logs", enabled)
			elif "debug_logs" in event_obj:
				event_obj.debug_logs = enabled

			# Update cached state + notify editor.
			var state: Dictionary = {}
			if id != "" and _state_by_id.has(id) and typeof(_state_by_id[id]) == TYPE_DICTIONARY:
				state = _state_by_id[id] as Dictionary
			elif path != "" and _state_by_id.has(path) and typeof(_state_by_id[path]) == TYPE_DICTIONARY:
				state = _state_by_id[path] as Dictionary
			else:
				# Best-effort registration to get an id/state.
				if event_obj is Resource:
					register_event(event_obj)
					var new_id := str((event_obj as Resource).resource_path)
					if new_id == "":
						new_id = str(event_obj.get_instance_id())
					if _state_by_id.has(new_id) and typeof(_state_by_id[new_id]) == TYPE_DICTIONARY:
						state = _state_by_id[new_id] as Dictionary

			if not state.is_empty():
				state["debug_logs"] = enabled
				_state_by_id[str(state.get("id", id if id != "" else path))] = state
				_send_update_state(state)
		return true

	if msg != MSG_RAISE:
		return false

	if _data.is_empty() or typeof(_data[0]) != TYPE_DICTIONARY:
		return true
	var payload := _data[0] as Dictionary
	var id := str(payload.get("id", ""))
	var path := str(payload.get("path", ""))

	# Try live reference first (works for runtime-only resources too).
	var event_obj: Object = null
	if id != "" and _event_ref_by_id.has(id) and typeof(_event_ref_by_id[id]) == TYPE_OBJECT:
		var wr := _event_ref_by_id[id] as WeakRef
		if wr != null:
			event_obj = wr.get_ref()

	# Then try loading by path (best for saved resources).
	if event_obj == null and path != "" and ResourceLoader.exists(path):
		event_obj = ResourceLoader.load(path)

	# Finally, attempt instance id lookup.
	if event_obj == null and id.is_valid_int():
		event_obj = instance_from_id(int(id))

	if event_obj == null:
		return true
	if event_obj.has_method("raise_event"):
		print("EventRuntimeReporter: raise ", path if path != "" else id)
		event_obj.call("raise_event")
	return true
