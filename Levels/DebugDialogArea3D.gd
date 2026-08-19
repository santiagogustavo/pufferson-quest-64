extends Area3D

func _ready() -> void:
	body_entered.connect(handle_play_debug_message)

func handle_play_debug_message(_body: Node3D) -> void:
	GameManager.emit_dialog(
		"Pufferson",
		"...",
		2.0
	)
