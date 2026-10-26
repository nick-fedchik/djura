extends Node2D

class_name HutsulAlly
const _LevelRoot = preload("res://scripts/level_root.gd")

signal bartka_melee_hit(enemy: Node2D)
signal bartka_thrown(bartka_pos: Vector2, target_pos: Vector2)
signal exited_scene

# Ієрархія союзних NPC Карпатських Гуцулів + Побратимів-Литвинів («Погоня»):
enum HutsulRank { LEGIN, OPRYSHOK, BOKORASH, TREMBITAR, MOLFAR, DOVBUSH, LITVIN_POHONIA }  # Ранг 1: Легінь-Полониник із флоярою  # Ранг 2: Гуцул-Опришок з мосяжною барткою (базовий)  # Ранг 3: Керманич-Бокораш із гаком-цапіною  # Ранг 4: Трембітар Полонини  # Ранг 5: Карпатський Мольфар-Градівник  # Ранг 6: Отаман Олекса Довбуш / Іван Сила з Золотою Громовою Барткою  # Побратим-Литвин ВКЛ / Білої Русі з щитом «Погоня» та гусарськими крилами

@export var hutsul_rank: HutsulRank = HutsulRank.OPRYSHOK

const MOVE_SPEED: float = 155.0
const JUMP_VELOCITY: float = -485.0
const GRAVITY: float = 860.0
const FLOOR_Y: float = 494.0

var velocity: Vector2 = Vector2(MOVE_SPEED, 0.0)
var on_ground: bool = false
var run_cycle: float = 0.0
var squash_stretch: Vector2 = Vector2.ONE
var time_passed: float = 0.0
var facing_dir: float = 1.0

# Бойова система: ближній бій барткою + одноразовий кидок і вихід зі сцени
var melee_cooldown: float = 0.0
var melee_swing_timer: float = 0.0
var melee_hits_count: int = 0
var has_thrown_bartka: bool = false
var is_exiting_scene: bool = false
var exit_dir: float = -1.0
var throw_countdown: float = 16.0
var jump_decision_timer: float = 1.65

var is_celebrating_victory: bool = false
var dance_time: float = 0.0

# Система втоми та короткого перепочинку Гуцула (спирається на бартку і переводить дух)
var is_resting: bool = false
var rest_timer: float = 0.0
var stamina_timer: float = 7.0

@onready var speech_bubble: SpeechBubble = $SpeechBubble
var bartka_scene: PackedScene = preload("res://scenes/hutsul_bartka.tscn")
var snd_bonk = preload("res://assets/audio/bonk.wav")
var snd_jump = preload("res://assets/audio/jump.wav")

const PHRASES_GREETING: Array[String] = [
	"Йой, здоров був, брате Джуро! Карпати на підмозі!",
	"Гей, бачу тобі туго — опришки прийшли!",
	"Тримайся, Джуро, зараз почастуємо злодіїв барткою!"
]

const PHRASES_REST: Array[String] = [
	"Хух, дай-но переведу дух після опришківського бігу!",
	"Йой, трохи впрів — перепочину на хвильку!",
	"Сперся на бартку, переведу подих — і знову в бій!"
]

const PHRASES_MELEE: Array[String] = [
	"На тобі барткою межи плечі, злодію!",
	"Ось тобі карпатський гостинець!",
	"Йой, тікай, нечиста сило, бо бартка пече!",
	"Лупцюймо опришківською барткою!"
]

const PHRASES_THROW_EXIT: Array[String] = [
	"Лови бартку наостанок! А я вертаю в Чорногору!",
	"Справу зроблено, брате Джуро! Бувай здоров!",
	"Метнув бартку межи роги — час назад у полонини!"
]

const PHRASES_VICTORY: Array[String] = [
	"Тріолі-гойра! Танцюймо гуцульський Аркан!", "Йой, яка файна перемога, брате Джуро!", "Слава козакам, опришкам і Киримли!"
]


func _ready() -> void:
	stamina_timer = randf_range(6.2, 8.8)
	await get_tree().create_timer(0.35).timeout
	say(PHRASES_GREETING.pick_random(), 2.6)


func start_rest(duration: float = 1.9) -> void:
	if is_celebrating_victory or is_exiting_scene:
		return
	is_resting = true
	rest_timer = duration
	velocity.x = 0.0
	if randf() < 0.65:
		say(PHRASES_REST.pick_random(), 1.8)
	queue_redraw()


