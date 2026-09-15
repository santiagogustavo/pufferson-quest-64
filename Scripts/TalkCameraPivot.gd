extends Marker3D
class_name TalkCameraPivot

@export var talking_targets: Array[Node3D] = []
@onready var subpivot: Node3D = Node3D.new()
@onready var camera: Camera3D = $Camera3D
var current_talking_target: int = -1

func _ready() -> void:
	subpivot.top_level = true
	add_child(subpivot)

func _process(delta: float) -> void:
	subpivot.global_position = camera.global_position
	if current_talking_target != -1:
		subpivot.look_at(Vector3(
			talking_targets[current_talking_target].global_position.x,
			talking_targets[current_talking_target].global_position.y + 0.75,
			talking_targets[current_talking_target].global_position.z,
		))
		camera.global_rotation = Vector3(
			lerp_angle(camera.global_rotation.x, subpivot.global_rotation.x, delta * 15),
			lerp_angle(camera.global_rotation.y, subpivot.global_rotation.y, delta * 15),
			lerp_angle(camera.global_rotation.z, subpivot.global_rotation.z, delta * 15),
		)
