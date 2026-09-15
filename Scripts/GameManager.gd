extends Node

signal dialog

@export var lives: int = 3
@export var score: int = 0

var is_paused: bool = false
var time_elapsed: float = 0.0
var time_string: String = "00:00"

func _ready() -> void:
	#TranslationServer.set_locale("en")
	update_mouse_mode()

func _process(delta: float) -> void:
	time_elapsed += delta
	time_string = format_time(time_elapsed)

func emit_dialog(
	speaker_name: Definitions.Characters,
	speaker_text: String,
	talk_time: float,
	skippable: bool = false,
) -> void:
	var speaker_voice: AudioStream = load(Definitions.CharacterVoices[speaker_name])
	var speaker_avatar: Texture2D = load(Definitions.CharacterAvatars[speaker_name])
	dialog.emit(
		Definitions.CharacterNames[speaker_name],
		speaker_text,
		talk_time,
		speaker_voice,
		speaker_avatar,
		skippable,
	)

func update_life(value: int) -> void:
	lives = value

func update_score(value: int) -> void:
	score = value

func toggle_pause() -> void:
	is_paused = !is_paused
	update_mouse_mode()

func update_mouse_mode() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_paused else Input.MOUSE_MODE_CAPTURED

func format_time(seconds: float) -> String:
	var mins := int(seconds / 60.0)
	var secs := int(fmod(seconds, 60.0))
	#var msecs := int(fmod(seconds, 1.0) * 100)
	return "%02d:%02d" % [mins, secs]
