extends Node

@export var animation_player: AnimationPlayer
@export var idle_animation_name: String

@export var health: IntVariable
@export var damage_hit_event: Event


# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	damage_hit_event.event_raised.connect(_on_damage_hit)
	
	if animation_player.has_animation(idle_animation_name):
		var idle_animation := animation_player.get_animation(idle_animation_name)
		idle_animation.loop_mode = Animation.LOOP_LINEAR

	# Play the idle animation when the scene is ready.
	animation_player.play(idle_animation_name)

func _on_damage_hit() -> void:
	health.value -= 10
	
