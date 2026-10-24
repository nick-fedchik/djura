extends Area2D

class_name FolkloreEnemy

signal defeated(enemy: FolkloreEnemy, points: int)
signal hit_player(enemy: FolkloreEnemy)
signal stolen_artifact_dropped(drop_pos: Vector2)

enum EnemyType { CHORT, VIDMA, VOGNYK, MOSKAL }

@export var enemy_type: EnemyType = EnemyType.CHORT

var velocity: Vector2 = Vector2(110.0, 90.0)
var time_passed: float = 0.0
var is_scared: bool = false
var scared_timer: float = 0.0
var base_speed: float = 120.0
# Відьми й відьмаки: інженери, що створили чортиків-роботів. Рідші, але міцніші й розумніші (GDD §1.2, SHR-001 I-6)
const VIDMA_ARMOR: int = 2
const VIDMA_REWARD: int = 1200
const VIDMA_ALERT_RADIUS: float = 170.0
var armor: int = 0
var _player_ref: Node2D = null

# Система втоми та короткого перепочинку NPC (Київнаукфільм-анімація відпочинку)
var is_resting: bool = false
var rest_timer: float = 0.0
var stamina_timer: float = 4.5
var fatigue_mult: float = 1.0

# Тимчасова перевага ворога, якщо він перехопив чар-артефакт (Золоті Підківки Вакули)
var has_stolen_artifact: bool = false
var artifact_buff_timer: float = 0.0

var snd_poof = preload("res://assets/audio/chort_poof.wav")

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if enemy_type == EnemyType.VIDMA:
		armor = VIDMA_ARMOR
		_player_ref = get_tree().root.find_child("Player", true, false) as Node2D
	var ang := randf_range(0.2, PI - 0.2)
	velocity = Vector2(cos(ang), sin(ang)).normalized() * base_speed
	stamina_timer = randf_range(3.5, 5.8)

func apply_stolen_artifact_buff(duration: float = 6.5) -> void:
	has_stolen_artifact = true
	artifact_buff_timer = duration
	is_resting = false
	rest_timer = 0.0
	is_scared = false
	scared_timer = 0.0
	fatigue_mult = 1.32 # +32% безвтомний турбо-ривок!
	stamina_timer = duration + 2.0
	queue_redraw()

func start_rest(duration: float = 2.2) -> void:
	if has_stolen_artifact:
		return
	is_resting = true
	rest_timer = duration
	fatigue_mult = 1.0

# Інженерний захисний щит поглинає перші удари: поки він є, відьма не лякається. true = удар поглинуто.
func absorb_strike() -> bool:
	if armor > 0:
		armor -= 1
		return true
	return false

func make_scared(duration: float = 8.0) -> void:
	if has_stolen_artifact:
		# Перший удар або переляк вибиває вкрадений артефакт із рук злодія назад на арену!
		has_stolen_artifact = false
		artifact_buff_timer = 0.0
		fatigue_mult = 1.0
		stolen_artifact_dropped.emit(global_position)
	is_scared = true
	scared_timer = duration
	is_resting = false
	rest_timer = 0.0
	# Панічний біг швидко виснажує сили супротивника — за кілька секунд він захекається!
	stamina_timer = randf_range(2.6, 3.8)
	velocity = -velocity * 0.75 # Reverse direction in panic!

func _process(delta: float) -> void:
	time_passed += delta
	
	if has_stolen_artifact:
		artifact_buff_timer -= delta
		fatigue_mult = 1.32
		is_resting = false
		if artifact_buff_timer <= 0.0:
			has_stolen_artifact = false
			fatigue_mult = 1.0
			start_rest(2.2) # Після закінчення чар-прискорення ворог одразу видихається!
	
	if is_scared:
		scared_timer -= delta
		if scared_timer <= 0.0:
			is_scared = false
			velocity = velocity.normalized() * base_speed
			# Після панічної втечі ворог одразу зупиняється перевести дух!
			start_rest(randf_range(2.0, 2.6))
	
	if is_resting:
		rest_timer -= delta
		if rest_timer <= 0.0:
			is_resting = false
			stamina_timer = randf_range(4.2, 6.4)
			fatigue_mult = 1.0
	elif not has_stolen_artifact:
		# Під час паніки ворог втомлюється ще швидше!
		var drain_rate := 1.35 if is_scared else 1.0
		stamina_timer -= delta * drain_rate
		# Поступове сповільнення перед зупинкою від втоми
		fatigue_mult = clampf(stamina_timer / 1.3, 0.35, 1.0) if stamina_timer < 1.3 else 1.0
		if stamina_timer <= 0.0:
			start_rest(randf_range(2.0, 2.6))
	
	if is_resting:
		# Короткий перепочинок: супротивник зупиняється на місці й важко переводить дух
		if enemy_type == EnemyType.VIDMA or enemy_type == EnemyType.VOGNYK:
			position.y += sin(time_passed * 5.0) * 5.0 * delta
	else:
		match enemy_type:
			EnemyType.VIDMA:
				if is_scared:
					position += velocity * fatigue_mult * delta
				else:
					var flight_dir := signf(velocity.x)
					if absf(flight_dir) < 0.1:
						flight_dir = 1.0
					# Розумніша за чортиків: помічає Джуру й тримає дистанцію
					if _player_ref != null and is_instance_valid(_player_ref) and position.distance_to(_player_ref.global_position) < VIDMA_ALERT_RADIUS:
						flight_dir = signf(position.x - _player_ref.global_position.x)
						if absf(flight_dir) < 0.1:
							flight_dir = 1.0
					position.x += flight_dir * 85.0 * fatigue_mult * delta
					position.y = 90.0 + sin(time_passed * 2.2) * 32.0
					velocity.x = flight_dir * 85.0
					velocity.y = cos(time_passed * 2.2) * 2.2 * 32.0
			EnemyType.VOGNYK:
				var float_speed := (65.0 if not is_scared else 115.0) * fatigue_mult
				var drift := Vector2(sin(time_passed * 1.5), cos(time_passed * 1.8)) * 16.0
				position += (velocity.normalized() * float_speed + drift) * delta
			EnemyType.CHORT:
				var speed := (base_speed if not is_scared else (base_speed * 1.35)) * fatigue_mult
				position += velocity.normalized() * speed * delta
			EnemyType.MOSKAL:
				# Неповороткий патрульний крок царського стрільця, а при переляку — панічний спринт!
				var speed := (base_speed * 0.75 if not is_scared else (base_speed * 1.55)) * fatigue_mult
				position += velocity.normalized() * speed * delta
	
	# Bounce off arena boundaries (960x540 2K 16:9 widescreen)
	if position.x < 32.0:
		position.x = 32.0
		velocity.x = abs(velocity.x)
	elif position.x > 928.0:
		position.x = 928.0
		velocity.x = -abs(velocity.x)
	
	if enemy_type == EnemyType.VIDMA and not is_scared:
		position.y = clamp(position.y, 45.0, 150.0)
	else:
		if position.y < 45.0:
			position.y = 45.0
			velocity.y = abs(velocity.y)
		elif position.y > 495.0:
			position.y = 495.0
			velocity.y = -abs(velocity.y)
	
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body is JackPlayer:
		if is_scared or body.is_charakterite:
			# Banished by Cossack / Charakterite power!
			_play_poof()
			var reward := 600 if enemy_type == EnemyType.MOSKAL else (VIDMA_REWARD if enemy_type == EnemyType.VIDMA else 500)
			defeated.emit(self, reward)
			queue_free()
		else:
			# Hits player
			hit_player.emit(self)
			body.take_hit(global_position)

func _play_poof() -> void:
	var sfx := AudioStreamPlayer2D.new()
	sfx.bus = "Master"
	sfx.stream = snd_poof
	sfx.position = global_position
	sfx.finished.connect(sfx.queue_free)
	get_parent().add_child(sfx)
	sfx.play()

