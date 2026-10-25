extends Node2D

class_name QirimliAlly
const _LevelRoot = preload("res://scripts/level_root.gd")

signal arrow_shot(arrow_pos: Vector2, arrow_dir: Vector2)
signal falcon_launched(falcon: Node2D)

# 6-рівнева історична ієрархія союзних NPC Побратимів-Киримли:
enum QirimliRank {
	CHORA,        # Ранг 1: Чора (юний зброєносець і розвідник з арканом — ровесник Джури)
	YIGIT,        # Ранг 2: Їгіт-Стрілець із Соколом (базовий)
	MURZA,        # Ранг 3: Мурза-Капикулу у срібній кольчузі-юшмані
	TOGANCHI,     # Ранг 4: Тоганчі-Баши (ханський сокільник і музика з даулом)
	TUGAY_BEY,    # Ранг 5: Перекопський Тугай-Бей з золотим луком і Королівським Беркутом
	QALGA_SULTAN  # Ранг 6: Калга-Султан / Хан Іслям III Ґерай зі щитом Золотої Тарак-Тамги
}

@export var qirimli_rank: QirimliRank = QirimliRank.YIGIT

const MOVE_SPEED: float = 148.0
const JUMP_VELOCITY: float = -475.0
const GRAVITY: float = 860.0
const FLOOR_Y: float = 494.0

@export var shoot_interval: float = 6.0
var velocity: Vector2 = Vector2(-MOVE_SPEED, 0.0)
var on_ground: bool = false
var run_cycle: float = 0.0
var squash_stretch: Vector2 = Vector2.ONE
var jump_decision_timer: float = 1.75
var shoot_timer: float = 2.5
var time_passed: float = 0.0
var facing_dir: float = -1.0 # Faces left or right towards enemies
var is_aiming: bool = false
var aim_progress: float = 0.0
var recoil_timer: float = 0.0
var has_launched_falcon: bool = false
var falcon_launch_timer: float = 4.2
var is_celebrating_victory: bool = false
var dance_time: float = 0.0

# Система втоми та короткого перепочинку Киримли (опускає лук і переводить подих)
var is_resting: bool = false
var rest_timer: float = 0.0
var stamina_timer: float = 7.4

@onready var speech_bubble: SpeechBubble = $SpeechBubble
var arrow_scene: PackedScene = preload("res://scenes/qirimli_arrow.tscn")
var falcon_scene: PackedScene = preload("res://scenes/qirimli_falcon.tscn")

const PHRASES_GREETING: Array[String] = [
	"Селям алейкум, Джуро!",
	"Разом ми непереможні, брате!",
	"Обороняємо фортецю пліч-о-пліч!"
]

const PHRASES_REST: Array[String] = [
	"Переведемо подих на мить, брате Джуро!",
	"Ох і спекотний бій — перепочину секунду!",
	"Дам спочити тятиві лука — і знову до бою!"
]

const PHRASES_COMBAT: Array[String] = [
	"Лови стрілу, царський стрільче!",
	"Стережися, Джуро, я прикриваю!",
	"Машалла! Чудовий стрибок!",
	"Не пропустимо нечисть на наші землі!"
]

const PHRASES_VICTORY: Array[String] = [
	"Перемога! Слава козакам і Киримли!",
	"Ай-яй, яка перемога! Танцюймо!",
	"Машалла, брате Джуро!"
]

func _ready() -> void:
	shoot_timer = randf_range(2.0, 4.0)
	stamina_timer = randf_range(6.8, 9.4)
	await get_tree().create_timer(1.2).timeout
	say(PHRASES_GREETING.pick_random(), 2.8)

func start_rest(duration: float = 1.85) -> void:
	if is_celebrating_victory:
		return
	is_resting = true
	is_aiming = false
	rest_timer = duration
	velocity.x = 0.0
	if randf() < 0.65:
		say(PHRASES_REST.pick_random(), 1.8)
	queue_redraw()

