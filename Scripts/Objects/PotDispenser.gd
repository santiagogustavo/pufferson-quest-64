extends InteractibleObject

@onready var navigation_region: NavigationRegion3D = $NavigationRegion3D
@onready var floor_raycast: RayCast3D = $RayCast3D
@onready var pot_prefab: PackedScene = load("res://Prefabs/Objects/Pot.tscn")
@onready var spawn_flare_prefab: PackedScene = load("res://Prefabs/Particles/SpawnFlare.tscn")

func _ready() -> void:
	interact.connect(handle_spawn_pots)

func handle_spawn_pots() -> void:
	var pot_instance: BreakableObject = pot_prefab.instantiate()
	var spawn_flare_instance: GPUParticles3D = spawn_flare_prefab.instantiate()
	var random_position: Vector3 = NavigationServer3D.region_get_random_point(
		navigation_region.get_rid(),
		navigation_region.navigation_layers,
		true
	)
	floor_raycast.global_position = random_position
	floor_raycast.force_raycast_update()
	if floor_raycast.is_colliding():
		random_position = floor_raycast.get_collision_point()
	get_tree().root.add_child(pot_instance)
	pot_instance.global_position = random_position
	pot_instance.scale = Vector3(0.01, 0.01, 0.01)
	create_tween().tween_property(pot_instance, "scale", Vector3(1.0, 1.0, 1.0), 0.15)
	get_tree().root.add_child(spawn_flare_instance)
	spawn_flare_instance.global_position = random_position
	spawn_flare_instance.emitting = true