func _draw() -> void:
	if is_resting:
		var breath := sin(time_passed * 9.0)
		draw_set_transform(Vector2(0.0, 2.4 + breath * 1.1), 0.0, Vector2(1.0 + breath * 0.08, 1.0 - breath * 0.08))
	else:
		var shake := Vector2(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5)) if is_scared else Vector2.ZERO
		draw_set_transform(shake, 0.0, Vector2.ONE)
	
	if has_stolen_artifact:
		# Золота аура перехопленого артефакту (Підківки Вакули) навколо ворога!
		var pulse_a := 1.0 + sin(time_passed * 14.0) * 0.16
		draw_circle(Vector2.ZERO, 21.0 * pulse_a, Color(1.0, 0.85, 0.15, 0.28))
		draw_arc(Vector2(0.0, -24.0), 5.5, 0.4, TAU - 0.4, 8, Color(1.0, 0.92, 0.22), 2.6)
		var fnt := ThemeDB.fallback_font
		if fnt:
			draw_string(fnt, Vector2(-26.0, -31.0), "ТРОФЕЙ! ✨", HORIZONTAL_ALIGNMENT_CENTER, 52.0, 9, Color(1.0, 0.94, 0.30))
	
	match enemy_type:
		EnemyType.CHORT:
			_draw_chort()
		EnemyType.VIDMA:
			_draw_vidma()
		EnemyType.VOGNYK:
			_draw_vognyk()
		EnemyType.MOSKAL:
			_draw_moskal()

# -------------------------------------------------------------
# ГОГОЛІВСЬКИЙ ЧОРТИК ("Ніч перед Різдвом", "Пропала грамота")
# -------------------------------------------------------------
const CHORT_HEAD_RX: float = 11.4
const CHORT_HEAD_RY: float = 10.8

# Геометрія ріжок чортика (чиста функція: перевіряється тестом Anti-Clipping, SWR-001-04).
static func chort_horn_points(fwd: float, bob: float, jiggle: float) -> Array:
	return [
		[Vector2(-6.2 * fwd, -7.6 + bob), Vector2(-11.5 * fwd + jiggle, -11.0 + bob), Vector2(-12.5 * fwd + jiggle * 1.5, -17.5 + bob)],
		[Vector2(6.2 * fwd, -7.6 + bob), Vector2(11.5 * fwd + jiggle, -11.0 + bob), Vector2(12.5 * fwd + jiggle * 1.5, -17.5 + bob)],
	]

