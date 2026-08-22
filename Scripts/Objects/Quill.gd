extends Node3D
class_name Quill

signal pickup

@onready var area_3d: Area3D = $Area3D
@onready var animation_tree: AnimationTree = $AnimationTree
var has_picked_up: bool = false

func _ready() -> void:
	area_3d.body_entered.connect(handle_pickup_quill)

func handle_pickup_quill(_body: Node3D) -> void:
	if has_picked_up:
		return
	has_picked_up = true
	pickup.emit()
	animation_tree.set("parameters/conditions/is_pickup", true)
	InputManager.vibrate_controller(0, 1.0, 0.0, 0.1)
	GameManager.update_life(GameManager.lives + 1)