func _process(delta: float) -> void:
	time_passed += delta
	squash_stretch = squash_stretch.lerp(Vector2.ONE, delta * 12.0)
	if recoil_timer > 0.0:
		recoil_timer -= delta
	
	if is_celebrating_victory:
		is_resting = false
		dance_time += delta
		queue_redraw()
		return
	
	if is_resting:
		rest_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, delta * 900.0)
		_apply_platformer_physics(delta)
		if rest_timer <= 0.0:
			is_resting = false
			stamina_timer = randf_range(6.8, 9.6)
		queue_redraw()
		return
	else:
		stamina_timer -= delta
		if stamina_timer <= 0.0 and on_ground and not is_aiming:
			start_rest(randf_range(1.75, 2.2))
			return
	
	if not has_launched_falcon:
		falcon_launch_timer -= delta
		if falcon_launch_timer <= 0.0:
			launch_falcon()
	
	shoot_timer -= delta
	if shoot_timer <= 0.85 and not is_aiming:
		is_aiming = true
	
	if is_aiming:
		aim_progress = clampf(1.0 - (shoot_timer / 0.85), 0.0, 1.0)
		velocity.x = move_toward(velocity.x, 0.0, delta * 900.0)
	else:
		aim_progress = move_toward(aim_progress, 0.0, delta * 5.0)
		velocity.x = facing_dir * MOVE_SPEED
		jump_decision_timer -= delta
		if on_ground and jump_decision_timer <= 0.0:
			_perform_jump()
			jump_decision_timer = randf_range(1.1, 1.85)
	
	run_cycle += absf(velocity.x) * delta * 0.065
	_apply_platformer_physics(delta)
	
	if shoot_timer <= 0.0:
		_shoot_arrow()
		recoil_timer = 0.22
		shoot_timer = shoot_interval + randf_range(-1.0, 1.5)
		is_aiming = false
		aim_progress = 0.0
		if randf() < 0.45:
			say(PHRASES_COMBAT.pick_random(), 2.2)
	
	queue_redraw()

func _perform_jump() -> void:
	velocity.y = JUMP_VELOCITY
	on_ground = false
	squash_stretch = Vector2(0.82, 1.24)

func _apply_platformer_physics(delta: float) -> void:
	var prev_y := position.y
	velocity.y += GRAVITY * delta
	position += velocity * delta
	on_ground = false
	
	var par = _LevelRoot.of(self)
	if par and par.has_node("Platforms") and velocity.y >= 0.0:
		for plat in par.get_node("Platforms").get_children():
			if plat is BombJackPlatform:
				var half_w: float = plat.width * 0.5 + 10.0
				var plat_top: float = plat.position.y - 22.0
				if absf(position.x - plat.position.x) <= half_w:
					if prev_y <= plat_top + 8.0 and position.y >= plat_top:
						position.y = plat_top
						if velocity.y > 180.0:
							squash_stretch = Vector2(1.24, 0.80)
						velocity.y = 0.0
						on_ground = true
						break
	
	if position.y >= FLOOR_Y:
		position.y = FLOOR_Y
		if velocity.y > 180.0:
			squash_stretch = Vector2(1.24, 0.80)
		velocity.y = 0.0
		on_ground = true
	
	if position.x < 36.0:
		position.x = 36.0
		facing_dir = 1.0
	elif position.x > 924.0:
		position.x = 924.0
		facing_dir = -1.0

func say(text: String, duration: float = 2.0) -> void:
	if speech_bubble:
		speech_bubble.say(text, duration)

func get_victory_dance_name() -> String:
	match qirimli_rank:
		QirimliRank.TOGANCHI:
			return "qirimli_davul_qaytarma"
		QirimliRank.MURZA, QirimliRank.TUGAY_BEY, QirimliRank.QALGA_SULTAN:
			return "qirimli_horan_tamga"
		_:
			return "qirimli_qaytarma_falcon"

func celebrate_victory() -> void:
	is_celebrating_victory = true
	velocity = Vector2.ZERO
	squash_stretch = Vector2.ONE
	dance_time = 0.0
	if qirimli_rank == QirimliRank.TOGANCHI:
		say("Вдаримо в даул! Танцюймо святкову Хайтарму!", 3.5)
	elif qirimli_rank in [QirimliRank.TUGAY_BEY, QirimliRank.QALGA_SULTAN]:
		say("Слава козакам і Киримли! Танцюймо Акъмесджит Хораны!", 3.5)
	else:
		say(PHRASES_VICTORY.pick_random(), 3.5)
	queue_redraw()