func _draw_chort() -> void:
	var fwd := signf(velocity.x) if absf(velocity.x) > 10.0 else 1.0
	var bob := sin(time_passed * 7.0) * 1.2 if is_resting else sin(time_passed * 12.0) * 2.0
	var c_body := Color(0.14, 0.12, 0.16) if not is_scared else Color(0.25, 0.35, 0.65)
	var c_fur_hi := Color(0.24, 0.21, 0.28) if not is_scared else Color(0.38, 0.50, 0.82)
	
	# 1. Кручений чортячий хвіст зі стрілочкою (опущений додолу під час перепочинку!)
	if is_resting:
		var t_base := Vector2(-8.0 * fwd, 4.5 + bob * 0.5)
		var t_mid := t_base + Vector2(-8.0 * fwd, 6.5)
		var t_tip := t_base + Vector2(-14.0 * fwd, 11.5 + sin(time_passed * 4.0) * 1.0)
		draw_line(t_base, t_mid, c_body, 2.8)
		draw_line(t_mid, t_tip, c_body, 2.0)
		draw_colored_polygon(PackedVector2Array([
			t_tip,
			t_tip + Vector2(-4.0 * fwd, -2.5),
			t_tip + Vector2(-5.5 * fwd, 1.5),
			t_tip + Vector2(-2.5 * fwd, 3.5)
		]), Color(0.72, 0.16, 0.16))
	elif not is_scared:
		var tail_wave := sin(time_passed * 16.0) * 6.0
		var t_base := Vector2(-8.0 * fwd, 4.0 + bob * 0.5)
		var t_mid := t_base + Vector2(-12.0 * fwd, -6.0 + tail_wave * 0.5)
		var t_tip := t_base + Vector2(-18.5 * fwd, tail_wave)
		draw_line(t_base, t_mid, c_body, 2.8)
		draw_line(t_mid, t_tip, c_body, 2.0)
		# Китиця-стрілка на хвості
		draw_colored_polygon(PackedVector2Array([
			t_tip,
			t_tip + Vector2(-4.5 * fwd, -4.0),
			t_tip + Vector2(-6.5 * fwd, 0.0),
			t_tip + Vector2(-4.5 * fwd, 4.0)
		]), Color(0.72, 0.16, 0.16))
	else:
		# Комічний закручений хвіст-пружинка!
		var t_base := Vector2(-8.0 * fwd, 4.0)
		var spiral_pts := PackedVector2Array([t_base])
		for sp in range(1, 14):
			var a := float(sp) * 0.85 + time_passed * 24.0
			var r := float(sp) * 0.8
			spiral_pts.append(t_base + Vector2(-r * fwd + cos(a) * 3.5, sin(a) * 3.5))
		for spi in range(spiral_pts.size() - 1):
			draw_line(spiral_pts[spi], spiral_pts[spi + 1], c_body, 2.2)
		draw_circle(spiral_pts[-1], 2.2, Color(0.85, 0.25, 0.25))
	
	# 1.5. Цапині ріжки в сторони: основа на контурі голови, малюються ПОЗАД тілом (Anti-Clipping, SHR-001 I-4)
	var horn_col := Color(0.68, 0.18, 0.15) if not is_scared else Color(0.92, 0.78, 0.22)
	var horn_tip_col := Color(0.95, 0.35, 0.25) if not is_scared else Color(1.0, 0.95, 0.50)
	var jiggle := sin(time_passed * 35.0) * (1.5 if is_scared else 0.0)
	# Ріжки: [основа, середина, кінчик]; задній від потилиці, передній від чола, обидва назовні й угору
	var horns := chort_horn_points(fwd, bob, jiggle)
	for horn in horns:
		draw_line(horn[0], horn[1], horn_col, 3.2)
		draw_line(horn[1], horn[2], horn_col, 2.0)
		draw_circle(horn[2], 1.1, horn_tip_col)
	var h1_tip: Vector2 = horns[0][2]
	var h2_tip: Vector2 = horns[1][2]

	# 1.8. Гоголівський мішок за спиною чортика (з якого виглядає крадений золотий серпик місяця!)
	var sack_c := Vector2(-7.2 * fwd, -0.5 + bob)
	_draw_oval(sack_c, 5.2, 6.0, Color(0.48, 0.36, 0.22))
	draw_arc(sack_c + Vector2(-2.2 * fwd, -3.5), 3.2, -0.8, 1.4, 8, Color(1.0, 0.92, 0.35), 1.8) # Крадений місяць у мішку!
	
	# 2. Волохате кругле тільце чортика з пухнастою грудкою, контурним світлом та копитцями
	_draw_oval(Vector2(0, bob), CHORT_HEAD_RX, CHORT_HEAD_RY, c_body)
	draw_arc(Vector2(0, bob), 11.0, -1.2, 0.8, 10, c_fur_hi, 1.6)
	_draw_oval(Vector2(2.2 * fwd, 1.5 + bob), 6.2, 5.8, c_fur_hi)
	# Волохаті виступи хутра з боків та кошлата борідка
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9.5 * fwd, -1.0 + bob), Vector2(-13.5 * fwd, 1.0 + bob), Vector2(-8.5 * fwd, 4.0 + bob)
	]), c_body)
	draw_colored_polygon(PackedVector2Array([
		Vector2(4.0 * fwd, 6.5 + bob), Vector2(7.5 * fwd, 11.2 + bob), Vector2(1.8 * fwd, 8.2 + bob)
	]), c_body)
	
	# Копитця (дві жваві ніжки знизу з роздвоєними копитцями або присідання на перепочинку)
	if is_resting:
		var foot_l := Vector2(-5.5, 14.2 + bob)
		var foot_r := Vector2(5.5, 14.2 + bob)
		draw_line(Vector2(-4.0, 9.0 + bob), foot_l, c_body, 2.6)
		draw_line(Vector2(4.0, 9.0 + bob), foot_r, c_body, 2.6)
		_draw_oval(foot_l + Vector2(0.8 * fwd, 0.5), 2.5, 1.5, Color(0.38, 0.16, 0.10))
		_draw_oval(foot_r + Vector2(0.8 * fwd, 0.5), 2.5, 1.5, Color(0.38, 0.16, 0.10))
	elif not is_scared:
		var trot := sin(time_passed * 16.0 * fatigue_mult) * 3.2
		var foot_l := Vector2(-4.0 - trot * 0.6, 15.5 + bob - maxf(0.0, trot) * 0.5)
		var foot_r := Vector2(4.0 + trot * 0.6, 15.5 + bob - maxf(0.0, -trot) * 0.5)
		draw_line(Vector2(-4.0, 9.0 + bob), foot_l, c_body, 2.4)
		draw_line(Vector2(4.0, 9.0 + bob), foot_r, c_body, 2.4)
		_draw_oval(foot_l + Vector2(0.8 * fwd, 0.5), 2.3, 1.5, Color(0.38, 0.16, 0.10))
		_draw_oval(foot_r + Vector2(0.8 * fwd, 0.5), 2.3, 1.5, Color(0.38, 0.16, 0.10))
	else:
		# Комічне мультяшне "колесо" з ніжок під час панічної втечі!
		var spin := time_passed * 36.0
		var r_spin := 6.5
		var l1 := Vector2(cos(spin) * r_spin, 14.0 + sin(spin) * 3.5 + bob)
		var l2 := Vector2(cos(spin + PI) * r_spin, 14.0 + sin(spin + PI) * 3.5 + bob)
		draw_line(Vector2(-3 * fwd, 8 + bob), l1, c_body, 2.4)
		draw_line(Vector2(3 * fwd, 8 + bob), l2, c_body, 2.4)
		draw_circle(l1, 2.0, Color(0.35, 0.15, 0.10))
		draw_circle(l2, 2.0, Color(0.35, 0.15, 0.10))
		# Кумедні клубочки куряви під ніжками
		var puff_x := -10.0 * fwd + sin(time_passed * 20.0) * 4.0
		draw_circle(Vector2(puff_x, 15.0 + bob), 2.5, Color(0.85, 0.85, 0.9, 0.55))
		draw_circle(Vector2(puff_x - 4.0 * fwd, 13.0 + bob), 1.8, Color(0.85, 0.85, 0.9, 0.40))
	
	# 2.5. Шкодливі лапки чортика (потирає лапки, витирає піт з лоба на відпочинку, або махає від переляку!)
	if is_resting:
		var wipe := sin(time_passed * 9.0) * 2.2
		var brow_paw := Vector2((4.2 + wipe) * fwd, -6.5 + bob)
		draw_line(Vector2(2.5 * fwd, 2.0 + bob), brow_paw, c_body, 2.4)
		draw_circle(brow_paw, 2.0, c_fur_hi)
		# Друга лапка спирається на коліно під час перепочинку
		var knee_paw := Vector2(-5.0 * fwd, 9.5 + bob)
		draw_line(Vector2(-3.5 * fwd, 3.0 + bob), knee_paw, c_body, 2.2)
		draw_circle(knee_paw, 1.8, c_fur_hi)
	elif not is_scared:
		var rub := sin(time_passed * 18.0) * 1.6
		var paw_pos := Vector2(7.5 * fwd, 5.5 + bob + rub)
		draw_line(Vector2(2.5 * fwd, 3.5 + bob), paw_pos, c_body, 2.2)
		draw_circle(paw_pos, 1.8, c_fur_hi)
	else:
		var wave_arm := sin(time_passed * 30.0) * 4.0
		draw_line(Vector2(-5.0 * fwd, -1.0 + bob), Vector2(-12.5 * fwd, -9.0 + bob + wave_arm), c_body, 2.2)
		draw_line(Vector2(5.0 * fwd, -1.0 + bob), Vector2(12.5 * fwd, -9.0 + bob - wave_arm), c_body, 2.2)
	
	# 3. Ріжки та гострі вушка (гоголівський бешкетник — суворе правило Anti-Clipping!)
	var ear_twitch := sin(time_passed * 9.0) * 0.8
	
	# Маленькі гострі чортячі вушка з боків голови та золота сережка-кільце!
	var ear_back := Vector2(-7.5 * fwd, -4.0 + bob)
	var ear_front := Vector2(4.5 * fwd, -5.5 + bob)
	draw_colored_polygon(PackedVector2Array([
		ear_back, ear_back + Vector2(-4.0 * fwd, -4.2 + ear_twitch), ear_back + Vector2(-1.5 * fwd, 2.0)
	]), c_body)
	draw_colored_polygon(PackedVector2Array([
		ear_front, ear_front + Vector2(4.0 * fwd, -4.2 - ear_twitch), ear_front + Vector2(1.5 * fwd, 2.0)
	]), c_body)
	draw_arc(ear_back + Vector2(-1.8 * fwd, 1.5), 1.6, 0.0, TAU, 8, Color(1.0, 0.86, 0.20), 1.2)
	
	# Іскри переляку на кінчиках ріжок під час паніки!
	if is_scared:
		var spk_ang := time_passed * 24.0
		var s1 := h1_tip + Vector2(cos(spk_ang), sin(spk_ang)) * 2.5
		var s2 := h2_tip + Vector2(cos(spk_ang + PI), sin(spk_ang + PI)) * 2.5
		draw_circle(s1, 1.2, Color(1.0, 0.95, 0.40))
		draw_circle(s2, 1.2, Color(1.0, 0.95, 0.40))
	
	# 4. Свинячий рожевий п'ятачок та пустотливий язичок (гоголівська класика!)
	var snout_wiggle := sin(time_passed * 14.0) * 0.6
	var snout_pos := Vector2(5.8 * fwd, 1.8 + bob + snout_wiggle)
	_draw_oval(snout_pos, 4.0, 2.9, Color(0.92, 0.48, 0.58))
	_draw_oval(snout_pos + Vector2(0.5 * fwd, -0.6), 2.4, 1.4, Color(0.98, 0.65, 0.72))
	draw_circle(snout_pos + Vector2(-1.0, 0.2), 0.85, Color(0.38, 0.12, 0.18)) # Ніздрі
	draw_circle(snout_pos + Vector2(1.1, 0.2), 0.85, Color(0.38, 0.12, 0.18))
	if is_resting or not is_scared:
		# Маленький рожевий язичок бешкетника (а коли відхекується — висолоплений довго!)
		var tongue_len := 3.8 + absf(sin(time_passed * 11.0)) * 1.1 if is_resting else 1.6
		_draw_oval(snout_pos + Vector2(1.0 * fwd, 3.6), 1.6, tongue_len, Color(0.95, 0.30, 0.40))
	
	# 5. Очі
	if is_resting:
		# Втомлено прикриті повіки чортика під час перепочинку
		var eye_pos := Vector2(3.0 * fwd, -3.2 + bob)
		draw_arc(eye_pos, 2.4, 0.15, PI - 0.15, 6, Color(1.0, 0.86, 0.16), 2.0)
		_draw_sweat_and_breath(Vector2(2.0 * fwd, -10.5 + bob), snout_pos + Vector2(3.5 * fwd, 1.5), fwd, "ФУХ!")
	elif not is_scared:
		# Лукаві палаючі жовті очі чортика з котячими зіницями
		var eye_pos := Vector2(3.0 * fwd, -3.2 + bob)
		draw_circle(eye_pos, 2.6, Color(1.0, 0.86, 0.16))
		draw_line(eye_pos + Vector2(0.7 * fwd, -1.6), eye_pos + Vector2(0.7 * fwd, 1.6), Color(0.08, 0.04, 0.04), 1.3)
		draw_circle(eye_pos + Vector2(1.0 * fwd, -0.7), 0.55, Color.WHITE)
		# Лукава брова
		draw_line(eye_pos + Vector2(-2.2 * fwd, -3.0), eye_pos + Vector2(2.2 * fwd, -2.0), Color(0.06, 0.04, 0.08), 1.5)
	else:
		# ВЕЛИЧЕЗНІ перелякані круглі очі-блюдця зі здивованими зіницями!
		var jitter := Vector2(sin(time_passed * 40.0) * 0.8, cos(time_passed * 35.0) * 0.8)
		var eye1 := Vector2(-3.5, -4.0 + bob)
		var eye2 := Vector2(5.5 * fwd, -4.0 + bob)
		draw_circle(eye1, 4.4, Color.WHITE)
		draw_circle(eye2, 4.4, Color.WHITE)
		draw_circle(eye1 + jitter + Vector2(1.2 * fwd, 0), 1.4, Color(0.1, 0.15, 0.35))
		draw_circle(eye2 + jitter + Vector2(-1.2 * fwd, 0), 1.4, Color(0.1, 0.15, 0.35))

