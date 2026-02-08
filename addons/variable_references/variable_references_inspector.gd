@tool
extends EditorInspectorPlugin


const MENU_LOG_REFERENCES := 1


func _can_handle(object: Object) -> bool:
	if object == null:
		return false
	if not (object is Resource):
		return false

	var res := object as Resource
	var script := res.get_script()
	if script == null:
		return false

	# Prefer global class_name when present.
	var global_name := ""
	if script.has_method("get_global_name"):
		global_name = script.get_global_name()

	if global_name != "" and global_name.ends_with("Variable"):
		return true

	# Fallback: handle scripts that live under scripts/variables.
	var script_path := ""
	if script is Script:
		script_path = (script as Script).resource_path
	return script_path.begins_with("res://scripts/variables/")


func _parse_begin(object: Object) -> void:
	var res := object as Resource
	if res == null:
		return

	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label := Label.new()
	label.text = "Variable"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	header.add_child(label)

	var menu := MenuButton.new()
	menu.text = "⋮"
	menu.tooltip_text = "Variable actions"
	menu.focus_mode = Control.FOCUS_NONE
	menu.flat = true
	header.add_child(menu)

	var popup := menu.get_popup()
	popup.add_item("Log references", MENU_LOG_REFERENCES)
	popup.id_pressed.connect(func(id: int) -> void:
		match id:
			MENU_LOG_REFERENCES:
				_log_references_for_resource(res)
	)

	add_custom_control(header)


func _log_references_for_resource(res: Resource) -> void:
	if res == null:
		return

	var target_path := res.resource_path
	if target_path == null:
		target_path = ""
	if target_path == "":
		push_warning("Variable References: resource has no resource_path (not saved to disk). Save it as a .tres first.")
		return

	print("Variable References: scanning for ", target_path)
	var results := _find_references_in_project(target_path)
	if results.is_empty():
		print("Variable References: no references found for ", target_path)
		return

	print("Variable References: found ", results.size(), " reference(s) for ", target_path)
	for entry in results:
		print(entry)


func _find_references_in_project(target_path: String) -> Array[String]:
	var files: Array[String] = []
	_gather_project_files("res://", files)

	var out: Array[String] = []
	for file_path in files:
		if not (file_path.ends_with(".tscn") or file_path.ends_with(".tres")):
			continue
		if file_path.ends_with(".import"):
			continue

		var text := _read_text_file(file_path)
		if text == "":
			continue

		if file_path.ends_with(".tscn"):
			out.append_array(_find_in_scene_text(file_path, text, target_path))
		else:
			out.append_array(_find_in_resource_text(file_path, text, target_path))

	return out


func _gather_project_files(dir_path: String, out_files: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return

	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name == "":
			break
		if name.begins_with("."):
			continue

		var full := dir_path.path_join(name)
		if dir.current_is_dir():
			# Skip Godot's internal cache folder.
			if name == ".godot":
				continue
			_gather_project_files(full, out_files)
		else:
			out_files.append(full)
	dir.list_dir_end()


func _read_text_file(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text()


func _find_in_resource_text(file_path: String, text: String, target_path: String) -> Array[String]:
	if text.find(target_path) == -1:
		return []

	# Provide a small amount of context: first matching line number.
	var lines := text.split("\n", false)
	for i in range(lines.size()):
		if lines[i].find(target_path) != -1:
			return ["Resource " + file_path + " references " + target_path + " (line " + str(i + 1) + ")"]
	return ["Resource " + file_path + " references " + target_path]


func _find_in_scene_text(scene_path: String, text: String, target_path: String) -> Array[String]:
	var lines := text.split("\n", false)

	# Pass 1: map ext_resource id -> path
	var ext_ids_for_target: Dictionary = {}
	var re_ext := RegEx.new()
	re_ext.compile('^\\[ext_resource\\s+.*path="([^"]+)".*\\sid="([^"]+)".*\\]$')

	for line in lines:
		var m := re_ext.search(line.strip_edges())
		if m == null:
			continue
		var p := m.get_string(1)
		var id := m.get_string(2)
		if p == target_path:
			ext_ids_for_target[id] = true

	# Fast bail-out if the scene doesn't even mention the target path.
	if ext_ids_for_target.is_empty() and text.find(target_path) == -1:
		return []

	# Pass 2: walk nodes and find ExtResource("id") usage
	var out: Array[String] = []
	var re_node := RegEx.new()
	re_node.compile('^\\[node\\s+.*name="([^"]+)".*?(?:\\s+parent="([^"]+)")?.*\\]$')
	var re_ext_use := RegEx.new()
	re_ext_use.compile('ExtResource\\("([^"]+)"\\)')

	var root_path := ""
	var current_node_path := ""
	for i in range(lines.size()):
		var raw := lines[i]
		var stripped := raw.strip_edges()

		var node_m := re_node.search(stripped)
		if node_m != null:
			var name := node_m.get_string(1)
			var parent := node_m.get_string(2)
			if parent == null:
				parent = ""
			current_node_path = _compute_scene_node_path_with_root(root_path, name, parent)
			if parent == "":
				root_path = current_node_path

			# Node headers can contain ExtResource(...) usage (e.g. instance=ExtResource("...")).
			var use_in_header := re_ext_use.search(stripped)
			while use_in_header != null:
				var id_in_header := use_in_header.get_string(1)
				if ext_ids_for_target.has(id_in_header):
					out.append("Scene " + scene_path + " node " + current_node_path + " references " + target_path + " (line " + str(i + 1) + ")")
					break
				use_in_header = re_ext_use.search(stripped, use_in_header.get_end())
			continue

		if current_node_path == "":
			continue

		var use_m := re_ext_use.search(stripped)
		while use_m != null:
			var id := use_m.get_string(1)
			if ext_ids_for_target.has(id):
				out.append("Scene " + scene_path + " node " + current_node_path + " references " + target_path + " (line " + str(i + 1) + ")")
				break
			use_m = re_ext_use.search(stripped, use_m.get_end())

	# If we couldn't resolve node usage, still report that the scene mentions it.
	if out.is_empty() and text.find(target_path) != -1:
		out.append("Scene " + scene_path + " references " + target_path + " (could not resolve node section)")

	return out


func _compute_scene_node_path_with_root(root_path: String, name: String, parent: String) -> String:
	# In .tscn files:
	# - The root node header has no `parent=`.
	# - `parent="."` means direct child of root.
	# - Other parent values are node paths relative to root.
	if parent == "":
		return "/" + name

	var normalized_root := root_path
	if normalized_root == "":
		normalized_root = "/"  # Fallback (should be set once root node is seen)

	if parent == ".":
		return _normalize_node_path(normalized_root + "/" + name)

	var rel_parent := parent
	if rel_parent.begins_with("/"):
		rel_parent = rel_parent.substr(1)
	return _normalize_node_path(normalized_root + "/" + rel_parent + "/" + name)


func _normalize_node_path(p: String) -> String:
	var out := p
	while out.find("//") != -1:
		out = out.replace("//", "/")
	return out.rstrip("/")
