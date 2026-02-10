@tool
extends VBoxContainer


const COL_NAME := 0
const COL_TYPE := 1
const COL_VALUE := 2
const COL_UPDATED := 3


var _tree: Tree
var _root: TreeItem
var _items_by_id: Dictionary = {}


func _ready() -> void:
	# Header
	var header := HBoxContainer.new()
	add_child(header)

	var title := Label.new()
	title.text = "Runtime Variable Values"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var clear_btn := Button.new()
	clear_btn.text = "Clear"
	clear_btn.pressed.connect(_on_clear_pressed)
	header.add_child(clear_btn)

	# Tree
	_tree = Tree.new()
	_tree.columns = 4
	_tree.column_titles_visible = true
	_tree.set_column_title(COL_NAME, "Variable")
	_tree.set_column_title(COL_TYPE, "Type")
	_tree.set_column_title(COL_VALUE, "Value")
	_tree.set_column_title(COL_UPDATED, "Updated")
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_tree)

	_root = _tree.create_item()


func _on_clear_pressed() -> void:
	_items_by_id.clear()
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

	item.set_text(COL_TYPE, str(payload.get("type", "")))
	item.set_text(COL_VALUE, str(payload.get("value_str", "")))

	var ticks := payload.get("ticks_msec", null)
	if ticks == null:
		item.set_text(COL_UPDATED, "")
	else:
		item.set_text(COL_UPDATED, str(ticks))
