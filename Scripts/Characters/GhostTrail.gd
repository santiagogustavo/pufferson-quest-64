extends Node3D
class_name GhostTrail

@export var total_time: float = 0.5
@export var ghost_meshes: Array[MeshInstance3D]
@export var dash_particle: GPUParticles3D
@export var max_ghosts: int = 5
@export var sfx: AudioStreamPlayer3D

var ghosts: Array[MeshInstance3D] = []
var is_playing_effect: bool = false
var current_index: int = 0

func play_effect() -> void:
	is_playing_effect = true
	instantiate_dash_particle()
	instantiate_sfx()
	create_next_timer()

func instantiate_sfx() -> void:
	if !sfx:
		return
	var sfx_instance = sfx.duplicate()
	sfx_instance.finished.connect(func ():
		sfx_instance.queue_free()
	)
	add_child(sfx_instance)
	sfx_instance.global_position = sfx.global_position
	sfx_instance.play()

func instantiate_dash_particle() -> void:
	if !dash_particle:
		return
	var particle_instance: GPUParticles3D = dash_particle.duplicate()
	particle_instance.finished.connect(particle_instance.queue_free)
	add_child(particle_instance)
	particle_instance.global_rotation = dash_particle.global_rotation
	particle_instance.emitting = true

func instantiate_ghost_step() -> void:
	for mesh in ghost_meshes:
		instantiate_ghost_mesh(mesh)
	current_index += 1
	create_next_timer()

func instantiate_ghost_mesh(mesh_instance: MeshInstance3D) -> void:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh_instance.mesh
	get_tree().root.add_child(instance)
	instance.top_level = true
	instance.global_position = mesh_instance.global_position
	instance.global_rotation = mesh_instance.global_rotation
	var instance_material: StandardMaterial3D = StandardMaterial3D.new()
	instance_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	instance_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance_material.albedo_color = get_rainbow_color(current_index, 0.15)
	instance.material_override = instance_material
	ghosts.append(instance)
	get_tree().create_timer(total_time).timeout.connect(func ():
		free_ghost_instance(instance)
	)

func create_next_timer() -> void:
	if ghosts.size() >= max_ghosts - 1:
		current_index = 0
		is_playing_effect = false
	else:
		get_tree().create_timer(total_time / max_ghosts).timeout.connect(instantiate_ghost_step)

func free_ghost_instance(instance: MeshInstance3D) -> void:
	ghosts.remove_at(ghosts.find(instance))
	instance.queue_free()

func get_rainbow_color(index: int, alpha: float) -> Color:
	var step_size: float = 1.0 / max_ghosts
	var hue: float = step_size * index
	return Color.from_hsv(hue, 1.0, 1.0, alpha)
