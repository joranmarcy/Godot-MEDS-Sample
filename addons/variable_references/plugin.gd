@tool
extends EditorPlugin


const VariableReferencesInspectorPlugin := preload("res://addons/variable_references/variable_references_inspector.gd")
const VariableValuesDock := preload("res://addons/variable_references/variable_values_dock.gd")
const VariableValuesDebugger := preload("res://addons/variable_references/variable_values_debugger.gd")


var _context_menu_plugin: EditorContextMenuPlugin
var _connected_rich_text_labels: Array[RichTextLabel] = []
var _is_listening_for_new_nodes := false

var _values_dock: Control
var _values_debugger: EditorDebuggerPlugin


func _enter_tree() -> void:
	print("Variable References: plugin loaded")
	_context_menu_plugin = VariableReferencesInspectorPlugin.new()
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, _context_menu_plugin)

	_values_dock = VariableValuesDock.new()
	_values_dock.name = "Variable Values"
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _values_dock)

	_values_debugger = VariableValuesDebugger.new()
	add_debugger_plugin(_values_debugger)
	# Connect debugger updates to the dock.
	if _values_debugger.has_signal("variable_value_updated"):
		_values_debugger.connect("variable_value_updated", Callable(_values_dock, "on_variable_value_updated"))
	# Connect dock edits back to the running game.
	if _values_dock.has_signal("variable_value_set_requested") and _values_debugger.has_method("request_set_value"):
		_values_dock.connect("variable_value_set_requested", Callable(_values_debugger, "request_set_value"))

	_connect_output_meta_handlers_deferred()
	_listen_for_rich_text_labels()


func _exit_tree() -> void:
	_stop_listening_for_rich_text_labels()
	_disconnect_output_meta_handlers()

	if _values_debugger:
		remove_debugger_plugin(_values_debugger)
		_values_debugger = null
	if _values_dock:
		remove_control_from_docks(_values_dock)
		_values_dock.queue_free()
		_values_dock = null

	if _context_menu_plugin:
		remove_context_menu_plugin(_context_menu_plugin)
		_context_menu_plugin = null


func _connect_output_meta_handlers_deferred() -> void:
	# Defer until the editor UI is fully built.
	call_deferred("_connect_output_meta_handlers")


func _connect_output_meta_handlers() -> void:
	# The editor may build/rebuild the Output dock lazily.
	# Retry a few frames to maximize the chance we catch it.
	for _i in range(5):
		await get_tree().process_frame

	var editor_interface := get_editor_interface()
	if editor_interface == null:
		return
	var base := editor_interface.get_base_control()
	if base == null:
		return

	# Godot's Output panel uses RichTextLabels internally. We attach to all of them
	# and only handle our own meta links (vr://...).
	var labels := base.find_children("*", "RichTextLabel", true, false)
	for n in labels:
		var label := n as RichTextLabel
		if label == null:
			continue
		_connect_label_if_needed(label)


func _listen_for_rich_text_labels() -> void:
	if _is_listening_for_new_nodes:
		return
	get_tree().node_added.connect(Callable(self, "_on_node_added"))
	_is_listening_for_new_nodes = true


func _stop_listening_for_rich_text_labels() -> void:
	if not _is_listening_for_new_nodes:
		return
	var cb := Callable(self, "_on_node_added")
	if get_tree().node_added.is_connected(cb):
		get_tree().node_added.disconnect(cb)
	_is_listening_for_new_nodes = false


func _on_node_added(node: Node) -> void:
	var label := node as RichTextLabel
	if label == null:
		return
	# Only hook labels that live under the editor UI.
	var editor_interface := get_editor_interface()
	if editor_interface == null:
		return
	var base := editor_interface.get_base_control()
	if base == null:
		return
	if not base.is_ancestor_of(label):
		return
	_connect_label_if_needed(label)


func _connect_label_if_needed(label: RichTextLabel) -> void:
	var cb := Callable(self, "_on_output_meta_clicked")
	if label.meta_clicked.is_connected(cb):
		return
	label.meta_clicked.connect(cb)
	_connected_rich_text_labels.append(label)


func _disconnect_output_meta_handlers() -> void:
	var cb := Callable(self, "_on_output_meta_clicked")
	for label in _connected_rich_text_labels:
		if is_instance_valid(label) and label.meta_clicked.is_connected(cb):
			label.meta_clicked.disconnect(cb)
	_connected_rich_text_labels.clear()


func _on_output_meta_clicked(meta: Variant) -> void:
	if typeof(meta) != TYPE_STRING:
		return
	var s := String(meta)
	if not s.begins_with("//open_node?"):
		return

	# print("Variable References: clicked link ", s)

	var q_index := s.find("?")
	if q_index == -1:
		return
	var query := s.substr(q_index + 1)
	var params := _parse_query(query)
	if not (params.has("scene") and params.has("node")):
		return

	var scene_path := String(params["scene"]).uri_decode()
	var node_path := String(params["node"]).uri_decode()
	call_deferred("_open_scene_and_select_node", scene_path, node_path)


func _parse_query(query: String) -> Dictionary:
	var out: Dictionary = {}
	for part in query.split("&", false):
		var eq := part.find("=")
		if eq == -1:
			continue
		var k := part.substr(0, eq)
		var v := part.substr(eq + 1)
		out[k] = v
	return out


func _open_scene_and_select_node(scene_path: String, node_path: String) -> void:
	var editor_interface := get_editor_interface()
	if editor_interface == null:
		return

	if scene_path == "":
		push_warning("Variable References: missing scene path in link")
		return

	# Open the scene first.
	editor_interface.open_scene_from_path(scene_path)

	# Wait a bit for the scene to become the edited scene.
	var root: Node = null
	for _i in range(10):
		await get_tree().process_frame
		root = editor_interface.get_edited_scene_root()
		if root != null:
			# If we can read the file path, ensure it matches.
			if root.has_method("get_scene_file_path"):
				var opened := String(root.get_scene_file_path())
				if opened == "" or opened == scene_path:
					break
			else:
				break

	if root == null:
		push_warning("Variable References: could not open scene " + scene_path)
		return

	var node := _resolve_node_from_logged_path(root, node_path)
	if node == null:
		push_warning("Variable References: node not found in opened scene: " + node_path)
		return

	# Select the node in the SceneTree dock.
	var selection := editor_interface.get_selection()
	if selection != null:
		selection.clear()
		selection.add_node(node)

	# Try to focus/edit it if the API is present.
	if editor_interface.has_method("edit_node"):
		editor_interface.edit_node(node)


func _resolve_node_from_logged_path(root: Node, logged_path: String) -> Node:
	# Logged paths look like "/Root/Child/..." (root name included).
	if logged_path == "" or logged_path == "/":
		return root

	var root_prefix := "/" + root.name
	if logged_path == root_prefix:
		return root

	var rel := ""
	if logged_path.begins_with(root_prefix + "/"):
		rel = logged_path.substr(root_prefix.length() + 1)
	elif logged_path.begins_with("/"):
		# Best effort: strip leading slash and try as relative.
		rel = logged_path.substr(1)
	else:
		rel = logged_path

	if rel == "":
		return root
	return root.get_node_or_null(NodePath(rel))