func _process(delta: float) -> void:
	time_passed += delta
	squash_stretch = squash_stretch.lerp(Vector2.ONE, delta * 12.0)

	if melee_cooldown > 0.0:
		melee_cooldown -= delta
	if melee_swing_timer > 0.0:
		melee_swing_timer -= delta

	if is_celebrating_victory:
		is_resting = false
		dance_time += delta
		queue_redraw()
		return

	# 1. Якщо Гуцул уже метнув бартку — він стрімко біжить і стрибає за край сцени!
	if is_exiting_scene:
		is_resting = false
		facing_dir = exit_dir
		velocity.x = exit_dir * (MOVE_SPEED * 1.38)
		run_cycle += delta * 18.0
		_apply_platformer_physics(delta, false)
		if position.x < -36.0 or position.x > 996.0:
			exited_scene.emit()
			queue_free()
			return
		queue_redraw()
		return

	# 1.5. Короткий перепочинок після інтенсивного бігу та стрибків
	if is_resting:
		rest_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, delta * 900.0)
		_apply_platformer_physics(delta, true)
		if rest_timer <= 0.0:
			is_resting = false
			stamina_timer = randf_range(6.5, 9.2)
		queue_redraw()
		return
	else:
		stamina_timer -= delta
		if stamina_timer <= 0.0 and on_ground and melee_swing_timer <= 0.0:
			start_rest(randf_range(1.75, 2.25))
			return

	# 2. Самостійний рух, стрибки по платформах (як у Джури) та пошук ворогів
	var enemies := _get_active_enemies()
	var nearest_enemy: FolkloreEnemy = null
	var nearest_dist := 99999.0
	for e in enemies:
		var d := global_position.distance_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest_enemy = e

	if nearest_enemy:
		var dx := nearest_enemy.global_position.x - global_position.x
		if absf(dx) > 14.0:
			facing_dir = signf(dx)
		velocity.x = facing_dir * MOVE_SPEED

		# Якщо ворог вище — Гуцул самостійно високо стрибає на балку як Джура!
		jump_decision_timer -= delta
		if on_ground and jump_decision_timer <= 0.0 and (nearest_enemy.global_position.y < global_position.y - 36.0 or randf() < 0.35):
			_perform_jump()
			jump_decision_timer = randf_range(0.95, 1.65)

		# Ближній бій: лупить барткою злодіїв поруч себе!
		if nearest_dist <= 56.0 and melee_cooldown <= 0.0 and not has_thrown_bartka:
			melee_strike_enemy(nearest_enemy)
	else:
		# Патрульний біг і стрибки по арені
		velocity.x = facing_dir * MOVE_SPEED * 0.85
		jump_decision_timer -= delta
		if on_ground and jump_decision_timer <= 0.0:
			_perform_jump()
			jump_decision_timer = randf_range(1.2, 2.0)

	run_cycle += absf(velocity.x) * delta * 0.065
	_apply_platformer_physics(delta, true)

	# 3. Одноразовий кидок бартки у злодія та вихід зі сцени
	throw_countdown -= delta
	if not has_thrown_bartka and (throw_countdown <= 0.0 or melee_hits_count >= 3):
		throw_bartka_once()

	queue_redraw()


func _perform_jump() -> void:
	velocity.y = JUMP_VELOCITY
	on_ground = false
	squash_stretch = Vector2(0.82, 1.24)


func _apply_platformer_physics(delta: float, clamp_bounds: bool) -> void:
	var prev_y := position.y
	velocity.y += GRAVITY * delta
	position += velocity * delta
	on_ground = false

	# Перевірка приземлення на балки (Platforms)
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

	# Перевірка приземлення на підлогу арени
	if position.y >= FLOOR_Y:
		position.y = FLOOR_Y
		if velocity.y > 180.0:
			squash_stretch = Vector2(1.24, 0.80)
		velocity.y = 0.0
		on_ground = true

	if clamp_bounds:
		if position.x < 36.0:
			position.x = 36.0
			facing_dir = 1.0
		elif position.x > 924.0:
			position.x = 924.0
			facing_dir = -1.0


func _get_active_enemies() -> Array[FolkloreEnemy]:
	var result: Array[FolkloreEnemy] = []
	var par = _LevelRoot.of(self)
	if par and par.has_node("Enemies"):
		for c in par.get_node("Enemies").get_children():
			if c is FolkloreEnemy and not c.is_queued_for_deletion():
				result.append(c)
	return result


# Ближній удар барткою по злодію поруч із Гуцулом!
func melee_strike_enemy(enemy: FolkloreEnemy) -> void:
	if not is_instance_valid(enemy) or has_thrown_bartka:
		return
	melee_cooldown = 0.75
	melee_swing_timer = 0.30
	melee_hits_count += 1
	squash_stretch = Vector2(1.18, 0.86)

	enemy.make_scared(8.0)
	enemy.velocity.x = facing_dir * 260.0
	say(PHRASES_MELEE.pick_random(), 1.8)
	bartka_melee_hit.emit(enemy)
	queue_redraw()


