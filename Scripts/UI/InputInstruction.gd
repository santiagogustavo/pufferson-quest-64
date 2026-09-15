extends HBoxContainer
class_name InputInstruction

enum InputAction {
	UI_ACCEPT,
	INTERACT,
}

const InputActionKeys: Dictionary = {
	InputAction.UI_ACCEPT: "ui_accept",
	InputAction.INTERACT: "interact",
}

@export var actions: Array[InputAction]
@export var custom_label_translation: String
@onready var rect_template: InputIconTextureRect = $InputIconTextureRect
@onready var label: Label = $Label

func _ready() -> void:
	for action in actions:
		add_input_icon_rect(action, 0)
		if custom_label_translation:
			label.text = tr(custom_label_translation)
		else:
			label.text = tr(InputActionKeys[action])
	rect_template.visible = false
	move_child(label, get_child_count() - 1)

func add_input_icon_rect(action: InputAction, event_index: int = 0) -> InputIconTextureRect:
	var rect: InputIconTextureRect = rect_template.duplicate()
	rect.action_name = InputActionKeys[action]
	rect.event_index = event_index
	add_child(rect)
	return rect
