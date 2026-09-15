extends CharacterBody3D
class_name PlayerCharacter

signal floored

@export var autocenter_camera: bool = false

@onready var model: Node3D = $Model
@onready var ghost_trail: GhostTrail = $GhostTrail
@onready var wand: Wand = $Model/Armature/Skeleton3D/RightHand/Offset/Wand
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var camera_pivot: CameraPivot = $CameraPivot
@onready var talk_camera_pivot: TalkCameraPivot = $Model/TalkCameraPivot
@onready var voice: AudioStream = load("uid://b154fct8cmqtk")
@onready var walk_sfx: AudioStreamPlayer3D = $Model/Walk
@onready var fall_sfx: AudioStreamPlayer3D = $Model/Fall
@onready var impact_particle: GPUParticles3D = $Model/Impact
@onready var impact_dust_particle: GPUParticles3D = $Model/ImpactDust
@onready var lumina: Lumina = $Model/Lumina
@onready var thud_area_3d: ThudArea3D = $Model/ThudArea3D

@onready var target_raycast: RayCast3D = $Model/TargetRaycast
@onready var enemy_scanner: EnemyScanner = $Model/EnemyScanner
var target_position: Vector3 = Vector3.ZERO

var model_pivot: Node3D

var computed_forces: Vector3 = Vector3.ZERO
var movement_vector: Vector2 = Vector2.ZERO
var is_walking: bool = false
var is_jumping: bool = false
var is_double_jumping: bool = false
var can_double_jump: bool = true
var jump_height: float = 22.0
var movement_speed: float = 6.0
var dash_speed: float = 20.0
var should_autocenter: bool = true
var movement_locked: bool = true
var is_dashing: bool = false
var is_shooting_spell: bool = false
var can_shoot_spell: bool = true
var shoot_spell_ratio: float = 0.4
var is_thudding: bool = false

var movement_direction: Vector3 = Vector3.ZERO
var force: Vector3 = Vector3.ZERO
var friction: float = 50.0

var look_at_enemy_timeout: float = 0.75
var look_at_enemy_timer: SceneTreeTimer
var should_look_at_enemy: bool = false
@onready var last_is_on_floor: bool = is_on_floor()

func _ready() -> void:
	model_pivot = Node3D.new()
	model_pivot.top_level = true
	model.add_child(model_pivot)
	computed_forces.y = get_gravity().y
	enemy_scanner.player = self

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
		if fall_sfx.playing:
			fall_sfx.stop()
		if !last_is_on_floor:
			floored.emit()
	last_is_on_floor = is_on_floor()

func update_internals(delta: float) -> void:
	compute_target()
	compute_shoot_spell()
	compute_thud()
	compute_camera_autocenter(delta)
	update_animation_tree_variables(delta)

