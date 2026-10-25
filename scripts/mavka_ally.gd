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
var ally_kind: String = "MAVKA" # "MAVKA" (L5), "DOMOVYK" (L15), "KOBZAR" (L16), "VAKULA" (L17)
var is_celebrating_victory: bool = false
var dance_time: float = 0.0

func _ready() -> void:
	_player_ref = get_tree().root.find_child("Player", true, false) as Node2D

func get_victory_dance_name() -> String:
	match ally_kind:
		"DOMOVYK":
			return "domovyk_hearth_hop"
		"KOBZAR":
			return "kobzar_bandura_kozachok"
		"VAKULA":
			return "vakula_forge_hopak"
		_:
			return "mavka_vesnianka_wreath"

func celebrate_victory() -> void:
	is_celebrating_victory = true
	velocity = Vector2.ZERO
	dance_time = randf_range(0.0, 0.4)
	queue_redraw()

func _process(delta: float) -> void:
	time_passed += delta
	cast_flash = maxf(0.0, cast_flash - delta)
	if is_celebrating_victory:
		dance_time += delta
		queue_redraw()
		return
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
	match ally_kind:
		"DOMOVYK":
			_draw_domovyk()
			return
		"KOBZAR":
			_draw_kobzar()
			return
		"VAKULA":
			_draw_vakula()
			return
	var fwd := facing_dir
	var float_y := sin(dance_time * 7.5) * -5.2 if is_celebrating_victory else sin(time_passed * 3.0) * 2.4
	var sway := sin(dance_time * 7.5) * 6.5 if is_celebrating_victory else sin(time_passed * 2.4) * 3.0
	if cast_flash > 0.0:
		var r := 18.0 + (0.7 - cast_flash) * 24.0
		draw_arc(Vector2(0, float_y), r, 0.0, TAU, 28, Color(0.7, 1.0, 0.9, 0.95), 2.0)
	if is_celebrating_victory:
		# Переможний танок Мавки «Лісова Веснянка-Хоровод з Віночком»: квітуча дуга над головою та пелюстки!
		for p_i in 6:
			var ang := dance_time * 4.5 + float(p_i) * TAU / 6.0
			var pet_p := Vector2(cos(ang) * 16.0, float_y - 4.0 + sin(ang) * 10.0)
			draw_circle(pet_p, 2.0, Color(0.45, 1.0, 0.72) if p_i % 2 == 0 else Color(1.0, 0.92, 0.35))
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
	if is_celebrating_victory:
		# Обидві руки високо підняті з квітучою гірляндою-веснянкою над головою
		var h_l := Vector2(-11.5, -18.5 + float_y + sin(dance_time * 7.5) * 2.5)
		var h_r := Vector2(11.5, -18.5 + float_y - sin(dance_time * 7.5) * 2.5)
		draw_line(Vector2(-3.0, -7.0 + float_y), h_l, Color(0.98, 0.84, 0.72), 2.2)
		draw_line(Vector2(3.0, -7.0 + float_y), h_r, Color(0.98, 0.84, 0.72), 2.2)
		draw_arc(Vector2(0.0, -18.5 + float_y), 11.5, PI, TAU, 14, Color(0.32, 0.88, 0.52), 2.4)
		for f_i in 5:
			var fx := -9.0 + float(f_i) * 4.5
			var fy := -23.0 + float_y + absf( float(f_i - 2) ) * 1.4
			draw_circle(Vector2(fx, fy), 2.1, Color(1.0, 0.92, 0.32) if f_i % 2 == 0 else Color(1.0, 0.48, 0.62))
	else:
		# Рука з сяючим польовим квітом
		var hand := Vector2(10.0 * fwd, -8.0 + float_y + sin(time_passed * 4.0) * 1.5)
		draw_line(Vector2(2.5 * fwd, -7.0 + float_y), hand, Color(0.98, 0.84, 0.72), 2.0)
		draw_circle(hand + Vector2(0, -2.5), 3.0, Color(1.0, 0.95, 0.5, 0.95))
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

# ----------------------------------------------------------------------------
# СОЮЗНИКИ АКТІВ 3–4 (T-023): ДОМОВИК (L15), КОБЗАР (L16), ВАКУЛА (L17)
# Чисті геометричні функції виступів для Anti-Clipping (I-4)
# ----------------------------------------------------------------------------
const ALLY_HEAD_RX: float = 6.5
const ALLY_HEAD_RY: float = 6.2

static func domovyk_ears_points(fwd: float, bob: float) -> Array:
	return [
		[Vector2(-4.0 * fwd, -12.0 + bob), Vector2(-8.2 * fwd, -15.5 + bob), Vector2(-10.5 * fwd, -18.5 + bob)],
		[Vector2(4.0 * fwd, -12.0 + bob), Vector2(8.2 * fwd, -15.5 + bob), Vector2(10.5 * fwd, -18.5 + bob)],
	]

static func kobzar_bandura_points(fwd: float, bob: float) -> Array:
	return [
		[Vector2(-4.2 * fwd, -11.5 + bob), Vector2(-9.5 * fwd, -16.0 + bob), Vector2(-12.5 * fwd, -20.0 + bob)],
		[Vector2(4.2 * fwd, -11.5 + bob), Vector2(9.5 * fwd, -16.0 + bob), Vector2(12.5 * fwd, -20.0 + bob)],
	]

static func vakula_hammer_points(fwd: float, bob: float) -> Array:
	return [
		[Vector2(-4.2 * fwd, -11.5 + bob), Vector2(-9.0 * fwd, -16.5 + bob), Vector2(-12.0 * fwd, -21.0 + bob)],
		[Vector2(4.2 * fwd, -11.5 + bob), Vector2(9.0 * fwd, -16.5 + bob), Vector2(12.0 * fwd, -21.0 + bob)],
	]

