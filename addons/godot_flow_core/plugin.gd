@tool
extends EditorPlugin

func _enter_tree() -> void:
	print("Godot Flow Core: plugin loaded")

func _exit_tree() -> void:
	print("Godot Flow Core: plugin unloaded")

