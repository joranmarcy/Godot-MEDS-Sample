@tool
extends Object


static func select_resource_in_editor(editor_interface: Object, path: String) -> void:
	# Best-effort: mimic selecting the resource in the editor.
	# 1) Focus the resource in the Inspector (edit_resource)
	# 2) Highlight it in the FileSystem dock (select_file)
	if editor_interface == null:
		return

	var normalized := (path if path != null else "")
	normalized = String(normalized).replace("\\", "/")
	if normalized == "":
		return

	focus_inspector_tab(editor_interface)

	var res: Resource = null
	if ResourceLoader.exists(normalized):
		res = load(normalized)
	if res != null and editor_interface.has_method("edit_resource"):
		editor_interface.call("edit_resource", res)

	select_file_in_filesystem_dock(editor_interface, normalized)


static func select_file_in_filesystem_dock(editor_interface: Object, path: String) -> void:
	if editor_interface == null:
		return
	var normalized := (path if path != null else "")
	normalized = String(normalized).replace("\\", "/")
	if normalized == "":
		return

	# Prefer the higher-level API if present.
	if editor_interface.has_method("select_file"):
		editor_interface.call("select_file", normalized)
		return

	if not editor_interface.has_method("get_file_system_dock"):
		return
	var fs_dock: Variant = editor_interface.call("get_file_system_dock")
	if fs_dock == null:
		return
	if fs_dock.has_method("select_file"):
		fs_dock.call("select_file", normalized)


static func focus_inspector_tab(editor_interface: Object) -> void:
	# The Inspector is not a "main screen" (2D/3D/Script), it's a dock tab.
	# Godot doesn't expose a stable API to focus it across all 4.x builds,
	# so we do a best-effort UI search for a TabContainer/TabBar tab titled "Inspector".
	if editor_interface == null:
		return
	if not editor_interface.has_method("get_base_control"):
		return
	var base: Variant = editor_interface.call("get_base_control")
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
