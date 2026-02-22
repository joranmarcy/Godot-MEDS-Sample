@tool
extends VBoxContainer


signal variable_value_set_requested(session_id: int, path: String, type_name: String, value_str: String)


const COL_NAME := 0
const COL_TYPE := 1
const COL_VALUE := 2

const EditorUIUtils := preload("res://addons/variable_references/editor_ui_utils.gd")


var _tree: Tree
var _root: TreeItem
var _items_by_id: Dictionary = {}
var _editor_interface: Object = null
var _last_selected_column := -1


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

	# Tree
	_tree = Tree.new()
	_tree.columns = 3
	_tree.column_titles_visible = true
	_tree.set_column_title(COL_NAME, "Variable")
	_tree.set_column_title(COL_TYPE, "Type")
	_tree.set_column_title(COL_VALUE, "Value")
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
	#  id, path, name, type, value_str, ticks_msec, session_id
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

	item.set_text(COL_TYPE, str(payload.get("type", "")))
	item.set_text(COL_VALUE, str(payload.get("value_str", "")))
	item.set_editable(COL_VALUE, true)
	item.set_metadata(COL_VALUE, {
		"session_id": int(payload.get("session_id", 0)),
		"path": str(payload.get("path", "")),
		"type": str(payload.get("type", "")),
	})


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



func _on_tree_item_edited() -> void:
	var item := _tree.get_edited()
	if item == null:
		return
	var column := _tree.get_edited_column()
	if column != COL_VALUE:
		return

	var meta: Variant = item.get_metadata(COL_VALUE)
	if typeof(meta) != TYPE_DICTIONARY:
		return
	var dict := meta as Dictionary
	var session_id := int(dict.get("session_id", 0))
	var path := str(dict.get("path", ""))
	var type_name := str(dict.get("type", ""))
	if path == "":
		push_warning("Variable Values: can't edit values for resources without a saved path.")
		return
	var value_str := item.get_text(COL_VALUE)
	variable_value_set_requested.emit(session_id, path, type_name, value_str)
