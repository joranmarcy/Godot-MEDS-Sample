@tool
extends VBoxContainer


signal event_raise_requested(session_id: int, event_id: String, path: String)
signal event_debug_logs_set_requested(session_id: int, event_id: String, path: String, enabled: bool)


const COL_NAME := 0
const COL_TYPE := 1
const COL_LISTENERS := 2
const COL_RAISED := 3
const COL_LAST_RAISED := 4
const COL_UPDATED := 5
const COL_DEBUG_LOGS := 6
const COL_RAISE := 7

const BTN_RAISE := 1


var _tree: Tree
var _root: TreeItem
var _items_by_id: Dictionary = {}
var _last_session_id := 0
var _editor_interface: Object = null
var _is_bulk_updating_debug_logs := false


func set_editor_interface(editor_interface: Object) -> void:
	_editor_interface = editor_interface


func _ready() -> void:
	# Header
	var header := HBoxContainer.new()
	add_child(header)

	var title := Label.new()
	title.text = "Runtime Events"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var all_debug_btn := Button.new()
	all_debug_btn.text = "Enable Debug Logs (All)"
	all_debug_btn.pressed.connect(_on_enable_all_debug_logs_pressed)
	header.add_child(all_debug_btn)

	var no_debug_btn := Button.new()
	no_debug_btn.text = "Disable Debug Logs (All)"
	no_debug_btn.pressed.connect(_on_disable_all_debug_logs_pressed)
	header.add_child(no_debug_btn)

	# Tree
	_tree = Tree.new()
	_tree.columns = 8
	_tree.column_titles_visible = true
	_tree.set_column_title(COL_NAME, "Event")
	_tree.set_column_title(COL_TYPE, "Type")
	_tree.set_column_title(COL_LISTENERS, "Listeners")
	_tree.set_column_title(COL_RAISED, "Raised")
	_tree.set_column_title(COL_LAST_RAISED, "Last Raised")
	_tree.set_column_title(COL_UPDATED, "Updated")
	_tree.set_column_title(COL_DEBUG_LOGS, "Debug Logs")
	_tree.set_column_title(COL_RAISE, "Raise")
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if _tree.has_signal("item_activated"):
		_tree.item_activated.connect(_on_tree_item_activated)
	if _tree.has_signal("item_edited"):
		_tree.item_edited.connect(_on_tree_item_edited)
	# Tree's button click signal name differs across Godot versions.
	if _tree.has_signal("button_clicked"):
		_tree.button_clicked.connect(_on_tree_button_clicked_4)
	elif _tree.has_signal("item_button_pressed"):
		_tree.item_button_pressed.connect(_on_tree_button_clicked_3)
	add_child(_tree)

	_root = _tree.create_item()


func clear_events() -> void:
	_items_by_id.clear()
	_last_session_id = 0
	if _tree != null:
		_tree.clear()
		_root = _tree.create_item()


func on_event_updated(payload: Dictionary) -> void:
	# payload format (best-effort):
	#  id, path, name, type, debug_logs, listener_count, raised_count, last_raised_ticks, ticks_msec, session_id
	_last_session_id = int(payload.get("session_id", _last_session_id))

	var id := str(payload.get("id", ""))
	if id == "":
		id = str(payload.get("path", ""))
	if id == "":
		return

	var item: TreeItem = null
	var is_new := false
	if _items_by_id.has(id) and is_instance_valid(_items_by_id[id]):
		item = _items_by_id[id]
	else:
		item = _tree.create_item(_root)
		_items_by_id[id] = item
		is_new = true

	if is_new:
		var icon: Texture2D = null
		if has_method("get_theme_icon"):
			# Editor icon set.
			icon = get_theme_icon("Play", "EditorIcons")
		item.add_button(COL_RAISE, icon, BTN_RAISE, false, "Raise this event")

	# Ensure checkbox column stays configured even if the row existed already.
	item.set_cell_mode(COL_DEBUG_LOGS, TreeItem.CELL_MODE_CHECK)
	item.set_editable(COL_DEBUG_LOGS, true)

	item.set_text(COL_NAME, str(payload.get("name", id)))
	item.set_text(COL_TYPE, str(payload.get("type", "")))
	item.set_text(COL_LISTENERS, str(payload.get("listener_count", "")))
	item.set_text(COL_RAISED, str(payload.get("raised_count", 0)))
	item.set_checked(COL_DEBUG_LOGS, bool(payload.get("debug_logs", false)))
	item.set_metadata(COL_DEBUG_LOGS, {
		"session_id": int(payload.get("session_id", _last_session_id)),
		"event_id": id,
		"path": str(payload.get("path", "")),
	})
	item.set_metadata(COL_RAISE, {
		"session_id": int(payload.get("session_id", _last_session_id)),
		"event_id": id,
		"path": str(payload.get("path", "")),
	})

	var last := payload.get("last_raised_ticks", null)
	if last == null:
		item.set_text(COL_LAST_RAISED, "")
	else:
		item.set_text(COL_LAST_RAISED, str(last))

	var ticks := payload.get("ticks_msec", null)
	if ticks == null:
		item.set_text(COL_UPDATED, "")
	else:
		item.set_text(COL_UPDATED, str(ticks))


func _on_tree_item_edited() -> void:
	if _is_bulk_updating_debug_logs:
		return
	if _tree == null:
		return
	var item := _tree.get_edited()
	if item == null:
		return
	var column := _tree.get_edited_column()
	if column != COL_DEBUG_LOGS:
		return

	var meta: Variant = item.get_metadata(COL_DEBUG_LOGS)
	if typeof(meta) != TYPE_DICTIONARY:
		return
	var dict := meta as Dictionary
	var session_id := int(dict.get("session_id", 0))
	if session_id == 0:
		session_id = _last_session_id
	var event_id := str(dict.get("event_id", ""))
	var path := str(dict.get("path", ""))
	var enabled := bool(item.is_checked(COL_DEBUG_LOGS))
	if event_id == "" and path == "":
		return
	event_debug_logs_set_requested.emit(session_id, event_id, path, enabled)