# Одноразовий запуск вірного степового Сокола (Şahin / Лачин) проти Нечистої Сили!
func launch_falcon() -> bool:
	if has_launched_falcon:
		return false
	has_launched_falcon = true
	
	var falcon = falcon_scene.instantiate()
	falcon.global_position = global_position + Vector2(facing_dir * 10.0, -14.0)
	falcon.velocity = Vector2(facing_dir * 420.0, 40.0)
	if get_parent():
		get_parent().add_child(falcon)
	say("Лети, мій Соколе! Розжени нечисту силу!", 2.8)
	falcon_launched.emit(falcon)
	queue_redraw()
	return true

func _shoot_arrow() -> void:
	# Find target enemy (prioritizing MOSKAL or nearest enemy)
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		# Fallback search by type in parent
		var par = _LevelRoot.of(self)
		if par and par.has_node("Enemies"):
			var e_node = par.get_node("Enemies")
			for c in e_node.get_children():
				if c is FolkloreEnemy and not c.is_queued_for_deletion():
					enemies.append(c)
	
	var target_pos := global_position + Vector2(facing_dir * 300.0, 0.0)
	if not enemies.is_empty():
		# Prioritize Moskal
		var moskals = enemies.filter(func(e): return e.enemy_type == FolkloreEnemy.EnemyType.MOSKAL)
		var chosen = moskals.pick_random() if not moskals.is_empty() else enemies.pick_random()
		if chosen:
			target_pos = chosen.global_position
			facing_dir = signf(target_pos.x - global_position.x)
			if absf(facing_dir) < 0.1:
				facing_dir = -1.0
	
	var dir := (target_pos - (global_position + Vector2(facing_dir * 12.0, -8.0))).normalized()
	
	var arrow = arrow_scene.instantiate()
	arrow.global_position = global_position + Vector2(facing_dir * 14.0, -8.0)
	arrow.velocity = dir * 460.0
	get_parent().add_child(arrow)
	arrow_shot.emit(arrow.global_position, arrow.velocity)

