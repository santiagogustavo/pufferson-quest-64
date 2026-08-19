extends Node3D
class_name Coin

signal pickup

@onready var area_3d: Area3D = $Area3D
@onready var animation_tree: AnimationTree = $AnimationTree

func _ready() -> void:
	area_3d.body_entered.connect(handle_pickup_coin)

func handle_pickup_coin(_body: Node3D) -> void:
	pickup.emit()
	animation_tree.set("parameters/conditions/is_pickup", true)
	GameManager.update_score(GameManager.score + 1)