func _on_enable_all_debug_logs_pressed() -> void:
	_set_debug_logs_for_all(true)


func _on_disable_all_debug_logs_pressed() -> void:
	_set_debug_logs_for_all(false)


func _set_debug_logs_for_all(enabled: bool) -> void:
	if _tree == null:
		return

	_is_bulk_updating_debug_logs = true
	for key in _items_by_id.keys():
		var item: Variant = _items_by_id[key]
		if not is_instance_valid(item):
			continue
		var tree_item := item as TreeItem
		if tree_item == null:
			continue
		# Update UI first.
		tree_item.set_checked(COL_DEBUG_LOGS, enabled)

		# Then request the runtime change.
		var meta: Variant = tree_item.get_metadata(COL_DEBUG_LOGS)
		if typeof(meta) != TYPE_DICTIONARY:
			continue
		var dict := meta as Dictionary
		var event_id := str(dict.get("event_id", ""))
		var path := str(dict.get("path", ""))
		if event_id == "" and path == "":
			continue
		# Use session_id 0 to broadcast to all active debug sessions.
		event_debug_logs_set_requested.emit(0, event_id, path, enabled)
	_is_bulk_updating_debug_logs = false


func _on_tree_button_clicked_4(item: TreeItem, column: int, id: int, _mouse_button_index: int) -> void:
	_on_tree_button_clicked(item, column, id)


func _on_tree_button_clicked_3(item: TreeItem, column: int, id: int) -> void:
	_on_tree_button_clicked(item, column, id)


func _on_tree_button_clicked(item: TreeItem, column: int, id: int) -> void:
	if item == null:
		return
	if column != COL_RAISE:
		return
	if id != BTN_RAISE:
		return

	var meta: Variant = item.get_metadata(COL_RAISE)
	if typeof(meta) != TYPE_DICTIONARY:
		return
	var dict := meta as Dictionary
	var session_id := int(dict.get("session_id", 0))
	if session_id == 0:
		session_id = _last_session_id
	var event_id := str(dict.get("event_id", ""))
	var path := str(dict.get("path", ""))

	if event_id == "" and path == "":
		return
	if path == "":
		push_warning("Events: can't raise event without a saved resource path (runtime-only events are not supported here yet).")
		# Still emit with id so runtime can try instance_id-based lookup.
	event_raise_requested.emit(session_id, event_id, path)


func _on_tree_item_activated() -> void:
	if _tree == null:
		return
	var item := _tree.get_selected()
	if item == null:
		return

	var meta: Variant = item.get_metadata(COL_RAISE)
	if typeof(meta) != TYPE_DICTIONARY:
		return
	var dict := meta as Dictionary
	var path := str(dict.get("path", ""))
	if path == "":
		return
	_select_event_resource_in_editor(path)


func _select_event_resource_in_editor(path: String) -> void:
	# Best-effort: mimic selecting the resource in the editor.
	# 1) Focus the resource in the Inspector (edit_resource)
	# 2) Highlight it in the FileSystem dock (select_file)
	if _editor_interface == null:
		return
	_focus_inspector_tab()

	var res: Resource = null
	if ResourceLoader.exists(path):
		res = load(path)
	if res != null and _editor_interface.has_method("edit_resource"):
		_editor_interface.call("edit_resource", res)

	_select_file_in_filesystem_dock(path)


func _select_file_in_filesystem_dock(path: String) -> void:
	if _editor_interface == null:
		return
	var normalized := path.replace("\\", "/")

	# Prefer the higher-level API if present.
	if _editor_interface.has_method("select_file"):
		_editor_interface.call("select_file", normalized)
		return

	if not _editor_interface.has_method("get_file_system_dock"):
		return
	var fs_dock: Variant = _editor_interface.call("get_file_system_dock")
	if fs_dock == null:
		return
	if fs_dock.has_method("select_file"):
		fs_dock.call("select_file", normalized)


func _focus_inspector_tab() -> void:
	# The Inspector is not a "main screen" (2D/3D/Script), it's a dock tab.
	# Godot doesn't expose a stable API to focus it across all 4.x builds,
	# so we do a best-effort UI search for a TabContainer/TabBar tab titled "Inspector".
	if _editor_interface == null:
		return
	if not _editor_interface.has_method("get_base_control"):
		return
	var base: Variant = _editor_interface.call("get_base_control")
	var base_control := base as Control
	if base_control == null:
		return

	# TabContainer approach.
	var tab_containers := base_control.find_children("*", "TabContainer", true, false)
	for n in tab_containers:
		var tc := n as TabContainer
		if tc == null:
			continue
		for i in range(tc.get_tab_count()):
			if tc.get_tab_title(i) == "Inspector":
				if tc.has_method("set_current_tab"):
					tc.call("set_current_tab", i)
				else:
					tc.current_tab = i
				return

	# TabBar approach (some editor UIs use a TabBar directly).
	var tab_bars := base_control.find_children("*", "TabBar", true, false)
	for n in tab_bars:
		var tb := n as TabBar
		if tb == null:
			continue
		for i in range(tb.get_tab_count()):
			if tb.get_tab_title(i) == "Inspector":
				if tb.has_method("set_current_tab"):
					tb.call("set_current_tab", i)
				else:
					tb.current_tab = i
				return