# -------------------------------------------------------------
# ВІДЬМА НА МІТЛІ (Солоха / Панночка з "Ночі перед Різдвом")
# -------------------------------------------------------------
func _draw_vidma() -> void:
	var fwd := signf(velocity.x) if absf(velocity.x) > 10.0 else 1.0
	var bob := sin(time_passed * 8.0) * 3.0
	var tilt := cos(time_passed * 8.0) * 1.5
	
	# 1. Автентична березова мітла (вигнуте древко + пишний віник + глиняний горщик із зіллям на передньому кінці!)
	var b_back := Vector2(-18.0 * fwd, 5.0 + bob - tilt)
	var b_mid := Vector2(0.0, 2.0 + bob)
	var b_front := Vector2(18.0 * fwd, -3.0 + bob + tilt)
	draw_line(b_back, b_mid, Color(0.45, 0.28, 0.14), 3.0)
	draw_line(b_mid, b_front, Color(0.52, 0.34, 0.18), 2.6)
	draw_circle(b_front, 1.6, Color(0.65, 0.45, 0.24))
	# Глиняний горщик із чар-зіллям, підвішений спереду мітли!
	var pot_c := b_front + Vector2(-2.5 * fwd, 4.2)
	_draw_oval(pot_c, 3.2, 3.0, Color(0.68, 0.32, 0.16))
	draw_line(pot_c + Vector2(-2.5, -2.4), pot_c + Vector2(2.5, -2.4), Color(0.48, 0.20, 0.10), 1.6)
	draw_circle(pot_c + Vector2(0.0, -3.6 - sin(time_passed * 12.0) * 1.2), 1.3, Color(0.45, 0.95, 0.55, 0.85))
	
	# Прути березового віника позаду
	var brush_pts := PackedVector2Array([
		b_back + Vector2(2.0 * fwd, -1.5),
		b_back + Vector2(-13.0 * fwd, -6.5),
		b_back + Vector2(-16.0 * fwd, 1.5),
		b_back + Vector2(-12.0 * fwd, 9.5),
		b_back + Vector2(2.0 * fwd, 2.0)
	])
	draw_colored_polygon(brush_pts, Color(0.62, 0.42, 0.20))
	draw_line(b_back + Vector2(-2.0 * fwd, -2.5), b_back + Vector2(-12.0 * fwd, -4.0), Color(0.78, 0.56, 0.28), 1.4)
	draw_line(b_back + Vector2(-2.0 * fwd, 2.5), b_back + Vector2(-11.0 * fwd, 6.5), Color(0.42, 0.26, 0.12), 1.4)
	# Золоте перевесло віника
	draw_line(b_back + Vector2(0, -2.4), b_back + Vector2(0, 2.4), Color(0.95, 0.80, 0.20), 2.2)
	
	# 2. Ніжки Солохи в червоних чобітках, що грайливо гойдаються під мітлою (або втомлено звисають на перепочинку)
	var leg_swing := 0.0 if is_resting else sin(time_passed * 11.0 * fatigue_mult) * 3.5
	var boot_l := Vector2(-3.0 * fwd + leg_swing, 13.5 + bob)
	var boot_r := Vector2(3.5 * fwd - leg_swing, 12.5 + bob)
	draw_line(Vector2(-2.0 * fwd, 3.0 + bob), boot_l, Color(0.92, 0.88, 0.84), 2.4)
	draw_line(Vector2(2.0 * fwd, 3.0 + bob), boot_r, Color(0.92, 0.88, 0.84), 2.4)
	_draw_oval(boot_l + Vector2(1.5 * fwd, 0.5), 2.8, 1.6, Color(0.82, 0.14, 0.16))
	_draw_oval(boot_r + Vector2(1.5 * fwd, 0.5), 2.8, 1.6, Color(0.82, 0.14, 0.16))
	
	# 3. Пишна українська плахта, корсетка та вишиті рукави Солохи
	var skirt_pts := PackedVector2Array([
		Vector2(-5.5 * fwd, -2.0 + bob),
		Vector2(5.5 * fwd, -2.0 + bob),
		Vector2(9.0 * fwd, 7.5 + bob),
		Vector2(-8.5 * fwd, 8.0 + bob)
	])
	draw_colored_polygon(skirt_pts, Color(0.58, 0.14, 0.28) if not is_scared else Color(0.35, 0.25, 0.55))
	# Картата плахта та фартушок-запаска з орнаментом
	draw_line(Vector2(-6.5 * fwd, 5.5 + bob), Vector2(7.0 * fwd, 5.5 + bob), Color(0.95, 0.78, 0.18), 1.6)
	draw_line(Vector2(-5.5 * fwd, 3.2 + bob), Vector2(6.2 * fwd, 3.2 + bob), Color(0.18, 0.62, 0.35), 1.2)
	# Оксамитова корсетка із золотим шнуруванням та білий рукав вишиванки, що тримає мітлу
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4.0 * fwd, -8.0 + bob),
		Vector2(4.5 * fwd, -8.0 + bob),
		Vector2(5.0 * fwd, -1.0 + bob),
		Vector2(-4.5 * fwd, -1.0 + bob)
	]), Color(0.22, 0.12, 0.28))
	# Рука у пишному білому рукаві з червоною вишивкою тримає держак мітли
	var hand_p := Vector2(7.5 * fwd, -1.0 + bob)
	draw_line(Vector2(1.5 * fwd, -6.5 + bob), hand_p, Color(0.96, 0.95, 0.98), 3.6)
	draw_circle(Vector2(4.0 * fwd, -4.0 + bob), 1.6, Color(0.85, 0.15, 0.18))
	draw_circle(hand_p, 1.8, Color(0.98, 0.84, 0.72))
	
	# Пишне трирядне червоне коралове намисто з золотим дукачем на шиї!
	for n_row in range(2):
		var ny := -7.5 + float(n_row) * 1.4 + bob
		draw_line(Vector2(-2.2 * fwd, ny), Vector2(3.2 * fwd, ny), Color(0.92, 0.15, 0.20), 1.6)
	draw_circle(Vector2(1.2 * fwd, -5.0 + bob), 1.5, Color(1.0, 0.86, 0.20)) # Золотий дукач!
	
	# 4. Голова, лукаве обличчя Солохи та традиційна хустка, зав'язана "ріжками"
	var head_c := Vector2(1.5 * fwd, -12.5 + bob)
	_draw_oval(head_c, 5.6, 5.4, Color(0.98, 0.85, 0.74))
	# Рум'яна щічка
	_draw_oval(head_c + Vector2(2.0 * fwd, 1.2), 1.8, 1.2, Color(0.96, 0.45, 0.48, 0.42))
	# Характерний гострий носик із родимкою
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(4.2 * fwd, -1.2),
		head_c + Vector2(8.0 * fwd, 0.4),
		head_c + Vector2(4.0 * fwd, 1.4)
	]), Color(0.95, 0.78, 0.66))
	draw_circle(head_c + Vector2(3.2 * fwd, 2.0), 0.65, Color(0.25, 0.14, 0.12)) # Родимка Солохи
	
	if is_resting:
		# Солоха переводить подих: втомлено прикрите око й обмахується білою хустинкою!
		draw_arc(head_c + Vector2(2.4 * fwd, -1.6), 2.0, 0.2, PI - 0.2, 6, Color(0.22, 0.12, 0.12), 1.8)
		var fan_wave := sin(time_passed * 14.0) * 2.5
		var hanky_pos := head_c + Vector2((7.5 + fan_wave * 0.4) * fwd, 1.0 + fan_wave)
		draw_colored_polygon(PackedVector2Array([
			hanky_pos, hanky_pos + Vector2(4.5 * fwd, -3.0), hanky_pos + Vector2(3.6 * fwd, 3.5)
		]), Color(0.98, 0.98, 1.0))
		_draw_sweat_and_breath(head_c + Vector2(0.0, -8.5), head_c + Vector2(5.5 * fwd, 2.0), fwd, "ОХ, ФУХ!")
	elif not is_scared:
		# Хитре примружене око та лукава посмішка
		draw_circle(head_c + Vector2(2.4 * fwd, -1.6), 1.8, Color.WHITE)
		draw_circle(head_c + Vector2(3.0 * fwd, -1.6), 1.0, Color(0.15, 0.38, 0.22)) # Зелені відьомські очі
		draw_line(head_c + Vector2(0.5 * fwd, -3.4), head_c + Vector2(4.2 * fwd, -2.6), Color(0.18, 0.10, 0.10), 1.5)
		draw_arc(head_c + Vector2(2.2 * fwd, 2.2), 2.2, 0.2, PI - 0.2, 6, Color(0.75, 0.15, 0.20), 1.5)
	else:
		# Перелякані очі-блюдця!
		draw_circle(head_c + Vector2(2.4 * fwd, -1.6), 3.2, Color.WHITE)
		draw_circle(head_c + Vector2(2.8 * fwd, -1.6), 1.1, Color(0.10, 0.15, 0.25))
		_draw_oval(head_c + Vector2(2.5 * fwd, 2.8), 1.8, 2.4, Color(0.25, 0.06, 0.08))
	
	# Святкова хустка-очіпок із зав'язаними вузликами вгорі та розмаяною косою
	_draw_oval(head_c + Vector2(-0.8 * fwd, -3.8), 6.0, 2.8, Color(0.85, 0.16, 0.22))
	draw_circle(head_c + Vector2(1.0 * fwd, -5.0), 1.2, Color(0.98, 0.85, 0.20)) # Золоті квіти на хустці
	draw_circle(head_c + Vector2(-2.5 * fwd, -4.8), 1.2, Color(0.98, 0.85, 0.20))
	# Два ріжки-вузлики хустки зверху (як у класичній екранізації Гоголя)
	draw_line(head_c + Vector2(2.5 * fwd, -5.5), head_c + Vector2(4.5 * fwd, -9.5), Color(0.85, 0.16, 0.22), 2.2)
	draw_line(head_c + Vector2(0.5 * fwd, -5.8), head_c + Vector2(-1.5 * fwd, -9.8), Color(0.85, 0.16, 0.22), 2.2)
	# Довга чорна коса, що майорить за вітром
	var hair_wave := sin(time_passed * 14.0) * 3.2
	draw_line(head_c + Vector2(-4.5 * fwd, -1.5), head_c + Vector2(-14.0 * fwd, -4.0 + hair_wave), Color(0.12, 0.08, 0.08), 2.6)
	draw_circle(head_c + Vector2(-14.5 * fwd, -4.0 + hair_wave), 1.6, Color(0.85, 0.16, 0.22)) # Червона стрічка в косі
	
	# 5. Зоряний попіл або комічні кільця диму з мітли при переляку
	for i in range(4):
		var spark_t := fmod(time_passed * 3.0 + float(i) * 0.25, 1.0)
		var spark_pos := Vector2(-24.0 * fwd - spark_t * 18.0 * fwd, 6.0 + bob + spark_t * 16.0)
		var spark_alpha := (1.0 - spark_t) * 0.78
		if is_scared:
			# Мітла чмихає кільцями диму як старий моторчик!
			draw_arc(spark_pos, 2.2 + spark_t * 3.5, 0.0, TAU, 10, Color(0.80, 0.82, 0.88, spark_alpha), 1.4)
		else:
			draw_circle(spark_pos, 1.6, Color(0.90, 0.96, 1.0, spark_alpha))
			draw_line(spark_pos - Vector2(2.2, 0), spark_pos + Vector2(2.2, 0), Color(1.0, 0.95, 0.55, spark_alpha), 1.0)
			draw_line(spark_pos - Vector2(0, 2.2), spark_pos + Vector2(0, 2.2), Color(1.0, 0.95, 0.55, spark_alpha), 1.0)

