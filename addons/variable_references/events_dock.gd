@tool
extends VBoxContainer


signal event_raise_requested(session_id: int, event_id: String, path: String)
signal event_debug_logs_set_requested(session_id: int, event_id: String, path: String, enabled: bool)


const COL_NAME := 0
const COL_LISTENERS := 1
const COL_RAISED := 2
const COL_DEBUG_LOGS := 3
const COL_RAISE := 4

const BTN_RAISE := 1

const EditorUIUtils := preload("res://addons/variable_references/editor_ui_utils.gd")


var _tree: Tree
var _root: TreeItem
var _items_by_id: Dictionary = {}
var _last_session_id := 0
var _editor_interface: Object = null
var _is_bulk_updating_debug_logs := false
var _listeners_dialog: AcceptDialog
var _listeners_tree: Tree
var _last_selected_column := -1


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

	# Listeners dialog
	_listeners_dialog = AcceptDialog.new()
	_listeners_dialog.title = "Event Listeners"
	_listeners_dialog.visible = false
	add_child(_listeners_dialog)

	var dialog_root := VBoxContainer.new()
	dialog_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_listeners_dialog.add_child(dialog_root)

	_listeners_tree = Tree.new()
	_listeners_tree.columns = 2
	_listeners_tree.column_titles_visible = true
	_listeners_tree.set_column_title(0, "Node")
	_listeners_tree.set_column_title(1, "Script")
	_listeners_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_listeners_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog_root.add_child(_listeners_tree)

	# Tree
	_tree = Tree.new()
	_tree.columns = 5
	_tree.column_titles_visible = true
	_tree.set_column_title(COL_NAME, "Event")
	_tree.set_column_title(COL_LISTENERS, "Listeners")
	_tree.set_column_title(COL_RAISED, "Raised")
	_tree.set_column_title(COL_DEBUG_LOGS, "Debug Logs")
	_tree.set_column_title(COL_RAISE, "Raise")
	# Column sizing: keep buttons compact, share remaining space.
	_tree.set_column_custom_minimum_width(COL_NAME, 200)
	_tree.set_column_expand(COL_NAME, true)
	_tree.set_column_expand_ratio(COL_NAME, 2)
	for col in [COL_LISTENERS, COL_RAISED, COL_DEBUG_LOGS, COL_RAISE]:
		_tree.set_column_expand(col, true)
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if _tree.has_signal("item_activated"):
		_tree.item_activated.connect(_on_tree_item_activated)
	if _tree.has_signal("item_edited"):
		_tree.item_edited.connect(_on_tree_item_edited)
	if _tree.has_signal("cell_selected"):
		_tree.cell_selected.connect(_on_tree_cell_selected)
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
	#  id, path, name, type, debug_logs, listener_count, listeners, raised_count, session_id
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

	var new_raised_count := int(payload.get("raised_count", 0))
	var old_raised_count := -1
	var old_blink_token := 0
	var raised_meta: Variant = item.get_metadata(COL_RAISED)
	if typeof(raised_meta) == TYPE_DICTIONARY:
		var rd := raised_meta as Dictionary
		old_raised_count = int(rd.get("raised_count", -1))
		old_blink_token = int(rd.get("blink_token", 0))

	item.set_text(COL_NAME, str(payload.get("name", id)))
	item.set_text(COL_LISTENERS, str(payload.get("listener_count", "")))
	item.set_text(COL_RAISED, str(new_raised_count))
	item.set_checked(COL_DEBUG_LOGS, bool(payload.get("debug_logs", false)))

	# Store raised_count for future blink detection.
	var blink_token := old_blink_token
	if old_raised_count >= 0 and new_raised_count > old_raised_count:
		blink_token += 1
	item.set_metadata(COL_RAISED, {
		"raised_count": new_raised_count,
		"blink_token": blink_token,
	})
	if old_raised_count >= 0 and new_raised_count > old_raised_count:
		_blink_cell_bg(item, COL_RAISED, blink_token)
	item.set_metadata(COL_LISTENERS, {
		"event_id": id,
		"path": str(payload.get("path", "")),
		"listeners": payload.get("listeners", []),
	})
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


func _blink_cell_bg(item: TreeItem, column: int, token: int) -> void:
	if item == null:
		return
	var blink_color := _get_blink_color()
	# TreeItem supports per-cell custom background.
	item.set_custom_bg_color(column, blink_color)
	call_deferred("_clear_blink_cell_bg_later", item, column, token)


func _clear_blink_cell_bg_later(item: TreeItem, column: int, token: int) -> void:
	# Short delay for the blink effect.
	await get_tree().create_timer(0.18).timeout
	if not is_instance_valid(item):
		return
	var meta: Variant = item.get_metadata(column)
	if typeof(meta) != TYPE_DICTIONARY:
		return
	var dict := meta as Dictionary
	if int(dict.get("blink_token", 0)) != token:
		return
	if item.has_method("clear_custom_bg_color"):
		item.call("clear_custom_bg_color", column)
	else:
		item.set_custom_bg_color(column, Color(0, 0, 0, 0))


func _get_blink_color() -> Color:
	# Prefer editor theme colors when available.
	if has_method("has_theme_color") and call("has_theme_color", "accent_color", "Editor"):
		var c: Color = get_theme_color("accent_color", "Editor")
		c.a = 0.35
		return c
	if has_method("has_theme_color") and call("has_theme_color", "warning_color", "Editor"):
		var w: Color = get_theme_color("warning_color", "Editor")
		w.a = 0.30
		return w
	return Color(1.0, 0.85, 0.2, 0.30)


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

	var column := _get_selected_column()
	if column == COL_LISTENERS:
		_open_listeners_dialog_for_item(item)
		return

	var meta: Variant = item.get_metadata(COL_RAISE)
	if typeof(meta) != TYPE_DICTIONARY:
		return
	var dict := meta as Dictionary
	var path := str(dict.get("path", ""))
	if path == "":
		return
	_select_event_resource_in_editor(path)


func _on_tree_cell_selected() -> void:
	_last_selected_column = _get_selected_column()


func _get_selected_column() -> int:
	if _tree == null:
		return _last_selected_column
	if _tree.has_method("get_selected_column"):
		return int(_tree.call("get_selected_column"))
	return _last_selected_column


func _open_listeners_dialog_for_item(item: TreeItem) -> void:
	if _listeners_dialog == null or _listeners_tree == null:
		return
	var meta: Variant = item.get_metadata(COL_LISTENERS)
	if typeof(meta) != TYPE_DICTIONARY:
		return
	var dict := meta as Dictionary
	var listeners: Variant = dict.get("listeners", [])
	if typeof(listeners) != TYPE_ARRAY:
		listeners = []
	var arr := listeners as Array

	_listeners_tree.clear()
	var root := _listeners_tree.create_item()
	for v in arr:
		if typeof(v) != TYPE_DICTIONARY:
			continue
		var l := v as Dictionary
		var node_label := str(l.get("node_path", l.get("node_name", "")))
		var script_label := str(l.get("script_path", l.get("script_name", "")))
		if script_label == "":
			script_label = "<no script>"
		var method := str(l.get("method", ""))
		if method != "":
			script_label = "%s (%s)" % [script_label, method]

		var row := _listeners_tree.create_item(root)
		row.set_text(0, node_label)
		row.set_text(1, script_label)

	_listeners_dialog.popup_centered_ratio(0.5)


func _select_event_resource_in_editor(path: String) -> void:
	EditorUIUtils.select_resource_in_editor(_editor_interface, path)
