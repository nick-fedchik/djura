extends Area2D

class_name QirimliFalcon
const _LevelRoot = preload("res://scripts/level_root.gd")

var velocity: Vector2 = Vector2(-420.0, 60.0)
var time_passed: float = 0.0
var targets_hit: int = 0
var snd_falcon_hit = preload("res://assets/audio/chort_poof.wav")


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	time_passed += delta

	# Наведення Сокола на найближчу Нечисту Силу (Чортика, Відьму, Вогника)
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		var par = _LevelRoot.of(self)
		if par and par.has_node("Enemies"):
			for c in par.get_node("Enemies").get_children():
				if c is FolkloreEnemy and not c.is_queued_for_deletion():
					enemies.append(c)

	var best_target: FolkloreEnemy = null
	var best_dist := 99999.0
	for e in enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion() and not e.is_scared:
			# Пріоритет: Нечиста Сила (Чорт, Відьма, Вогник), а також вороги загалом
			var d := global_position.distance_to(e.global_position)
			if e.enemy_type != FolkloreEnemy.EnemyType.MOSKAL:
				d *= 0.65
			if d < best_dist:
				best_dist = d
				best_target = e

	if best_target and time_passed < 3.0:
		var desired := (best_target.global_position - global_position).normalized() * 440.0
		velocity = velocity.lerp(desired, delta * 7.5)
	elif time_passed >= 2.6:
		# Після очищення арени Сокіл гордо злітає високо в небо
		velocity = velocity.lerp(Vector2(signf(velocity.x) * 320.0, -420.0), delta * 4.0)

	position += velocity * delta

	if time_passed > 4.2 or position.x < -60.0 or position.x > 1020.0 or position.y < -60.0 or position.y > 600.0:
		queue_free()

	queue_redraw()


func _on_area_entered(area: Area2D) -> void:
	if area is FolkloreEnemy:
		_strike_unclean_force(area)


func _strike_unclean_force(enemy: FolkloreEnemy) -> void:
	targets_hit += 1
	var sfx := AudioStreamPlayer2D.new()
	sfx.bus = "Master"
	sfx.stream = snd_falcon_hit
	sfx.position = global_position
	sfx.pitch_scale = 1.45
	sfx.finished.connect(sfx.queue_free)
	get_parent().add_child(sfx)
	sfx.play()

	if enemy.enemy_type == FolkloreEnemy.EnemyType.CHORT:
		enemy._play_poof()
		enemy.defeated.emit(enemy, 500)
		enemy.queue_free()
	else:
		enemy.make_scared(9.5)


func _draw() -> void:
	var fwd := velocity.normalized()
	if fwd.length_squared() < 0.01:
		fwd = Vector2(-1.0, 0.0)
	var ang := fwd.angle()
	draw_set_transform(Vector2.ZERO, ang, Vector2.ONE)

	var flap := sin(time_passed * 28.0) * 12.0
	var c_plumage := Color(0.36, 0.24, 0.16)
	var c_wing_tip := Color(0.18, 0.12, 0.10)
	var c_breast := Color(0.92, 0.84, 0.72)
	var c_gold := Color(1.0, 0.88, 0.25)

	# Золотий сонячний шлейф стрімкого пікірування Сокола
	draw_line(Vector2(-26.0, 0.0), Vector2(6.0, 0.0), Color(1.0, 0.90, 0.35, 0.38), 6.0)

	# Розправлене віяло хвоста
	draw_colored_polygon(
		PackedVector2Array([Vector2(-6.0, 0.0), Vector2(-18.0, -5.5), Vector2(-21.0, 0.0), Vector2(-18.0, 5.5)]), c_plumage
	)

	# Гострі серпоподібні крила сокола-сапсана (верхнє і нижнє)
	draw_colored_polygon(
		PackedVector2Array([Vector2(2.0, -2.0), Vector2(-4.0, -16.0 - flap * 0.7), Vector2(-12.0, -22.0 - flap), Vector2(-8.0, -3.0)]),
		c_plumage
	)
	draw_line(Vector2(2.0, -2.0), Vector2(-12.0, -22.0 - flap), c_wing_tip, 2.0)

	draw_colored_polygon(
		PackedVector2Array([Vector2(2.0, 2.0), Vector2(-4.0, 16.0 + flap * 0.7), Vector2(-12.0, 22.0 + flap), Vector2(-8.0, 3.0)]),
		c_plumage
	)
	draw_line(Vector2(2.0, 2.0), Vector2(-12.0, 22.0 + flap), c_wing_tip, 2.0)

	# Обтічний тулуб і світлі груди в цятку
	_draw_oval(Vector2(0.0, 0.0), 9.5, 4.2, c_plumage)
	_draw_oval(Vector2(2.5, 0.0), 6.0, 3.0, c_breast)

	# Голова сокола, хижий золотий дзьоб і зірке око
	draw_circle(Vector2(8.5, 0.0), 3.6, c_wing_tip)
	draw_colored_polygon(PackedVector2Array([Vector2(11.5, -1.6), Vector2(16.0, 0.0), Vector2(11.5, 1.6)]), c_gold)
	draw_circle(Vector2(9.5, -1.2), 1.1, c_gold)
	draw_circle(Vector2(9.7, -1.2), 0.5, Color.BLACK)

	# Іскри святого вогню проти нечисті
	var spk := Vector2(-14.0 + sin(time_passed * 35.0) * 4.0, cos(time_passed * 30.0) * 5.0)
	draw_circle(spk, 1.6, Color(1.0, 0.96, 0.55))


func _draw_oval(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	var num_pts := 14
	for i in range(num_pts):
		var phi := float(i) / float(num_pts) * TAU
		pts.append(center + Vector2(cos(phi) * rx, sin(phi) * ry))
	draw_colored_polygon(pts, color)
