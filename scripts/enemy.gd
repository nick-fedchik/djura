extends Area2D

class_name FolkloreEnemy

signal defeated(enemy: FolkloreEnemy, points: int)
signal hit_player(enemy: FolkloreEnemy)
signal stolen_artifact_dropped(drop_pos: Vector2)

enum EnemyType { CHORT, VIDMA, VOGNYK, MOSKAL, ZLYDNI, BASAVRIUK, VIJ, VIDMAK, FINAL_BOSS }

# Історично-фольклорна ієрархія ворожих NPC фракції Загарбників («Від Шиша до Воєводи» + Ординсько-Монгольські найманці Московії):
enum MoskalRank {
	SHYSH,         # Ранг 1: «Шиш» — лісовий/болотяний нишпорка-мародер у латаній сірячині й лаптях (полює за артефактами)
	STRELETS,      # Ранг 2: «Стрілець» — рядовий піхотинець у червоному каптані з бердишем і самоваром
	DYAK,          # Ранг 3: «Приказний Дяк» — сутулий писарчук у довгих рукавах до землі з сувоєм указу і чорнильницею
	OPRYCHNYK,     # Ранг 4: «Опричник / Боярський Син» — у чорному каптані й панцирі-бехтерці (1 щит) з мітлою і шестопером
	VOYEVODA,      # Ранг 5: «Пихатий Воєвода» — товстун у парчовій шубі та високій соболиній шапці з барабаном/перначем (1 щит)
	TSAR_GENERAL,  # Ранг 6: «Генерал-Каратель на Цар-Мортирі» — у пудреній перуці й треуголці верхи на чавунній мортирі (2 щити)
	MONGOL_NUKER,  # Найманець Орди 1: «Нӧкер-Конокрад з Арканом» у малахаї з лисячим хвостом та степовому халаті
	MONGOL_SHAMAN, # Найманець Орди 2: «Шаман Чорного Вітру з Бубном» у плащі з воронячого пір'я й рогатій шапці
	MONGOL_NOYON   # Найманець Орди 3: «Панцерний Нойон / Тайша» у ламелярному панцирі-хуяг та золоченому шоломі (1 щит)
}

@export var enemy_type: EnemyType = EnemyType.CHORT
@export var moskal_rank: MoskalRank = MoskalRank.STRELETS

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
var is_dancing_defeat: bool = false
var defeat_dance_time: float = 0.0

# Тимчасова перевага ворога, якщо він перехопив чар-артефакт (Золоті Підківки Вакули)
var has_stolen_artifact: bool = false
var artifact_buff_timer: float = 0.0

var snd_poof = preload("res://assets/audio/chort_poof.wav")

static func get_moskal_rank_armor(rank: MoskalRank) -> int:
	match rank:
		MoskalRank.OPRYCHNYK, MoskalRank.VOYEVODA, MoskalRank.MONGOL_NOYON:
			return 1
		MoskalRank.TSAR_GENERAL:
			return 2
		_:
			return 0

static func get_moskal_rank_reward(rank: MoskalRank) -> int:
	match rank:
		MoskalRank.SHYSH:
			return 550
		MoskalRank.STRELETS:
			return 600
		MoskalRank.MONGOL_NUKER:
			return 650
		MoskalRank.DYAK:
			return 700
		MoskalRank.MONGOL_SHAMAN:
			return 800
		MoskalRank.OPRYCHNYK:
			return 850
		MoskalRank.MONGOL_NOYON:
			return 950
		MoskalRank.VOYEVODA:
			return 1000
		MoskalRank.TSAR_GENERAL:
			return 1150
		_:
			return 600

static func get_moskal_rank_title(rank: MoskalRank) -> String:
	match rank:
		MoskalRank.SHYSH:
			return "ШИШ"
		MoskalRank.STRELETS:
			return "СТРІЛЕЦЬ"
		MoskalRank.DYAK:
			return "ПРИКАЗНИЙ ДЯК"
		MoskalRank.OPRYCHNYK:
			return "ОПРИЧНИК"
		MoskalRank.VOYEVODA:
			return "ВОЄВОДА"
		MoskalRank.TSAR_GENERAL:
			return "ГЕНЕРАЛ"
		MoskalRank.MONGOL_NUKER:
			return "ОРДИНСЬКИЙ НӦКЕР"
		MoskalRank.MONGOL_SHAMAN:
			return "ШАМАН БУРАНУ"
		MoskalRank.MONGOL_NOYON:
			return "ТАЙША-НОЙОН"
		_:
			return "СТРІЛЕЦЬ"

func set_moskal_rank(rank: MoskalRank) -> void:
	moskal_rank = rank
	if enemy_type == EnemyType.MOSKAL:
		armor = get_moskal_rank_armor(rank)
	queue_redraw()

func npc_id() -> String:
	match enemy_type:
		EnemyType.CHORT: return "CHORT"
		EnemyType.VIDMA: return "VIDMA"
		EnemyType.VOGNYK: return "VOGNYK"
		EnemyType.ZLYDNI: return "ZLYDNI"
		EnemyType.BASAVRIUK: return "BASAVRIUK"
		EnemyType.VIJ: return "VIJ"
		EnemyType.VIDMAK: return "VIDMAK"
		EnemyType.FINAL_BOSS: return "FINAL_BOSS"
		EnemyType.MOSKAL:
			match moskal_rank:
				MoskalRank.STRELETS: return "MOSKAL"
				MoskalRank.SHYSH: return "MOSKAL_SHYSH"
				MoskalRank.DYAK: return "MOSKAL_DYAK"
				MoskalRank.OPRYCHNYK: return "MOSKAL_OPRYCHNYK"
				MoskalRank.VOYEVODA: return "MOSKAL_VOYEVODA"
				MoskalRank.TSAR_GENERAL: return "MOSKAL_TSAR_GENERAL"
				MoskalRank.MONGOL_NUKER: return "MONGOL_NUKER"
				MoskalRank.MONGOL_SHAMAN: return "MONGOL_SHAMAN"
				MoskalRank.MONGOL_NOYON: return "MONGOL_NOYON"
				_: return "MOSKAL"
	return "CHORT"

func get_enemy_type_name() -> String:
	return npc_id()

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if enemy_type == EnemyType.VIDMA or enemy_type == EnemyType.VIDMAK:
		armor = VIDMA_ARMOR
		_player_ref = get_tree().root.find_child("Player", true, false) as Node2D
	elif enemy_type == EnemyType.MOSKAL:
		armor = get_moskal_rank_armor(moskal_rank)
	elif enemy_type == EnemyType.BASAVRIUK or enemy_type == EnemyType.VIJ:
		armor = 1
	elif enemy_type == EnemyType.FINAL_BOSS:
		armor = 3
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

func get_defeat_dance_name() -> String:
	match enemy_type:
		EnemyType.MOSKAL:
			if moskal_rank in [MoskalRank.MONGOL_NUKER, MoskalRank.MONGOL_SHAMAN, MoskalRank.MONGOL_NOYON]:
				return "horde_buran_stumble"
			return "moskal_komarynska_fail"
		EnemyType.CHORT, EnemyType.ZLYDNI:
			return "chort_tail_tangle_hop"
		EnemyType.VIDMA, EnemyType.VIDMAK:
			return "engineer_broom_misfire_jig"
		EnemyType.VOGNYK:
			return "vognyk_flicker_fizzle"
		EnemyType.BASAVRIUK, EnemyType.VIJ, EnemyType.FINAL_BOSS:
			return "boss_crown_wobble_stomp"
		_:
			return "folklore_defeat_hop"

func start_defeat_dance() -> void:
	is_dancing_defeat = true
	is_resting = false
	rest_timer = 0.0
	is_scared = false
	scared_timer = 0.0
	has_stolen_artifact = false
	artifact_buff_timer = 0.0
	velocity = Vector2.ZERO
	defeat_dance_time = randf_range(0.0, 0.5)
	queue_redraw()

func start_rest(duration: float = 2.2) -> void:
	if has_stolen_artifact:
		return
	is_dancing_defeat = false
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
	is_dancing_defeat = false
	is_scared = true
	scared_timer = duration
	is_resting = false
	rest_timer = 0.0
	# Панічний біг швидко виснажує сили супротивника — за кілька секунд він захекається!
	stamina_timer = randf_range(2.6, 3.8)
	velocity = -velocity * 0.75 # Reverse direction in panic!