# Одноразове метання бартки у злодія та стрімкий вихід Гуцула зі сцени!
func throw_bartka_once() -> bool:
	if has_thrown_bartka:
		return false
	has_thrown_bartka = true

	var enemies := _get_active_enemies()
	var target_pos := global_position + Vector2(facing_dir * 260.0, -20.0)
	if not enemies.is_empty():
		var chosen := enemies[0]
		target_pos = chosen.global_position
		facing_dir = signf(target_pos.x - global_position.x)
		if absf(facing_dir) < 0.1:
			facing_dir = 1.0

	var bartka = bartka_scene.instantiate()
	bartka.global_position = global_position + Vector2(facing_dir * 12.0, -8.0)
	bartka.target_pos = target_pos
	if get_parent():
		get_parent().add_child(bartka)
	bartka_thrown.emit(bartka.global_position, target_pos)

	# Після одноразового кидка бартки Гуцул прощається і тікає зі сцени в рідні Карпати!
	is_exiting_scene = true
	exit_dir = -1.0 if global_position.x < 480.0 else 1.0
	if on_ground:
		_perform_jump()
	say(PHRASES_THROW_EXIT.pick_random(), 2.5)
	queue_redraw()
	return true


# Backward-compatible helper alias
func _throw_bartka() -> bool:
	return throw_bartka_once()


func say(text: String, duration: float = 2.0) -> void:
	if speech_bubble:
		speech_bubble.say(text, duration)


func get_victory_dance_name() -> String:
	match hutsul_rank:
		HutsulRank.LITVIN_POHONIA:
			return "litvin_liavonicha_pohonia"
		HutsulRank.TREMBITAR:
			return "hutsul_arkan_trembita"
		HutsulRank.MOLFAR, HutsulRank.DOVBUSH:
			return "hutsul_thunder_arkan_dovbush"
		_:
			return "hutsul_arkan_kolomyika"


func celebrate_victory() -> void:
	is_celebrating_victory = true
	is_exiting_scene = false
	velocity = Vector2.ZERO
	squash_stretch = Vector2.ONE
	dance_time = randf_range(0.0, 0.6)  # Легкий зсув фази для живого гуртового танцю ватаги гуцулів!
	if hutsul_rank == HutsulRank.LITVIN_POHONIA:
		say("Жыве Воля! Танцюймо литвинську Лявоніху з Погонею!", 3.8)
	elif hutsul_rank == HutsulRank.TREMBITAR:
		say("Заграй, трембіто, на всі Карпати! Танцюймо Аркан!", 3.8)
	else:
		say(PHRASES_VICTORY.pick_random(), 3.8)
	queue_redraw()


