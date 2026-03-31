extends Control


@export_file("*.tscn") var retry_scene_path: String
@export_node_path("BaseButton") var retry_button: NodePath

var _is_transitioning := false


func _ready() -> void:
	var retry_button_node := get_node_or_null(retry_button) as BaseButton
	if retry_button_node != null:
		retry_button_node.pressed.connect(_on_retry_pressed)


func _on_retry_pressed() -> void:
	if _is_transitioning or retry_scene_path.is_empty():
		return
	_is_transitioning = true
	call_deferred("_change_scene", retry_scene_path)


func _change_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
