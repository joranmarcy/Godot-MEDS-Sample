@tool
extends EditorPlugin

const _EXTENSIONS_PLUGIN_NAME := "Godot Flow Extensions"
const _DebuggerMessageSilencer := preload("res://addons/godot_flow_core/scripts/utils/debugger_message_silencer.gd")

var _debugger_silencer: EditorDebuggerPlugin = null
var _last_extensions_enabled: bool = false

func _enter_tree() -> void:
	print("Godot Flow Core: plugin loaded")
	_last_extensions_enabled = _is_extensions_enabled()
	_update_debugger_silencer(_last_extensions_enabled)
	set_process(true)

func _exit_tree() -> void:
	set_process(false)
	_update_debugger_silencer(true) # force remove
	print("Godot Flow Core: plugin unloaded")


func _process(_delta: float) -> void:
	var enabled := _is_extensions_enabled()
	if enabled == _last_extensions_enabled:
		return
	_last_extensions_enabled = enabled
	_update_debugger_silencer(enabled)


func _is_extensions_enabled() -> bool:
	var ei := get_editor_interface()
	if ei != null and ei.has_method("is_plugin_enabled"):
		# Godot identifies plugins slightly differently across versions (name vs folder).
		# Try a few common identifiers.
		if bool(ei.call("is_plugin_enabled", _EXTENSIONS_PLUGIN_NAME)):
			return true
		if bool(ei.call("is_plugin_enabled", "godot_flow_extensions")):
			return true
		if bool(ei.call("is_plugin_enabled", "res://addons/godot_flow_extensions")):
			return true
		return false
	# Best-effort fallback: if we can't determine, assume enabled so we don't
	# interfere with the extensions debugger.
	return true


func _update_debugger_silencer(extensions_enabled: bool) -> void:
	# If extensions is enabled, don't intercept messages; let the real debugger plugin handle them.
	if extensions_enabled:
		if _debugger_silencer != null:
			remove_debugger_plugin(_debugger_silencer)
			_debugger_silencer = null
		return

	# Extensions disabled: add a lightweight capture to consume messages and silence warnings.
	if _debugger_silencer == null:
		_debugger_silencer = _DebuggerMessageSilencer.new()
		add_debugger_plugin(_debugger_silencer)