func _process(delta: float) -> void:
	time_passed += delta
	if is_dancing_defeat:
		defeat_dance_time += delta
		queue_redraw()
		return
	
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
		if enemy_type == EnemyType.VIDMA or enemy_type == EnemyType.VIDMAK or enemy_type == EnemyType.VOGNYK:
			position.y += sin(time_passed * 5.0) * 5.0 * delta
	else:
		match enemy_type:
			EnemyType.VIDMA, EnemyType.VIDMAK:
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
			EnemyType.CHORT, EnemyType.ZLYDNI:
				var z_mult := 1.08 if enemy_type == EnemyType.ZLYDNI else 1.0
				var speed := (base_speed * z_mult if not is_scared else (base_speed * 1.35)) * fatigue_mult
				position += velocity.normalized() * speed * delta
			EnemyType.BASAVRIUK:
				var b_speed := (base_speed * 0.88 if not is_scared else (base_speed * 1.45)) * fatigue_mult
				position += velocity.normalized() * b_speed * delta
				if not is_scared:
					position.y += sin(time_passed * 4.5) * 22.0 * delta
			EnemyType.VIJ:
				var v_speed := (base_speed * 0.56 if not is_scared else (base_speed * 1.25)) * fatigue_mult
				position += velocity.normalized() * v_speed * delta
			EnemyType.FINAL_BOSS:
				var fb_speed := (base_speed * 0.72 if not is_scared else (base_speed * 1.40)) * fatigue_mult
				position += velocity.normalized() * fb_speed * delta
			EnemyType.MOSKAL:
				# Поведінка та швидкість залежать від рангу московського війська («Від Шиша до Воєводи»):
				var rank_mult := 0.75
				match moskal_rank:
					MoskalRank.SHYSH:
						rank_mult = 1.02 # «Шиш» — найпрудкіший болотний нишпорка, полює за артефактами!
						if not is_scared and not has_stolen_artifact and get_parent() and get_parent().get_parent():
							var items_container := get_parent().get_parent().get_node_or_null("Items")
							if items_container and items_container.get_child_count() > 0:
								var target_item := items_container.get_child(0) as Node2D
								if target_item and is_instance_valid(target_item):
									var to_item := (target_item.global_position - global_position).normalized()
									velocity = velocity.lerp(to_item * base_speed, minf(1.0, delta * 3.8))
					MoskalRank.STRELETS:
						rank_mult = 0.75 # Класичний важкий марш стрільця з бердишем
					MoskalRank.DYAK:
						rank_mult = 0.84 # Приказний Дяк петляє зигзагами, розкидаючи чорнильні клякси
						if not is_scared:
							position.y += sin(time_passed * 4.2) * 20.0 * delta
					MoskalRank.OPRYCHNYK:
						rank_mult = 0.80 # Панцерний опричник із шестопером і мітлою
					MoskalRank.VOYEVODA:
						rank_mult = 0.64 # Пихатий товстун-воєвода, що б'є в тулумбас і підганяє посіпак
					MoskalRank.TSAR_GENERAL:
						rank_mult = 0.70 # Генерал-каратель котиться на чавунній «Цар-гарматі»
					MoskalRank.MONGOL_NUKER:
						rank_mult = 0.96 # Степовий ординський найманець з арканом — стрімкий зигзаг
						if not is_scared:
							position.y += cos(time_passed * 5.0) * 18.0 * delta
					MoskalRank.MONGOL_SHAMAN:
						rank_mult = 0.78 # Шаман чорного бурану з бубном
					MoskalRank.MONGOL_NOYON:
						rank_mult = 0.82 # Панцерний тайша-нойон у ламелярному хуягу
				var speed := (base_speed * rank_mult if not is_scared else (base_speed * 1.55)) * fatigue_mult
				position += velocity.normalized() * speed * delta
	
	# Bounce off arena boundaries (960x540 2K 16:9 widescreen)
	if position.x < 32.0:
		position.x = 32.0
		velocity.x = abs(velocity.x)
	elif position.x > 928.0:
		position.x = 928.0
		velocity.x = -abs(velocity.x)
	
	if (enemy_type == EnemyType.VIDMA or enemy_type == EnemyType.VIDMAK) and not is_scared:
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
	if is_dancing_defeat:
		return
	if body is JackPlayer:
		if is_scared or body.is_charakterite:
			# Banished by Cossack / Charakterite power!
			_play_poof()
			var reward := 500
			match enemy_type:
				EnemyType.MOSKAL: reward = get_moskal_rank_reward(moskal_rank)
				EnemyType.VIDMA, EnemyType.VIDMAK: reward = VIDMA_REWARD
				EnemyType.ZLYDNI: reward = 550
				EnemyType.BASAVRIUK: reward = 900
				EnemyType.VIJ: reward = 1100
				EnemyType.FINAL_BOSS: reward = 2500
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
	if is_dancing_defeat:
		var w_phase := defeat_dance_time * 10.5
		var squat_y := absf(cos(w_phase)) * 3.8
		var sway_x := sin(w_phase) * 3.0
		var tilt := sin(w_phase * 0.5) * 0.16
		draw_set_transform(Vector2(sway_x, squat_y), tilt, Vector2(1.0 + sin(w_phase) * 0.10, 1.0 - sin(w_phase) * 0.10))
	elif is_resting:
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
			draw_string(fnt, Vector2(-26.0, -31.0), "ТРОФЕЙ! ", HORIZONTAL_ALIGNMENT_CENTER, 52.0, 9, Color(1.0, 0.94, 0.30))
	
	if armor > 0 and not is_scared:
		# Візуальна підказка захисного щита інженерів та панцерних ворогів (T-018): мерехтливе кільце й мітки ударів
		var sh_pulse := 0.55 + 0.35 * sin(time_passed * 10.0)
		draw_arc(Vector2(0.0, -2.0), 20.0, 0.0, TAU, 24, Color(0.45, 0.92, 1.0, sh_pulse), 2.2)
		for s_i in armor:
			var pip_x := (float(s_i) - float(armor - 1) * 0.5) * 6.5
			draw_circle(Vector2(pip_x, -25.0), 2.4, Color(0.55, 0.96, 1.0, 0.95))

	match enemy_type:
		EnemyType.CHORT:
			_draw_chort()
		EnemyType.VIDMA:
			_draw_vidma()
		EnemyType.VOGNYK:
			_draw_vognyk()
		EnemyType.MOSKAL:
			_draw_moskal()
		EnemyType.ZLYDNI:
			_draw_zlydni()
		EnemyType.BASAVRIUK:
			_draw_basavriuk()
		EnemyType.VIJ:
			_draw_vij()
		EnemyType.VIDMAK:
			_draw_vidmak()
		EnemyType.FINAL_BOSS:
			_draw_final_boss()

	if is_dancing_defeat:
		_draw_defeat_dance_overlay()

# Національний / фольклорний танок невдачі злодіїв (комічний, без страху, стиль «Київнаукфільм»)
func _draw_defeat_dance_overlay() -> void:
	var t := defeat_dance_time * 10.0
	var kick := sin(t) * 8.5
	match get_defeat_dance_name():
		"moskal_komarynska_fail":
			# Комічна лапотна «Комаринська-Невдаха вприсядку»: лапті заплітаються врізнобіч, руки хапаються за шапку!
			var lapot_l := Vector2(-10.5 - maxf(0.0, kick), 18.0 - maxf(0.0, kick) * 0.45)
			var lapot_r := Vector2(10.5 + maxf(0.0, -kick), 18.0 - maxf(0.0, -kick) * 0.45)
			draw_line(Vector2(-3.5, 11.0), lapot_l, Color(0.68, 0.14, 0.16), 3.4)
			draw_line(Vector2(3.5, 11.0), lapot_r, Color(0.68, 0.14, 0.16), 3.4)
			_draw_oval(lapot_l, 4.6, 2.3, Color(0.78, 0.62, 0.34)) # Плетений ликовий лапоть ліворуч
			_draw_oval(lapot_r, 4.6, 2.3, Color(0.78, 0.62, 0.34)) # Плетений ликовий лапоть праворуч
			# Обидві руки кумедно тримаються за перекошену шапку («Ой-йой, пропала грамота!»)
			draw_line(Vector2(-6.5, -2.0), Vector2(-9.5, -14.5 + sin(t) * 1.5), Color(0.74, 0.14, 0.16), 3.0)
			draw_line(Vector2(6.5, -2.0), Vector2(9.5, -14.5 - sin(t) * 1.5), Color(0.74, 0.14, 0.16), 3.0)
			draw_circle(Vector2(-9.5, -14.5 + sin(t) * 1.5), 2.1, Color(0.96, 0.82, 0.72))
			draw_circle(Vector2(9.5, -14.5 - sin(t) * 1.5), 2.1, Color(0.96, 0.82, 0.72))
		"horde_buran_stumble":
			# Ординський «Буран-Спотикач»: заплутаний аркан навколо ніг і перевернутий бубон!
			draw_arc(Vector2(0.0, 14.5), 8.5, 0.0, TAU, 14, Color(0.76, 0.60, 0.32), 2.0)
			_draw_oval(Vector2(11.5, 14.0 + sin(t) * 2.0), 4.5, 3.2, Color(0.85, 0.68, 0.38))
		"chort_tail_tangle_hop":
			# Чортячий «Гопки-Плутанка Хвостом»: наступив собі на хвіст і стрибає на одній лапі!
			var hop_y := -absf(sin(t)) * 4.5
			draw_arc(Vector2(0.0, 14.0 + hop_y), 7.5, 0.2, PI * 1.4, 10, Color(0.18, 0.15, 0.22), 2.4)
		"engineer_broom_misfire_jig":
			# Конструкторський танок зламаної мітли й шестерні: пара та розгублено розведені руки!
			for g_i in 3:
				var p_ang := t * 0.6 + float(g_i) * TAU / 3.0
				draw_circle(Vector2(cos(p_ang) * 14.0, -16.0 + sin(p_ang) * 4.0), 2.4, Color(0.85, 0.90, 0.96, 0.85))
		_:
			# Комічний тупіт посоромленого велетня / ліхтарика
			draw_circle(Vector2(-9.0, 18.5), 2.6 + absf(sin(t)) * 1.5, Color(0.82, 0.78, 0.70, 0.75))
			draw_circle(Vector2(9.0, 18.5), 2.6 + absf(cos(t)) * 1.5, Color(0.82, 0.78, 0.70, 0.75))
	# Веселі зірочки запаморочення над головою злодія-невдахи
	for s_i in 3:
		var a := defeat_dance_time * 5.2 + float(s_i) * TAU / 3.0
		var sp := Vector2(cos(a) * 11.0, -23.5 + sin(a) * 3.2)
		draw_circle(sp, 1.8, Color(1.0, 0.90, 0.25))

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
		var hoof_l := foot_l + Vector2(0.8 * fwd, 0.5)
		var hoof_r := foot_r + Vector2(0.8 * fwd, 0.5)
		_draw_oval(hoof_l, 2.6, 1.6, Color(0.38, 0.16, 0.10))
		_draw_oval(hoof_r, 2.6, 1.6, Color(0.38, 0.16, 0.10))
		draw_line(hoof_l + Vector2(0, -1.0), hoof_l + Vector2(0, 1.2), Color(0.16, 0.06, 0.04), 1.1)
		draw_line(hoof_r + Vector2(0, -1.0), hoof_r + Vector2(0, 1.2), Color(0.16, 0.06, 0.04), 1.1)
		draw_circle(hoof_l + Vector2(-0.7 * fwd, -0.4), 0.5, Color(0.65, 0.35, 0.25))
		draw_circle(hoof_r + Vector2(-0.7 * fwd, -0.4), 0.5, Color(0.65, 0.35, 0.25))
	elif not is_scared:
		var trot := sin(time_passed * 16.0 * fatigue_mult) * 3.2
		var foot_l := Vector2(-4.0 - trot * 0.6, 15.5 + bob - maxf(0.0, trot) * 0.5)
		var foot_r := Vector2(4.0 + trot * 0.6, 15.5 + bob - maxf(0.0, -trot) * 0.5)
		draw_line(Vector2(-4.0, 9.0 + bob), foot_l, c_body, 2.4)
		draw_line(Vector2(4.0, 9.0 + bob), foot_r, c_body, 2.4)
		var hoof_l := foot_l + Vector2(0.8 * fwd, 0.5)
		var hoof_r := foot_r + Vector2(0.8 * fwd, 0.5)
		_draw_oval(hoof_l, 2.4, 1.6, Color(0.38, 0.16, 0.10))
		_draw_oval(hoof_r, 2.4, 1.6, Color(0.38, 0.16, 0.10))
		draw_line(hoof_l + Vector2(0, -1.0), hoof_l + Vector2(0, 1.2), Color(0.16, 0.06, 0.04), 1.1)
		draw_line(hoof_r + Vector2(0, -1.0), hoof_r + Vector2(0, 1.2), Color(0.16, 0.06, 0.04), 1.1)
		draw_circle(hoof_l + Vector2(-0.6 * fwd, -0.4), 0.5, Color(0.65, 0.35, 0.25))
		draw_circle(hoof_r + Vector2(-0.6 * fwd, -0.4), 0.5, Color(0.65, 0.35, 0.25))
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
		# Лукаві палаючі жовті очі чортика з котячими зіницями та подвійним бліком
		var eye_pos := Vector2(3.0 * fwd, -3.2 + bob)
		draw_circle(eye_pos, 2.7, Color(1.0, 0.86, 0.16))
		draw_circle(eye_pos, 2.1, Color(1.0, 0.94, 0.32))
		draw_line(eye_pos + Vector2(0.6 * fwd, -1.7), eye_pos + Vector2(0.6 * fwd, 1.7), Color(0.08, 0.04, 0.04), 1.3)
		draw_circle(eye_pos + Vector2(1.0 * fwd, -0.7), 0.6, Color.WHITE)
		draw_circle(eye_pos + Vector2(0.3 * fwd, 0.6), 0.35, Color(1.0, 1.0, 1.0, 0.75))
		# Лукава брова
		draw_line(eye_pos + Vector2(-2.2 * fwd, -3.0), eye_pos + Vector2(2.2 * fwd, -2.0), Color(0.06, 0.04, 0.08), 1.6)
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

