extends StaticBody3D
class_name BreakableObject

@export var health: int = 1

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var coin_prefab: PackedScene = load("res://Prefabs/Objects/Coin.tscn")

var broken: bool = false

func _process(_delta: float) -> void:
	if health <= 0:
		handle_break_object()

func handle_projectile_hit(damage = 1) -> void:
	if broken:
		return
	health -= damage
	playback.travel("Hit")

func handle_break_object() -> void:
	if broken:
		return
	broken = true
	playback.travel("Break")
	var coin_instance: Coin = coin_prefab.instantiate()
	coin_instance.blow_up_on_start = true
	get_tree().root.add_child(coin_instance)
	coin_instance.global_position = global_position