# -------------------------------------------------------------
# БЛУКАЮЧИЙ ВОГНИК (Потерчата / Купальський Лісовий Дух)
# -------------------------------------------------------------
func _draw_vognyk() -> void:
	var pulse := (0.76 + sin(time_passed * 5.0) * 0.06) if is_resting else (1.0 + sin(time_passed * 16.0) * 0.22)
	var sway := sin(time_passed * 10.0) * 3.5
	var c_outer := Color(0.12, 0.85, 0.75, 0.22) if not is_scared else Color(0.45, 0.65, 1.0, 0.25)
	var c_mid := Color(0.22, 0.96, 0.58, 0.52) if not is_scared else Color(0.55, 0.80, 1.0, 0.55)
	var c_core := Color(0.95, 1.0, 0.82, 0.94)
	
	# 1. Танцюючі язики купальського полум'я вгорі
	for t_i in range(3):
		var offset_x := (float(t_i) - 1.0) * 4.5
		var tongue_wave := sin(time_passed * 14.0 + float(t_i) * 1.8) * 3.2
		var tongue_h := (16.5 if t_i == 1 else 12.5) * pulse
		draw_colored_polygon(PackedVector2Array([
			Vector2(offset_x - 4.5, 2.0),
			Vector2(offset_x + tongue_wave, -tongue_h),
			Vector2(offset_x + 4.5, 2.0)
		]), c_mid)
	
	# 1.5. Вогняний хвіст-шлейф позаду (впізнаваний силует: не кулька, а купальська «блудна свічка»)
	var tail_dir := -(signf(velocity.x) if absf(velocity.x) > 5.0 else 1.0)
	var c_tail := Color(c_mid.r, c_mid.g, c_mid.b, 0.88)
	for t_j in range(3):
		var t_len := (22.0 - float(t_j) * 5.0) * pulse
		var t_y := -4.0 + float(t_j) * 4.0
		var t_wob := sin(time_passed * 12.0 + float(t_j) * 1.7) * 3.4
		draw_colored_polygon(PackedVector2Array([
			Vector2(0.0, t_y - 3.2), Vector2(tail_dir * t_len, t_y + t_wob), Vector2(0.0, t_y + 3.2)
		]), c_tail)
	
	# 2. Ефірне смарагдово-блакитне сяйво ядра
	draw_circle(Vector2.ZERO, 15.5 * pulse, c_outer)
	draw_circle(Vector2(0, -1.0), 10.2 * pulse, c_mid)
	draw_circle(Vector2(0, -0.5), 6.2 * pulse, c_core)
	
	# 3. Живі містичні оченята духа-потерчати всередині ядра!
	var look_dir := signf(velocity.x) if absf(velocity.x) > 5.0 else 1.0
	if is_resting:
		# Сонно прикриті оченята Купальського Вогника під час короткого перепочинку
		draw_arc(Vector2(-2.2 + look_dir * 0.5, -0.5), 1.7, 0.2, PI - 0.2, 6, Color(0.06, 0.28, 0.22), 1.8)
		draw_arc(Vector2(2.2 + look_dir * 0.5, -0.5), 1.7, 0.2, PI - 0.2, 6, Color(0.06, 0.28, 0.22), 1.8)
		_draw_sweat_and_breath(Vector2(0.0, -10.5), Vector2(4.5 * look_dir, 1.5), look_dir, "ХУХ...")
	elif not is_scared:
		_draw_oval(Vector2(-2.2 + look_dir * 0.8, -0.5), 1.4, 2.0, Color(0.06, 0.28, 0.22))
		_draw_oval(Vector2(2.2 + look_dir * 0.8, -0.5), 1.4, 2.0, Color(0.06, 0.28, 0.22))
		draw_circle(Vector2(-1.9 + look_dir * 0.8, -1.1), 0.55, Color.WHITE)
		draw_circle(Vector2(2.5 + look_dir * 0.8, -1.1), 0.55, Color.WHITE)
	else:
		# Перелякані круглі оченята
		draw_circle(Vector2(-2.4, -0.5), 2.2, Color.WHITE)
		draw_circle(Vector2(2.4, -0.5), 2.2, Color.WHITE)
		draw_circle(Vector2(-2.4, -0.5), 0.9, Color(0.08, 0.15, 0.35))
		draw_circle(Vector2(2.4, -0.5), 0.9, Color(0.08, 0.15, 0.35))
	
	# 3.5. Купальський віночок із папороті та польових квітів на голівці духа!
	draw_arc(Vector2(0.0, -5.2), 6.2, PI + 0.2, TAU - 0.2, 8, Color(0.16, 0.62, 0.30), 2.2)
	draw_circle(Vector2(-3.8, -5.8), 1.6, Color(1.0, 0.32, 0.42))
	draw_circle(Vector2(0.0, -6.6), 1.7, Color(1.0, 0.88, 0.22))
	draw_circle(Vector2(3.8, -5.8), 1.6, Color(0.32, 0.68, 1.0))
	
	# 4. Орбітальні купальські світлячки навколо вогника
	for sp in range(3):
		var a := time_passed * 5.5 + float(sp) * (TAU / 3.0)
		var sp_pos := Vector2(cos(a) * 13.0, sin(a * 1.3) * 8.5)
		draw_circle(sp_pos, 1.5, Color(1.0, 1.0, 0.75, 0.85))

