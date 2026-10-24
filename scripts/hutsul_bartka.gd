extends Area2D

class_name HutsulBartka

var start_pos: Vector2 = Vector2.ZERO
var target_pos: Vector2 = Vector2.ZERO
var time_passed: float = 0.0
var flight_duration: float = 0.65
var snd_hit = preload("res://assets/audio/chort_poof.wav")

func _ready() -> void:
	start_pos = global_position
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	time_passed += delta
	var u := clampf(time_passed / flight_duration, 0.0, 1.0)
	# Одноразовий прицільний кидок бартки по дузі прямо у злодія!
	var arc_lift := sin(u * PI) * -32.0
	global_position = start_pos.lerp(target_pos, u) + Vector2(0.0, arc_lift)
	
	if time_passed >= flight_duration:
		queue_free()
	
	queue_redraw()

func _on_area_entered(area: Area2D) -> void:
	if area is FolkloreEnemy:
		_hit_enemy(area)

func _hit_enemy(enemy: FolkloreEnemy) -> void:
	if enemy.enemy_type == FolkloreEnemy.EnemyType.CHORT:
		enemy._play_poof()
		enemy.defeated.emit(enemy, 500)
		enemy.queue_free()
	else:
		enemy.make_scared(9.0)
	var sfx := AudioStreamPlayer2D.new()
	sfx.bus = "Master"
	sfx.stream = snd_hit
	sfx.position = global_position
	sfx.pitch_scale = 1.18
	sfx.finished.connect(sfx.queue_free)
	get_parent().add_child(sfx)
	sfx.play()
	queue_free()

func _draw() -> void:
	var rot := time_passed * 28.0
	draw_set_transform(Vector2.ZERO, rot, Vector2.ONE)
	
	# Сяючий вихор обертання гуцульської бартки
	draw_arc(Vector2.ZERO, 13.5, 0.0, TAU, 16, Color(1.0, 0.88, 0.28, 0.38), 2.5)
	
	# Різьблене ясенове топорище бартки з мосяжною оковкою
	draw_line(Vector2(0, -11), Vector2(0, 11), Color(0.52, 0.32, 0.16), 2.8)
	draw_line(Vector2(0, -4), Vector2(0, 4), Color(0.95, 0.78, 0.18), 3.0)
	
	# Мосяжне (латунне) лезо гуцульської барткою з обушком-келепом
	var brass_col := Color(0.98, 0.84, 0.22)
	var brass_hi := Color(1.0, 0.96, 0.65)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -9.0),
		Vector2(9.5, -12.5),
		Vector2(10.5, -4.5),
		Vector2(0.0, -5.5)
	]), brass_col)
	draw_line(Vector2(9.5, -12.5), Vector2(10.5, -4.5), brass_hi, 1.8)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -8.5),
		Vector2(-5.5, -9.5),
		Vector2(-5.5, -6.0),
		Vector2(0.0, -6.0)
	]), brass_col)
