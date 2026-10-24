extends Area2D

class_name VakulaHorseshoeItem

signal collected(item: VakulaHorseshoeItem)
signal stolen_by_enemy(item: VakulaHorseshoeItem, enemy: Node2D)

var velocity: Vector2 = Vector2(60.0, 50.0)
var time_passed: float = 0.0
var pulse_speed: float = 5.0
var enemy_grab_grace_timer: float = 2.0

@onready var col_shape: CollisionShape2D = $CollisionShape2D
var snd_anvil = preload("res://assets/audio/vakula_anvil.wav")

func _ready() -> void:
	body_entered.connect(_on_body_entered, CONNECT_DEFERRED)
	area_entered.connect(_on_area_entered, CONNECT_DEFERRED)
	var ang := randf_range(0.0, TAU)
	velocity = Vector2(cos(ang), sin(ang)) * 75.0

func _process(delta: float) -> void:
	time_passed += delta
	if enemy_grab_grace_timer > 0.0:
		enemy_grab_grace_timer -= delta
	position += velocity * delta
	
	# Bounce off arena boundaries (960x540 2K 16:9 widescreen)
	if position.x < 30.0:
		position.x = 30.0
		velocity.x = abs(velocity.x)
	elif position.x > 930.0:
		position.x = 930.0
		velocity.x = -abs(velocity.x)
	
	if position.y < 45.0:
		position.y = 45.0
		velocity.y = abs(velocity.y)
	elif position.y > 495.0:
		position.y = 495.0
		velocity.y = -abs(velocity.y)
	
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body is JackPlayer:
		_play_anvil()
		collected.emit(self)
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if enemy_grab_grace_timer > 0.0:
		return
	if area is FolkloreEnemy and not area.is_scared and not area.has_stolen_artifact:
		area.apply_stolen_artifact_buff(6.5)
		stolen_by_enemy.emit(self, area)
		queue_free()

func _play_anvil() -> void:
	var sfx := AudioStreamPlayer2D.new()
	sfx.bus = "Master"
	sfx.stream = snd_anvil
	sfx.position = global_position
	sfx.finished.connect(sfx.queue_free)
	get_parent().add_child(sfx)
	sfx.play()

func _draw() -> void:
	var pulse := 1.0 + sin(time_passed * pulse_speed) * 0.15
	var bob := sin(time_passed * 6.0) * 2.5
	
	# 1. Золота сяюча аура ковальського вогню
	draw_circle(Vector2(0, bob), 20.0 * pulse, Color(1.0, 0.75, 0.15, 0.22))
	draw_circle(Vector2(0, bob), 13.0 * pulse, Color(1.0, 0.90, 0.35, 0.35))
	
	# 2. Золота підківка Вакули
	var gold_col := Color(1.0, 0.85, 0.20)
	var gold_shadow := Color(0.72, 0.52, 0.10)
	var gold_highlight := Color(1.0, 1.0, 0.70)
	
	# Малюємо дугу підкови з товстими лініями
	var outer_pts := PackedVector2Array()
	var num_pts := 14
	var r := 11.0
	for i in range(num_pts + 1):
		var phi := PI * 0.2 + (float(i) / float(num_pts)) * (PI * 1.6)
		outer_pts.append(Vector2(cos(phi) * r, sin(phi) * r + bob))
	
	# Тіло підкови
	for i in range(outer_pts.size() - 1):
		draw_line(outer_pts[i], outer_pts[i + 1], gold_shadow, 4.8)
		draw_line(outer_pts[i], outer_pts[i + 1], gold_col, 3.4)
		draw_line(outer_pts[i] - Vector2(0, 0.8), outer_pts[i + 1] - Vector2(0, 0.8), gold_highlight, 1.2)
	
	# Шипи / загини на кінцях підкови (вушка)
	draw_circle(outer_pts[0], 2.8, gold_col)
	draw_circle(outer_pts[-1], 2.8, gold_col)
	
	# Отвори для ухналів (ковальських цвяхів)
	for i in [2, 5, 8, 11]:
		if i < outer_pts.size():
			draw_circle(outer_pts[i], 1.1, Color(0.20, 0.12, 0.05))