# -------------------------------------------------------------
# ЦАРСЬКИЙ СТРІЛЕЦЬ-ЗАГАРБНИК ("МОСКАЛЬ" - САТИРА КИЇВНАУКФІЛЬМ)
# -------------------------------------------------------------
func _draw_moskal() -> void:
	var fwd := signf(velocity.x) if absf(velocity.x) > 10.0 else 1.0
	var waddle := 0.0 if is_resting else sin(time_passed * 10.0 * fatigue_mult) * (2.4 if not is_scared else 1.2)
	var bob := sin(time_passed * 7.0) * 1.2 if is_resting else absf(sin(time_passed * 10.0 * fatigue_mult)) * 2.6
	
	# 0. Мішок-лантух для мародерства за плечима (з якого стирчить крадений мідний самовар!)
	var sack_pos := Vector2(-8.8 * fwd, 2.0 + waddle * 0.8)
	_draw_oval(sack_pos, 6.5, 7.8, Color(0.62, 0.52, 0.38))
	draw_line(sack_pos + Vector2(-3.0, -5.0), sack_pos + Vector2(2.0, -5.0), Color(0.42, 0.32, 0.20), 1.6)
	# Мідний кран та ручки краденого самовара, що виглядають із мішка
	draw_circle(sack_pos + Vector2(-3.5 * fwd, -7.2), 2.8, Color(0.88, 0.65, 0.20))
	draw_line(sack_pos + Vector2(-3.5 * fwd, -9.8), sack_pos + Vector2(-3.5 * fwd, -12.0), Color(0.75, 0.52, 0.16), 2.0)
	
	# 1. Червоний об'ємний каптан / охабень із золотими петлицями та високим коміром
	var c_coat := Color(0.85, 0.15, 0.18) if not is_scared else Color(0.65, 0.18, 0.35)
	var c_coat_sh := Color(0.58, 0.08, 0.10) if not is_scared else Color(0.45, 0.10, 0.24)
	var c_braid := Color(0.96, 0.82, 0.18) # Золоті петлиці (бранденбури)
	
	# Тіло каптана (розширений донизу дзвін)
	var body_pts := PackedVector2Array([
		Vector2(-9.5 * fwd, -4.5 + waddle),
		Vector2(9.5 * fwd, -4.5 + waddle),
		Vector2(14.5 * fwd, 15.2 - bob),
		Vector2(-12.5 * fwd, 15.2 - bob)
	])
	draw_colored_polygon(body_pts, c_coat)
	draw_line(Vector2(-12.0 * fwd, 14.8 - bob), Vector2(14.0 * fwd, 14.8 - bob), c_braid, 2.0) # Золота облямівка подолу
	draw_line(Vector2(0, -4.5 + waddle), Vector2(0, 15.0 - bob), c_coat_sh, 1.8)
	
	# Характерні горизонтальні стрілецькі петлиці на грудях (3 смуги із золотими ґудзиками)
	for b in range(3):
		var by := float(b) * 4.4 + waddle
		draw_line(Vector2(-6.5 * fwd, by), Vector2(6.5 * fwd, by), c_braid, 2.0)
		draw_circle(Vector2(-6.5 * fwd, by), 1.0, c_braid)
		draw_circle(Vector2(6.5 * fwd, by), 1.0, c_braid)
		draw_circle(Vector2(0, by), 1.3, Color(1.0, 0.95, 0.55))
	
	# 2. Неповороткі ноги у лаптях з переплетеними онучами
	if is_resting:
		# Напівзігнуті ноги під час важкого перепочинку
		var ankle_l := Vector2(-5.5 * fwd, 19.5)
		var ankle_r := Vector2(5.5 * fwd, 19.5)
		draw_line(Vector2(-5.0 * fwd, 14.5), ankle_l, Color(0.78, 0.72, 0.62), 3.6)
		draw_line(Vector2(5.0 * fwd, 14.5), ankle_r, Color(0.78, 0.72, 0.62), 3.6)
		_draw_oval(ankle_l + Vector2(2.0 * fwd, 0.5), 3.8, 2.1, Color(0.72, 0.55, 0.28))
		_draw_oval(ankle_r + Vector2(2.0 * fwd, 0.5), 3.8, 2.1, Color(0.72, 0.55, 0.28))
	elif not is_scared:
		# Кумедна перевалююча хода ("ведмежий крок")
		var step_l := sin(time_passed * 10.0 * fatigue_mult) * 4.5
		var step_r := -step_l
		var lift_l := maxf(0.0, -cos(time_passed * 10.0 * fatigue_mult)) * 2.2
		var lift_r := maxf(0.0, cos(time_passed * 10.0 * fatigue_mult)) * 2.2
		var ankle_l := Vector2(-5.0 * fwd + step_l, 20.0 - lift_l)
		var ankle_r := Vector2(5.0 * fwd + step_r, 20.0 - lift_r)
		draw_line(Vector2(-5.0 * fwd, 14.5), ankle_l, Color(0.78, 0.72, 0.62), 3.6) # Білі онучі
		draw_line(Vector2(5.0 * fwd, 14.5), ankle_r, Color(0.78, 0.72, 0.62), 3.6)
		# Перев'язки онучів
		draw_line(Vector2(-5.0 * fwd + step_l * 0.5, 16.5), Vector2(-3.0 * fwd + step_l * 0.5, 18.0), Color(0.45, 0.32, 0.18), 1.2)
		draw_line(Vector2(5.0 * fwd + step_r * 0.5, 16.5), Vector2(7.0 * fwd + step_r * 0.5, 18.0), Color(0.45, 0.32, 0.18), 1.2)
		# Лапті (плетене ликове взуття)
		_draw_oval(ankle_l + Vector2(2.0 * fwd, 0.5), 3.8, 2.1, Color(0.72, 0.55, 0.28))
		_draw_oval(ankle_r + Vector2(2.0 * fwd, 0.5), 3.8, 2.1, Color(0.72, 0.55, 0.28))
	else:
		# Панічне мигтіння ніг-коліс під час втечі та лапті, що губляться на бігу!
		var spin := time_passed * 34.0
		draw_arc(Vector2(0, 18.0), 6.5, spin, spin + PI, 6, Color(0.72, 0.55, 0.28), 3.2)
		draw_arc(Vector2(0, 18.0), 6.5, spin + PI, spin + TAU, 6, Color(0.35, 0.22, 0.12), 3.2)
		# Загублений лапоть летить у повітрі позаду!
		var lost_shoe_x := -17.0 * fwd + sin(time_passed * 16.0) * 4.0
		var lost_shoe_y := 12.0 + cos(time_passed * 18.0) * 5.0
		_draw_oval(Vector2(lost_shoe_x, lost_shoe_y), 3.4, 2.0, Color(0.72, 0.55, 0.28))
		# Хмаринки куряви від переляканого бігу
		draw_circle(Vector2(-12.0 * fwd, 19.0), 3.2, Color(0.85, 0.82, 0.75, 0.60))
	
	# 3. Важкий незграбний бердиш (сокира-півмісяць на держаку) та рукави каптана
	if is_resting:
		# Спирається на встромлений у землю бердиш і витирає чоло рукавом!
		var pole_top := Vector2(12.0 * fwd, -14.0)
		var pole_bot := Vector2(11.5 * fwd, 20.0)
		draw_line(pole_bot, pole_top, Color(0.42, 0.26, 0.14), 2.8)
		draw_arc(pole_top + Vector2(2.0 * fwd, 4.0), 10.0, -1.3 if fwd > 0 else PI - 1.3, 1.3 if fwd > 0 else PI + 1.3, 10, Color(0.82, 0.86, 0.92), 3.2)
		var hand_lean := Vector2(11.5 * fwd, 1.5)
		draw_line(Vector2(5.5 * fwd, -2.5), hand_lean, c_coat, 3.8)
		draw_circle(hand_lean, 2.0, Color(0.96, 0.82, 0.70))
		var brow_wipe := Vector2((2.5 + sin(time_passed * 8.0) * 1.6) * fwd, -11.5)
		draw_line(Vector2(-5.5 * fwd, -2.5), brow_wipe, c_coat, 3.6)
		draw_circle(brow_wipe, 2.0, Color(0.96, 0.82, 0.70))
	elif not is_scared:
		var pole_top := Vector2(16.0 * fwd, -16.5 + waddle)
		var pole_bot := Vector2(4.5 * fwd, 15.5 + waddle)
		# Рука в червоному рукаві тримає ратище бердиша
		var hand_grip := Vector2(10.5 * fwd, 0.0 + waddle)
		draw_line(Vector2(5.5 * fwd, -2.5 + waddle), hand_grip, c_coat, 3.8)
		draw_circle(hand_grip, 2.0, Color(0.96, 0.82, 0.70))
		draw_line(pole_bot, pole_top, Color(0.42, 0.26, 0.14), 2.8) # Дерев'яне ратище
		# Залізне півмісячне лезо бердиша з полиском
		draw_arc(pole_top + Vector2(2.0 * fwd, 4.0), 10.5, -1.3 if fwd > 0 else PI - 1.3, 1.3 if fwd > 0 else PI + 1.3, 10, Color(0.82, 0.86, 0.92), 3.4)
		draw_line(pole_top + Vector2(2.0 * fwd, -6.5), pole_top + Vector2(2.0 * fwd, 12.5), Color(0.62, 0.68, 0.75), 2.0)
	else:
		# Кинув бердиш, летить шкереберть у повітрі!
		var axe_rot := time_passed * 16.0
		var axe_c := Vector2(-18.0 * fwd, -4.0 + sin(time_passed * 10.0) * 6.0)
		draw_line(axe_c - Vector2(cos(axe_rot), sin(axe_rot)) * 12.0, axe_c + Vector2(cos(axe_rot), sin(axe_rot)) * 12.0, Color(0.40, 0.25, 0.14), 2.2)
		draw_arc(axe_c + Vector2(cos(axe_rot), sin(axe_rot)) * 10.0, 6.2, 0, PI, 6, Color(0.78, 0.82, 0.88), 2.6)
		# Руки підняті догори у паніці ("Караул!")
		var arm_wave := sin(time_passed * 26.0) * 5.5
		draw_line(Vector2(-7.0 * fwd, -2.0 + waddle), Vector2(-15.5 * fwd, -15.5 + waddle + arm_wave), c_coat, 3.4)
		draw_line(Vector2(7.0 * fwd, -2.0 + waddle), Vector2(15.5 * fwd, -15.5 + waddle - arm_wave), c_coat, 3.4)
		draw_circle(Vector2(-15.5 * fwd, -15.5 + waddle + arm_wave), 2.0, Color(0.96, 0.82, 0.70))
		draw_circle(Vector2(15.5 * fwd, -15.5 + waddle - arm_wave), 2.0, Color(0.96, 0.82, 0.70))
	
	# 4. Голова, широка борода лопатою та червоний ніс-слива
	var head_c := Vector2(0.0, -8.2 + waddle)
	_draw_oval(head_c, 7.0, 6.4, Color(0.96, 0.82, 0.70))
	_draw_oval(head_c + Vector2(2.2 * fwd, 1.0), 2.2, 1.5, Color(0.95, 0.45, 0.45, 0.45)) # Червоні щоки
	
	# Волохата руда / бура борода лопатою (сатира Дахна)
	var beard_col := Color(0.46, 0.28, 0.15) if not is_scared else Color(0.35, 0.22, 0.14)
	var beard_hi := Color(0.58, 0.38, 0.22)
	var beard_pts := PackedVector2Array([
		head_c + Vector2(-5.8 * fwd, 1.8),
		head_c + Vector2(5.8 * fwd, 1.8),
		head_c + Vector2(7.5 * fwd, 11.2),
		head_c + Vector2(-7.5 * fwd, 11.2)
	])
	draw_colored_polygon(beard_pts, beard_col)
	draw_line(head_c + Vector2(-2.0 * fwd, 3.5), head_c + Vector2(-2.5 * fwd, 9.5), beard_hi, 1.4)
	draw_line(head_c + Vector2(2.0 * fwd, 3.5), head_c + Vector2(2.5 * fwd, 9.5), beard_hi, 1.4)
	# Підстрибуючі пасма бороди
	draw_line(head_c + Vector2(-4.2 * fwd, 11.0), head_c + Vector2(-4.2 * fwd, 14.2 + sin(time_passed * 12.0) * 1.5), beard_col, 2.2)
	draw_line(head_c + Vector2(0.0, 11.0), head_c + Vector2(0.0, 15.2 + cos(time_passed * 12.0) * 1.5), beard_col, 2.4)
	draw_line(head_c + Vector2(4.2 * fwd, 11.0), head_c + Vector2(4.2 * fwd, 14.2 - sin(time_passed * 12.0) * 1.5), beard_col, 2.2)
	
	# Булькатий червоний ніс-картоплина
	draw_circle(head_c + Vector2(3.8 * fwd, -0.8), 2.8, Color(0.92, 0.34, 0.34))
	draw_circle(head_c + Vector2(4.5 * fwd, -1.6), 0.9, Color(1.0, 0.78, 0.78))
	
	# Очі та брови
	if is_resting:
		# Царський стрілець упрів у важкому каптані й важко відхекується!
		draw_arc(head_c + Vector2(1.6 * fwd, -3.0), 2.0, 0.2, PI - 0.2, 6, Color(0.18, 0.10, 0.10), 1.9)
		draw_arc(head_c + Vector2(-2.4 * fwd, -3.0), 2.0, 0.2, PI - 0.2, 6, Color(0.18, 0.10, 0.10), 1.9)
		_draw_sweat_and_breath(head_c + Vector2(1.5 * fwd, -9.5), head_c + Vector2(5.5 * fwd, 3.0), fwd, "УПРІВ!")
	elif not is_scared:
		# Густа суцільна насуплена моноброва
		draw_line(head_c + Vector2(-4.8 * fwd, -5.4), head_c + Vector2(0.5 * fwd, -4.4), Color(0.24, 0.15, 0.08), 2.4)
		draw_line(head_c + Vector2(0.5 * fwd, -4.4), head_c + Vector2(4.8 * fwd, -5.2), Color(0.24, 0.15, 0.08), 2.4)
		# Маленькі хитрі оченята з білками
		draw_circle(head_c + Vector2(1.6 * fwd, -3.0), 1.9, Color.WHITE)
		draw_circle(head_c + Vector2(-2.4 * fwd, -3.0), 1.9, Color.WHITE)
		draw_circle(head_c + Vector2(2.0 * fwd, -3.0), 1.1, Color(0.12, 0.10, 0.10))
		draw_circle(head_c + Vector2(-2.0 * fwd, -3.0), 1.1, Color(0.12, 0.10, 0.10))
	else:
		# ОЧІ-БЛЮДЦЯ НА ВИКОТІ ВІД ПАНІКИ!
		var eye1 := head_c + Vector2(-2.5 * fwd, -4.5)
		var eye2 := head_c + Vector2(3.5 * fwd, -4.5)
		draw_circle(eye1, 4.3, Color.WHITE)
		draw_circle(eye2, 4.3, Color.WHITE)
		draw_circle(eye1, 1.4, Color(0.12, 0.15, 0.35))
		draw_circle(eye2, 1.4, Color(0.12, 0.15, 0.35))
		# Відкритий рот кричить від жаху
		_draw_oval(head_c + Vector2(1.5 * fwd, 3.6), 2.6, 3.4, Color(0.20, 0.05, 0.05))
	
	# 5. Висока гостроверха стрілецька шапка-ковпак із хутряною опушкою
	var fur_col := Color(0.36, 0.24, 0.14)
	if not is_scared:
		var tip_sway := sin(time_passed * 10.0) * 1.4
		_draw_oval(head_c + Vector2(0.0, -6.5), 7.8, 2.8, fur_col)
		var cap_pts := PackedVector2Array([
			head_c + Vector2(-6.2 * fwd, -7.0),
			head_c + Vector2(6.2 * fwd, -7.0),
			head_c + Vector2(-4.2 * fwd + tip_sway, -22.5)
		])
		draw_colored_polygon(cap_pts, Color(0.85, 0.15, 0.18))
		draw_line(head_c + Vector2(0.0, -7.0), head_c + Vector2(-4.2 * fwd + tip_sway, -22.5), c_braid, 1.4)
		draw_circle(head_c + Vector2(-4.2 * fwd + tip_sway, -22.5), 2.3, fur_col)
	else:
		# Шапка злетіла в повітря від переляку і обертається над головою!
		var cap_pos := head_c + Vector2(0.0, -19.0 + sin(time_passed * 20.0) * 3.2)
		var cap_angle := time_passed * 16.0
		var c_off := Vector2(cos(cap_angle), sin(cap_angle)) * 6.2
		_draw_oval(cap_pos, 6.6, 2.3, fur_col)
		draw_colored_polygon(PackedVector2Array([
			cap_pos - c_off, cap_pos + c_off, cap_pos + Vector2(0, -14.0)
		]), Color(0.85, 0.15, 0.18))
		draw_circle(cap_pos + Vector2(0, -14.0), 2.1, fur_col)