func _draw() -> void:
	var fwd := facing_dir
	if is_celebrating_victory:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_draw_celebrating(fwd)
		return
	
	var run_anim := sin(run_cycle)
	var bob := absf(run_anim) * -2.0 if on_ground and absf(velocity.x) > 10.0 else sin(time_passed * 6.0) * 1.4
	var tilt := (velocity.x / MOVE_SPEED) * 0.08
	draw_set_transform(Vector2.ZERO, tilt, squash_stretch)
	
	# Контактна тінь на мурі
	if on_ground:
		_draw_oval(Vector2(0.0, 21.5), 9.5, 2.8, Color(0.0, 0.0, 0.05, 0.35))
	
	# Золотий щит Тарак-Тамги для високих рангів (Тугай-Бей / Калга-Султан / Мурза)
	if qirimli_rank in [QirimliRank.MURZA, QirimliRank.TUGAY_BEY, QirimliRank.QALGA_SULTAN]:
		draw_circle(Vector2(0.0, 2.0 + bob), 18.0, Color(0.20, 0.85, 0.98, 0.16))
		draw_arc(Vector2(0.0, 2.0 + bob), 18.0, 0.0, TAU, 14, Color(1.0, 0.86, 0.22, 0.35), 1.5)
	
	# 1. Стрункі ноги у темно-синіх шароварах та м'яких шкіряних чоботях (ічіги / чєріки) — біг та стрибки!
	var is_moving := absf(velocity.x) > 15.0
	var stride_l := run_anim * 6.0 if (on_ground and is_moving) else (-3.5 if not on_ground else 0.0)
	var stride_r := -run_anim * 6.0 if (on_ground and is_moving) else (4.0 if not on_ground else 0.0)
	var lift_l := maxf(0.0, run_anim) * 2.8 if (on_ground and is_moving) else (2.2 if not on_ground else 0.0)
	var lift_r := maxf(0.0, -run_anim) * 2.8 if (on_ground and is_moving) else (1.4 if not on_ground else 0.0)
	var ankle_l := Vector2((-4.0 + stride_l) * fwd, 20.5 - lift_l)
	var ankle_r := Vector2((4.0 + stride_r) * fwd, 20.5 - lift_r)
	
	draw_line(Vector2(-4.0 * fwd, 13.0 + bob), ankle_l, Color(0.14, 0.18, 0.28), 3.4)
	draw_line(Vector2(4.0 * fwd, 13.0 + bob), ankle_r, Color(0.14, 0.18, 0.28), 3.4)
	_draw_oval(ankle_l + Vector2(1.5 * fwd, 0.5), 3.4, 1.8, Color(0.45, 0.28, 0.16))
	_draw_oval(ankle_r + Vector2(1.5 * fwd, 0.5), 3.4, 1.8, Color(0.45, 0.28, 0.16))
	
	# 2. Сагайдак зі стрілами за спиною та кримська шабля (клидж / qılıç) при поясі
	var q_top := Vector2(-10.5 * fwd, -16.5 + bob)
	var q_bot := Vector2(-5.5 * fwd, 4.0 + bob)
	draw_line(q_bot, q_top, Color(0.48, 0.28, 0.14), 4.6)
	draw_line(q_bot.lerp(q_top, 0.5), q_bot.lerp(q_top, 0.7), Color(0.96, 0.82, 0.18), 2.2) # Золотий орнамент сагайдака
	# Біле соколине оперення стріл
	for a_i in range(3):
		var a_off := Vector2((float(a_i) - 1.0) * 2.6 * fwd, -5.5 - float(a_i % 2) * 1.5)
		draw_line(q_top, q_top + a_off, Color(0.95, 0.96, 1.0), 1.7)
	
	# Вигнута шабля-клидж у піхвах збоку
	var sabre_hilt := Vector2(-4.5 * fwd, 6.5 + bob)
	var sabre_tip := Vector2(-14.5 * fwd, 16.5 + bob)
	draw_line(sabre_hilt, sabre_tip, Color(0.25, 0.18, 0.14), 2.4)
	draw_circle(sabre_hilt + Vector2(1.5 * fwd, -1.5), 1.8, Color(0.98, 0.84, 0.20)) # Золоте перехрестя шаблі
	
	# 3. Тіло та смарагдово-зелений традиційний бешмет / чекмень (Київнаукфільм)
	var c_coat := Color(0.12, 0.44, 0.33) # Смарагдовий кримськотатарський бешмет
	var c_coat_hi := Color(0.18, 0.56, 0.42)
	var c_gold := Color(0.96, 0.82, 0.18) # Золота тасьма
	
	var body_pts := PackedVector2Array([
		Vector2(-7.2 * fwd, -4.5 + bob),
		Vector2(7.2 * fwd, -4.5 + bob),
		Vector2(10.5 * fwd, 14.2),
		Vector2(-9.5 * fwd, 14.2)
	])
	draw_colored_polygon(body_pts, c_coat)
	draw_line(Vector2(2.0 * fwd, -4.0 + bob), Vector2(3.5 * fwd, 13.5), c_coat_hi, 2.4)
	draw_line(Vector2(-9.2 * fwd, 14.0), Vector2(10.2 * fwd, 14.0), c_gold, 1.6)
	# Нагрудні срібні газирі (hazine) та золоті чапрази на смарагдовому бешметі
	for ch_i in range(2):
		var cy := -1.5 + float(ch_i) * 3.0 + bob
		draw_line(Vector2(-4.5 * fwd, cy), Vector2(4.5 * fwd, cy), c_gold, 1.4)
	for gz_i in range(-2, 3):
		if gz_i != 0:
			var gx := float(gz_i) * 1.9 * fwd
			draw_line(Vector2(gx, -2.8 + bob), Vector2(gx, 0.6 + bob), Color(0.90, 0.92, 0.96), 1.2)
	draw_line(Vector2(0, -4.5 + bob), Vector2(0, 6.0 + bob), c_gold, 1.6)
	
	# Багряно-золотий шовковий пояс-кушак (їпек къушакъ) зі срібною пряжкою-пафтою та кинджалом-пичаком!
	_draw_oval(Vector2(0.0, 5.8 + bob), 7.8, 2.2, Color(0.78, 0.14, 0.18))
	draw_line(Vector2(-7.2 * fwd, 5.8 + bob), Vector2(7.2 * fwd, 5.8 + bob), c_gold, 1.5)
	_draw_oval(Vector2(0.8 * fwd, 5.8 + bob), 2.4, 1.6, Color(0.95, 0.90, 0.55)) # Філігранна пряжка
	draw_line(Vector2(2.8 * fwd, 4.2 + bob), Vector2(5.2 * fwd, 8.8 + bob), Color(1.0, 0.86, 0.22), 1.8) # Кинджал пичак
	var sash_tail := Vector2(-5.5 * fwd + sin(time_passed * 7.0) * 1.4, 12.5 + bob)
	draw_line(Vector2(-4.5 * fwd, 6.5 + bob), sash_tail, c_gold, 2.0)
	
	# 4. Двосегментні руки та складний кримськотатарський композитний лук (Qabaq Yay)
	if is_aiming or recoil_timer > 0.0:
		var pull := aim_progress if is_aiming else 0.0
		var bow_hand := Vector2(14.5 * fwd, -7.2 + bob)
		var bow_elbow := Vector2(7.5 * fwd, -4.5 + bob)
		var string_hand := bow_hand.lerp(Vector2(-2.5 * fwd, -7.2 + bob), pull)
		var string_elbow := Vector2(-7.5 * fwd, -5.0 + bob)
		
		# Передня рука тримає рукоять лука
		draw_line(Vector2(3.5 * fwd, -3.0 + bob), bow_elbow, c_coat, 3.4)
		draw_line(bow_elbow, bow_hand, c_coat_hi, 3.0)
		draw_circle(bow_hand, 1.9, Color(0.96, 0.84, 0.72))
		
		# Вигнутий композитний роговий лук (гинається сильніше при натягуванні!)
		var bow_curve := 1.15 + pull * 0.22
		draw_arc(bow_hand - Vector2(3.5 * fwd, 0), 15.5, -bow_curve if fwd > 0 else PI - bow_curve, bow_curve if fwd > 0 else PI + bow_curve, 12, Color(0.58, 0.38, 0.16), 3.0)
		draw_arc(bow_hand - Vector2(3.5 * fwd, 0), 14.5, -bow_curve * 0.6 if fwd > 0 else PI - bow_curve * 0.6, bow_curve * 0.6 if fwd > 0 else PI + bow_curve * 0.6, 8, c_gold, 1.4)
		
		var tip_top := bow_hand + Vector2(-2.5 * fwd * pull, -14.0)
		var tip_bot := bow_hand + Vector2(-2.5 * fwd * pull, 14.0)
		var string_mid := string_hand
		if recoil_timer > 0.0:
			string_mid = bow_hand + Vector2(sin(time_passed * 55.0) * 2.5 * fwd, 0.0)
		draw_line(tip_top, string_mid, Color(0.95, 0.96, 1.0), 1.3)
		draw_line(tip_bot, string_mid, Color(0.95, 0.96, 1.0), 1.3)
		
		# Задня рука відтягує тятиву до щоки
		draw_line(Vector2(-3.5 * fwd, -3.0 + bob), string_elbow, c_coat, 3.4)
		draw_line(string_elbow, string_hand, c_coat, 3.0)
		draw_circle(string_hand, 1.9, Color(0.96, 0.84, 0.72))
		
		if is_aiming:
			# Стріла з білим оперенням і золотим вістрям на тятиві
			var arrow_tip := bow_hand + Vector2(6.5 * fwd, 0.0)
			draw_line(string_hand, arrow_tip, Color(0.92, 0.78, 0.45), 2.0)
			draw_colored_polygon(PackedVector2Array([
				arrow_tip + Vector2(3.5 * fwd, 0.0),
				arrow_tip + Vector2(-1.5 * fwd, -2.2),
				arrow_tip + Vector2(-1.5 * fwd, 2.2)
			]), Color(1.0, 0.92, 0.25))
	else:
		# Спокійна вартова стійка з луком напоготові
		var hand_rest := Vector2(8.5 * fwd, 3.5 + bob)
		draw_line(Vector2(3.0 * fwd, -2.5 + bob), hand_rest, c_coat, 3.4)
		draw_circle(hand_rest, 1.9, Color(0.96, 0.84, 0.72))
		draw_arc(hand_rest, 14.0, -0.95 if fwd > 0 else PI - 0.95, 0.95 if fwd > 0 else PI + 0.95, 10, Color(0.58, 0.38, 0.16), 2.8)
	
	# 5. Голова та виразне обличчя відважного кримськотатарського їгіта
	var head_c := Vector2(0.0, -8.8 + bob)
	_draw_oval(head_c, 6.7, 6.3, Color(0.96, 0.84, 0.72))
	_draw_oval(head_c + Vector2(2.5 * fwd, 1.5), 2.0, 1.4, Color(0.95, 0.48, 0.48, 0.38))
	
	# Очі: пильний приціл при натягуванні лука, перепочинок або відкритий дружній погляд
	var eye_c := head_c + Vector2(2.4 * fwd, -1.8)
	if is_resting:
		draw_arc(eye_c, 2.0, 0.2, PI - 0.2, 6, Color(0.16, 0.10, 0.08), 1.7)
		_draw_rest_sweat_and_breath(head_c + Vector2(1.5 * fwd, -7.5), head_c + Vector2(5.0 * fwd, 2.5), fwd)
	elif is_aiming and aim_progress > 0.35:
		# Снайперський приціл сокола!
		draw_line(eye_c + Vector2(-2.2 * fwd, -0.4), eye_c + Vector2(2.2 * fwd, 0.0), Color(0.14, 0.10, 0.08), 1.9)
		draw_circle(eye_c + Vector2(0.8 * fwd, 0.0), 1.1, Color(0.15, 0.25, 0.35))
	else:
		draw_circle(eye_c, 2.2, Color.WHITE)
		draw_circle(eye_c + Vector2(0.8 * fwd, 0.0), 1.25, Color(0.15, 0.25, 0.35))
		draw_circle(eye_c + Vector2(1.1 * fwd, -0.4), 0.55, Color.WHITE)
	# Виразна соколина брова
	draw_line(eye_c + Vector2(-2.4 * fwd, -2.6), eye_c + Vector2(2.4 * fwd, -1.9), Color(0.16, 0.10, 0.08), 1.7)
	
	# Тонкі шляхетні вусики їгіта та щира посмішка
	draw_line(head_c + Vector2(1.0 * fwd, 1.8), head_c + Vector2(4.8 * fwd, 1.2), Color(0.16, 0.10, 0.08), 1.5)
	draw_arc(head_c + Vector2(1.8 * fwd, 2.8), 2.4, 0.2, PI - 0.2, 6, Color(0.68, 0.18, 0.18), 1.6)
	
	# 6. Традиційний кримськотатарський калпак (Къалпакъ) з блакитним верхом, золотою Тарак-Тамгою та білим соколиним пером!
	var hat_c := head_c + Vector2(0.0, -6.5)
	_draw_oval(hat_c, 7.6, 2.9, Color(0.14, 0.12, 0.14)) # Каракулева опушка
	var hat_top := PackedVector2Array([
		hat_c + Vector2(-5.6 * fwd, -1.0),
		hat_c + Vector2(5.6 * fwd, -1.0),
		hat_c + Vector2(3.6 * fwd, -9.2),
		hat_c + Vector2(-3.6 * fwd, -9.2)
	])
	draw_colored_polygon(hat_top, Color(0.20, 0.56, 0.86)) # Небесно-блакитний Kök mavı
	
	# Біле соколине перо збоку калпака, що коливається на вітрі
	var feather_sway := sin(time_passed * 9.0) * 1.8
	var f_base := hat_c + Vector2(-4.2 * fwd, -3.5)
	var f_tip := hat_c + Vector2(-9.5 * fwd + feather_sway, -13.5)
	draw_line(f_base, f_tip, Color(0.96, 0.98, 1.0), 2.4)
	draw_circle(f_base, 1.2, Color(1.0, 0.86, 0.20)) # Золота брошка пера
	
	# Золота кримськотатарська Тарак-Тамга (Taraq Tamğa) на калпаку!
	var t_pos := hat_c + Vector2(0.0, -5.0)
	draw_line(t_pos + Vector2(0, 3), t_pos + Vector2(0, -3), Color(1.0, 0.88, 0.22), 1.6)
	draw_line(t_pos + Vector2(-3, 0), t_pos + Vector2(3, 0), Color(1.0, 0.88, 0.22), 1.5)
	draw_line(t_pos + Vector2(-3, 0), t_pos + Vector2(-3, -3), Color(1.0, 0.88, 0.22), 1.5)
	draw_line(t_pos + Vector2(3, 0), t_pos + Vector2(3, -3), Color(1.0, 0.88, 0.22), 1.5)
	
	# 7. Степовий Сокіл (Şahin) на плечі Киримли (до одноразового запуску!)
	if not has_launched_falcon:
		var f_pos := Vector2(-6.5 * fwd, -8.0 + bob)
		_draw_oval(f_pos, 3.2, 4.6, Color(0.36, 0.24, 0.16))
		_draw_oval(f_pos + Vector2(1.0 * fwd, 0.5), 2.0, 3.2, Color(0.92, 0.84, 0.72))
		var f_head := f_pos + Vector2(0.8 * fwd, -4.8)
		draw_circle(f_head, 2.4, Color(0.20, 0.14, 0.12))
		draw_colored_polygon(PackedVector2Array([
			f_head + Vector2(1.8 * fwd, -0.8),
			f_head + Vector2(4.2 * fwd, 0.2),
			f_head + Vector2(1.6 * fwd, 1.0)
		]), Color(1.0, 0.86, 0.20))
		draw_circle(f_head + Vector2(0.8 * fwd, -0.5), 0.7, Color(1.0, 0.90, 0.25))

