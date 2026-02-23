@tool
extends VBoxContainer


signal variable_value_set_requested(session_id: int, path: String, type_name: String, value_str: String)
signal variable_debug_logs_set_requested(session_id: int, path: String, enabled: bool)


const COL_NAME := 0
const COL_TYPE := 1
const COL_VALUE := 2
const COL_DEBUG_LOGS := 3

const EditorUIUtils := preload("res://addons/variable_references/editor_ui_utils.gd")


var _tree: Tree
var _root: TreeItem
var _items_by_id: Dictionary = {}
var _editor_interface: Object = null
var _last_selected_column := -1
var _is_bulk_updating_debug_logs := false


func _get_pretty_type_name(type_name: String) -> String:
	# Runtime reports use script class names like "BoolVariable".
	# For the UI, show a shorter label like "bool".
	var t := type_name
	if t.ends_with("Variable"):
		return t.trim_suffix("Variable").to_lower()
	return t.to_lower()


func set_editor_interface(editor_interface: Object) -> void:
	_editor_interface = editor_interface


func _ready() -> void:
	# Header
	var header := HBoxContainer.new()
	add_child(header)

	var title := Label.new()
	title.text = "Runtime Variable Values"
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
	_tree.columns = 4
	_tree.column_titles_visible = true
	_tree.set_column_title(COL_NAME, "Variable")
	_tree.set_column_title(COL_TYPE, "Type")
	_tree.set_column_title(COL_VALUE, "Value")
	_tree.set_column_title(COL_DEBUG_LOGS, "Debug Logs")
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.item_edited.connect(_on_tree_item_edited)
	if _tree.has_signal("item_activated"):
		_tree.item_activated.connect(_on_tree_item_activated)
	if _tree.has_signal("cell_selected"):
		_tree.cell_selected.connect(_on_tree_cell_selected)
	add_child(_tree)

	_root = _tree.create_item()


func clear_values() -> void:
	_items_by_id.clear()
	if _tree != null:
		_tree.clear()
		_root = _tree.create_item()


func on_variable_value_updated(payload: Dictionary) -> void:
	# payload format (best-effort):
	#  id, path, name, type, value_str, debug_logs, ticks_msec, session_id
	var id := str(payload.get("id", ""))
	if id == "":
		id = str(payload.get("path", ""))
	if id == "":
		return

	var item: TreeItem = null
	if _items_by_id.has(id) and is_instance_valid(_items_by_id[id]):
		item = _items_by_id[id]
	else:
		item = _tree.create_item(_root)
		_items_by_id[id] = item
		item.set_text(COL_NAME, str(payload.get("name", id)))

	# Allow double-click selection to open the resource in the inspector.
	item.set_metadata(COL_NAME, {
		"path": str(payload.get("path", "")),
	})

	var raw_type := str(payload.get("type", ""))
	var new_value_str := str(payload.get("value_str", ""))
	var old_value_str := ""
	var old_blink_token := 0
	var value_meta_before: Variant = item.get_metadata(COL_VALUE)
	if typeof(value_meta_before) == TYPE_DICTIONARY:
		var vd := value_meta_before as Dictionary
		old_value_str = str(vd.get("value_str", ""))
		old_blink_token = int(vd.get("blink_token", 0))
	item.set_text(COL_TYPE, _get_pretty_type_name(raw_type))
	item.set_text(COL_VALUE, new_value_str)
	item.set_editable(COL_VALUE, true)
	item.set_cell_mode(COL_DEBUG_LOGS, TreeItem.CELL_MODE_CHECK)
	item.set_editable(COL_DEBUG_LOGS, true)
	item.set_checked(COL_DEBUG_LOGS, bool(payload.get("debug_logs", false)))

	# Store value_str for future blink detection.
	var blink_token := old_blink_token
	if old_value_str != "" and new_value_str != old_value_str:
		blink_token += 1
	item.set_metadata(COL_VALUE, {
		"session_id": int(payload.get("session_id", 0)),
		"path": str(payload.get("path", "")),
		"type": raw_type,
		"value_str": new_value_str,
		"blink_token": blink_token,
	})
	if old_value_str != "" and new_value_str != old_value_str:
		_blink_cell_bg(item, COL_VALUE, blink_token)
	item.set_metadata(COL_DEBUG_LOGS, {
		"session_id": int(payload.get("session_id", 0)),
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


func _on_tree_cell_selected() -> void:
	_last_selected_column = _get_selected_column()


func _get_selected_column() -> int:
	if _tree == null:
		return _last_selected_column
	if _tree.has_method("get_selected_column"):
		return int(_tree.call("get_selected_column"))
	return _last_selected_column


func _on_tree_item_activated() -> void:
	if _tree == null:
		return
	var item := _tree.get_selected()
	if item == null:
		return

	var column := _get_selected_column()
	if column != COL_NAME:
		return

	var meta: Variant = item.get_metadata(COL_NAME)
	if typeof(meta) != TYPE_DICTIONARY:
		return
	var dict := meta as Dictionary
	var path := str(dict.get("path", ""))
	if path == "":
		push_warning("Variable Values: can't open variable without a saved resource path.")
		return

	EditorUIUtils.select_resource_in_editor(_editor_interface, path)



func _get_metadata_dict(item: TreeItem, column: int) -> Dictionary:
	if item == null:
		return {}
	var meta: Variant = item.get_metadata(column)
	if typeof(meta) != TYPE_DICTIONARY:
		return {}
	return meta as Dictionary



func _on_tree_item_edited() -> void:
	if _is_bulk_updating_debug_logs:
		return
	var item := _tree.get_edited()
	if item == null:
		return
	var column := _tree.get_edited_column()
	match column:
		COL_VALUE:
			var value_meta := _get_metadata_dict(item, COL_VALUE)
			if value_meta.is_empty():
				return
			var session_id := int(value_meta.get("session_id", 0))
			var path := str(value_meta.get("path", ""))
			var type_name := str(value_meta.get("type", ""))
			if path == "":
				push_warning("Variable Values: can't edit values for resources without a saved path.")
				return
			var value_str := item.get_text(COL_VALUE)
			variable_value_set_requested.emit(session_id, path, type_name, value_str)
			return

		COL_DEBUG_LOGS:
			var debug_meta := _get_metadata_dict(item, COL_DEBUG_LOGS)
			if debug_meta.is_empty():
				return
			var session_id := int(debug_meta.get("session_id", 0))
			var path := str(debug_meta.get("path", ""))
			if path == "":
				push_warning("Variable Values: can't toggle debug logs for resources without a saved path.")
				return
			var enabled := bool(item.is_checked(COL_DEBUG_LOGS))
			variable_debug_logs_set_requested.emit(session_id, path, enabled)
			return

		_:
			return


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
		var path := str(dict.get("path", ""))
		if path == "":
			continue
		# Use session_id 0 to broadcast to all active debug sessions.
		variable_debug_logs_set_requested.emit(0, path, enabled)
	_is_bulk_updating_debug_logs = false
