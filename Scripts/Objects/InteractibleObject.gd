extends Area3D
class_name InteractibleObject

signal interact

@export var interact_box: InteractBox
@onready var body_entered_connect = body_entered.connect(handle_player_entered)
@onready var body_exited_connect = body_exited.connect(handle_player_exited)

var player_is_in: bool = false
var current_body: PlayerCharacter

func _input(event: InputEvent) -> void:
	if !player_is_in:
		return
	if event.is_action_pressed("interact"):
		interact.emit()
		handle_player_exited(current_body)

func handle_player_entered(body: PlayerCharacter) -> void:
	body.lumina.start_interacting()
	current_body = body
	interact_box.is_popped = true
	player_is_in = true

func handle_player_exited(body: PlayerCharacter) -> void:
	current_body = null
	body.lumina.end_interacting()
	interact_box.is_popped = false
	player_is_in = false
