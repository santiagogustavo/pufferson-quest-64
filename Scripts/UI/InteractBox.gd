extends Node3D
class_name InteractBox

@export var is_popped: bool = false
@onready var animation_tree: AnimationTree = $AnimationTree

func _process(_delta: float) -> void:
	animation_tree.set("parameters/conditions/is_popped", is_popped)
	animation_tree.set("parameters/conditions/is_not_popped", !is_popped)
