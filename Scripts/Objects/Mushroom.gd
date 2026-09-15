extends Node3D

@onready var area_3d: Area3D = $Collision
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = (
	animation_tree.get("parameters/playback")
)

func _ready() -> void:
	area_3d.body_entered.connect(handle_area_collision)

func handle_area_collision(body: Node3D) -> void:
	if body is not PlayerCharacter:
		return
	animation_playback.travel("Bounce")
	(body as PlayerCharacter).launch_bounce()