func _draw() -> void:
	var fwd := facing_dir
	if is_celebrating_victory:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_draw_celebrating(fwd)
		return

	var run_anim := sin(run_cycle) if not is_resting else 0.0
	var bob := (sin(time_passed * 9.0) * 1.6) if is_resting else (absf(run_anim) * -2.2 if on_ground else -1.5)
	var tilt := (velocity.x / MOVE_SPEED) * 0.10
	draw_set_transform(Vector2.ZERO, tilt, squash_stretch)

	# Контактна тінь під ногами
	if on_ground:
		_draw_oval(Vector2(0.0, 21.5), 9.5, 2.8, Color(0.0, 0.0, 0.05, 0.35))

	# Спеціальна атрибутика вищих чинів Гуцулів (Олекса Довбуш / Мольфар) або Побратима-Литвина з «Погонею»:
	if hutsul_rank == HutsulRank.LITVIN_POHONIA:
		# Крила литвинського гусара за спиною та червоний лицарський щит «Погоня»!
		draw_arc(Vector2(-7.5 * fwd, -6.0 + bob), 13.0, PI * 0.65, PI * 1.35, 8, Color(0.95, 0.96, 1.0, 0.90), 2.6)
		var sh_c := Vector2(-6.5 * fwd, 3.0 + bob)
		_draw_oval(sh_c, 6.2, 7.2, Color(0.86, 0.14, 0.18))
		draw_arc(sh_c, 6.2, 0.0, TAU, 10, Color(0.98, 0.85, 0.22), 1.5)
		draw_line(sh_c + Vector2(-2.5, 1.5), sh_c + Vector2(2.5, -2.5), Color.WHITE, 2.0)  # Срібний вершник «Погоні»
	elif hutsul_rank == HutsulRank.DOVBUSH or hutsul_rank == HutsulRank.MOLFAR:
		# Золота громова аура Олекси Довбуша та Карпатського Мольфара
		draw_circle(Vector2(0.0, 2.0 + bob), 18.5, Color(1.0, 0.88, 0.22, 0.18))

	# 1. Динамічні ноги у червоних сукняних гачах та шкіряних постолах (біг і стрибки як у Джури!)
	var stride_l := 0.0 if is_resting else (run_anim * 6.5 if on_ground else -4.0)
	var stride_r := 0.0 if is_resting else (-run_anim * 6.5 if on_ground else 4.5)
	var lift_l := 0.0 if is_resting else (maxf(0.0, run_anim) * 3.0 if on_ground else 2.5)
	var lift_r := 0.0 if is_resting else (maxf(0.0, -run_anim) * 3.0 if on_ground else 1.5)
	var ankle_l := Vector2((-3.5 + stride_l) * fwd, 20.5 - lift_l)
	var ankle_r := Vector2((3.5 + stride_r) * fwd, 20.5 - lift_r)

	draw_line(Vector2(-3.5 * fwd, 12.5 + bob), ankle_l, Color(0.78, 0.14, 0.14), 3.6)
	draw_line(Vector2(3.5 * fwd, 12.5 + bob), ankle_r, Color(0.78, 0.14, 0.14), 3.6)
	_draw_oval(ankle_l + Vector2(1.8 * fwd, 0.5), 3.6, 1.8, Color(0.48, 0.28, 0.14))
	_draw_oval(ankle_r + Vector2(1.8 * fwd, 0.5), 3.6, 1.8, Color(0.48, 0.28, 0.14))

	# 2. Біла вишивана сорочка, гуцульський кептар з дармовисами та шкіряна тобівка через плече!
	var body_pts := PackedVector2Array(
		[Vector2(-7.8 * fwd, -4.6 + bob), Vector2(7.8 * fwd, -4.6 + bob), Vector2(9.4 * fwd, 13.6 + bob), Vector2(-9.4 * fwd, 13.6 + bob)]
	)
	draw_colored_polygon(body_pts, Color(0.96, 0.93, 0.86))
	# Овече хутро по краях кептаря та вишиті сап'янові лиштви
	draw_line(Vector2(-7.2 * fwd, -4.2 + bob), Vector2(-8.2 * fwd, 13.2 + bob), Color(0.84, 0.14, 0.16), 2.5)
	draw_line(Vector2(7.2 * fwd, -4.2 + bob), Vector2(8.2 * fwd, 13.2 + bob), Color(0.84, 0.14, 0.16), 2.5)
	draw_line(Vector2(-1.4 * fwd, -4.2 + bob), Vector2(-1.4 * fwd, 5.0 + bob), Color(0.78, 0.12, 0.14), 1.8)
	draw_line(Vector2(1.4 * fwd, -4.2 + bob), Vector2(1.4 * fwd, 5.0 + bob), Color(0.78, 0.12, 0.14), 1.8)
	# Гуцульські капсулі (мосяжні кружальця) та червоно-зелені вовняні дармовиси (китиці)
	draw_circle(Vector2(-4.0 * fwd, -0.5 + bob), 1.6, Color(0.16, 0.58, 0.30))
	draw_circle(Vector2(4.0 * fwd, -0.5 + bob), 1.6, Color(0.16, 0.58, 0.30))
	draw_circle(Vector2(-3.2 * fwd, -2.6 + bob), 1.5, Color(0.90, 0.14, 0.16))
	draw_circle(Vector2(3.2 * fwd, -2.6 + bob), 1.5, Color(0.90, 0.14, 0.16))
	draw_circle(Vector2(-4.0 * fwd, 2.0 + bob), 1.1, Color(1.0, 0.84, 0.22))
	draw_circle(Vector2(4.0 * fwd, 2.0 + bob), 1.1, Color(1.0, 0.84, 0.22))

	# Черезплічний ремінь та різьблена шкіряна тобівка з мосяжними цвяшками і порохівницею!
	draw_line(Vector2(-5.5 * fwd, -4.2 + bob), Vector2(6.5 * fwd, 8.5 + bob), Color(0.42, 0.22, 0.10), 2.0)
	var tobivka_c := Vector2(-6.5 * fwd, 9.2 + bob)
	_draw_oval(tobivka_c, 3.8, 3.2, Color(0.46, 0.24, 0.12))
	draw_circle(tobivka_c, 1.1, Color(1.0, 0.86, 0.22))

	# 3. Широкий кований шкіряний пояс — Черес із 3 пряжками та опришківським пістолем за поясом!
	_draw_oval(Vector2(0.0, 6.2 + bob), 8.4, 3.5, Color(0.42, 0.22, 0.10))
	for b_i in range(3):
		var by := 4.6 + float(b_i) * 1.6 + bob
		draw_line(Vector2(-7.4 * fwd, by), Vector2(7.4 * fwd, by), Color(0.96, 0.80, 0.20), 1.2)
	# Золоте руків'я гуцульського пістоля за чересом
	draw_line(Vector2(2.5 * fwd, 4.2 + bob), Vector2(5.5 * fwd, 1.5 + bob), Color(0.88, 0.72, 0.20), 2.2)

	# 4. Білі вишиті рукави та Мосяжна Бартка (ближній удар, опора під час перепочинку або в руці до кидка)
	var sleeve_col := Color(0.96, 0.96, 0.99)
	if is_resting:
		# Ліва рука витирає піт з чола рукавом вишиванки
		var wipe_pos := Vector2((3.5 + sin(time_passed * 8.0) * 1.5) * fwd, -12.5 + bob)
		draw_line(Vector2(-5.5 * fwd, -3.0 + bob), wipe_pos, sleeve_col, 3.4)
		draw_circle(wipe_pos, 1.9, Color(0.96, 0.82, 0.70))
		# Права рука спирається на держак бартки, поставленої на землю
		var hand_rest := Vector2(10.5 * fwd, 1.5 + bob)
		draw_line(Vector2(6.5 * fwd, -3.0 + bob), hand_rest, sleeve_col, 3.5)
		draw_circle(hand_rest, 2.0, Color(0.96, 0.82, 0.70))
		if not has_thrown_bartka:
			draw_line(Vector2(11.5 * fwd, 20.5), hand_rest + Vector2(0.0, -2.0), Color(0.50, 0.30, 0.15), 2.8)
			draw_colored_polygon(
				PackedVector2Array(
					[
						hand_rest + Vector2(-1.0 * fwd, -2.5),
						hand_rest + Vector2(7.5 * fwd, -4.0),
						hand_rest + Vector2(8.0 * fwd, 1.5),
						hand_rest + Vector2(-1.0 * fwd, 0.5)
					]
				),
				Color(1.0, 0.86, 0.22)
			)
	else:
		draw_line(Vector2(-6.5 * fwd, -3.0 + bob), Vector2((-9.5 - run_anim * 3.0) * fwd, 2.5 + bob), sleeve_col, 3.5)

		var swing_Ratio := melee_swing_timer / 0.30 if melee_swing_timer > 0.0 else 0.0
		var arm_angle := -0.4 + sin(swing_Ratio * PI) * 1.65
		var hand_r := Vector2((10.5 + sin(swing_Ratio * PI) * 5.0) * fwd, -3.5 + bob + sin(swing_Ratio * PI) * 4.0)
		draw_line(Vector2(6.5 * fwd, -3.0 + bob), hand_r, sleeve_col, 3.6)
		draw_circle(hand_r, 2.0, Color(0.96, 0.82, 0.70))

		# Бартка в руці (відображається доки Гуцул її не метнув наостанок!)
		if not has_thrown_bartka:
			var b_dir := Vector2(cos(arm_angle) * fwd, sin(arm_angle))
			var b_perp := Vector2(-b_dir.y, b_dir.x)
			var b_top := hand_r + b_dir * 13.5
			var b_bot := hand_r - b_dir * 5.5
			draw_line(b_bot, b_top, Color(0.50, 0.30, 0.15), 2.6)
			draw_colored_polygon(
				PackedVector2Array(
					[
						b_top - b_dir * 2.5,
						b_top + b_perp * (7.8 * fwd) - b_dir * 4.5,
						b_top + b_perp * (8.8 * fwd) + b_dir * 1.5,
						b_top + b_dir * 1.0
					]
				),
				Color(1.0, 0.86, 0.22)
			)
			if melee_swing_timer > 0.0:
				# Золота дуга розтину повітря під час удару барткою зблизька!
				draw_arc(hand_r, 15.5, -0.9 if fwd > 0 else PI - 0.9, 0.9 if fwd > 0 else PI + 0.9, 10, Color(1.0, 0.92, 0.35, 0.85), 2.6)

	# 5. Голова, довгі чорні кучері опришка та вуса
	var head_c := Vector2(0.0, -9.0 + bob)
	draw_circle(head_c + Vector2(-4.8 * fwd, 1.5), 3.2, Color(0.14, 0.10, 0.08))
	_draw_oval(head_c, 6.7, 6.3, Color(0.96, 0.83, 0.71))
	_draw_oval(head_c + Vector2(2.4 * fwd, 1.4), 2.1, 1.4, Color(0.96, 0.45, 0.45, 0.40))

	var eye_c := head_c + Vector2(2.2 * fwd, -1.8)
	if is_resting:
		draw_arc(eye_c, 2.0, 0.2, PI - 0.2, 6, Color(0.18, 0.12, 0.08), 1.7)
		_draw_rest_sweat_and_breath(head_c + Vector2(1.5 * fwd, -7.5), head_c + Vector2(5.0 * fwd, 2.5), fwd)
	else:
		draw_circle(eye_c, 2.2, Color.WHITE)
		draw_circle(eye_c + Vector2(0.8 * fwd, 0.0), 1.2, Color(0.22, 0.14, 0.08))
		draw_circle(eye_c + Vector2(1.1 * fwd, -0.4), 0.55, Color.WHITE)
	draw_line(eye_c + Vector2(-2.2 * fwd, -2.5), eye_c + Vector2(2.2 * fwd, -1.9), Color(0.14, 0.10, 0.08), 1.7)
	draw_line(head_c + Vector2(0.5 * fwd, 1.8), head_c + Vector2(5.2 * fwd, 1.2), Color(0.14, 0.10, 0.08), 1.8)
	draw_arc(head_c + Vector2(1.8 * fwd, 2.8), 2.4, 0.2, PI - 0.2, 6, Color(0.70, 0.16, 0.18), 1.6)

	# 6. Гуцульська Кресаня з гарасівкою та павиним пером (косицею)
	var hat_c := head_c + Vector2(0.0, -5.8)
	draw_line(hat_c + Vector2(-9.5 * fwd, 0.5), hat_c + Vector2(9.5 * fwd, 0.5), Color(0.12, 0.10, 0.12), 2.8)
	draw_colored_polygon(
		PackedVector2Array(
			[
				hat_c + Vector2(-6.0 * fwd, 0.0),
				hat_c + Vector2(6.0 * fwd, 0.0),
				hat_c + Vector2(5.2 * fwd, -5.8),
				hat_c + Vector2(-5.2 * fwd, -5.8)
			]
		),
		Color(0.14, 0.12, 0.14)
	)
	draw_line(hat_c + Vector2(-5.8 * fwd, -1.2), hat_c + Vector2(5.8 * fwd, -1.2), Color(0.88, 0.14, 0.18), 2.0)
	var feather_sway := sin(time_passed * 9.5) * 1.8
	var f_base := hat_c + Vector2(-4.5 * fwd, -2.5)
	var f_tip := hat_c + Vector2(-10.5 * fwd + feather_sway, -13.5)
	draw_line(f_base, f_tip, Color(0.18, 0.78, 0.48), 2.4)
	draw_circle(f_tip, 2.2, Color(0.16, 0.55, 0.88))
	draw_circle(f_base, 1.8, Color(0.92, 0.16, 0.20))


