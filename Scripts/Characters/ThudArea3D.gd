extends Area3D
class_name ThudArea3D

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")

func _ready() -> void:
	top_level = true
	monitoring = false
	body_entered.connect(handle_target_collision)

func start_monitoring(impact_point: Vector3) -> void:
	global_position = impact_point
	monitoring = true
	playback.travel("Impact")
	get_tree().create_timer(0.1).timeout.connect(func ():
		monitoring = false
	)

func handle_target_collision(body: Node3D) -> void:
	if body is BreakableObject:
		body.handle_projectile_hit(2)
