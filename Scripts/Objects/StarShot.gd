extends Node3D
class_name StarShot

@export var speed: float = 30.0
@export var lifetime: float = 2.0

@onready var collider: Area3D = $Area3D
@onready var hit_particles: GPUParticles3D = $HitParticles

func _ready() -> void:
	collider.body_entered.connect(handle_shot_collision)
	get_tree().create_timer(lifetime).timeout.connect(func ():
		if self:
			self.queue_free()
	)

func _physics_process(delta: float) -> void:
	position += transform.basis * Vector3(0, 0, -1) * speed * delta

func handle_shot_collision(body: Node3D) -> void:
	if body is BreakableObject:
		body.handle_projectile_hit()
	var hit_particles_instance = hit_particles.duplicate()
	get_tree().root.add_child(hit_particles_instance)
	hit_particles_instance.global_position = global_position
	hit_particles_instance.global_rotation = global_rotation
	hit_particles_instance.emitting = true
	(hit_particles_instance.get_child(0) as AudioStreamPlayer3D).play()
	queue_free()