func _draw_sweat_and_breath(brow_pos: Vector2, mouth_pos: Vector2, fwd: float, rest_label: String = "ФУХ!") -> void:
	# 1. Великі виразні крапельки поту (Київнаукфільм-стиль) над чолом під час перепочинку
	for i in range(3):
		var cyc := fmod(time_passed * 2.6 + float(i) * 0.33, 1.0)
		var side := 1.0 if i % 2 == 0 else -1.0
		var drop_p := brow_pos + Vector2((3.0 + float(i) * 2.5 + cyc * 6.5) * fwd * side, -2.5 + cyc * 7.5)
		var alpha := (1.0 - cyc) * 0.95
		draw_circle(drop_p, 1.8, Color(0.35, 0.88, 1.0, alpha))
		draw_colored_polygon(PackedVector2Array([
			drop_p + Vector2(-1.5, 0.0),
			drop_p + Vector2(0.0, -3.4),
			drop_p + Vector2(1.5, 0.0)
		]), Color(0.35, 0.88, 1.0, alpha))
	
	# 2. Хмаринки важкого подиху ("Хух-парі!") біля рота
	var puff_t := fmod(time_passed * 2.2, 1.0)
	var puff_p := mouth_pos + Vector2(puff_t * 9.5 * fwd, -puff_t * 4.0)
	var puff_a := (1.0 - puff_t) * 0.78
	draw_circle(puff_p, 2.2 + puff_t * 2.6, Color(0.96, 0.98, 1.0, puff_a))
	draw_circle(puff_p + Vector2(2.6 * fwd, -1.2), 1.6 + puff_t * 1.8, Color(0.96, 0.98, 1.0, puff_a * 0.85))
	
	# 3. Коміксна хмаринка перепочинку над головою супротивника ("ФУХ!" / "УПРІВ!")
	var bub_pos := brow_pos + Vector2(0.0, -14.5 + sin(time_passed * 6.0) * 1.2)
	_draw_oval(bub_pos, 18.0, 7.2, Color(1.0, 0.98, 0.90, 0.92))
	draw_arc(bub_pos, 17.5, 0.0, TAU, 14, Color(0.18, 0.14, 0.10, 0.85), 1.3)
	var fnt := ThemeDB.fallback_font
	if fnt:
		draw_string(fnt, bub_pos + Vector2(-14.0, 3.5), rest_label, HORIZONTAL_ALIGNMENT_CENTER, 28.0, 9, Color(0.15, 0.10, 0.08))

func _draw_oval(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	var num_pts := 16
	for i in range(num_pts):
		var phi := float(i) / float(num_pts) * TAU
		pts.append(center + Vector2(cos(phi) * rx, sin(phi) * ry))
	draw_colored_polygon(pts, color)