func _draw_domovyk() -> void:
	var fwd := facing_dir
	var bob := -absf(sin(dance_time * 9.0)) * 5.5 if is_celebrating_victory else sin(time_passed * 3.2) * 2.0
	for e_p in domovyk_ears_points(fwd, bob):
		draw_line(e_p[0], e_p[1], Color(0.75, 0.58, 0.38), 2.8)
		draw_line(e_p[1], e_p[2], Color(0.88, 0.72, 0.48), 2.2)
	_draw_oval(Vector2(0, 2.0 + bob), 8.5, 9.0, Color(0.68, 0.48, 0.28)) # Кожушок Домовика
	_draw_oval(Vector2(0, -9.0 + bob), ALLY_HEAD_RX, ALLY_HEAD_RY, Color(0.96, 0.82, 0.70))
	_draw_oval(Vector2(0, -4.5 + bob), 6.2, 4.5, Color(0.92, 0.90, 0.85)) # Пишна сива борода
	if is_celebrating_victory:
		# Переможний танок Домовика: присядка з дерев'яною ложкою та глиняним горщиком меду!
		var kick := sin(dance_time * 9.0) * 5.0
		draw_line(Vector2(-3.5, 10.0 + bob), Vector2(-7.5 - kick, 16.5), Color(0.45, 0.28, 0.14), 3.2)
		draw_line(Vector2(3.5, 10.0 + bob), Vector2(7.5 + kick, 16.5), Color(0.45, 0.28, 0.14), 3.2)
		var spoon_top := Vector2(13.5, -14.0 + bob + kick * 0.4)
		draw_line(Vector2(6.5, -1.0 + bob), spoon_top, Color(0.82, 0.58, 0.24), 2.4)
		draw_circle(spoon_top, 3.0, Color(0.95, 0.76, 0.22))
		_draw_oval(Vector2(-12.0, -5.0 + bob - kick * 0.3), 4.2, 4.6, Color(0.76, 0.38, 0.18)) # Горщик узвару/меду

func _draw_kobzar() -> void:
	var fwd := facing_dir
	var bob := -absf(sin(dance_time * 8.4)) * 5.0 if is_celebrating_victory else sin(time_passed * 2.8) * 1.8
	for b_p in kobzar_bandura_points(fwd, bob):
		draw_line(b_p[0], b_p[1], Color(0.55, 0.34, 0.16), 3.0)
		draw_line(b_p[1], b_p[2], Color(0.72, 0.48, 0.22), 2.4)
	_draw_oval(Vector2(0, 2.5 + bob), 8.2, 9.5, Color(0.32, 0.36, 0.44)) # Свита Кобзаря
	_draw_oval(Vector2(3.5 * fwd, 3.0 + bob), 5.2, 6.5, Color(0.68, 0.44, 0.20)) # Корпус кобзи-бандури
	_draw_oval(Vector2(0, -9.0 + bob), ALLY_HEAD_RX, ALLY_HEAD_RY, Color(0.96, 0.82, 0.70))
	if is_celebrating_victory:
		# Переможний танок Кобзаря «Козачок із Золотою Бандурою»: золоті струни й музичні кільця-ноти!
		var step_k := sin(dance_time * 8.4) * 4.5
		draw_line(Vector2(-3.5, 11.0 + bob), Vector2(-6.5 + step_k, 17.5), Color(0.58, 0.16, 0.16), 3.2)
		draw_line(Vector2(3.5, 11.0 + bob), Vector2(6.5 - step_k, 17.5), Color(0.58, 0.16, 0.16), 3.2)
		for n_i in 3:
			var r_note := 10.0 + float(n_i) * 5.0 + fmod(dance_time * 12.0, 5.0)
			draw_arc(Vector2(3.5 * fwd, 2.0 + bob), r_note, -1.1, 1.1, 10, Color(1.0, 0.88, 0.25, 0.85), 1.8)

func _draw_vakula() -> void:
	var fwd := facing_dir
	var bob := -absf(sin(dance_time * 9.2)) * 6.2 if is_celebrating_victory else sin(time_passed * 3.4) * 2.0
	for h_p in vakula_hammer_points(fwd, bob):
		draw_line(h_p[0], h_p[1], Color(0.48, 0.32, 0.18), 3.0)
		draw_line(h_p[1], h_p[2], Color(0.52, 0.56, 0.64), 3.6)
	_draw_oval(Vector2(0, 2.5 + bob), 8.8, 9.5, Color(0.52, 0.26, 0.16)) # Ковальський фартух Вакули
	_draw_oval(Vector2(0, -9.0 + bob), ALLY_HEAD_RX, ALLY_HEAD_RY, Color(0.96, 0.82, 0.70))
	if is_celebrating_victory:
		# Переможний танок Вакули «Ковальський Гопак з Молотом і Золотою Підківкою»!
		var split := absf(sin(dance_time * 9.2)) * 7.5
		draw_line(Vector2(-4.0, 11.0 + bob), Vector2(-8.0 - split, 17.0 - split * 0.5), Color(0.20, 0.24, 0.34), 3.4)
		draw_line(Vector2(4.0, 11.0 + bob), Vector2(8.0 + split, 17.0 - split * 0.5), Color(0.20, 0.24, 0.34), 3.4)
		var shoe_pos := Vector2(-13.0 * fwd, -15.5 + bob)
		draw_line(Vector2(-5.5 * fwd, -2.0 + bob), shoe_pos, Color(0.96, 0.82, 0.70), 2.8)
		draw_arc(shoe_pos + Vector2(0.0, -3.5), 4.2, 0.35, TAU - 0.35, 10, Color(1.0, 0.90, 0.22), 2.4) # Золота підківка в руці!