# Геометрія язика полум'я Вогника (чиста функція: Anti-Clipping, SWR-001-04).
# Замкнений контур від основи base у напрямку dir: вигнута хвиляста вісь, ширина звужується до кінчика (0).
static func vognyk_flame_points(base: Vector2, dir: Vector2, length: float, width: float, t: float, phase: float) -> PackedVector2Array:
	var d := dir.normalized()
	var n := Vector2(-d.y, d.x)
	var steps := 8
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in range(steps + 1):
		var s := float(i) / float(steps)
		var sway := sin(t - s * 4.0 + phase) * 0.22 * length * s * s
		var c := base + d * (length * s) + n * sway
		var w := width * pow(1.0 - s, 0.85) * (1.0 + 0.25 * sin(s * PI))
		left.append(c + n * w)
		right.append(c - n * w)
	right.reverse()
	left.append_array(right)
	return left

# Іскорки-ембери: [позиція, вік 0..1]; відлітають у напрямку dir (назад від руху) і згасають.
static func vognyk_ember_points(dir: Vector2, t: float, count: int, reach: float) -> Array:
	var out: Array = []
	for i in range(count):
		var life := fposmod(t * 0.9 + float(i) / float(count), 1.0)
		var lane := sin(float(i) * 2.7) * 7.0
		var pos := dir.normalized() * (8.0 + reach * life) + Vector2(0.0, lane * (0.4 + life) + sin(t * 9.0 + float(i)) * 1.5)
		out.append([pos, life])
	return out

# -------------------------------------------------------------
# БЛУКАЮЧИЙ ВОГНИК (Потерчата / Купальський Лісовий Дух)
# -------------------------------------------------------------
func _draw_vognyk() -> void:
	var pulse := (0.76 + sin(time_passed * 5.0) * 0.06) if is_resting else (1.0 + sin(time_passed * 16.0) * 0.22)
	var sway := sin(time_passed * 10.0) * 3.5
	var c_outer := Color(0.12, 0.85, 0.75, 0.22) if not is_scared else Color(0.45, 0.65, 1.0, 0.25)
	var c_mid := Color(0.22, 0.96, 0.58, 0.52) if not is_scared else Color(0.55, 0.80, 1.0, 0.55)
	var c_core := Color(0.95, 1.0, 0.82, 0.94)
	var c_flame_in := Color(1.0, 0.92, 0.55, 0.92) if not is_scared else Color(0.85, 0.95, 1.0, 0.92)
	var c_tail := Color(c_mid.r, c_mid.g, c_mid.b, 0.88)
	
	# 1. Танцюючі вигнуті язики купальського полум'я вгорі (зовнішній смарагдовий + внутрішній золотий)
	for t_i in range(3):
		var offset_x := (float(t_i) - 1.0) * 4.5
		var tongue_h := (17.0 if t_i == 1 else 12.5) * pulse
		var lean := (1.0 if t_i == 2 else -1.0) if t_i != 1 else sin(time_passed * 6.0)
		var up_pts := vognyk_flame_points(Vector2(offset_x, 2.0), Vector2(lean * 0.35, -1.0).normalized(), tongue_h, 4.6, time_passed * 14.0, float(t_i) * 1.8)
		draw_colored_polygon(up_pts, c_mid)
		var up_in := vognyk_flame_points(Vector2(offset_x, 2.0), Vector2(lean * 0.35, -1.0).normalized(), tongue_h * 0.62, 2.4, time_passed * 14.0, float(t_i) * 1.8)
		draw_colored_polygon(up_in, c_flame_in)

	# 1.5. Багаторівневий вогняний хвіст-шлейф позаду: три хвилясті язики, кожен із двох шарів
	var tail_dir := -(signf(velocity.x) if absf(velocity.x) > 5.0 else 1.0)
	var tail_rest := 0.7 if is_resting else 1.0
	for t_j in range(3):
		var t_len := (27.0 - float(t_j) * 5.5) * pulse * tail_rest
		var t_y := -5.0 + float(t_j) * 5.0
		var base := Vector2(0.0, t_y)
		var dir := Vector2(tail_dir, (float(t_j) - 1.0) * 0.18)
		draw_colored_polygon(vognyk_flame_points(base, dir, t_len, 4.8, time_passed * 12.0, float(t_j) * 1.7), c_tail)
		draw_colored_polygon(vognyk_flame_points(base, dir, t_len * 0.66, 2.6, time_passed * 12.0, float(t_j) * 1.7 + 0.5), c_flame_in)
		draw_polyline(vognyk_flame_points(base, dir, t_len, 4.8, time_passed * 12.0, float(t_j) * 1.7), Color(0.04, 0.30, 0.28, 0.9), 1.2)

	# 1.6. Живі іскорки-ембери відлітають назад по траєкторії польоту
	for ember in vognyk_ember_points(Vector2(tail_dir, 0.0), time_passed, 6, 36.0):
		var e_pos: Vector2 = ember[0]
		var e_life: float = ember[1]
		draw_circle(e_pos, 1.9 * (1.0 - e_life) + 0.5, Color(1.0, 0.86 - 0.3 * e_life, 0.32, 0.95 * (1.0 - e_life)))

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
# ФРАКЦІЯ ЗАГАРБНИКІВ («МОСКАЛІ»: 6 РАНГІВ ВІД «ШИША» ДО «ВОЄВОДИ» Й «ГЕНЕРАЛА»)
# -------------------------------------------------------------
func _draw_moskal() -> void:
	match moskal_rank:
		MoskalRank.SHYSH:
			_draw_moskal_shysh()
		MoskalRank.DYAK:
			_draw_moskal_dyak()
		MoskalRank.OPRYCHNYK:
			_draw_moskal_oprychnyk()
		MoskalRank.VOYEVODA:
			_draw_moskal_voyevoda()
		MoskalRank.TSAR_GENERAL:
			_draw_moskal_tsar_general()
		MoskalRank.MONGOL_NUKER, MoskalRank.MONGOL_SHAMAN, MoskalRank.MONGOL_NOYON:
			_draw_moskal_mongol()
		_:
			_draw_moskal_strelets()

# ОРДИНСЬКО-МОНГОЛЬСЬКІ НАЙМАНЦІ НА СЛУЖБІ МОСКОВСЬКОГО ЦАРЯ (Нӧкер / Шаман Бурану / Панцерний Тайша-Нойон)
func _draw_moskal_mongol() -> void:
	var fwd := signf(velocity.x) if absf(velocity.x) > 10.0 else 1.0
	var waddle := 0.0 if is_resting else sin(time_passed * 12.5 * fatigue_mult) * 2.2
	var bob := sin(time_passed * 7.0) * 1.1 if is_resting else absf(sin(time_passed * 12.5 * fatigue_mult)) * 2.4
	var is_shaman := (moskal_rank == MoskalRank.MONGOL_SHAMAN)
	var is_noyon := (moskal_rank == MoskalRank.MONGOL_NOYON)
	
	# 0. Східний сагайдак за плечима або чорно-пір'яний плащ шамана
	if is_shaman and not is_scared:
		var wind_r := 16.0 + fmod(time_passed * 24.0, 14.0)
		draw_arc(Vector2.ZERO, wind_r, 0.0, TAU, 14, Color(0.55, 0.42, 0.75, 0.30), 1.8)
	
	# 1. Стьобаний степовий халат-деел або ламелярний панцир-хуяг (для Нойона)
	var c_robe := Color(0.68, 0.42, 0.16) if not is_shaman else Color(0.28, 0.22, 0.36)
	if is_noyon:
		c_robe = Color(0.76, 0.18, 0.16)
	if is_scared:
		c_robe = Color(0.35, 0.38, 0.58)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8.8 * fwd, -4.5 + waddle),
		Vector2(8.8 * fwd, -4.5 + waddle),
		Vector2(12.8 * fwd, 14.8 - bob),
		Vector2(-11.5 * fwd, 14.8 - bob)
	]), c_robe)
	# Косий запах халата та широкий шовковий пояс
	draw_line(Vector2(-4.0 * fwd, -4.5 + waddle), Vector2(5.5 * fwd, 14.5 - bob), Color(0.95, 0.78, 0.22), 1.8)
	draw_line(Vector2(-9.5 * fwd, 5.0 + waddle), Vector2(9.8 * fwd, 5.0 + waddle), Color(0.88, 0.68, 0.18), 2.6)
	
	if is_noyon and armor > 0:
		# Ламелярний пластинчастий панцир-хуяг поверх халата
		draw_rect(Rect2(Vector2(-7.0, -3.2 + waddle), Vector2(14.0, 11.5)), Color(0.78, 0.66, 0.28))
		for row in range(3):
			var ry := -1.0 + float(row) * 3.8 + waddle
			draw_line(Vector2(-6.8, ry), Vector2(6.8, ry), Color(0.45, 0.34, 0.12), 1.4)
	
	_draw_moskal_legs(fwd, 14.2, 1.15)
	
	# 2. Зброя в руках: волосяний аркан (Нӧкер), великий бубон (Шаман) або крива шабля й бунчук (Нойон)
	var hand_p := Vector2(10.2 * fwd, 0.5 + waddle)
	draw_line(Vector2(5.5 * fwd, -2.0 + waddle), hand_p, c_robe, 3.6)
	if is_shaman:
		# Великий розмальований шаманський бубон
		_draw_oval(hand_p + Vector2(3.5 * fwd, -2.0), 5.5, 6.2, Color(0.88, 0.76, 0.54))
		draw_arc(hand_p + Vector2(3.5 * fwd, -2.0), 5.5, 0.0, TAU, 10, Color(0.52, 0.24, 0.14), 1.8)
		draw_circle(hand_p + Vector2(3.5 * fwd, -2.0), 2.0, Color(0.85, 0.20, 0.20))
	elif is_noyon:
		# Крива ординська шабля-елд із золотим ефесом
		draw_arc(hand_p + Vector2(3.0 * fwd, -6.5), 9.0, -1.2 if fwd > 0 else PI - 1.2, 0.6 if fwd > 0 else PI + 0.6, 8, Color(0.88, 0.92, 0.98), 2.8)
	else:
		# Закручена петля степового аркана над головою!
		var lasso_c := hand_p + Vector2(3.5 * fwd, -10.5 + sin(time_passed * 16.0) * 1.5)
		draw_line(hand_p, lasso_c, Color(0.82, 0.70, 0.42), 1.8)
		_draw_oval(lasso_c, 6.2, 2.8, Color(0.82, 0.70, 0.42, 0.45))
	
	# 3. Голова з характерними довгими вусами підковою донизу та гостроверхим малахаєм із лисячим хвостом
	var head_c := Vector2(0.5 * fwd, -8.2 + waddle)
	_draw_oval(head_c, 6.8, 6.0, Color(0.92, 0.76, 0.58))
	# Довгі чорні вуса підковою донизу
	draw_line(head_c + Vector2(0.5 * fwd, 1.5), head_c + Vector2(-4.5 * fwd, 7.5), Color(0.14, 0.12, 0.10), 2.0)
	draw_line(head_c + Vector2(2.5 * fwd, 1.5), head_c + Vector2(6.5 * fwd, 7.5), Color(0.14, 0.12, 0.10), 2.0)
	
	_draw_moskal_eyes(head_c, fwd, "ОХ, ЮРТА!" if is_noyon else "УРГА!")
	
	# 4. Хутряний малахай з лисячим хвостом і червоною китицею (або рогата шапка шамана / золочений шолом Нойона)
	_draw_oval(head_c + Vector2(0.0, -6.0), 7.6, 2.8, Color(0.48, 0.28, 0.14))
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-5.8, -6.5),
		head_c + Vector2(5.8, -6.5),
		head_c + Vector2(0.0, -18.5)
	]), Color(0.92, 0.74, 0.18) if is_noyon else Color(0.78, 0.22, 0.18))
	draw_circle(head_c + Vector2(0.0, -18.8), 2.2, Color(0.95, 0.18, 0.18)) # Червона китиця малахая
	# Пухнастий рудий лисячий хвіст позаду шапки!
	draw_line(head_c + Vector2(-5.5 * fwd, -6.0), head_c + Vector2(-13.5 * fwd, -2.0 + sin(time_passed * 12.0) * 2.0), Color(0.85, 0.42, 0.15), 3.6)

