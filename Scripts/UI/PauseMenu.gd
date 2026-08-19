extends CanvasLayer
class_name PauseMenu

@onready var animation_tree: AnimationTree = $Control/AnimationTree

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		GameManager.toggle_pause()
	get_tree().paused = GameManager.is_paused
	update_animation_tree()

func update_animation_tree() -> void:
	animation_tree.set("parameters/conditions/is_paused", GameManager.is_paused)
	animation_tree.set("parameters/conditions/is_not_paused", !GameManager.is_paused)