# Танець святкування перемоги (кримськотатарський Хоран / Хайтарма — Qaytarma)
func _draw_celebrating(_fwd: float) -> void:
	var jump_bob := absf(sin(dance_time * 8.5)) * 6.5
	var arm_wave := sin(dance_time * 8.5)
	var body_sway := cos(dance_time * 4.25) * 1.8
	var c_coat := Color(0.12, 0.44, 0.33)
	var c_gold := Color(0.96, 0.82, 0.18)
	
	# Контактна тінь у танці
	_draw_oval(Vector2(body_sway * 0.5, 21.0), 8.5, 2.4, Color(0.0, 0.0, 0.05, 0.32))
	
	# Танцюючі ноги у кримськотатарських чоботях-ічігах
	var step_l := maxf(0.0, arm_wave) * 3.5
	var step_r := maxf(0.0, -arm_wave) * 3.5
	draw_line(Vector2(-4.0 + body_sway, 12.0 - jump_bob), Vector2(-6.5, 19.5 - step_l), Color(0.14, 0.18, 0.28), 3.2)
	draw_line(Vector2(4.0 + body_sway, 12.0 - jump_bob), Vector2(6.5, 19.5 - step_r), Color(0.14, 0.18, 0.28), 3.2)
	_draw_oval(Vector2(-6.5, 19.5 - step_l), 3.4, 1.8, Color(0.45, 0.28, 0.16))
	_draw_oval(Vector2(6.5, 19.5 - step_r), 3.4, 1.8, Color(0.45, 0.28, 0.16))
	
	# Корпус у святковому бешметі
	var body_pts := PackedVector2Array([
		Vector2(-7.2 + body_sway, -4.0 - jump_bob),
		Vector2(7.2 + body_sway, -4.0 - jump_bob),
		Vector2(10.0 + body_sway, 12.5 - jump_bob),
		Vector2(-10.0 + body_sway, 12.5 - jump_bob)
	])
	draw_colored_polygon(body_pts, c_coat)
	_draw_oval(Vector2(body_sway, 5.2 - jump_bob), 7.8, 2.2, Color(0.78, 0.14, 0.18))
	draw_line(Vector2(-7.5 + body_sway, 5.2 - jump_bob), Vector2(7.5 + body_sway, 5.2 - jump_bob), c_gold, 1.8)
	
	# Класична постановка рук у танці Хайтарма (одна рука високо вигнута соколом, друга вбік)
	var elbow_l := Vector2(-12.5 + body_sway, -6.5 - jump_bob + arm_wave * 3.0)
	var hand_l := Vector2(-16.5 + body_sway, -15.5 - jump_bob + arm_wave * 6.5)
	var elbow_r := Vector2(12.5 + body_sway, -6.5 - jump_bob - arm_wave * 3.0)
	var hand_r := Vector2(16.5 + body_sway, -15.5 - jump_bob - arm_wave * 6.5)
	draw_line(Vector2(-6.5 + body_sway, -2.5 - jump_bob), elbow_l, c_coat, 3.4)
	draw_line(elbow_l, hand_l, c_coat, 3.0)
	draw_line(Vector2(6.5 + body_sway, -2.5 - jump_bob), elbow_r, c_coat, 3.4)
	draw_line(elbow_r, hand_r, c_coat, 3.0)
	draw_circle(hand_l, 2.2, Color(0.96, 0.84, 0.72))
	draw_circle(hand_r, 2.2, Color(0.96, 0.84, 0.72))
	if qirimli_rank == QirimliRank.TOGANCHI:
		# Тоганчі-Баши у танці Хайтарма б'є у кримський барабан-даул!
		var davul_c := Vector2(-9.5 + body_sway, 4.0 - jump_bob)
		_draw_oval(davul_c, 5.5, 4.8, Color(0.58, 0.34, 0.16))
		_draw_oval(davul_c, 4.2, 3.6, Color(0.96, 0.92, 0.82))
		draw_line(hand_r, davul_c, Color(0.45, 0.25, 0.12), 2.0)
	elif qirimli_rank in [QirimliRank.MURZA, QirimliRank.TUGAY_BEY, QirimliRank.QALGA_SULTAN]:
		# Золотий ореол Акъмесджит Хораны із Тарак-Тамгою
		draw_arc(Vector2(body_sway, -2.0 - jump_bob), 20.0, 0.0, TAU, 16, Color(1.0, 0.88, 0.22, 0.55), 1.8)
	
	# Голова, калпак із Тарак-Тамгою та соколиним пером
	var head_c := Vector2(body_sway, -8.8 - jump_bob)
	_draw_oval(head_c, 6.7, 6.3, Color(0.96, 0.84, 0.72))
	_draw_oval(head_c + Vector2(0.0, -6.5), 7.6, 2.9, Color(0.14, 0.12, 0.14))
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-5.2, -7.5), head_c + Vector2(5.2, -7.5),
		head_c + Vector2(3.4, -15.5), head_c + Vector2(-3.4, -15.5)
	]), Color(0.20, 0.56, 0.86))
	draw_line(head_c + Vector2(-4.0, -9.5), head_c + Vector2(-9.5 + arm_wave * 2.0, -18.5), Color.WHITE, 2.2)
	var t_pos := head_c + Vector2(0.0, -11.5)
	draw_line(t_pos + Vector2(0, 2.5), t_pos + Vector2(0, -2.5), c_gold, 1.5)
	draw_line(t_pos + Vector2(-2.5, 0), t_pos + Vector2(2.5, 0), c_gold, 1.5)
	
	# Щасливі замружені очі «^_^», вусики та широка посмішка побратима
	draw_arc(head_c + Vector2(-2.2, -2.0), 2.0, PI + 0.3, TAU - 0.3, 6, Color(0.18, 0.12, 0.10), 1.6)
	draw_arc(head_c + Vector2(2.2, -2.0), 2.0, PI + 0.3, TAU - 0.3, 6, Color(0.18, 0.12, 0.10), 1.6)
	draw_line(head_c + Vector2(-3.8, 1.4), head_c + Vector2(-1.0, 1.8), Color(0.16, 0.10, 0.08), 1.4)
	draw_line(head_c + Vector2(1.0, 1.8), head_c + Vector2(3.8, 1.4), Color(0.16, 0.10, 0.08), 1.4)
	draw_arc(head_c + Vector2(0.0, 2.5), 3.2, 0.2, PI - 0.2, 8, Color(0.70, 0.15, 0.18), 2.0)

func _draw_rest_sweat_and_breath(brow_pos: Vector2, mouth_pos: Vector2, fwd: float) -> void:
	for i in range(2):
		var cyc := fmod(time_passed * 2.3 + float(i) * 0.5, 1.0)
		var drop_p := brow_pos + Vector2((3.5 + float(i) * 2.8 + cyc * 5.0) * fwd, -1.5 + cyc * 6.0)
		var alpha := (1.0 - cyc) * 0.88
		draw_circle(drop_p, 1.3, Color(0.42, 0.85, 1.0, alpha))
	var puff_t := fmod(time_passed * 1.8, 1.0)
	var puff_p := mouth_pos + Vector2(puff_t * 8.0 * fwd, -puff_t * 3.0)
	var puff_a := (1.0 - puff_t) * 0.62
	draw_circle(puff_p, 1.7 + puff_t * 2.0, Color(0.95, 0.98, 1.0, puff_a))

func _draw_oval(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	var num_pts := 16
	for i in range(num_pts):
		var phi := float(i) / float(num_pts) * TAU
		pts.append(center + Vector2(cos(phi) * rx, sin(phi) * ry))
	draw_colored_polygon(pts, color)
