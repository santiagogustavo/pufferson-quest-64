extends CanvasLayer
class_name PauseMenu

@export var buttons: Array[PauseMenuButton]
@onready var animation_tree: AnimationTree = $Control/AnimationTree

func _ready() -> void:
	for button in buttons:
		button.mouse_entered.connect(func():
			button.grab_focus()
		)
		button.pressed.connect(func ():
			handle_button_action(button.button_action)
		)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		GameManager.toggle_pause()
	get_tree().paused = GameManager.is_paused
	update_animation_tree()

func update_animation_tree() -> void:
	animation_tree.set("parameters/conditions/is_paused", GameManager.is_paused)
	animation_tree.set("parameters/conditions/is_not_paused", !GameManager.is_paused)

func handle_button_action(action: PauseMenuButton.Action) -> void:
	match action:
		PauseMenuButton.Action.Resume:
			GameManager.toggle_pause()
		PauseMenuButton.Action.Exit:
			get_tree().quit()
	
