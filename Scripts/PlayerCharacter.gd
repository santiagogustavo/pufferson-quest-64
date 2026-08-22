extends CharacterBody3D
class_name PlayerCharacter

@export var autocenter_camera: bool = false

@onready var model: Node3D = $Model
@onready var ghost_trail: GhostTrail = $GhostTrail
@onready var wand: Wand = $Model/Armature/Skeleton3D/RightHand/Offset/Wand
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var camera_pivot: CameraPivot = $CameraPivot
@onready var voice: AudioStream = load("uid://b154fct8cmqtk")
@onready var walk_sfx: AudioStreamPlayer3D = $Model/Walk
@onready var impact_particle: GPUParticles3D = $Model/Impact
@onready var impact_dust_particle: GPUParticles3D = $Model/ImpactDust

var model_pivot: Node3D

var computed_forces: Vector3
var movement_vector: Vector2
var is_walking: bool = false
var is_jumping: bool = false
var is_double_jumping: bool = false
var can_double_jump: bool = true
var jump_height: float = 22
var movement_speed: float = 6
var should_autocenter: bool = true
var movement_locked: bool = true
var is_dashing: bool = false
var is_shooting_spell: bool = false
var can_shoot_spell: bool = true
var shoot_spell_ratio: float = 0.4
var is_thudding: bool = false

var force: Vector3 = Vector3.ZERO
var friction: float = 50.0

func _ready() -> void:
	model_pivot = Node3D.new()
	model.add_child(model_pivot)
	computed_forces.y = get_gravity().y

func _process(delta: float) -> void:
	update_internals(delta)
	move_and_slide()

func _physics_process(delta: float) -> void:
	compute_jump()
	compute_dash()
	compute_gravity(delta)
	compute_movement(delta)
	compute_forces(delta)
	if is_on_floor():
		apply_thud_impact()

func update_internals(delta: float) -> void:
	compute_shoot_spell()
	compute_thud()
	compute_camera_autocenter(delta)
	update_animation_tree_variables(delta)

func compute_movement(delta: float) -> void:
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
	if movement_locked:
		direction = Vector3.ZERO
	direction.y = 0.0
	if direction:
		velocity.x = direction.x * movement_speed
		velocity.z = direction.z * movement_speed
	else:
		velocity.x = move_toward(direction.x, 0.0, movement_speed)
		velocity.z = move_toward(direction.z, 0.0, movement_speed)
	if direction.length():
		model_pivot.look_at(model.global_position - direction)
		model.global_rotation.y = lerp_angle(
			model.global_rotation.y,
			model_pivot.global_rotation.y,
			delta * 50
		)

func compute_forces(delta: float) -> void:
	force.x = compensate_friction(force.x, delta)
	force.y = compensate_friction(force.y, delta)
	force.z = compensate_friction(force.z, delta)
	var local_x_direction = model.global_transform.basis * Vector3.LEFT
	var local_z_direction = model.global_transform.basis * Vector3.BACK
	velocity += local_x_direction * force.x
	velocity += local_z_direction * force.z
	velocity.y += force.y

func apply_force(applied_force: Vector3) -> void:
	force += applied_force

func compensate_friction(value: float, delta: float) -> float:
	var friction_delta = friction * delta
	if value < -friction_delta:
		return value + friction_delta
	elif value > friction_delta:
		return value - friction_delta
	else:
		return 0

func compute_dash() -> void:
	var can_dash: bool = !is_dashing
	if Input.is_action_just_pressed("dash") and can_dash:
		ghost_trail.play_effect()
		is_dashing = true
		InputManager.vibrate_controller(0, 0.5, 0.5, 0.2)
		apply_force(Vector3(0.0, 0.0, 20.0))
		get_tree().create_timer(ghost_trail.total_time).timeout.connect(func ():
			is_dashing = false
		)

func compute_camera_autocenter(delta: float) -> void:
	if !autocenter_camera:
		return
	if camera_pivot.rotation_vector.length() > 0 and should_autocenter:
		should_autocenter = false
		get_tree().create_timer(3.0).timeout.connect(func ():
			should_autocenter = true
		)
	elif should_autocenter and movement_vector != Vector2.DOWN:
		var autocenter_speed: float = delta
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

func compute_jump() -> void:
	is_jumping = is_on_floor() and Input.is_action_just_pressed("jump")
	is_double_jumping = can_double_jump and !is_on_floor() and Input.is_action_just_pressed("jump")
	if is_double_jumping:
		can_double_jump = false
	if is_on_floor():
		can_double_jump = true
	if is_jumping:
		playback.travel("Jump", true)
	if is_double_jumping:
		playback.travel("DoubleJump", true)

func compute_shoot_spell() -> void:
	if movement_locked:
		return
	is_shooting_spell = (
		Input.is_action_just_pressed("shoot_spell")
		and is_on_floor()
		and !is_dashing
		and can_shoot_spell
	)
	if is_shooting_spell:
		can_shoot_spell = false
		get_tree().create_timer(shoot_spell_ratio).timeout.connect(func ():
			can_shoot_spell = true
		)
		wand.shoot_spell()
		playback.travel("Spell", true)
		animation_tree.set("parameters/Spell/TimeSeek/seek_request", 0.0)

func compute_thud() -> void:
	if Input.is_action_just_pressed("thud"):
		playback.travel("Thud", true)
		movement_locked = true
		get_tree().create_timer(0.3).timeout.connect(func ():
			is_thudding = true
		)

func apply_thud_impact() -> void:
	if !is_thudding:
		return
	is_thudding = false
	impact_particle.emitting = true
	impact_dust_particle.emitting = true
	InputManager.vibrate_controller(0, 0.0, 1.0, 0.1)

func apply_jump_force() -> void:
	computed_forces.y += jump_height

func compute_gravity(delta) -> void:
	velocity.y = computed_forces.y + force.y
	computed_forces.y = max(get_gravity().y, computed_forces.y - delta * 50)

func play_walk_sound() -> void:
	if !is_walking:
		return
	walk_sfx.play()

func unlock_movement() -> void:
	movement_locked = false

func update_animation_tree_variables(delta: float) -> void:
	var walk_blend: float = lerp(animation_tree.get("parameters/Walk/blend_position"), 1.0 if is_walking else 0.0, delta * 10)
	animation_tree.set("parameters/Walk/blend_position", walk_blend)
	animation_tree.set("parameters/Spell/BlendSpace1D/blend_position", walk_blend)
	animation_tree.set("parameters/conditions/is_walking", is_walking)
	animation_tree.set("parameters/conditions/is_not_walking", !is_walking)
	animation_tree.set("parameters/conditions/is_dashing", is_dashing)
	animation_tree.set("parameters/conditions/is_not_dashing", !is_dashing)
	animation_tree.set("parameters/conditions/is_jumping", is_jumping)
	animation_tree.set("parameters/conditions/is_double_jumping", is_double_jumping)
	animation_tree.set("parameters/conditions/is_not_jumping", is_on_floor())
	animation_tree.set("parameters/conditions/is_not_double_jumping", !is_double_jumping)
	animation_tree.set("parameters/conditions/is_shooting_spell", is_shooting_spell)
	animation_tree.set("parameters/conditions/is_not_shooting_spell", !is_shooting_spell)