# РАНГ 1: «ШИШ» (Лісовий/болотяний мародер-нишпорка у драній сірячині й лаптях)
func _draw_moskal_shysh() -> void:
	var fwd := signf(velocity.x) if absf(velocity.x) > 10.0 else 1.0
	var waddle := 0.0 if is_resting else sin(time_passed * 13.5 * fatigue_mult) * (2.2 if not is_scared else 1.2)
	var bob := sin(time_passed * 7.5) * 1.1 if is_resting else absf(sin(time_passed * 13.5 * fatigue_mult)) * 2.4
	
	# 0. Латана полотняна торба за спиною (з якої стирчить крадений зелений качан капусти й бублик!)
	var sack_pos := Vector2(-7.8 * fwd, 1.5 + waddle * 0.7)
	_draw_oval(sack_pos, 5.8, 6.8, Color(0.55, 0.48, 0.36))
	draw_circle(sack_pos + Vector2(-2.8 * fwd, -5.8), 2.8, Color(0.32, 0.75, 0.28)) # Крадена капуста
	draw_arc(sack_pos + Vector2(-2.8 * fwd, -5.8), 2.2, -0.5, 2.0, 6, Color(0.55, 0.90, 0.45), 1.2)
	draw_arc(sack_pos + Vector2(2.2 * fwd, -4.8), 1.8, 0, TAU, 8, Color(0.92, 0.75, 0.28), 1.3) # Крадений бублик
	
	# 1. Худорлява драна сірячина (буро-сіра свитка з кольоровими латками та мотузковим поясом)
	var c_coat := Color(0.46, 0.42, 0.34) if not is_scared else Color(0.38, 0.42, 0.56)
	var body_pts := PackedVector2Array([
		Vector2(-7.2 * fwd, -4.0 + waddle),
		Vector2(7.5 * fwd, -4.0 + waddle),
		Vector2(10.2 * fwd, 13.8 - bob),
		Vector2(-9.5 * fwd, 13.8 - bob)
	])
	draw_colored_polygon(body_pts, c_coat)
	# Яскраві латки на сірячині (синя і руда, прошиті хрестиком)
	draw_rect(Rect2(Vector2(-4.5 * fwd, 2.0 + waddle), Vector2(4.2, 3.6)), Color(0.28, 0.48, 0.68))
	draw_line(Vector2(-4.5 * fwd, 2.0 + waddle), Vector2(-0.3 * fwd, 5.6 + waddle), Color(0.95, 0.95, 0.95), 0.8)
	draw_rect(Rect2(Vector2(1.5 * fwd, 6.8 + waddle), Vector2(3.8, 3.4)), Color(0.75, 0.40, 0.22))
	draw_line(Vector2(1.5 * fwd, 6.8 + waddle), Vector2(5.3 * fwd, 10.2 + waddle), Color(0.95, 0.95, 0.95), 0.8)
	# Мотузковий пояс-очкурик із китицею
	draw_line(Vector2(-8.2 * fwd, 5.2 + waddle), Vector2(8.4 * fwd, 5.2 + waddle), Color(0.78, 0.66, 0.42), 2.0)
	draw_line(Vector2(2.0 * fwd, 5.2 + waddle), Vector2(1.5 * fwd, 10.2 + waddle + sin(time_passed * 10.0) * 1.0), Color(0.78, 0.66, 0.42), 1.6)
	
	# 2. Прудкі ноги у великих ликових лаптях та онучах
	_draw_moskal_legs(fwd, 13.5, 1.25)
	
	# 3. Сучкувата дерев'яна дубина-макогін / рогатина в руці
	if is_resting:
		var club_top := Vector2(10.5 * fwd, -10.0)
		var club_bot := Vector2(10.0 * fwd, 19.5)
		draw_line(club_bot, club_top, Color(0.45, 0.30, 0.16), 3.2)
		_draw_oval(club_top, 3.5, 4.2, Color(0.38, 0.24, 0.12))
		var brow_wipe := Vector2((2.2 + sin(time_passed * 8.0) * 1.5) * fwd, -10.5)
		draw_line(Vector2(-4.5 * fwd, -2.0), brow_wipe, c_coat, 3.2)
		draw_circle(brow_wipe, 1.9, Color(0.95, 0.80, 0.68))
	elif not is_scared:
		var hand_p := Vector2(9.2 * fwd, 0.5 + waddle)
		draw_line(Vector2(4.5 * fwd, -2.0 + waddle), hand_p, c_coat, 3.2)
		draw_circle(hand_p, 1.9, Color(0.95, 0.80, 0.68))
		var club_tip := hand_p + Vector2(6.5 * fwd, -11.5)
		draw_line(hand_p + Vector2(-2.0 * fwd, 4.0), club_tip, Color(0.46, 0.30, 0.15), 3.0)
		_draw_oval(club_tip, 3.8, 4.6, Color(0.38, 0.24, 0.12)) # Товсте навершя дубини-макогона
	else:
		var arm_w := sin(time_passed * 26.0) * 5.0
		draw_line(Vector2(-5.5 * fwd, -2.0), Vector2(-13.5 * fwd, -14.0 + arm_w), c_coat, 3.0)
		draw_line(Vector2(5.5 * fwd, -2.0), Vector2(13.5 * fwd, -14.0 - arm_w), c_coat, 3.0)
	
	# 4. Худорлява скуйовджена голова з ріденькою цапиною борідкою та кривою вушанкою
	var head_c := Vector2(0.5 * fwd, -8.0 + waddle)
	_draw_oval(head_c, 6.2, 5.8, Color(0.95, 0.80, 0.68))
	# Ріденька скуйовджена борідка-шиш
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-2.8 * fwd, 3.2),
		head_c + Vector2(3.8 * fwd, 3.2),
		head_c + Vector2(2.2 * fwd, 9.8 + sin(time_passed * 14.0) * 1.2)
	]), Color(0.42, 0.28, 0.16))
	draw_circle(head_c + Vector2(3.8 * fwd, -0.6), 2.4, Color(0.92, 0.36, 0.34)) # Хитрий червоний ніс
	
	_draw_moskal_eyes(head_c, fwd, "НІ ШИША!")
	
	# 5. Крива шапка-вушанка (одне вухо стирчить догори, друге теліпається!)
	var fur_c := Color(0.38, 0.26, 0.16)
	_draw_oval(head_c + Vector2(0.0, -5.8), 6.8, 3.2, fur_c)
	# Ліве вухо шапки стирчить угору антеною!
	draw_line(head_c + Vector2(-5.2 * fwd, -6.2), head_c + Vector2(-8.8 * fwd, -15.5 + sin(time_passed * 14.0) * 1.8), fur_c, 3.2)
	# Праве вухо шапки звисає донизу
	draw_line(head_c + Vector2(5.2 * fwd, -5.2), head_c + Vector2(7.8 * fwd, 1.5), fur_c, 3.2)

