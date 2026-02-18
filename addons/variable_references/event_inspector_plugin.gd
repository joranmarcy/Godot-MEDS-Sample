@tool
extends EditorInspectorPlugin


var _owner_plugin: EditorPlugin


func _init(owner_plugin: EditorPlugin = null) -> void:
	_owner_plugin = owner_plugin


func _can_handle(object: Object) -> bool:
	if object == null:
		return false

	# Prefer a duck-typed check so this also works for remote-inspected objects.
	if object.has_method("raise_event") and object.has_signal("event_raised"):
		return true

	# Fallback: check by script global name when possible.
	if object is Resource:
		var res := object as Resource
		var script := res.get_script()
		if script != null and script.has_method("get_global_name"):
			return String(script.get_global_name()) == "Event"

	return false


func _parse_begin(object: Object) -> void:
	var raise_button := Button.new()
	raise_button.text = "Raise Event"
	raise_button.tooltip_text = "Emit this Event's event_raised signal."
	raise_button.pressed.connect(Callable(self, "_on_raise_pressed").bind(object))
	add_custom_control(raise_button)


func _on_raise_pressed(object: Object) -> void:
	if not is_instance_valid(object):
		return
	# In the editor, this Resource instance is not the same as the running game's instance.
	# Send a debugger message so the running game can raise its cached resource.
	if _owner_plugin != null and _owner_plugin.has_method("request_raise_event_resource"):
		_owner_plugin.call("request_raise_event_resource", object)
		return
	push_warning("Events: cannot raise event (missing owner plugin reference).")
