extends Label
class_name LabelTyper

signal typed
signal played

@export var typing_time: float = 0.5

var initial_text: String = ""
var has_played: bool = false
var individual_key_time: float = 0.0
var current_index: int = 0

var current_timer: SceneTreeTimer

func play_effect() -> void:
	clear_current_timer()
	set_initial_text(text)
	compute_individual_key_time()
	current_index = 0
	text = ""
	type_current_index()

func skip_effect() -> void:
	clear_current_timer()
	current_index = initial_text.length() - 1
	has_played = true
	text = initial_text
	played.emit()

func clear_current_timer() -> void:
	if current_timer and current_timer.timeout.is_connected(type_current_index):
		current_timer.timeout.disconnect(type_current_index)

func set_initial_text(init_text: String) -> void:
	initial_text = init_text

func compute_individual_key_time() -> void:
	individual_key_time = typing_time / initial_text.length()

func type_current_index() -> void:
	if current_index >= initial_text.length():
		has_played = true
		played.emit()
	else:
		text += initial_text[current_index]
		typed.emit(initial_text[current_index])
		current_index += 1
		current_timer = get_tree().create_timer(individual_key_time)
		current_timer.timeout.connect(type_current_index)
