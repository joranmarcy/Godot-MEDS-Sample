extends Node

@export var animation_player: AnimationPlayer
@export var idle_animation_name: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if animation_player.has_animation(idle_animation_name):
		var idle_animation := animation_player.get_animation(idle_animation_name)
		idle_animation.loop_mode = Animation.LOOP_LINEAR

	# Play the idle animation when the scene is ready.
	animation_player.play(idle_animation_name)