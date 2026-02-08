@tool
extends EditorPlugin


var _context_menu_plugin: EditorContextMenuPlugin


func _enter_tree() -> void:
	_context_menu_plugin = preload("res://addons/variable_references/variable_references_inspector.gd").new()
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, _context_menu_plugin)


func _exit_tree() -> void:
	if _context_menu_plugin:
		remove_context_menu_plugin(_context_menu_plugin)
		_context_menu_plugin = null
