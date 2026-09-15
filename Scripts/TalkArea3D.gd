extends Area3D
class_name TalkArea3D

@export var stop_and_wait: bool = false
@export var lines: Array[DialogLine] = []
@export var skippable: bool = false

var current_line: int = -1
var current_body: PlayerCharacter

var is_playing: bool = false

func _ready() -> void:
	if lines.size() == 0:
		return
	body_entered.connect(handle_play_dialog)
	body_exited.connect(handle_player_exited)
	DialogBox.instance.ended_talking.connect(handle_line_ended)

func handle_play_dialog(body: PlayerCharacter) -> void:
	if !current_body:
		current_body = body
	current_line = 0
	is_playing = true
	if stop_and_wait:
		current_body.lumina.start_talking()
		body.movement_locked = true
		body.talk_camera_pivot.talking_targets = [body.model, body.lumina.model]
		if !body.is_on_floor() and !body.floored.is_connected(handle_stop_and_play):
			body.floored.connect(handle_stop_and_play)
		else:
			handle_stop_and_play()
	else:
		play_current_dialog()

func handle_player_exited(_body: PlayerCharacter) -> void:
	pass

func play_current_dialog() -> void:
	if stop_and_wait and current_body:
		match lines[current_line].character:
			Definitions.Characters.Pufferson:
				current_body.talk_camera_pivot.current_talking_target = 0
			Definitions.Characters.Lumina:
				current_body.talk_camera_pivot.current_talking_target = 1
	GameManager.emit_dialog(
		lines[current_line].character,
		lines[current_line].line,
		lines[current_line].talk_time,
		skippable
	)

func handle_stop_and_play() -> void:
	current_body.switch_camera_smooth(current_body.talk_camera_pivot.camera)
	get_tree().create_timer(0.25).timeout.connect(func ():
		play_current_dialog()
	)

func handle_line_ended() -> void:
	if current_line == lines.size() - 1:
		is_playing = false
		if !current_body:
			return
		if current_body.floored.is_connected(handle_stop_and_play):
			current_body.floored.disconnect(handle_stop_and_play)
		if stop_and_wait:
			current_body.lumina.end_talking()
			await current_body.switch_camera_smooth(current_body.camera_pivot.camera)
			current_body.movement_locked = false
	else:
		current_line += 1
		await get_tree().create_timer(0.2).timeout
		play_current_dialog()
