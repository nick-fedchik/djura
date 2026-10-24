extends Node2D
# Мавка (лісова чарівниця, «Лісова пісня»): союзниця, що вперше з'являється на рівні 5 (GDD, SHR-001 I-1).
# Ширяє поруч із Джурою й періодично відводить чарами найближчого ворога: той лякається й тікає.

const _LevelRoot = preload("res://scripts/level_root.gd")
const SPELL_INTERVAL: float = 9.0
const SPELL_FEAR_S: float = 6.0
const FOLLOW_OFFSET: Vector2 = Vector2(-80.0, -46.0)

var time_passed: float = 0.0
var spell_timer: float = 4.0
var cast_flash: float = 0.0
var facing_dir: float = 1.0
var _player_ref: Node2D = null
var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	_player_ref = get_tree().root.find_child("Player", true, false) as Node2D

func _process(delta: float) -> void:
	time_passed += delta
	cast_flash = maxf(0.0, cast_flash - delta)
	var target := position
	if _player_ref != null and is_instance_valid(_player_ref):
		var side := -1.0 if _player_ref.global_position.x > 480.0 else 1.0
		target = _player_ref.global_position + Vector2(FOLLOW_OFFSET.x * side, FOLLOW_OFFSET.y) + Vector2(0.0, sin(time_passed * 1.7) * 6.0)
	var step := (target - position) * minf(1.0, delta * 2.2)
	velocity = step / maxf(delta, 0.0001)
	position += step
	if absf(step.x) > 0.05:
		facing_dir = signf(step.x)
	spell_timer -= delta
	if spell_timer <= 0.0:
		spell_timer = SPELL_INTERVAL
		cast_spell()
	queue_redraw()

# Чари: лякає найближчого ворога, що ще не наляканий. true, якщо чари подіяли.
func cast_spell() -> bool:
	var root_node := _LevelRoot.of(self)
	if root_node == null or not root_node.has_node("Enemies"):
		return false
	var best: FolkloreEnemy = null
	var best_d := 1e9
	for c in root_node.get_node("Enemies").get_children():
		if c is FolkloreEnemy and not c.is_queued_for_deletion() and not c.is_scared:
			var d := global_position.distance_to(c.global_position)
			if d < best_d:
				best_d = d
				best = c
	if best == null:
		return false
	best.make_scared(SPELL_FEAR_S)
	cast_flash = 0.7
	return true

func _draw_oval(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * float(i) / 20.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, color)

func _draw() -> void:
	var fwd := facing_dir
	var float_y := sin(time_passed * 3.0) * 2.4
	var sway := sin(time_passed * 2.4) * 3.0
	# М'яке лісове сяйво навколо (прозоре, без контуру)
	draw_circle(Vector2(0, float_y), 25.0 + sin(time_passed * 3.0) * 1.5, Color(0.55, 1.0, 0.85, 0.12))
	if cast_flash > 0.0:
		var r := 30.0 + (0.7 - cast_flash) * 70.0
		draw_arc(Vector2(0, float_y), r, 0.0, TAU, 28, Color(0.7, 1.0, 0.9, cast_flash * 0.6), 2.0)
	# Довге розвіяне волосся (темно-зелене) позаду
	var hair_col := Color(0.12, 0.30, 0.24)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5.0 * fwd, -17.0 + float_y), Vector2((-15.0 + sway) * fwd, -3.0 + float_y),
		Vector2((-12.0 + sway * 1.4) * fwd, 12.0 + float_y), Vector2(-1.0 * fwd, -2.0 + float_y)
	]), hair_col)
	# Біла серпанкова сукня-хвиля з бірюзовим відтінком
	var gown := Color(0.92, 0.98, 0.96)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-3.5, -9.0 + float_y), Vector2(3.5, -9.0 + float_y),
		Vector2(11.0 + sway * 0.5, 14.0 + float_y), Vector2(0.0, 17.0 + float_y), Vector2(-11.0 + sway * 0.5, 14.0 + float_y)
	]), gown)
	draw_line(Vector2(-8.0 + sway * 0.4, 11.0 + float_y), Vector2(8.0 + sway * 0.4, 11.0 + float_y), Color(0.55, 0.85, 0.78), 1.6)
	# Рука з сяючим польовим квітом
	var hand := Vector2(10.0 * fwd, -8.0 + float_y + sin(time_passed * 4.0) * 1.5)
	draw_line(Vector2(2.5 * fwd, -7.0 + float_y), hand, Color(0.98, 0.84, 0.72), 2.0)
	draw_circle(hand + Vector2(0, -2.5), 3.0, Color(1.0, 0.95, 0.5, 0.9))
	draw_circle(hand + Vector2(0, -2.5), 1.4, Color(1.0, 0.45, 0.55))
	# Голова
	_draw_oval(Vector2(0, -13.0 + float_y), 5.4, 5.8, Color(0.98, 0.84, 0.72))
	draw_circle(Vector2(2.0 * fwd, -13.5 + float_y), 0.9, Color(0.1, 0.2, 0.3))
	draw_arc(Vector2(2.4 * fwd, -11.2 + float_y), 1.4, 0.2, PI - 0.2, 6, Color(0.7, 0.3, 0.3), 1.0)
	# Вінок із польових квітів і полину
	for i in 5:
		var a := PI + 0.3 + float(i) * (PI - 0.6) / 4.0
		var p := Vector2(cos(a) * 5.6, -13.0 + float_y + sin(a) * 6.0)
		draw_circle(p, 1.7, [Color(1.0, 0.45, 0.55), Color(1.0, 0.9, 0.3), Color(0.5, 0.75, 1.0), Color(1.0, 0.45, 0.55), Color(1.0, 0.9, 0.3)][i])
	# Рух: дві іскорки позаду
	for j in 3:
		var t := time_passed * 3.0 + float(j) * 2.1
		draw_circle(Vector2((-14.0 - float(j) * 3.0) * fwd, 4.0 + float_y + sin(t) * 5.0), 1.0, Color(0.8, 1.0, 0.9, 0.45))
