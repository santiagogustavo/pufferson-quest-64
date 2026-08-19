extends CanvasLayer
class_name HUD

@onready var time_label = $MarginContainer/Control/TimeContainer/Label
@onready var life_label = $MarginContainer/Control/LifeContainer/Label
@onready var coin_label = $MarginContainer/Control/CoinsContainer/Control/Label

func _process(_delta: float) -> void:
	compute_time_label()
	compute_life_label()
	compute_coin_label()

func compute_time_label() -> void:
	time_label.text = GameManager.time_string

func compute_life_label() -> void:
	life_label.text = str(GameManager.lives).pad_zeros(2)

func compute_coin_label() -> void:
	coin_label.text = str(GameManager.score).pad_zeros(3)
