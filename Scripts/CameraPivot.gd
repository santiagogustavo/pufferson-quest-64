extends Marker3D
class_name CameraPivot

@export var look_speed: float = 5.0
@export_range(60.0, 90.0) var look_vertical_clamp_degrees: float = 60.0

@onready var camera: Camera3D = $Camera3D
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var spring_position: Node3D = $SpringArm3D/SpringPosition3D

var reset_rotation: Vector3
var rotation_vector: Vector2

func _ready() -> void:
	reset_rotation = rotation
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	compute_camera()
	update_camera_collision(delta)
	clear_frame_variables()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation_vector.y = deg_to_rad(-event.relative.x)
		rotation_vector.x = deg_to_rad(-event.relative.y)

func compute_camera() -> void:
	rotation_degrees.y += rotation_vector.y * look_speed
	rotation_degrees.x += -rotation_vector.x * look_speed
	rotation_degrees.x = clamp(
		rotation_degrees.x,
		-look_vertical_clamp_degrees,
		look_vertical_clamp_degrees
	)

func update_camera_collision(delta: float) -> void:
	camera.global_transform.origin = lerp(
		camera.global_transform.origin,
		spring_position.global_transform.origin,
		50 * delta
	)

func clear_frame_variables() -> void:
	rotation_vector = Vector2.ZERO
