extends Node3D
class_name Wand

@onready var star_shot: PackedScene = load("res://Prefabs/Objects/StarShot.tscn")
@onready var sfx: AudioStreamPlayer3D = $SFX
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")

var target_position: Vector3 = Vector3.FORWARD

func shoot_spell() -> void:
	instantiate_sfx()
	instantiate_star_shot()
	playback.travel("Spell", true)
	animation_tree.set("parameters/Spell/TimeSeek/seek_request", 0.0)

func instantiate_star_shot() -> void:
	var star_shot_instance: StarShot = star_shot.instantiate()
	get_tree().root.add_child(star_shot_instance)
	star_shot_instance.global_position = global_position
	star_shot_instance.look_at(target_position)

func instantiate_sfx() -> void:
	var sfx_instance: AudioStreamPlayer3D = sfx.duplicate()
	sfx_instance.finished.connect(func (): sfx_instance.queue_free())
	add_child(sfx_instance)
	sfx_instance.global_position = sfx.global_position
	sfx_instance.play()
