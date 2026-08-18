extends CharacterBody3D
class_name PlayerCharacter

@export var autocenter_camera: bool = true

@onready var model: Node3D = $Model
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var camera_pivot: CameraPivot = $CameraPivot

var model_pivot: Node3D

var computed_forces: Vector3
var movement_vector: Vector2
var is_walking: bool = false
var is_jumping: bool = false
var jump_height: float = 22
var movement_speed: float = 6
var should_autocenter: bool = true
var movement_locked: bool = true

func _ready() -> void:
	model_pivot = Node3D.new()
	model.add_child(model_pivot)
	computed_forces.y = get_gravity().y

func _process(delta: float) -> void:
	update_internals(delta)
	move_and_slide()

func _physics_process(delta: float) -> void:
	compute_gravity()
	compute_jump(delta)

func update_internals(delta: float) -> void:
	compute_movement(delta)
	compute_camera_autocenter(delta)
	update_animation_tree_variables()

func compute_movement(delta: float) -> void:
	if movement_locked:
		return
	var cam_transform = camera_pivot.global_transform
	var cam_forward = -cam_transform.basis.z
	var cam_right = -cam_transform.basis.x
	cam_forward.y = 0.0
	cam_forward = cam_forward.normalized()
	cam_right.y = 0.0
	cam_right = cam_right.normalized()
	movement_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	movement_vector = movement_vector.normalized()
	is_walking = movement_vector.length() > 0
	var direction = (cam_right * movement_vector.x + cam_forward * movement_vector.y).normalized()
	direction.y = 0.0
	if direction:
		velocity.x = direction.x * movement_speed
		velocity.z = direction.z * movement_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, movement_speed)
		velocity.z = move_toward(velocity.z, 0.0, movement_speed)
	if direction.length():
		model_pivot.look_at(model.global_position - direction)
		model.global_rotation.y = lerp_angle(
			model.global_rotation.y,
			model_pivot.global_rotation.y,
			delta * 10
		)

func compute_camera_autocenter(delta: float) -> void:
	if movement_locked:
		return
	if camera_pivot.rotation_vector.length() > 0 and should_autocenter:
		should_autocenter = false
		get_tree().create_timer(3.0).timeout.connect(func ():
			should_autocenter = true
		)
	elif should_autocenter and movement_vector != Vector2.DOWN:
		var autocenter_speed: float = delta / 2
		camera_pivot.global_rotation.x = lerp_angle(
			camera_pivot.global_rotation.x,
			camera_pivot.reset_rotation.x,
			autocenter_speed,
		)
		camera_pivot.global_rotation.y = lerp_angle(
			camera_pivot.global_rotation.y,
			model.global_rotation.y,
			autocenter_speed,
		)

func compute_jump(delta) -> void:
	is_jumping = is_on_floor() and Input.is_action_just_pressed("jump")
	if is_jumping:
		computed_forces.y += jump_height
	else:
		computed_forces.y = max(get_gravity().y, computed_forces.y - delta * 50)

func compute_gravity() -> void:
	velocity.y = computed_forces.y

func unlock_movement() -> void:
	movement_locked = false

func update_animation_tree_variables() -> void:
	animation_tree.set("parameters/conditions/is_walking", is_walking)
	animation_tree.set("parameters/conditions/is_not_walking", !is_walking)
	animation_tree.set("parameters/conditions/is_jumping", is_jumping)
	animation_tree.set("parameters/conditions/is_not_jumping", is_on_floor())
