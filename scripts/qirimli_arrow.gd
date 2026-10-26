extends Area2D

class_name QirimliArrow

var velocity: Vector2 = Vector2(480.0, 0.0)
var time_passed: float = 0.0
var snd_arrow_hit = preload("res://assets/audio/chort_poof.wav")


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	time_passed += delta
	position += velocity * delta

	if position.x < 10.0 or position.x > 950.0 or position.y < 10.0 or position.y > 530.0:
		queue_free()

	queue_redraw()


func _on_area_entered(area: Area2D) -> void:
	if area is FolkloreEnemy:
		_hit_enemy(area)


func _on_body_entered(_body: Node2D) -> void:
	# Hits solid obstacles
	queue_free()


func _hit_enemy(enemy: FolkloreEnemy) -> void:
	enemy.make_scared(7.0)
	var sfx := AudioStreamPlayer2D.new()
	sfx.bus = "Master"
	sfx.stream = snd_arrow_hit
	sfx.position = global_position
	sfx.pitch_scale = 1.3
	sfx.finished.connect(sfx.queue_free)
	get_parent().add_child(sfx)
	sfx.play()
	queue_free()


func _draw() -> void:
	var fwd := velocity.normalized()
	var perp := Vector2(-fwd.y, fwd.x)
	var arrow_len := 22.0
	var tip := fwd * (arrow_len * 0.5)
	var tail := -fwd * (arrow_len * 0.5)

	# Сяюча золота комета-шлейф
	draw_line(tail - fwd * 12.0, tip, Color(1.0, 0.88, 0.35, 0.40), 4.0)
	# Дерев'яне ясенове ратище стріли
	draw_line(tail, tip, Color(0.55, 0.38, 0.20), 2.2)
	# Залізний гострий наконечник
	draw_colored_polygon(PackedVector2Array([tip + fwd * 4.0, tip + perp * 2.5, tip - perp * 2.5]), Color(0.90, 0.92, 0.96))
	# Біле лебедине оперення
	draw_line(tail, tail + fwd * 6.0 + perp * 3.0, Color.WHITE, 1.8)
	draw_line(tail, tail + fwd * 6.0 - perp * 3.0, Color.WHITE, 1.8)
	# Золоті чарівні іскри
	var spk := tip + Vector2(sin(time_passed * 30.0), cos(time_passed * 25.0)) * 3.0
	draw_circle(spk, 1.5, Color(1.0, 0.95, 0.50))