# РАНГ 2: «СТРІЛЕЦЬ» (Рядовий піхотинець у червоному каптані з бердишем і самоваром)
func _draw_moskal_strelets() -> void:
	var fwd := signf(velocity.x) if absf(velocity.x) > 10.0 else 1.0
	var waddle := 0.0 if is_resting else sin(time_passed * 10.0 * fatigue_mult) * (2.4 if not is_scared else 1.2)
	var bob := sin(time_passed * 7.0) * 1.2 if is_resting else absf(sin(time_passed * 10.0 * fatigue_mult)) * 2.6
	
	# 0. Мішок-лантух для мародерства за плечима (з якого стирчить крадений мідний самовар!)
	var sack_pos := Vector2(-8.8 * fwd, 2.0 + waddle * 0.8)
	_draw_oval(sack_pos, 6.5, 7.8, Color(0.62, 0.52, 0.38))
	draw_line(sack_pos + Vector2(-3.0, -5.0), sack_pos + Vector2(2.0, -5.0), Color(0.42, 0.32, 0.20), 1.6)
	draw_circle(sack_pos + Vector2(-3.5 * fwd, -7.2), 3.0, Color(0.88, 0.65, 0.20))
	draw_circle(sack_pos + Vector2(-3.5 * fwd, -7.2), 1.6, Color(1.0, 0.85, 0.35))
	draw_line(sack_pos + Vector2(-3.5 * fwd, -9.8), sack_pos + Vector2(-3.5 * fwd, -12.5), Color(0.75, 0.52, 0.16), 2.0)
	draw_line(sack_pos + Vector2(-3.5 * fwd, -12.5), sack_pos + Vector2(-1.5 * fwd, -14.0), Color(0.65, 0.45, 0.14), 1.8)
	
	# 1. Червоний об'ємний каптан / охабень із золотими петлицями та високим коміром
	var c_coat := Color(0.85, 0.15, 0.18) if not is_scared else Color(0.65, 0.18, 0.35)
	var c_coat_sh := Color(0.58, 0.08, 0.10) if not is_scared else Color(0.45, 0.10, 0.24)
	var c_braid := Color(0.96, 0.82, 0.18) # Золоті петлиці (бранденбури)
	
	var body_pts := PackedVector2Array([
		Vector2(-9.5 * fwd, -4.5 + waddle),
		Vector2(9.5 * fwd, -4.5 + waddle),
		Vector2(14.5 * fwd, 15.2 - bob),
		Vector2(-12.5 * fwd, 15.2 - bob)
	])
	draw_colored_polygon(body_pts, c_coat)
	draw_line(Vector2(-12.0 * fwd, 14.8 - bob), Vector2(14.0 * fwd, 14.8 - bob), c_braid, 2.0)
	draw_line(Vector2(0, -4.5 + waddle), Vector2(0, 15.0 - bob), c_coat_sh, 1.8)
	
	for b in range(3):
		var by := float(b) * 4.4 + waddle
		draw_line(Vector2(-6.5 * fwd, by), Vector2(6.5 * fwd, by), c_braid, 2.2)
		draw_circle(Vector2(-6.5 * fwd, by), 1.2, c_braid)
		draw_circle(Vector2(6.5 * fwd, by), 1.2, c_braid)
		draw_circle(Vector2(0, by), 1.4, Color(1.0, 0.95, 0.55))
		draw_circle(Vector2(0, by), 0.6, Color(0.85, 0.12, 0.12))
	
	# 2. Неповороткі ноги у лаптях з переплетеними онучами
	_draw_moskal_legs(fwd, 14.5, 1.0)
	
	# 3. Важкий незграбний бердиш (сокира-півмісяць на держаку) та рукави каптана
	if is_resting:
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
		var hand_grip := Vector2(10.5 * fwd, 0.0 + waddle)
		draw_line(Vector2(5.5 * fwd, -2.5 + waddle), hand_grip, c_coat, 3.8)
		draw_circle(hand_grip, 2.0, Color(0.96, 0.82, 0.70))
		draw_line(pole_bot, pole_top, Color(0.42, 0.26, 0.14), 2.8)
		draw_arc(pole_top + Vector2(2.0 * fwd, 4.0), 10.5, -1.3 if fwd > 0 else PI - 1.3, 1.3 if fwd > 0 else PI + 1.3, 10, Color(0.82, 0.86, 0.92), 3.4)
		draw_arc(pole_top + Vector2(2.0 * fwd, 4.0), 10.5, -0.9 if fwd > 0 else PI - 0.9, 0.9 if fwd > 0 else PI + 0.9, 8, Color(1.0, 1.0, 1.0, 0.85), 1.4)
		draw_line(pole_top + Vector2(2.0 * fwd, -6.5), pole_top + Vector2(2.0 * fwd, 12.5), Color(0.62, 0.68, 0.75), 2.0)
		draw_circle(pole_top + Vector2(2.0 * fwd, -2.0), 0.9, Color(0.88, 0.65, 0.20))
		draw_circle(pole_top + Vector2(2.0 * fwd, 6.0), 0.9, Color(0.88, 0.65, 0.20))
	else:
		var axe_rot := time_passed * 16.0
		var axe_c := Vector2(-18.0 * fwd, -4.0 + sin(time_passed * 10.0) * 6.0)
		draw_line(axe_c - Vector2(cos(axe_rot), sin(axe_rot)) * 12.0, axe_c + Vector2(cos(axe_rot), sin(axe_rot)) * 12.0, Color(0.40, 0.25, 0.14), 2.2)
		draw_arc(axe_c + Vector2(cos(axe_rot), sin(axe_rot)) * 10.0, 6.2, 0, PI, 6, Color(0.78, 0.82, 0.88), 2.6)
		var arm_wave := sin(time_passed * 26.0) * 5.5
		draw_line(Vector2(-7.0 * fwd, -2.0 + waddle), Vector2(-15.5 * fwd, -15.5 + waddle + arm_wave), c_coat, 3.4)
		draw_line(Vector2(7.0 * fwd, -2.0 + waddle), Vector2(15.5 * fwd, -15.5 + waddle - arm_wave), c_coat, 3.4)
		draw_circle(Vector2(-15.5 * fwd, -15.5 + waddle + arm_wave), 2.0, Color(0.96, 0.82, 0.70))
		draw_circle(Vector2(15.5 * fwd, -15.5 + waddle - arm_wave), 2.0, Color(0.96, 0.82, 0.70))
	
	# 4. Голова, широка борода лопатою та червоний ніс-слива
	var head_c := Vector2(0.0, -8.2 + waddle)
	_draw_oval(head_c, 7.0, 6.4, Color(0.96, 0.82, 0.70))
	_draw_oval(head_c + Vector2(2.2 * fwd, 1.0), 2.2, 1.5, Color(0.95, 0.45, 0.45, 0.45))
	
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
	draw_line(head_c + Vector2(-4.2 * fwd, 11.0), head_c + Vector2(-4.2 * fwd, 14.2 + sin(time_passed * 12.0) * 1.5), beard_col, 2.2)
	draw_line(head_c + Vector2(0.0, 11.0), head_c + Vector2(0.0, 15.2 + cos(time_passed * 12.0) * 1.5), beard_col, 2.4)
	draw_line(head_c + Vector2(4.2 * fwd, 11.0), head_c + Vector2(4.2 * fwd, 14.2 - sin(time_passed * 12.0) * 1.5), beard_col, 2.2)
	
	draw_circle(head_c + Vector2(3.8 * fwd, -0.8), 2.8, Color(0.92, 0.34, 0.34))
	draw_circle(head_c + Vector2(4.5 * fwd, -1.6), 0.9, Color(1.0, 0.78, 0.78))
	
	_draw_moskal_eyes(head_c, fwd, "УПРІВ!")
	
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
		var cap_pos := head_c + Vector2(0.0, -19.0 + sin(time_passed * 20.0) * 3.2)
		var cap_angle := time_passed * 16.0
		var c_off := Vector2(cos(cap_angle), sin(cap_angle)) * 6.2
		_draw_oval(cap_pos, 6.6, 2.3, fur_col)
		draw_colored_polygon(PackedVector2Array([
			cap_pos - c_off, cap_pos + c_off, cap_pos + Vector2(0, -14.0)
		]), Color(0.85, 0.15, 0.18))
		draw_circle(cap_pos + Vector2(0, -14.0), 2.1, fur_col)

# РАНГ 3: «ПРИКАЗНИЙ ДЯК» (Сутулий царський писарчук із довгими рукавами до землі, сувоєм Указу та чорнильницею)
func _draw_moskal_dyak() -> void:
	var fwd := signf(velocity.x) if absf(velocity.x) > 10.0 else 1.0
	var waddle := 0.0 if is_resting else sin(time_passed * 11.0 * fatigue_mult) * 2.0
	var bob := sin(time_passed * 7.0) * 1.0 if is_resting else absf(sin(time_passed * 11.0 * fatigue_mult)) * 2.1
	
	# 0. Чорнильні клякси, що капають із каламаря позаду Приказного Дяка!
	for k in range(2):
		var kt := fmod(time_passed * 2.2 + float(k) * 0.5, 1.0)
		var k_pos := Vector2((-10.0 - kt * 12.0) * fwd, 6.0 + kt * 12.0)
		draw_circle(k_pos, 2.4 * (1.0 - kt * 0.5), Color(0.10, 0.08, 0.18, 0.80 * (1.0 - kt)))
	
	# 1. Довгий темно-зелений приказний каптан до п'ят і комічно довгі рукави до землі ("спущені рукави")
	var c_coat := Color(0.16, 0.38, 0.30) if not is_scared else Color(0.24, 0.30, 0.52)
	var body_pts := PackedVector2Array([
		Vector2(-8.0 * fwd, -4.5 + waddle),
		Vector2(8.5 * fwd, -4.5 + waddle),
		Vector2(11.8 * fwd, 16.5 - bob),
		Vector2(-10.8 * fwd, 16.5 - bob)
	])
	draw_colored_polygon(body_pts, c_coat)
	draw_line(Vector2(-10.5 * fwd, 16.2 - bob), Vector2(11.5 * fwd, 16.2 - bob), Color(0.85, 0.72, 0.25), 1.8)
	
	_draw_moskal_legs(fwd, 15.5, 1.05)
	
	# Довжелезний задній рукав волочиться до самої підлоги!
	var drag_sleeve_end := Vector2(-13.5 * fwd, 18.5 + sin(time_passed * 12.0) * 1.5)
	draw_line(Vector2(-6.5 * fwd, -1.5 + waddle), drag_sleeve_end, c_coat.darkened(0.15), 4.2)
	
	# Передній рукав тримає довгий розгорнутий сувій «ЦАРСЬКОГО УКАЗУ» з червоною сургучевою печаткою!
	var scroll_hand := Vector2(10.5 * fwd, 0.5 + waddle)
	draw_line(Vector2(5.5 * fwd, -2.0 + waddle), scroll_hand, c_coat, 3.8)
	var scroll_bot := scroll_hand + Vector2(3.5 * fwd, 11.5 + sin(time_passed * 14.0) * 1.8)
	draw_line(scroll_hand, scroll_bot, Color(0.96, 0.92, 0.78), 5.2) # Пергамент сувою
	draw_circle(scroll_bot + Vector2(0.0, 2.0), 2.4, Color(0.88, 0.16, 0.16)) # Сургучева печатка
	
	# 2. Сутула голова з гачкуватим носом, окулярами, гусячим пером за вухом та високою горлатною шапкою
	var head_c := Vector2(1.8 * fwd, -8.5 + waddle)
	_draw_oval(head_c, 6.4, 6.0, Color(0.95, 0.84, 0.72))
	# Біле гусяче перо стирчить за вухом!
	draw_line(head_c + Vector2(-2.0 * fwd, -2.0), head_c + Vector2(-12.5 * fwd, -12.5), Color(0.98, 0.98, 1.0), 2.4)
	# Довгий ніс і круглі скельця окулярів
	draw_circle(head_c + Vector2(4.2 * fwd, -0.5), 2.3, Color(0.92, 0.42, 0.40))
	draw_arc(head_c + Vector2(2.2 * fwd, -3.0), 2.5, 0.0, TAU, 8, Color(0.88, 0.76, 0.22), 1.2)
	# Цапина борідка клинцем
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-2.5 * fwd, 2.8),
		head_c + Vector2(4.2 * fwd, 2.8),
		head_c + Vector2(3.0 * fwd, 10.5)
	]), Color(0.32, 0.24, 0.18))
	
	_draw_moskal_eyes(head_c, fwd, "УКАЗ!")
	
	# Висока чорна приказна шапка-циліндр («горлатна»)
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-5.5 * fwd, -6.2),
		head_c + Vector2(5.5 * fwd, -6.2),
		head_c + Vector2(6.8 * fwd, -19.5),
		head_c + Vector2(-6.8 * fwd, -19.5)
	]), Color(0.18, 0.16, 0.20))

