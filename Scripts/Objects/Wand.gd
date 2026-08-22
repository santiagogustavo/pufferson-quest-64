extends Node3D
class_name Wand

@onready var sfx: AudioStreamPlayer3D = $SFX
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")

func shoot_spell() -> void:
	instantiate_sfx()
	playback.travel("Spell", true)
	animation_tree.set("parameters/Spell/TimeSeek/seek_request", 0.0)

func instantiate_sfx() -> void:
	var sfx_instance: AudioStreamPlayer3D = sfx.duplicate()
	sfx_instance.finished.connect(func (): sfx_instance.queue_free())
	add_child(sfx_instance)
	sfx_instance.global_position = sfx.global_position
	sfx_instance.play()
