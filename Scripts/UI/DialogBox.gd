extends CanvasLayer

signal ended_talking

@export var speaker_avatar: Texture2D
@export var speaker_name: String
@export var speaker_text: String
@export var bubble_time: float = 1.0
@export var default_speaking_time: float = 2.0
@export var autoplay: bool = true
@export var voice_stream: AudioStream
@export var debug_on_start: bool = false

@onready var avatar_rect: TextureRect = $MarginContainer/Control/BoxContainer/Box/Speaker/Avatar
@onready var speaker_label: Label = $MarginContainer/Control/BoxContainer/Box/Speaker
@onready var text_label: LabelTyper = $MarginContainer/Control/BoxContainer/Box/Text
@onready var voice_sfx: AudioStreamPlayer2D = $MarginContainer/Control/BoxContainer/Box/Voice
@onready var animation_tree: AnimationTree = $MarginContainer/AnimationTree
@onready var skip_label: InputInstruction = $MarginContainer/Control/BoxContainer/Box/SkipLabel

var is_talking: bool = false
var current_timer: SceneTreeTimer
static var instance: DialogBox

func _init() -> void:
	instance = self

func _ready() -> void:
	GameManager.dialog.connect(handle_receive_dialog_from_game_manager)
	text_label.typed.connect(handle_text_typed)
	if debug_on_start:
		handle_receive_dialog_from_game_manager(
			speaker_name,
			speaker_text,
			default_speaking_time,
			voice_stream,
		)

func _process(_delta: float) -> void:
	animation_tree.set("parameters/conditions/is_talking", is_talking)
	animation_tree.set("parameters/conditions/is_not_talking", !is_talking)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		handle_skip()

func handle_skip() -> void:
	if autoplay:
		return
	if !text_label.has_played:
		text_label.skip_effect()
	else:
		end_talking()

func handle_receive_dialog_from_game_manager(
	speaker: String,
	text: String,
	talk_time: float = default_speaking_time,
	voice: AudioStream = voice_stream,
	avatar: Texture2D = speaker_avatar,
	skippable: bool = !autoplay
) -> void:
	autoplay = !skippable
	skip_label.visible = !autoplay
	reset_animation_tree()
	speaker_avatar = avatar
	speaker_name = speaker
	speaker_text = text
	voice_stream = voice
	start_talking(talk_time)

func reset_animation_tree() -> void:
	var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
	playback.travel("Start", true)
	if current_timer and current_timer.timeout.is_connected(end_talking):
		current_timer.timeout.disconnect(end_talking)

func start_talking(talk_time: float) -> void:
	is_talking = true
	if speaker_avatar:
		avatar_rect.texture = speaker_avatar
	if speaker_name:
		speaker_label.text = speaker_name
	if speaker_text:
		text_label.text = speaker_text
	if voice_stream:
		(voice_sfx.stream as AudioStreamRandomizer).set("stream_0/stream", voice_stream)
	text_label.typing_time = talk_time
	text_label.play_effect()
	if autoplay:
		current_timer = get_tree().create_timer(bubble_time + talk_time)
		current_timer.timeout.connect(end_talking)

func end_talking() -> void:
	ended_talking.emit()
	is_talking = false

func handle_text_typed(typed: String) -> void:
	if typed != " ":
		voice_sfx.play()