# РАНГ 4: «ОПРИЧНИК / БОЯРСЬКИЙ СИН» (У чорному каптані, панцирі-бехтерці з прив'язаною мітлою та шестопером)
func _draw_moskal_oprychnyk() -> void:
	var fwd := signf(velocity.x) if absf(velocity.x) > 10.0 else 1.0
	var waddle := 0.0 if is_resting else sin(time_passed * 10.0 * fatigue_mult) * 2.2
	var bob := sin(time_passed * 7.0) * 1.2 if is_resting else absf(sin(time_passed * 10.0 * fatigue_mult)) * 2.4
	
	# 0. Опрична березова мітла за плечима (історичний атрибут опричника!)
	var broom_top := Vector2(-11.5 * fwd, -15.5 + waddle)
	draw_line(Vector2(-5.0 * fwd, 6.0), broom_top, Color(0.45, 0.28, 0.14), 2.4)
	draw_colored_polygon(PackedVector2Array([
		broom_top,
		broom_top + Vector2(-5.5 * fwd, -6.5),
		broom_top + Vector2(1.5 * fwd, -8.0)
	]), Color(0.68, 0.54, 0.26))
	
	# 1. Чорний опричний каптан із багряною облямівкою
	var c_coat := Color(0.16, 0.15, 0.20) if not is_scared else Color(0.28, 0.24, 0.42)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-10.0 * fwd, -4.8 + waddle),
		Vector2(10.0 * fwd, -4.8 + waddle),
		Vector2(14.5 * fwd, 15.2 - bob),
		Vector2(-13.0 * fwd, 15.2 - bob)
	]), c_coat)
	draw_line(Vector2(-12.5 * fwd, 14.8 - bob), Vector2(14.0 * fwd, 14.8 - bob), Color(0.85, 0.18, 0.18), 2.2)
	
	# Якщо щит-броня ще цілий (armor > 0) — поверх каптана блищить сталевий пластинчастий панцир-бехтерець!
	if armor > 0:
		draw_rect(Rect2(Vector2(-7.2, -3.5 + waddle), Vector2(14.4, 12.5)), Color(0.68, 0.74, 0.82))
		for r in range(3):
			var ry := -1.5 + float(r) * 4.0 + waddle
			draw_line(Vector2(-6.8, ry), Vector2(6.8, ry), Color(0.42, 0.48, 0.56), 1.4)
			draw_circle(Vector2(-4.5, ry - 1.2), 0.9, Color(0.95, 0.85, 0.35))
			draw_circle(Vector2(4.5, ry - 1.2), 0.9, Color(0.95, 0.85, 0.35))
	
	_draw_moskal_legs(fwd, 14.5, 1.0)
	
	# 2. Важкий залізний шестопер / пернач у руці
	var hand_p := Vector2(10.5 * fwd, 0.0 + waddle)
	draw_line(Vector2(6.0 * fwd, -2.5 + waddle), hand_p, c_coat, 4.0)
	var mace_top := hand_p + Vector2(4.5 * fwd, -11.5)
	draw_line(hand_p + Vector2(-1.5 * fwd, 3.5), mace_top, Color(0.55, 0.58, 0.65), 2.8)
	draw_circle(mace_top, 4.2, Color(0.75, 0.80, 0.88))
	
	# 3. Похмура бородата голова та шапка-мурмолка
	var head_c := Vector2(0.0, -8.5 + waddle)
	_draw_oval(head_c, 7.2, 6.5, Color(0.95, 0.80, 0.68))
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-6.0 * fwd, 1.5),
		head_c + Vector2(6.0 * fwd, 1.5),
		head_c + Vector2(7.0 * fwd, 11.5),
		head_c + Vector2(-7.0 * fwd, 11.5)
	]), Color(0.18, 0.14, 0.12))
	draw_circle(head_c + Vector2(3.8 * fwd, -0.8), 2.7, Color(0.90, 0.34, 0.34))
	
	_draw_moskal_eyes(head_c, fwd, "ОЙ, ПАНЦИР!")
	
	if armor > 0 and not is_scared:
		# Залізна шапка-шишак із хутряною опушкою
		_draw_oval(head_c + Vector2(0.0, -6.5), 8.0, 2.8, Color(0.25, 0.20, 0.18))
		draw_colored_polygon(PackedVector2Array([
			head_c + Vector2(-6.5, -7.0),
			head_c + Vector2(6.5, -7.0),
			head_c + Vector2(0.0, -21.0)
		]), Color(0.72, 0.78, 0.86))

# РАНГ 5: «ПИХАТИЙ ВОЄВОДА» (Товстун-боярин у парчовій шубі та високій соболиній шапці з барабаном і перначем)
func _draw_moskal_voyevoda() -> void:
	var fwd := signf(velocity.x) if absf(velocity.x) > 10.0 else 1.0
	var waddle := 0.0 if is_resting else sin(time_passed * 8.5 * fatigue_mult) * 2.8
	var bob := sin(time_passed * 6.5) * 1.4 if is_resting else absf(sin(time_passed * 8.5 * fatigue_mult)) * 2.8
	
	# Командна аура тулумбаса воєводи
	if not is_scared and not is_resting:
		var ring_r := 18.0 + fmod(time_passed * 22.0, 16.0)
		draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 16, Color(1.0, 0.82, 0.20, 0.28), 1.6)
	
	# 1. Величезне кругле боярське черево у розшитій золотом пурпуровій шубі з соболиним коміром!
	var c_robe := Color(0.62, 0.12, 0.38) if not is_scared else Color(0.45, 0.18, 0.42)
	_draw_oval(Vector2(1.5 * fwd, 5.2 - bob * 0.5), 13.8, 11.8, c_robe) # Товсте черево!
	# Золоті боярські візерунки та соболина опушка
	_draw_oval(Vector2(0.0, -4.2 + waddle), 11.2, 3.8, Color(0.42, 0.26, 0.14)) # Широкий соболиний комір
	for b in range(3):
		var by := 0.5 + float(b) * 4.5
		draw_line(Vector2(-8.5, by), Vector2(9.5, by), Color(0.98, 0.84, 0.22), 2.2)
	
	_draw_moskal_legs(fwd, 15.2, 0.85)
	
	# 2. Золота воєводська булава-пернач у руці
	var hand_p := Vector2(12.5 * fwd, 1.0 + waddle)
	draw_line(Vector2(7.5 * fwd, -2.0 + waddle), hand_p, c_robe, 4.4)
	var pernach_top := hand_p + Vector2(4.0 * fwd, -11.0 + sin(time_passed * 14.0) * 2.5)
	draw_line(hand_p, pernach_top, Color(0.88, 0.72, 0.18), 3.0)
	_draw_oval(pernach_top, 4.5, 5.2, Color(1.0, 0.88, 0.25))
	
	# 3. Надуті червоні щоки, широченна борода лопатою до живота та величезна соболина горлатна шапка
	var head_c := Vector2(0.0, -9.2 + waddle)
	_draw_oval(head_c, 8.2, 7.0, Color(0.96, 0.80, 0.68))
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-7.5 * fwd, 1.8),
		head_c + Vector2(7.8 * fwd, 1.8),
		head_c + Vector2(10.2 * fwd, 13.5),
		head_c + Vector2(-9.5 * fwd, 13.5)
	]), Color(0.52, 0.34, 0.18))
	draw_circle(head_c + Vector2(4.2 * fwd, -0.8), 3.1, Color(0.94, 0.32, 0.32))
	
	_draw_moskal_eyes(head_c, fwd, "ОХ, ЧЕРЕВО!")
	
	if armor > 0 or not is_scared:
		# Висока розширена догори соболина боярська шапка з парчовим верхом
		draw_colored_polygon(PackedVector2Array([
			head_c + Vector2(-6.8, -6.5),
			head_c + Vector2(6.8, -6.5),
			head_c + Vector2(9.2, -22.5),
			head_c + Vector2(-9.2, -22.5)
		]), Color(0.38, 0.24, 0.12))
		_draw_oval(head_c + Vector2(0.0, -22.5), 8.8, 2.8, Color(0.96, 0.82, 0.20))