func compute_target() -> void:
	if enemy_scanner.closest_enemy:
		target_raycast.look_at(
			enemy_scanner.closest_enemy.global_position + Vector3(0.0, 0.5, 0.0),
			Vector3.UP,
			true
		)
	else:
		target_raycast.rotation_degrees = Vector3.ZERO
	if target_raycast.is_colliding():
		var point = target_raycast.get_collision_point()
		target_position = point
	else:
		target_position = target_raycast.global_basis * target_raycast.target_position

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
	if movement_locked:
		movement_vector = Vector2.ZERO
	is_walking = movement_vector.length() > 0
	movement_direction = (cam_right * movement_vector.x + cam_forward * movement_vector.y).normalized()
	movement_direction.y = 0.0
	if movement_direction:
		velocity.x = movement_direction.x * movement_speed
		velocity.z = movement_direction.z * movement_speed
	else:
		velocity.x = move_toward(movement_direction.x, 0.0, movement_speed)
		velocity.z = move_toward(movement_direction.z, 0.0, movement_speed)
	model_pivot.global_position = model.global_position
	if should_look_at_enemy and enemy_scanner.closest_enemy:
		model_pivot.look_at(
			enemy_scanner.closest_enemy.global_position,
			Vector3.UP,
			true
		)
	elif movement_direction.length() and !should_look_at_enemy:
		model_pivot.look_at(model.global_position + movement_direction, Vector3.UP, true)
	model.global_rotation.y = lerp_angle(
		model.global_rotation.y,
		model_pivot.global_rotation.y,
		delta * 15
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

func launch_bounce() -> void:
	apply_force(Vector3(0.0, 25.0, 0.0))
	InputManager.vibrate_controller(0, 0.5, 0.5, 0.1)
	playback.travel("Launch")

func compensate_friction(value: float, delta: float) -> float:
	var friction_delta = friction * delta
	if value < -friction_delta:
		return value + friction_delta
	elif value > friction_delta:
		return value - friction_delta
	else:
		return 0

func compute_dash() -> void:
	if movement_locked:
		return
	var can_dash: bool = !is_dashing
	if Input.is_action_just_pressed("dash") and can_dash:
		ghost_trail.play_effect()
		is_dashing = true
		InputManager.vibrate_controller(0, 0.5, 0.5, 0.2)
		var dash_direction: Vector3 = Vector3(0.0, 0.0, dash_speed)
		if should_look_at_enemy:
			dash_direction = Vector3(
				movement_vector.x * dash_speed,
				0.0,
				movement_vector.y * dash_speed * -1,
			)
		apply_force(dash_direction)
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
	if movement_locked:
		return
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
		if enemy_scanner.closest_enemy != null:
			should_look_at_enemy = true
			create_or_update_look_at_enemy_timer()
		can_shoot_spell = false
		get_tree().create_timer(shoot_spell_ratio).timeout.connect(func ():
			can_shoot_spell = true
		)
		wand.target_position = target_position
		wand.shoot_spell()
		playback.travel("Spell", true)
		animation_tree.set("parameters/Spell/TimeSeek/seek_request", 0.0)

func compute_thud() -> void:
	if movement_locked:
		return
	if Input.is_action_just_pressed("thud") and !is_thudding:
		playback.travel("Thud", true)
		movement_locked = true
		get_tree().create_timer(0.3).timeout.connect(func ():
			is_thudding = true
		)

func apply_thud_impact() -> void:
	if !is_thudding:
		return
	force.y = 0.0
	is_thudding = false
	impact_particle.emitting = true
	impact_dust_particle.emitting = true
	thud_area_3d.start_monitoring(global_position)
	InputManager.vibrate_controller(0, 0.0, 1.0, 0.15)

func apply_jump_force() -> void:
	computed_forces.y += jump_height

func compute_gravity(delta) -> void:
	velocity.y = computed_forces.y + force.y
	computed_forces.y = max(get_gravity().y, computed_forces.y - delta * 50)

func play_walk_sound() -> void:
	if !is_walking:
		return
	walk_sfx.play()

func create_or_update_look_at_enemy_timer() -> void:
	if look_at_enemy_timer:
		look_at_enemy_timer.timeout.disconnect(clear_should_look_at_enemy)
	look_at_enemy_timer = get_tree().create_timer(look_at_enemy_timeout)
	look_at_enemy_timer.timeout.connect(clear_should_look_at_enemy)

func clear_should_look_at_enemy() -> void:
	should_look_at_enemy = false

func unlock_movement() -> void:
	movement_locked = false

func switch_camera_smooth(target_camera: Camera3D, duration: float = 0.25) -> void:
	var current_cam = get_viewport().get_camera_3d()
	if not current_cam or current_cam == target_camera:
		return
	var transition_camera = current_cam.duplicate()
	get_tree().root.add_child(transition_camera)
		
	# Create a temporary or dedicated transition camera at current pos
	transition_camera.global_transform = current_cam.global_transform
	transition_camera.make_current()
	
	# Animate transform to target camera
	var tween = create_tween().set_parallel(true)
	tween.tween_property(transition_camera, "global_position", target_camera.global_position, duration)
	tween.tween_method(func(weight: float): 
		transition_camera.global_rotation = Vector3(
			lerp_angle(transition_camera.global_rotation.x, target_camera.global_rotation.x, weight),
			lerp_angle(transition_camera.global_rotation.y, target_camera.global_rotation.y, weight),
			lerp_angle(transition_camera.global_rotation.z, target_camera.global_rotation.z, weight)
		),
		0.0, 1.0, duration
	)
	await tween.finished
	target_camera.make_current()
	transition_camera.queue_free()

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
