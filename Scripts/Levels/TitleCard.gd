extends CanvasLayer
class_name TitleCard

@export var level_title: String
@export var level_subtitle: String
@export var popup_delay_msec: float = 1.0

@onready var title_label: Label = $Control/Title
@onready var subtitle_label: Label = $Control/Title/Subtitle
@onready var animation_tree: AnimationTree = $Control/AnimationTree

func _ready() -> void:
	title_label.text = level_title if level_title else title_label.text
	subtitle_label.text = level_subtitle if level_subtitle else subtitle_label.text
	get_tree().create_timer(popup_delay_msec).timeout.connect(handle_play_popup)

func handle_play_popup() -> void:
	animation_tree.set("parameters/conditions/play_popup", true)