# РАНГ 6: «ГЕНЕРАЛ-КАРАТЕЛЬ НА ЦАР-МОРТИРІ» (У напудреній перуці й треуголці верхи на чавунній гарматі)
func _draw_moskal_tsar_general() -> void:
	var fwd := signf(velocity.x) if absf(velocity.x) > 10.0 else 1.0
	var waddle := 0.0 if is_resting else sin(time_passed * 11.0 * fatigue_mult) * 1.8
	
	# 1. Пузата чавунна «Цар-Мортира» на дерев'яних колесах під генералом!
	var barrel_c := Vector2(2.0 * fwd, 10.5)
	_draw_oval(barrel_c, 13.5, 6.8, Color(0.24, 0.26, 0.30)) # Чавунне дуло мортири
	draw_circle(barrel_c + Vector2(12.5 * fwd, -1.5), 4.8, Color(0.14, 0.15, 0.18)) # Жерло гармати
	# Дерев'яні колеса лафета зі спицями
	for wx in [-7.5, 7.5]:
		var wheel_c := Vector2(wx, 17.5)
		draw_circle(wheel_c, 5.2, Color(0.48, 0.30, 0.15))
		draw_arc(wheel_c, 5.2, 0.0, TAU, 10, Color(0.70, 0.74, 0.80), 1.6)
		var sp_ang := time_passed * 10.0 * fwd
		draw_line(wheel_c - Vector2(cos(sp_ang), sin(sp_ang)) * 4.5, wheel_c + Vector2(cos(sp_ang), sin(sp_ang)) * 4.5, Color(0.35, 0.20, 0.10), 1.4)
	
	# 2. Зелений імперський мундир із золотими еполетами та червоною стрічкою
	var c_coat := Color(0.12, 0.44, 0.28) if not is_scared else Color(0.25, 0.35, 0.55)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8.5 * fwd, -5.0 + waddle),
		Vector2(8.5 * fwd, -5.0 + waddle),
		Vector2(10.0 * fwd, 8.5),
		Vector2(-10.0 * fwd, 8.5)
	]), c_coat)
	# Золоті еполети з бахромою на плечах
	_draw_oval(Vector2(-8.2 * fwd, -4.5 + waddle), 3.6, 2.2, Color(1.0, 0.86, 0.20))
	_draw_oval(Vector2(8.2 * fwd, -4.5 + waddle), 3.6, 2.2, Color(1.0, 0.86, 0.20))
	draw_line(Vector2(-6.5 * fwd, -4.5 + waddle), Vector2(6.5 * fwd, 7.5), Color(0.90, 0.18, 0.20), 2.6) # Орденська стрічка
	
	# 3. Голова в білій напудреній перуці з буклями та чорному трикутному капелюсі (треуголці)
	var head_c := Vector2(0.0, -10.0 + waddle)
	# Білі напудрені буклі перуки з боків
	draw_circle(head_c + Vector2(-6.8, -1.0), 3.2, Color(0.95, 0.96, 1.0))
	draw_circle(head_c + Vector2(6.8, -1.0), 3.2, Color(0.95, 0.96, 1.0))
	_draw_oval(head_c, 6.6, 6.0, Color(0.96, 0.82, 0.72))
	draw_circle(head_c + Vector2(3.6 * fwd, -0.5), 2.5, Color(0.92, 0.35, 0.35))
	
	_draw_moskal_eyes(head_c, fwd, "ПХИК!")
	
	# Чорна треуголка з золотим галуном та білим плюмажем
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-11.5, -5.8),
		head_c + Vector2(11.5, -5.8),
		head_c + Vector2(0.0, -16.5)
	]), Color(0.14, 0.14, 0.18))
	draw_line(head_c + Vector2(-11.0, -5.8), head_c + Vector2(0.0, -16.2), Color(0.98, 0.85, 0.22), 1.6)
	draw_line(head_c + Vector2(11.0, -5.8), head_c + Vector2(0.0, -16.2), Color(0.98, 0.85, 0.22), 1.6)

# Спільні виразні ніжки та очі з емоціями для всіх чинів фракції Загарбників
func _draw_moskal_legs(fwd: float, hip_y: float, cadence_mult: float) -> void:
	var c_wrap := Color(0.78, 0.72, 0.62)
	var c_cord := Color(0.48, 0.36, 0.22)
	var c_lapot := Color(0.72, 0.55, 0.28)
	var c_lapot_weave := Color(0.50, 0.36, 0.16)
	if is_resting:
		var ankle_l := Vector2(-5.2 * fwd, hip_y + 5.0)
		var ankle_r := Vector2(5.2 * fwd, hip_y + 5.0)
		draw_line(Vector2(-4.8 * fwd, hip_y), ankle_l, c_wrap, 3.4)
		draw_line(Vector2(4.8 * fwd, hip_y), ankle_r, c_wrap, 3.4)
		# Мотузкові обори (перехрещені шнури на онучах)
		draw_line(Vector2(-6.2 * fwd, hip_y + 1.2), Vector2(-3.5 * fwd, hip_y + 3.8), c_cord, 1.2)
		draw_line(Vector2(-3.5 * fwd, hip_y + 1.2), Vector2(-6.2 * fwd, hip_y + 3.8), c_cord, 1.2)
		draw_line(Vector2(3.5 * fwd, hip_y + 1.2), Vector2(6.2 * fwd, hip_y + 3.8), c_cord, 1.2)
		draw_line(Vector2(6.2 * fwd, hip_y + 1.2), Vector2(3.5 * fwd, hip_y + 3.8), c_cord, 1.2)
		# Ликові плетені лапті з характерним перехресним візерунком
		var lap_l := ankle_l + Vector2(2.0 * fwd, 0.5)
		var lap_r := ankle_r + Vector2(2.0 * fwd, 0.5)
		_draw_oval(lap_l, 3.8, 2.1, c_lapot)
		_draw_oval(lap_r, 3.8, 2.1, c_lapot)
		draw_line(lap_l - Vector2(1.8 * fwd, 0.8), lap_l + Vector2(1.8 * fwd, 0.8), c_lapot_weave, 1.0)
		draw_line(lap_l - Vector2(1.8 * fwd, -0.8), lap_l + Vector2(1.8 * fwd, -0.8), c_lapot_weave, 1.0)
		draw_line(lap_r - Vector2(1.8 * fwd, 0.8), lap_r + Vector2(1.8 * fwd, 0.8), c_lapot_weave, 1.0)
		draw_line(lap_r - Vector2(1.8 * fwd, -0.8), lap_r + Vector2(1.8 * fwd, -0.8), c_lapot_weave, 1.0)
	elif not is_scared:
		var step_l := sin(time_passed * 10.0 * cadence_mult * fatigue_mult) * 4.5
		var step_r := -step_l
		var lift_l := maxf(0.0, -cos(time_passed * 10.0 * cadence_mult * fatigue_mult)) * 2.2
		var lift_r := maxf(0.0, cos(time_passed * 10.0 * cadence_mult * fatigue_mult)) * 2.2
		var ankle_l := Vector2(-5.0 * fwd + step_l, hip_y + 5.5 - lift_l)
		var ankle_r := Vector2(5.0 * fwd + step_r, hip_y + 5.5 - lift_r)
		draw_line(Vector2(-5.0 * fwd, hip_y), ankle_l, c_wrap, 3.5)
		draw_line(Vector2(5.0 * fwd, hip_y), ankle_r, c_wrap, 3.5)
		# Перехресні обори під час ходи
		var mid_l := Vector2(-5.0 * fwd, hip_y).lerp(ankle_l, 0.5)
		var mid_r := Vector2(5.0 * fwd, hip_y).lerp(ankle_r, 0.5)
		draw_line(mid_l - Vector2(1.5, -1.2), mid_l + Vector2(1.5, -1.2), c_cord, 1.2)
		draw_line(mid_r - Vector2(1.5, -1.2), mid_r + Vector2(1.5, -1.2), c_cord, 1.2)
		var lap_l := ankle_l + Vector2(2.0 * fwd, 0.5)
		var lap_r := ankle_r + Vector2(2.0 * fwd, 0.5)
		_draw_oval(lap_l, 3.8, 2.1, c_lapot)
		_draw_oval(lap_r, 3.8, 2.1, c_lapot)
		draw_line(lap_l - Vector2(1.8 * fwd, 0.8), lap_l + Vector2(1.8 * fwd, 0.8), c_lapot_weave, 1.0)
		draw_line(lap_l - Vector2(1.8 * fwd, -0.8), lap_l + Vector2(1.8 * fwd, -0.8), c_lapot_weave, 1.0)
		draw_line(lap_r - Vector2(1.8 * fwd, 0.8), lap_r + Vector2(1.8 * fwd, 0.8), c_lapot_weave, 1.0)
		draw_line(lap_r - Vector2(1.8 * fwd, -0.8), lap_r + Vector2(1.8 * fwd, -0.8), c_lapot_weave, 1.0)
	else:
		var spin := time_passed * 34.0
		draw_arc(Vector2(0, hip_y + 3.5), 6.5, spin, spin + PI, 6, c_lapot, 3.2)
		draw_arc(Vector2(0, hip_y + 3.5), 6.5, spin + PI, spin + TAU, 6, Color(0.35, 0.22, 0.12), 3.2)
		var lost_shoe_x := -17.0 * fwd + sin(time_passed * 16.0) * 4.0
		var lost_shoe_y := hip_y - 2.0 + cos(time_passed * 18.0) * 5.0
		var lost_p := Vector2(lost_shoe_x, lost_shoe_y)
		_draw_oval(lost_p, 3.4, 2.0, c_lapot)
		draw_line(lost_p - Vector2(1.5, 0.6), lost_p + Vector2(1.5, 0.6), c_lapot_weave, 0.9)

func _draw_moskal_eyes(head_c: Vector2, fwd: float, rest_label: String) -> void:
	if is_resting:
		draw_arc(head_c + Vector2(1.6 * fwd, -3.0), 2.0, 0.2, PI - 0.2, 6, Color(0.18, 0.10, 0.10), 1.9)
		draw_arc(head_c + Vector2(-2.4 * fwd, -3.0), 2.0, 0.2, PI - 0.2, 6, Color(0.18, 0.10, 0.10), 1.9)
		_draw_sweat_and_breath(head_c + Vector2(1.5 * fwd, -9.5), head_c + Vector2(5.5 * fwd, 3.0), fwd, rest_label)
	elif not is_scared:
		draw_line(head_c + Vector2(-4.8 * fwd, -5.4), head_c + Vector2(0.5 * fwd, -4.4), Color(0.24, 0.15, 0.08), 2.4)
		draw_line(head_c + Vector2(0.5 * fwd, -4.4), head_c + Vector2(4.8 * fwd, -5.2), Color(0.24, 0.15, 0.08), 2.4)
		draw_circle(head_c + Vector2(1.6 * fwd, -3.0), 1.9, Color.WHITE)
		draw_circle(head_c + Vector2(-2.4 * fwd, -3.0), 1.9, Color.WHITE)
		draw_circle(head_c + Vector2(2.0 * fwd, -3.0), 1.1, Color(0.12, 0.10, 0.10))
		draw_circle(head_c + Vector2(-2.0 * fwd, -3.0), 1.1, Color(0.12, 0.10, 0.10))
	else:
		var eye1 := head_c + Vector2(-2.5 * fwd, -4.5)
		var eye2 := head_c + Vector2(3.5 * fwd, -4.5)
		draw_circle(eye1, 4.3, Color.WHITE)
		draw_circle(eye2, 4.3, Color.WHITE)
		draw_circle(eye1, 1.4, Color(0.12, 0.15, 0.35))
		draw_circle(eye2, 1.4, Color(0.12, 0.15, 0.35))
		_draw_oval(head_c + Vector2(1.5 * fwd, 3.6), 2.6, 3.4, Color(0.20, 0.05, 0.05))

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

# ============================================================================
# НОВІ ВОРОЖІ NPC КАМПАНІЇ 20 РІВНІВ (T-023: ЗЛИДНІ, БАСАВРЮК, ВІЙ, ВІДЬМАК, БОС)
# Збережено інваріанти I-3 (Zero-Horror) та I-4 (Anti-Clipping: виступи позаду тіла)
# ============================================================================

const ZLYDNI_HEAD_RX: float = 9.0
const ZLYDNI_HEAD_RY: float = 8.4
static func zlydni_ear_points(fwd: float, bob: float) -> Array:
	return [
		[Vector2(-5.2 * fwd, -4.8 + bob), Vector2(-10.5 * fwd, -8.5 + bob), Vector2(-13.0 * fwd, -12.0 + bob)],
		[Vector2(5.2 * fwd, -4.8 + bob), Vector2(10.5 * fwd, -8.5 + bob), Vector2(13.0 * fwd, -12.0 + bob)],
	]