func _draw_celebrating(_fwd: float) -> void:
	# ГУЦУЛЬСЬКИЙ ПЕРЕМОЖНИЙ ТАНЕЦЬ «АРКАН» ТА «КОЛОМИЙКА» З БАРТКОЮ!
	var rhythm := dance_time * 9.5
	var jump_bob := absf(sin(rhythm)) * 7.5
	var knee_lift := sin(rhythm)
	var body_sway := cos(rhythm * 0.5) * 2.2
	var axe_swing := cos(rhythm) * 6.5

	# Контактна тінь під час високих стрибків Аркана
	_draw_oval(Vector2(body_sway * 0.5, 21.0), 9.2 - jump_bob * 0.25, 2.6, Color(0.0, 0.0, 0.05, 0.34))

	# 1. Високе гуцульське притупування («притуп» і «гайдук») у червоних гачах та постолах
	var foot_l_y := 19.8 - maxf(0.0, knee_lift) * 8.5
	var foot_r_y := 19.8 - maxf(0.0, -knee_lift) * 8.5
	var knee_l := Vector2(-5.5 + body_sway, 13.5 - jump_bob - maxf(0.0, knee_lift) * 5.0)
	var knee_r := Vector2(5.5 + body_sway, 13.5 - jump_bob - maxf(0.0, -knee_lift) * 5.0)
	var ankle_l := Vector2(-7.0 + body_sway - maxf(0.0, knee_lift) * 2.5, foot_l_y)
	var ankle_r := Vector2(7.0 + body_sway + maxf(0.0, -knee_lift) * 2.5, foot_r_y)

	draw_line(Vector2(-4.0 + body_sway, 11.5 - jump_bob), knee_l, Color(0.78, 0.14, 0.14), 3.8)
	draw_line(knee_l, ankle_l, Color(0.78, 0.14, 0.14), 3.4)
	draw_line(Vector2(4.0 + body_sway, 11.5 - jump_bob), knee_r, Color(0.78, 0.14, 0.14), 3.8)
	draw_line(knee_r, ankle_r, Color(0.78, 0.14, 0.14), 3.4)
	_draw_oval(ankle_l + Vector2(-1.0, 0.5), 3.8, 1.9, Color(0.48, 0.28, 0.14))
	_draw_oval(ankle_r + Vector2(1.0, 0.5), 3.8, 1.9, Color(0.48, 0.28, 0.14))

	# 2. Святкова вишиванка та гуцульський кептар із червоними китицями-дармовисами
	var body_pts := PackedVector2Array(
		[
			Vector2(-7.6 + body_sway, -4.2 - jump_bob),
			Vector2(7.6 + body_sway, -4.2 - jump_bob),
			Vector2(9.4 + body_sway, 12.8 - jump_bob),
			Vector2(-9.4 + body_sway, 12.8 - jump_bob)
		]
	)
	draw_colored_polygon(body_pts, Color(0.95, 0.92, 0.86))
	draw_line(Vector2(-7.0 + body_sway, -3.8 - jump_bob), Vector2(-8.2 + body_sway, 12.4 - jump_bob), Color(0.84, 0.14, 0.16), 2.4)
	draw_line(Vector2(7.0 + body_sway, -3.8 - jump_bob), Vector2(8.2 + body_sway, 12.4 - jump_bob), Color(0.84, 0.14, 0.16), 2.4)
	draw_circle(Vector2(-3.5 + body_sway, -0.5 - jump_bob), 1.6, Color(0.16, 0.58, 0.30))
	draw_circle(Vector2(3.5 + body_sway, -0.5 - jump_bob), 1.6, Color(0.16, 0.58, 0.30))
	draw_circle(Vector2(-2.2 + body_sway, -2.5 - jump_bob), 1.5, Color(0.88, 0.12, 0.16))
	draw_circle(Vector2(2.2 + body_sway, -2.5 - jump_bob), 1.5, Color(0.88, 0.12, 0.16))

	# Широкий черес із мосяжними пряжками
	_draw_oval(Vector2(body_sway, 5.8 - jump_bob), 8.4, 3.3, Color(0.42, 0.22, 0.10))
	for b_i in range(3):
		var by := 4.3 + float(b_i) * 1.5 - jump_bob
		draw_line(Vector2(-7.2 + body_sway, by), Vector2(7.2 + body_sway, by), Color(0.96, 0.80, 0.20), 1.1)

	# 3. Високо підняті в танці «Аркан» руки з мосяжною барткою над головою!
	var hand_l := Vector2(-14.0 + body_sway, -13.5 - jump_bob - axe_swing * 0.45)
	var hand_r := Vector2(14.0 + body_sway, -16.5 - jump_bob + axe_swing * 0.65)
	draw_line(Vector2(-6.5 + body_sway, -2.5 - jump_bob), hand_l, Color(0.96, 0.96, 0.99), 3.6)
	draw_line(Vector2(6.5 + body_sway, -2.5 - jump_bob), hand_r, Color(0.96, 0.96, 0.99), 3.6)
	draw_circle(hand_l, 2.1, Color(0.96, 0.82, 0.70))
	draw_circle(hand_r, 2.1, Color(0.96, 0.82, 0.70))

	# Золота бартка виблискує у правій руці в ритмі Аркана!
	var b_angle := -1.1 + sin(rhythm) * 0.45
	var b_dir := Vector2(cos(b_angle), sin(b_angle))
	var b_perp := Vector2(-b_dir.y, b_dir.x)
	var b_top := hand_r + b_dir * 14.0
	var b_bot := hand_r - b_dir * 5.0
	draw_line(b_bot, b_top, Color(0.50, 0.30, 0.15), 2.6)
	draw_colored_polygon(
		PackedVector2Array(
			[b_top - b_dir * 2.5, b_top + b_perp * 8.0 - b_dir * 4.5, b_top + b_perp * 9.0 + b_dir * 1.5, b_top + b_dir * 1.0]
		),
		Color(1.0, 0.88, 0.22)
	)
	draw_arc(hand_r, 15.0, -1.9, -0.3, 10, Color(1.0, 0.92, 0.35, 0.55), 2.0)
	if hutsul_rank == HutsulRank.LITVIN_POHONIA:
		# Особистий переможний танок Литвина («Лявоніха з Погонею»): крила гусара й високо піднятий щит «Погоня» у лівій руці!
		draw_arc(Vector2(body_sway, -6.0 - jump_bob), 15.0, PI * 0.72, PI * 1.28, 10, Color(0.96, 0.98, 1.0, 0.92), 2.8)
		_draw_oval(hand_l, 6.2, 7.0, Color(0.86, 0.14, 0.18))
		draw_arc(hand_l, 6.2, 0.0, TAU, 10, Color(0.98, 0.85, 0.22), 1.6)
		draw_line(hand_l + Vector2(-2.5, 1.5), hand_l + Vector2(2.5, -2.5), Color.WHITE, 2.0)
	elif hutsul_rank == HutsulRank.TREMBITAR:
		# Особистий переможний танок Трембітаря: золота карпатська трембіта сурмить угору!
		var tr_end := hand_l + Vector2(-16.0, -14.0)
		draw_line(hand_l, tr_end, Color(0.85, 0.62, 0.28), 3.0)
		draw_circle(tr_end, 3.2, Color(0.98, 0.82, 0.22))
		draw_arc(tr_end, 7.5 + fmod(dance_time * 10.0, 4.0), PI * 0.8, PI * 1.5, 8, Color(1.0, 0.92, 0.35, 0.85), 1.8)
	elif hutsul_rank == HutsulRank.DOVBUSH or hutsul_rank == HutsulRank.MOLFAR:
		# Громовий Аркан Олекси Довбуша / Мольфара
		draw_arc(Vector2(body_sway, -2.0 - jump_bob), 21.0, 0.0, TAU, 18, Color(1.0, 0.88, 0.22, 0.55), 2.0)

	# 4. Голова, чорні кучері опришка, вуса та гуцульська кресаня з павиним пером!
	var head_c := Vector2(body_sway, -9.0 - jump_bob)
	draw_circle(head_c + Vector2(-5.0, 1.5), 3.0, Color(0.14, 0.10, 0.08))
	draw_circle(head_c + Vector2(5.0, 1.5), 3.0, Color(0.14, 0.10, 0.08))
	_draw_oval(head_c, 6.7, 6.3, Color(0.96, 0.83, 0.71))
	_draw_oval(head_c + Vector2(-3.0, 1.4), 1.9, 1.3, Color(0.96, 0.45, 0.45, 0.40))
	_draw_oval(head_c + Vector2(3.0, 1.4), 1.9, 1.3, Color(0.96, 0.45, 0.45, 0.40))

	# Кресаня з червоною гарасівкою та павиним пером (косицею)
	var hat_c := head_c + Vector2(0.0, -5.8)
	draw_line(hat_c + Vector2(-9.5, 0.5), hat_c + Vector2(9.5, 0.5), Color(0.12, 0.10, 0.12), 2.8)
	draw_colored_polygon(
		PackedVector2Array(
			[hat_c + Vector2(-6.0, 0.0), hat_c + Vector2(6.0, 0.0), hat_c + Vector2(5.2, -5.8), hat_c + Vector2(-5.2, -5.8)]
		),
		Color(0.14, 0.12, 0.14)
	)
	draw_line(hat_c + Vector2(-5.8, -1.2), hat_c + Vector2(5.8, -1.2), Color(0.88, 0.14, 0.18), 2.0)
	var f_base := hat_c + Vector2(-4.2, -2.5)
	var f_tip := hat_c + Vector2(-10.5 + sin(rhythm) * 2.5, -13.8)
	draw_line(f_base, f_tip, Color(0.18, 0.78, 0.48), 2.4)
	draw_circle(f_tip, 2.2, Color(0.16, 0.55, 0.88))
	draw_circle(f_base, 1.8, Color(0.92, 0.16, 0.20))

	# Щаслива посмішка, козацько-опришківські вуса та очі «^_^»
	draw_arc(head_c + Vector2(-2.2, -2.0), 2.0, PI + 0.3, TAU - 0.3, 6, Color(0.18, 0.12, 0.10), 1.6)
	draw_arc(head_c + Vector2(2.2, -2.0), 2.0, PI + 0.3, TAU - 0.3, 6, Color(0.18, 0.12, 0.10), 1.6)
	draw_line(head_c + Vector2(-4.5, 1.5), head_c + Vector2(-1.0, 1.9), Color(0.14, 0.10, 0.08), 1.6)
	draw_line(head_c + Vector2(1.0, 1.9), head_c + Vector2(4.5, 1.5), Color(0.14, 0.10, 0.08), 1.6)
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
