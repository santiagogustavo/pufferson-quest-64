extends Marker3D
class_name CameraPivot

@export var look_speed: float = 5.0
@export var follow_camera: bool = true
@export_range(60.0, 90.0) var look_vertical_clamp_degrees: float = 60.0

@onready var camera: Camera3D = $Camera3D
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var spring_position: Node3D = $SpringArm3D/SpringPosition3D
@onready var initial_offset: Vector3 = global_position

var reset_rotation: Vector3
var rotation_vector: Vector2

func _ready() -> void:
	top_level = follow_camera
	reset_rotation = rotation
	global_rotation = reset_rotation

func _process(delta: float) -> void:
	compute_camera()
	compute_look_stick()
	compute_follow(delta)
	update_camera_collision(delta)
	clear_frame_variables()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation_vector.y = deg_to_rad(-event.relative.x)
		rotation_vector.x = deg_to_rad(-event.relative.y)

func compute_follow(delta: float) -> void:
	if !follow_camera:
		return
	var parent: Node3D = get_parent()
	global_position = lerp(global_position, parent.global_position + initial_offset, delta * 10)

func compute_camera() -> void:
	rotation_degrees.y += rotation_vector.y * look_speed
	rotation_degrees.x += -rotation_vector.x * look_speed
	rotation_degrees.x = clamp(
		rotation_degrees.x,
		-look_vertical_clamp_degrees,
		look_vertical_clamp_degrees
	)

func compute_look_stick() -> void:
	var look_dir = Input.get_vector("look_left", "look_right", "look_up", "look_down", 0.2)
	var stick_sensitivity: float = 50.0
	rotation_degrees.y += deg_to_rad(-look_dir.x) * stick_sensitivity
	rotation_degrees.x += deg_to_rad(look_dir.y) * stick_sensitivity

func update_camera_collision(delta: float) -> void:
	camera.global_transform.origin = lerp(
		camera.global_transform.origin,
		spring_position.global_transform.origin,
		50 * delta
	)

func clear_frame_variables() -> void:
	rotation_vector = Vector2.ZERO
