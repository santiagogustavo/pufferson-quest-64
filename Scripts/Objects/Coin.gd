extends RigidBody3D
class_name Coin

signal pickup

@export var blow_up_on_start: bool = false

@onready var area_3d: Area3D = $Area3D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var blow_up_sfx: AudioStreamPlayer3D = $BlowUpSFX
var has_picked_up: bool = false

func _ready() -> void:
	if blow_up_on_start:
		apply_force(Vector3(0.0, 75.0, 0.0))
		blow_up_sfx.play()
	area_3d.body_entered.connect(handle_pickup_coin)

func handle_pickup_coin(body: Node3D) -> void:
	if body is not PlayerCharacter or has_picked_up:
		return
	freeze = true
	has_picked_up = true
	pickup.emit()
	animation_tree.set("parameters/conditions/is_pickup", true)
	InputManager.vibrate_controller(0, 0.1, 0.0, 0.1)
	GameManager.update_score(GameManager.score + 1)
