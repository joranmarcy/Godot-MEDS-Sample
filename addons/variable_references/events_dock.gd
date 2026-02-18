@tool
extends VBoxContainer


signal events_list_requested(session_id: int)


const COL_NAME := 0
const COL_TYPE := 1
const COL_LISTENERS := 2
const COL_RAISED := 3
const COL_LAST_RAISED := 4
const COL_UPDATED := 5


var _tree: Tree
var _root: TreeItem
var _items_by_id: Dictionary = {}
var _last_session_id := 0


func _ready() -> void:
	# Header
	var header := HBoxContainer.new()
	add_child(header)

	var title := Label.new()
	title.text = "Runtime Events"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var refresh_btn := Button.new()
	refresh_btn.text = "Refresh"
	refresh_btn.pressed.connect(_on_refresh_pressed)
	header.add_child(refresh_btn)

	var clear_btn := Button.new()
	clear_btn.text = "Clear"
	clear_btn.pressed.connect(_on_clear_pressed)
	header.add_child(clear_btn)

	# Tree
	_tree = Tree.new()
	_tree.columns = 6
	_tree.column_titles_visible = true
	_tree.set_column_title(COL_NAME, "Event")
	_tree.set_column_title(COL_TYPE, "Type")
	_tree.set_column_title(COL_LISTENERS, "Listeners")
	_tree.set_column_title(COL_RAISED, "Raised")
	_tree.set_column_title(COL_LAST_RAISED, "Last Raised")
	_tree.set_column_title(COL_UPDATED, "Updated")
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_tree)

	_root = _tree.create_item()


func _on_clear_pressed() -> void:
	_items_by_id.clear()
	_last_session_id = 0
	_tree.clear()
	_root = _tree.create_item()


func _on_refresh_pressed() -> void:
	if _last_session_id == 0:
		push_warning("Events: no active debug session yet. Run the game with the debugger attached.")
		return
	events_list_requested.emit(_last_session_id)


func on_event_updated(payload: Dictionary) -> void:
	# payload format (best-effort):
	#  id, path, name, type, listener_count, raised_count, last_raised_ticks, ticks_msec, session_id
	_last_session_id = int(payload.get("session_id", _last_session_id))

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
	item.set_text(COL_LISTENERS, str(payload.get("listener_count", "")))
	item.set_text(COL_RAISED, str(payload.get("raised_count", 0)))

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