func _draw_zlydni() -> void:
	var fwd := signf(velocity.x) if absf(velocity.x) > 10.0 else 1.0
	var bob := sin(time_passed * 14.0) * 1.8
	# 1. Довгі капловухі вушка Злидня малюються ПОЗАДУ голови (Anti-Clipping I-4)
	var ears := zlydni_ear_points(fwd, bob)
	for e_pts in ears:
		draw_line(e_pts[0], e_pts[1], Color(0.55, 0.46, 0.36), 3.0)
		draw_line(e_pts[1], e_pts[2], Color(0.68, 0.54, 0.42), 2.2)
	# 2. Латана сіра свитинка й короткі ніжки
	_draw_moskal_legs(fwd, 7.5, 1.35)
	_draw_oval(Vector2(0.0, 2.5 + bob), 8.2, 6.8, Color(0.46, 0.42, 0.36) if not is_scared else Color(0.32, 0.44, 0.68))
	draw_rect(Rect2(-3.5, 1.0 + bob, 4.5, 3.8), Color(0.68, 0.52, 0.32)) # Латка на свитині
	# 3. Голова та кумедний ніс-картоплина
	_draw_oval(Vector2(0.0, -3.0 + bob), ZLYDNI_HEAD_RX, ZLYDNI_HEAD_RY, Color(0.76, 0.68, 0.56))
	draw_circle(Vector2(4.2 * fwd, -2.0 + bob), 2.4, Color(0.88, 0.52, 0.48))
	_draw_moskal_eyes(Vector2(0.0, -3.0 + bob), fwd, "ОЙ-ОЙ!")

const BASAVRIUK_HEAD_RX: float = 10.6
const BASAVRIUK_HEAD_RY: float = 10.0
static func basavriuk_horn_points(fwd: float, bob: float) -> Array:
	return [
		[Vector2(-6.0 * fwd, -6.5 + bob), Vector2(-11.2 * fwd, -11.5 + bob), Vector2(-13.8 * fwd, -16.5 + bob)],
		[Vector2(6.0 * fwd, -6.5 + bob), Vector2(11.2 * fwd, -11.5 + bob), Vector2(13.8 * fwd, -16.5 + bob)],
	]

func _draw_basavriuk() -> void:
	var fwd := signf(velocity.x) if absf(velocity.x) > 10.0 else 1.0
	var bob := sin(time_passed * 9.0) * 1.8
	# 1. Кручені ріжки шинкаря-біса Басаврюка ПОЗАДУ голови (Anti-Clipping I-4)
	var horns := basavriuk_horn_points(fwd, bob)
	for h in horns:
		draw_line(h[0], h[1], Color(0.28, 0.14, 0.12), 3.4)
		draw_line(h[1], h[2], Color(0.85, 0.68, 0.22), 2.4)
	# 2. Червоний каптан-жупан і мішок із черепками
	_draw_moskal_legs(fwd, 9.5, 0.95)
	_draw_oval(Vector2(-7.5 * fwd, 2.0 + bob), 6.0, 5.5, Color(0.58, 0.44, 0.24)) # Торба черепків за спиною
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8.5 * fwd, -3.0 + bob), Vector2(8.5 * fwd, -3.0 + bob),
		Vector2(10.5 * fwd, 9.5 + bob), Vector2(-10.5 * fwd, 9.5 + bob)
	]), Color(0.68, 0.14, 0.18) if not is_scared else Color(0.28, 0.36, 0.64))
	# 3. Голова та вуса
	_draw_oval(Vector2(0.0, -3.5 + bob), BASAVRIUK_HEAD_RX, BASAVRIUK_HEAD_RY, Color(0.88, 0.72, 0.64))
	_draw_moskal_eyes(Vector2(0.0, -3.5 + bob), fwd, "Тьху!")

const VIJ_HEAD_RX: float = 13.0
const VIJ_HEAD_RY: float = 12.2
static func vij_brow_points(fwd: float, bob: float) -> Array:
	return [
		[Vector2(-7.8 * fwd, -7.2 + bob), Vector2(-14.5 * fwd, -10.5 + bob), Vector2(-17.5 * fwd, -13.5 + bob)],
		[Vector2(7.8 * fwd, -7.2 + bob), Vector2(14.5 * fwd, -10.5 + bob), Vector2(17.5 * fwd, -13.5 + bob)],
	]

func _draw_vij() -> void:
	var fwd := signf(velocity.x) if absf(velocity.x) > 10.0 else 1.0
	var bob := sin(time_passed * 6.0) * 1.5
	# 1. Кумедні розлогі брови-повіки сонного Вія ПОЗАДУ контуру голови (Anti-Clipping I-4, Zero-Horror I-3)
	var brows := vij_brow_points(fwd, bob)
	for b in brows:
		draw_line(b[0], b[1], Color(0.36, 0.38, 0.44), 4.0)
		draw_line(b[1], b[2], Color(0.52, 0.56, 0.64), 3.0)
	# 2. Приземкуватий кам'яно-моховий тулуб
	_draw_moskal_legs(fwd, 10.0, 0.65)
	_draw_oval(Vector2(0.0, 2.0 + bob), VIJ_HEAD_RX, VIJ_HEAD_RY, Color(0.42, 0.46, 0.40) if not is_scared else Color(0.35, 0.48, 0.70))
	# Сонні напівприкриті повіки з мідними окулярами
	draw_circle(Vector2(-3.5 * fwd, -2.0 + bob), 3.6, Color(0.85, 0.72, 0.32))
	draw_circle(Vector2(3.5 * fwd, -2.0 + bob), 3.6, Color(0.85, 0.72, 0.32))
	_draw_moskal_eyes(Vector2(0.0, -1.0 + bob), fwd, "ХРР-ПФ!")

const VIDMAK_HEAD_RX: float = 10.0
const VIDMAK_HEAD_RY: float = 9.6
static func vidmak_wrench_points(fwd: float, bob: float) -> Array:
	return [
		[Vector2(-6.0 * fwd, -5.5 + bob), Vector2(-12.0 * fwd, -10.5 + bob), Vector2(-15.5 * fwd, -15.0 + bob)],
		[Vector2(6.0 * fwd, -5.5 + bob), Vector2(12.0 * fwd, -10.5 + bob), Vector2(15.5 * fwd, -15.0 + bob)],
	]

func _draw_vidmak() -> void:
	var fwd := signf(velocity.x) if absf(velocity.x) > 10.0 else 1.0
	var bob := sin(time_passed * 8.0) * 2.4
	# 1. Схрещені мідні гайкові ключі та антени інженера-відьмака ПОЗАДУ тулуба й голови (Anti-Clipping I-4, GDD §1.2)
	var wrenches := vidmak_wrench_points(fwd, bob)
	for w in wrenches:
		draw_line(w[0], w[1], Color(0.58, 0.62, 0.68), 3.2)
		draw_line(w[1], w[2], Color(0.88, 0.72, 0.28), 2.8)
		draw_circle(w[2], 2.5, Color(0.75, 0.80, 0.86))
	# 2. Механічний планер-мітла з шестернями
	draw_line(Vector2(-18.0 * fwd, 6.0 + bob), Vector2(18.0 * fwd, 2.0 + bob), Color(0.45, 0.32, 0.20), 3.2)
	draw_circle(Vector2(-14.0 * fwd, 6.0 + bob), 4.2, Color(0.85, 0.68, 0.24))
	# 3. Синій інженерний жупан із шкіряним фартухом і голова в мідних гоглах
	_draw_oval(Vector2(0.0, 1.5 + bob), 8.6, 7.2, Color(0.20, 0.28, 0.44) if not is_scared else Color(0.32, 0.44, 0.72))
	_draw_oval(Vector2(0.0, -4.5 + bob), VIDMAK_HEAD_RX, VIDMAK_HEAD_RY, Color(0.95, 0.82, 0.72))
	# Мідні інженерні гогли з бірюзовими лінзами
	draw_circle(Vector2(-3.0 * fwd, -5.5 + bob), 3.0, Color(0.85, 0.62, 0.22))
	draw_circle(Vector2(3.2 * fwd, -5.5 + bob), 3.0, Color(0.85, 0.62, 0.22))
	draw_circle(Vector2(-3.0 * fwd, -5.5 + bob), 1.8, Color(0.35, 0.95, 0.90))
	draw_circle(Vector2(3.2 * fwd, -5.5 + bob), 1.8, Color(0.35, 0.95, 0.90))

const BOSS_HEAD_RX: float = 12.2
const BOSS_HEAD_RY: float = 11.4
static func boss_crown_points(fwd: float, bob: float) -> Array:
	return [
		[Vector2(-7.2 * fwd, -7.0 + bob), Vector2(-13.5 * fwd, -13.0 + bob), Vector2(-16.5 * fwd, -19.0 + bob)],
		[Vector2(7.2 * fwd, -7.0 + bob), Vector2(13.5 * fwd, -13.0 + bob), Vector2(16.5 * fwd, -19.0 + bob)],
	]

func _draw_final_boss() -> void:
	var fwd := signf(velocity.x) if absf(velocity.x) > 10.0 else 1.0
	var bob := sin(time_passed * 7.5) * 2.0
	# 1. Зубці великої картонної корони на пружинках ПОЗАДУ голови (Anti-Clipping I-4)
	var prongs := boss_crown_points(fwd, bob)
	for p in prongs:
		draw_line(p[0], p[1], Color(0.98, 0.82, 0.18), 3.6)
		draw_line(p[1], p[2], Color(1.0, 0.90, 0.30), 2.8)
		draw_circle(p[2], 2.4, Color(0.92, 0.18, 0.24))
	# 2. Парова колісниця-самовар на колесах і пишна мантія
	for wx in [-9.0, 9.0]:
		draw_circle(Vector2(wx, 14.5), 5.0, Color(0.38, 0.26, 0.16))
		draw_arc(Vector2(wx, 14.5), 5.0, 0.0, TAU, 10, Color(0.92, 0.78, 0.24), 1.6)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-11.0 * fwd, -2.0 + bob), Vector2(11.0 * fwd, -2.0 + bob),
		Vector2(13.5 * fwd, 11.0 + bob), Vector2(-13.5 * fwd, 11.0 + bob)
	]), Color(0.55, 0.12, 0.22) if not is_scared else Color(0.28, 0.38, 0.66))
	# 3. Голова самодура
	_draw_oval(Vector2(0.0, -3.0 + bob), BOSS_HEAD_RX, BOSS_HEAD_RY, Color(0.96, 0.82, 0.72))
	_draw_moskal_eyes(Vector2(0.0, -3.0 + bob), fwd, "РЯТУЙТЕ!")
