extends Node3D
class_name Lumina

@onready var model: Node3D = $Model
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")

var is_talking: bool = false
var is_interacting: bool = false

func _ready() -> void:
	if get_parent():
		top_level = true

func _process(delta: float) -> void:
	update_follow(delta)
	update_animation_tree()

func update_follow(delta: float) -> void:
	var parent = get_parent()
	if !parent:
		return
	global_position = lerp(global_position, parent.global_position, delta * 5)
	global_rotation = Vector3(
		lerp_angle(global_rotation.x, parent.global_rotation.x, delta * 5),
		lerp_angle(global_rotation.y, parent.global_rotation.y, delta * 5),
		lerp_angle(global_rotation.z, parent.global_rotation.z, delta * 5),
	)

func update_animation_tree() -> void:
	animation_tree.set("parameters/conditions/finished_dialog", !is_talking)
	animation_tree.set("parameters/conditions/finished_interact", !is_interacting)

func start_talking() -> void:
	is_talking = true
	update_animation_tree()
	playback.travel("DialogPopIn")

func end_talking() -> void:
	is_talking = false

func start_interacting() -> void:
	is_interacting = true
	update_animation_tree()
	playback.travel("InteractPopIn")

func end_interacting() -> void:
	is_interacting = false
