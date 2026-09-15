extends Area3D
class_name EnemyScanner

signal enemy_detected
signal enemy_left

var player: PlayerCharacter
var closest_enemy: Node3D = null
var detected_enemies: Array[Node3D] = []

func _ready() -> void:
	body_entered.connect(handle_enemy_detected)
	body_exited.connect(handle_enemy_left)

func _process(_delta: float) -> void:
	if !player:
		return
	compute_closest_enemy()

func compute_closest_enemy() -> void:
	if !detected_enemies.size():
		closest_enemy = null
	for enemy in detected_enemies:
		if !closest_enemy:
			closest_enemy = enemy
		elif (
			enemy.global_position.distance_to(player.global_position)
			< closest_enemy.global_position.distance_to(player.global_position)
			or
			(closest_enemy is BreakableObject and closest_enemy.broken)
		):
			closest_enemy = enemy

func handle_enemy_detected(enemy: Node3D) -> void:
	detected_enemies.append(enemy)
	enemy_detected.emit(enemy)

func handle_enemy_left(enemy: Node3D) -> void:
	var index = detected_enemies.find(enemy)
	detected_enemies.remove_at(index)
	enemy_left.emit(enemy)
