extends Node2D

class_name GameManager

@export var bomb_scene: PackedScene = preload("res://scenes/bomb.tscn")
@export var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
@export var flower_scene: PackedScene = preload("res://scenes/power_flower.tscn")
@export var horseshoe_scene: PackedScene = preload("res://scenes/vakula_horseshoe.tscn")
@export var platform_scene: PackedScene = preload("res://scenes/platform.tscn")
@export var qirimli_scene: PackedScene = preload("res://scenes/qirimli_ally.tscn")
@export var hutsul_scene: PackedScene = preload("res://scenes/hutsul_ally.tscn")

@onready var hud: JackHUD = $HUD
@onready var bombs_node: Node2D = $Bombs
@onready var cast_node: Node2D = $Cast
@onready var player: JackPlayer = $Cast/Player
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer
@onready var background_visual: BackgroundVisual = $Background
@onready var platforms_node: Node2D = $Platforms
@onready var enemies_node: Node2D = $Enemies
@onready var items_node: Node2D = $Items
@onready var story_cards: StoryCardsOverlay = $StoryCards

var score: int = 0
var high_score: int = 20000
var lit_streak: int = 1
var level: int = 1
var is_transitioning_level: bool = false
var bombs_collected_on_level: int = 0
var hutsul_spawned_this_level: bool = false
var hutsul_waves_spawned: int = 0
var qirimli_spawned_this_level: bool = false
# Складність і якість проходження (scripts/difficulty.gd, scripts/telemetry_engine.gd, SHR-001 I-7)
const _Difficulty = preload("res://scripts/difficulty.gd")
const _MavkaAlly = preload("res://scripts/mavka_ally.gd")
const _PlayerModel = preload("res://scripts/player_model.gd")
const _Telemetry = preload("res://scripts/telemetry.gd")
const _LevelDifficulty = preload("res://scripts/level_difficulty.gd")
const PROFILE_PATH: String = "user://player_profile.json"
var adaptive_enabled: bool = true      # false: детермінована база difficulty.coefficient (для наборів тестів складу рівнів)
var player_model = null
var telemetry = null
var level_offset: float = 0.0
var level_in_progress: bool = false
const _TelemetryEngine = preload("res://scripts/telemetry_engine.gd")
var telemetry_engine: TelemetryEngine = null
var difficulty_k: float = 1.0
var prev_quality: float = 0.5
var level_started_ms: int = 0
var hits_this_level: int = 0
var max_lit_streak_level: int = 1
var mavka_spawned_this_level: bool = false
var mavka_ally: Node2D = null
var level_enemy_count_start: int = 0
var qirimli_ally: Node2D = null
var hutsul_ally: Node2D = null
var hutsul_allies: Array[Node2D] = []

const COMBAT_HINTS: Dictionary = {
	"basic_strike": {
		"title": "ПРЯМИЙ УДАР КОЗАКА",
		"hint": "УДАР РУКОЮ: Клавіатура [X / J / Ctrl] або Геймпад Logitech [X / RB] — прямий удар!"
	},
	"hopak_kick": {
		"title": "КОЗАЦЬКИЙ УДАР НОГОЮ (ТИНОК / ЩУПАК)",
		"hint": "УДАР НОГОЮ (ГОПАК): Клавіатура [C / K / Z] або Геймпад [B / Y / LB] — удар чоботом «Тинок» і «Щупак»!"
	},
	"air_slam_combo": {
		"title": "УДАР СОКОЛА В СТРИБКУ",
		"hint": "КОМБО В ПОВІТРІ: у стрибку [Пробіл + X/C] або Геймпад [Стрибок A -> X / B] — удар з неба!"
	},
	"roll_strike_combo": {
		"title": "КОЗАЦЬКИЙ ПОВЗУНЕЦЬ З УДАРОМ",
		"hint": "КОМБО «ПОВЗУНЕЦЬ»: затисни [Вниз + X/C] або Геймпад [Стік вниз + X / B] — перекат і підсічка!"
	},
	"steelhammer_jab": {
		"title": "СТАЛЕВИЙ ДЖЕБ ВОЛОДИМИРА КЛИЧКА",
		"hint": "СУПЕРУДАР (В. КЛИЧКО): Клавіатура [X / J] або Геймпад [X / RB] — далекобійний «Сталевий Джеб»!"
	},
	"ironfist_hook": {
		"title": "ЗАЛІЗНИЙ ОВЕРХЕНД ВІТАЛІЯ КЛИЧКА",
		"hint": "КОМБО (ВІТАЛІЙ КЛИЧКО): у стрибку [Вниз + X] або Геймпад [Стрибок A + X] — «Залізний Оверхенд»!"
	},
	"usyk_slip_counter": {
		"title": "ЧОВНИК ТА КОНТРАТАКА ОЛЕКСАНДРА УСИКА",
		"hint": "КОМБО (О. УСИК): [Вниз + Вбік + X] або Геймпад [Стік вниз + X] — «Човник Усика»!"
	},
	"undisputed_trio": {
		"title": "АБСОЛЮТНА СЕРІЯ ТРЬОХ ЧЕМПІОНІВ",
		"hint": "СУПЕР-КОМБО ЧЕМПІОНІВ: Клавіатура [X / J] або Геймпад [X / RB] — «Золота Хвиля Тризуба»!"
	}
}

var pending_combat_moves: Array[String] = ["basic_strike", "hopak_kick", "air_slam_combo", "roll_strike_combo"]
var completed_combat_moves: Dictionary = {}

var snd_bomb_regular = preload("res://assets/audio/bomb_regular.wav")
var snd_bomb_lit = preload("res://assets/audio/bomb_lit.wav")
var snd_level_clear = preload("res://assets/audio/level_clear.wav")
var snd_hopak_music = preload("res://assets/audio/hopak_music.wav")
var snd_poof = preload("res://assets/audio/chort_poof.wav")

func _ready() -> void:
	telemetry_engine = _TelemetryEngine.new()
	telemetry_engine.name = "TelemetryEngine"
	add_child(telemetry_engine)
	telemetry_engine.mamay_tip_ready.connect(_on_mamay_tip_ready)
	if hud:
		hud.update_score(score)
		hud.update_highscore(high_score)
		hud.profile_changed.connect(set_player_profile)
	if player:
		player.vakula_shoes_state_changed.connect(_on_vakula_shoes_state_changed)
		player.combat_move_performed.connect(_on_player_combat_move_performed)
	player.reset_to_normal_state(Vector2(480, 494))
	_setup_audio()
	_init_adaptation()
	_setup_level()
	_refresh_bottom_combat_hint()
	if story_cards and story_cards.has_story_for_level(level):
		story_cards.show_story_for_level(level)
		await story_cards.story_finished
	hud.announce_level(level, 2.4)

func _process(delta: float) -> void:
	if telemetry_engine and not is_transitioning_level:
		telemetry_engine.sample_frame(delta, player, enemies_node)

func _on_mamay_tip_ready(mamay_tip: String) -> void:
	if mamay_tip.length() > 0 and hud and not is_transitioning_level:
		hud.show_message("КОЗАК МАМАЙ: «%s»" % mamay_tip, 3.6, Color(0.45, 0.96, 1.0))

func _refresh_bottom_combat_hint() -> void:
	if not hud:
		return
	if pending_combat_moves.is_empty():
		hud.show_persistent_combat_hint("")
		return
	var current_id: String = pending_combat_moves[0]
	var info: Dictionary = COMBAT_HINTS.get(current_id, {})
	hud.show_persistent_combat_hint(info.get("hint", ""))

func _queue_combat_hint_front(move_id: String) -> void:
	if completed_combat_moves.get(move_id, false):
		return
	pending_combat_moves.erase(move_id)
	pending_combat_moves.push_front(move_id)
	_refresh_bottom_combat_hint()

func _on_player_combat_move_performed(move_id: String) -> void:
	if telemetry_engine:
		if move_id == "hopak_kick":
			telemetry_engine.record_kick()
		else:
			telemetry_engine.record_punch()
	if not pending_combat_moves.has(move_id):
		return
	completed_combat_moves[move_id] = true
	var was_current_front := (pending_combat_moves[0] == move_id)
	pending_combat_moves.erase(move_id)
	if was_current_front and hud:
		var info: Dictionary = COMBAT_HINTS.get(move_id, {})
		var title: String = info.get("title", move_id)
		var next_hint: String = ""
		if not pending_combat_moves.is_empty():
			var next_info: Dictionary = COMBAT_HINTS.get(pending_combat_moves[0], {})
			next_hint = next_info.get("hint", "")
		hud.complete_combat_hint(title, next_hint)

func _setup_audio() -> void:
	if bgm_player and not bgm_player.playing:
		bgm_player.play()

func _play_sfx(stream: AudioStream, pitch_scale: float = 1.0) -> void:
	var sfx = AudioStreamPlayer.new()
	sfx.bus = "Master"
	sfx.stream = stream
	sfx.pitch_scale = pitch_scale
	sfx.finished.connect(sfx.queue_free)
	add_child(sfx)
	sfx.play()

func _play_sfx_at(stream: AudioStream, pos: Vector2, pitch_scale: float = 1.0) -> void:
	var sfx := AudioStreamPlayer2D.new()
	sfx.bus = "Master"
	sfx.position = pos
	sfx.stream = stream
	sfx.pitch_scale = pitch_scale
	sfx.max_distance = 1500.0
	sfx.attenuation = 0.3
	sfx.finished.connect(sfx.queue_free)
	add_child(sfx)
	sfx.play()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen") or (event is InputEventKey and event.pressed and event.keycode == KEY_F11):
		_toggle_fullscreen()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

const LEVEL_PLATFORMS: Dictionary = {
	1: [ # СІЧ НА ХОРТИЦІ (960x540 2K 16:9: просторі дубові помости, легкий підйом)
		{"pos": Vector2(480, 425), "width": 260.0},
		{"pos": Vector2(180, 350), "width": 180.0},
		{"pos": Vector2(780, 350), "width": 180.0},
		{"pos": Vector2(480, 275), "width": 240.0},
		{"pos": Vector2(210, 195), "width": 190.0},
		{"pos": Vector2(750, 195), "width": 190.0},
		{"pos": Vector2(480, 125), "width": 280.0}
	],
	2: [ # СТЕПОВИЙ ХУТІР (960x540 2K 16:9: стріхи, вітряк, міст через яр)
		{"pos": Vector2(200, 430), "width": 200.0},
		{"pos": Vector2(760, 420), "width": 200.0},
		{"pos": Vector2(480, 340), "width": 180.0},
		{"pos": Vector2(170, 250), "width": 160.0},
		{"pos": Vector2(790, 250), "width": 160.0},
		{"pos": Vector2(480, 175), "width": 220.0},
		{"pos": Vector2(220, 115), "width": 160.0},
		{"pos": Vector2(740, 115), "width": 160.0}
	],
	3: [ # КАМ'ЯНЕЦЬКА ТВЕРДИНЯ (960x540 2K 16:9: кам'яні мури, башти над каньйоном)
		{"pos": Vector2(480, 125), "width": 260.0},
		{"pos": Vector2(210, 195), "width": 180.0},
		{"pos": Vector2(750, 195), "width": 180.0},
		{"pos": Vector2(480, 275), "width": 240.0},
		{"pos": Vector2(180, 355), "width": 180.0},
		{"pos": Vector2(780, 355), "width": 180.0},
		{"pos": Vector2(340, 435), "width": 180.0},
		{"pos": Vector2(620, 435), "width": 180.0}
	],
	4: [ # ГЕТЬМАНСЬКИЙ БАТУРИН (960x540: барокові палаци, скарбниця, колонади)
		{"pos": Vector2(480, 135), "width": 260.0},
		{"pos": Vector2(190, 205), "width": 180.0},
		{"pos": Vector2(770, 205), "width": 180.0},
		{"pos": Vector2(480, 280), "width": 250.0},
		{"pos": Vector2(210, 360), "width": 180.0},
		{"pos": Vector2(750, 360), "width": 180.0},
		{"pos": Vector2(480, 435), "width": 280.0}
	],
	5: [ # ПЕРЕКОПСЬКИЙ ВАЛ — БРАМА ОР-КАПУ (960x540: вапняковий мур Ор-Капу, кримська брама)
		{"pos": Vector2(480, 120), "width": 280.0},
		{"pos": Vector2(200, 190), "width": 170.0},
		{"pos": Vector2(760, 190), "width": 170.0},
		{"pos": Vector2(480, 265), "width": 240.0},
		{"pos": Vector2(170, 350), "width": 160.0},
		{"pos": Vector2(790, 350), "width": 160.0},
		{"pos": Vector2(340, 435), "width": 190.0},
		{"pos": Vector2(620, 435), "width": 190.0}
	],
	6: [ # ХАНСЬКИЙ БАХЧИСАРАЙ ТА СКЕЛІ ЧУФУТ-КАЛЕ (тераси палацу й мінарети)
		{"pos": Vector2(480, 430), "width": 240.0},
		{"pos": Vector2(190, 355), "width": 180.0},
		{"pos": Vector2(770, 355), "width": 180.0},
		{"pos": Vector2(480, 280), "width": 220.0},
		{"pos": Vector2(220, 200), "width": 180.0},
		{"pos": Vector2(740, 200), "width": 180.0},
		{"pos": Vector2(480, 125), "width": 260.0}
	],
	7: [ # КОНОТОПСЬКА ПЕРЕПРАВА (мостові настили й греблі через річку Соснівку)
		{"pos": Vector2(205, 428), "width": 205.0},
		{"pos": Vector2(755, 422), "width": 205.0},
		{"pos": Vector2(480, 342), "width": 185.0},
		{"pos": Vector2(165, 252), "width": 165.0},
		{"pos": Vector2(795, 252), "width": 165.0},
		{"pos": Vector2(480, 178), "width": 225.0},
		{"pos": Vector2(225, 118), "width": 160.0},
		{"pos": Vector2(735, 118), "width": 160.0}
	],
	8: [ # СТАРОДАВНІЙ ПОЛОЦЬК І ПУЩА (вежі замку ВКЛ та соснові помости)
		{"pos": Vector2(330, 435), "width": 180.0},
		{"pos": Vector2(630, 435), "width": 180.0},
		{"pos": Vector2(175, 355), "width": 175.0},
		{"pos": Vector2(785, 355), "width": 175.0},
		{"pos": Vector2(480, 275), "width": 230.0},
		{"pos": Vector2(205, 195), "width": 175.0},
		{"pos": Vector2(755, 195), "width": 175.0},
		{"pos": Vector2(480, 122), "width": 250.0}
	],
	9: [ # ЧОРНОГОРА — СКЕЛІ ДОВБУША (гірські карпатські плаї та скельні полиці)
		{"pos": Vector2(480, 432), "width": 270.0},
		{"pos": Vector2(200, 358), "width": 175.0},
		{"pos": Vector2(760, 358), "width": 175.0},
		{"pos": Vector2(480, 282), "width": 240.0},
		{"pos": Vector2(185, 202), "width": 175.0},
		{"pos": Vector2(775, 202), "width": 175.0},
		{"pos": Vector2(480, 130), "width": 250.0}
	],
	10: [ # ЗОЛОТІ ВОРОТА КИЄВА (оборонні яруси та золочені склепіння)
		{"pos": Vector2(345, 435), "width": 185.0},
		{"pos": Vector2(615, 435), "width": 185.0},
		{"pos": Vector2(175, 352), "width": 165.0},
		{"pos": Vector2(785, 352), "width": 165.0},
		{"pos": Vector2(480, 268), "width": 235.0},
		{"pos": Vector2(205, 192), "width": 175.0},
		{"pos": Vector2(755, 192), "width": 175.0},
		{"pos": Vector2(480, 120), "width": 270.0}
	],
	11: [ # ОЛЕШКІВСЬКА СІЧ У ДНІПРОВСЬКИХ ПЛАВНЯХ (козацькі чайки та очеретяні кладки)
		{"pos": Vector2(480, 428), "width": 250.0},
		{"pos": Vector2(185, 352), "width": 185.0},
		{"pos": Vector2(775, 352), "width": 185.0},
		{"pos": Vector2(480, 276), "width": 235.0},
		{"pos": Vector2(215, 198), "width": 185.0},
		{"pos": Vector2(745, 198), "width": 185.0},
		{"pos": Vector2(480, 126), "width": 270.0}
	],
	12: [ # ЗАМКОВА ГОРА І ТРОКИ (озерні мости й червоні цегляні вежі Литви)
		{"pos": Vector2(205, 428), "width": 195.0},
		{"pos": Vector2(755, 422), "width": 195.0},
		{"pos": Vector2(480, 342), "width": 185.0},
		{"pos": Vector2(175, 252), "width": 165.0},
		{"pos": Vector2(785, 252), "width": 165.0},
		{"pos": Vector2(480, 176), "width": 225.0},
		{"pos": Vector2(225, 116), "width": 160.0},
		{"pos": Vector2(735, 116), "width": 160.0}
	],
	13: [ # ХОЛОДНИЙ ЯР — ДУБ МАКСИМА ЗАЛІЗНЯКА (яруси лісових схилів та гілля тисячолітнього дуба)
		{"pos": Vector2(335, 435), "width": 185.0},
		{"pos": Vector2(625, 435), "width": 185.0},
		{"pos": Vector2(180, 355), "width": 180.0},
		{"pos": Vector2(780, 355), "width": 180.0},
		{"pos": Vector2(480, 275), "width": 245.0},
		{"pos": Vector2(210, 195), "width": 180.0},
		{"pos": Vector2(750, 195), "width": 180.0},
		{"pos": Vector2(480, 125), "width": 265.0}
	],
	14: [ # АККЕРМАНСЬКА ФОРТЕЦЯ НАД ЛИМАНОМ (білокам'яні зубці й вежа Овідія)
		{"pos": Vector2(480, 434), "width": 275.0},
		{"pos": Vector2(205, 360), "width": 180.0},
		{"pos": Vector2(755, 360), "width": 180.0},
		{"pos": Vector2(480, 280), "width": 245.0},
		{"pos": Vector2(190, 204), "width": 180.0},
		{"pos": Vector2(770, 204), "width": 180.0},
		{"pos": Vector2(480, 134), "width": 255.0}
	],
	15: [ # ПІДЗЕМЕЛЛЯ ХОТИНСЬКОЇ ФОРТЕЦІ (кам'яні склепіння та високі галереї)
		{"pos": Vector2(340, 435), "width": 190.0},
		{"pos": Vector2(620, 435), "width": 190.0},
		{"pos": Vector2(170, 350), "width": 165.0},
		{"pos": Vector2(790, 350), "width": 165.0},
		{"pos": Vector2(480, 265), "width": 240.0},
		{"pos": Vector2(200, 190), "width": 170.0},
		{"pos": Vector2(760, 190), "width": 170.0},
		{"pos": Vector2(480, 120), "width": 280.0}
	],
	16: [ # ЗАДУНАЙСЬКА СІЧ ТА ДУНАЙСЬКІ ГИРЛА (причали чайок і сторожові каланчі)
		{"pos": Vector2(480, 426), "width": 255.0},
		{"pos": Vector2(180, 350), "width": 180.0},
		{"pos": Vector2(780, 350), "width": 180.0},
		{"pos": Vector2(480, 275), "width": 240.0},
		{"pos": Vector2(210, 195), "width": 190.0},
		{"pos": Vector2(750, 195), "width": 190.0},
		{"pos": Vector2(480, 125), "width": 275.0}
	],
	17: [ # БІЛОРУСЬКА ПУЩА КАСТУСЯ КАЛИНОВСЬКОГО (партизанські засеки й лісові вежі)
		{"pos": Vector2(200, 430), "width": 200.0},
		{"pos": Vector2(760, 420), "width": 200.0},
		{"pos": Vector2(480, 340), "width": 185.0},
		{"pos": Vector2(170, 250), "width": 160.0},
		{"pos": Vector2(790, 250), "width": 160.0},
		{"pos": Vector2(480, 175), "width": 220.0},
		{"pos": Vector2(220, 115), "width": 160.0},
		{"pos": Vector2(740, 115), "width": 160.0}
	],
	18: [ # ВЕРХОВИНА Й ПИСАНИЙ КАМІНЬ (полонини, смерекові мости й скелі мольфарів)
		{"pos": Vector2(340, 435), "width": 180.0},
		{"pos": Vector2(620, 435), "width": 180.0},
		{"pos": Vector2(180, 355), "width": 180.0},
		{"pos": Vector2(780, 355), "width": 180.0},
		{"pos": Vector2(480, 275), "width": 240.0},
		{"pos": Vector2(210, 195), "width": 180.0},
		{"pos": Vector2(750, 195), "width": 180.0},
		{"pos": Vector2(480, 125), "width": 260.0}
	],
	19: [ # ГЕЗЛЬОВ (ЄВПАТОРІЯ) ТА ХАН-ДЖАМІ (морські бастіони й куполи Джума-Джамі)
		{"pos": Vector2(480, 435), "width": 280.0},
		{"pos": Vector2(210, 360), "width": 180.0},
		{"pos": Vector2(750, 360), "width": 180.0},
		{"pos": Vector2(480, 280), "width": 250.0},
		{"pos": Vector2(190, 205), "width": 180.0},
		{"pos": Vector2(770, 205), "width": 180.0},
		{"pos": Vector2(480, 135), "width": 260.0}
	],
	20: [ # ТАРАСОВА ГОРА У КАНЕВІ — ВЕЛИКИЙ СОБОР НАРОДІВ (дніпровські кручі та арка свободи)
		{"pos": Vector2(340, 435), "width": 190.0},
		{"pos": Vector2(620, 435), "width": 190.0},
		{"pos": Vector2(170, 350), "width": 160.0},
		{"pos": Vector2(790, 350), "width": 160.0},
		{"pos": Vector2(480, 265), "width": 240.0},
		{"pos": Vector2(200, 190), "width": 170.0},
		{"pos": Vector2(760, 190), "width": 170.0},
		{"pos": Vector2(480, 120), "width": 280.0}
	]
}

const LEVEL_BOMBS: Dictionary = {
	1: [
		# Січ: 24 ядра по широкій 16:9 фортеці (ергономічна висота, легкий доступ)
		Vector2(440, 90), Vector2(480, 85), Vector2(520, 90),
		Vector2(150, 155), Vector2(210, 150), Vector2(270, 155),
		Vector2(690, 155), Vector2(750, 150), Vector2(810, 155),
		Vector2(410, 235), Vector2(480, 230), Vector2(550, 235),
		Vector2(120, 310), Vector2(180, 310), Vector2(240, 310),
		Vector2(720, 310), Vector2(780, 310), Vector2(840, 310),
		Vector2(410, 385), Vector2(480, 380), Vector2(550, 385),
		Vector2(100, 480), Vector2(480, 475), Vector2(860, 480)
	],
	2: [
		# Хутір: Сяюча дуга Чумацького Шляху через усе 16:9 небо та ядра над хутором
		Vector2(100, 70), Vector2(220, 60), Vector2(350, 75), Vector2(480, 95), Vector2(610, 75), Vector2(740, 60), Vector2(860, 70),
		Vector2(400, 140), Vector2(480, 135), Vector2(560, 140),
		Vector2(120, 210), Vector2(170, 210), Vector2(220, 210),
		Vector2(740, 210), Vector2(790, 210), Vector2(840, 210),
		Vector2(420, 300), Vector2(480, 295), Vector2(540, 300),
		Vector2(150, 390), Vector2(200, 390), Vector2(250, 390),
		Vector2(710, 380), Vector2(760, 380), Vector2(810, 380)
	],
	3: [
		# Кам'янець: 24 ядра по бастіонах, баштах та каньйону
		Vector2(440, 90), Vector2(480, 85), Vector2(520, 90),
		Vector2(160, 155), Vector2(210, 150), Vector2(260, 155),
		Vector2(700, 155), Vector2(750, 150), Vector2(800, 155),
		Vector2(420, 235), Vector2(480, 230), Vector2(540, 235),
		Vector2(130, 315), Vector2(180, 310), Vector2(230, 315),
		Vector2(730, 315), Vector2(780, 310), Vector2(830, 315),
		Vector2(340, 395), Vector2(480, 390), Vector2(620, 395),
		Vector2(120, 480), Vector2(480, 475), Vector2(840, 480)
	],
	4: [
		# Батурин: 24 ядра по гетьманських палацах, скарбниці та барокових арках
		Vector2(440, 100), Vector2(480, 95), Vector2(520, 100),
		Vector2(150, 165), Vector2(190, 160), Vector2(230, 165),
		Vector2(730, 165), Vector2(770, 160), Vector2(810, 165),
		Vector2(420, 240), Vector2(480, 235), Vector2(540, 240),
		Vector2(160, 320), Vector2(210, 315), Vector2(260, 320),
		Vector2(700, 320), Vector2(750, 315), Vector2(800, 320),
		Vector2(410, 395), Vector2(480, 390), Vector2(550, 395),
		Vector2(130, 480), Vector2(480, 475), Vector2(830, 480)
	],
	5: [
		# Перекопський Вал (Ор-Капу): 24 ядра по валу та кримських бастіонах
		Vector2(440, 85), Vector2(480, 80), Vector2(520, 85),
		Vector2(150, 150), Vector2(200, 145), Vector2(250, 150),
		Vector2(710, 150), Vector2(760, 145), Vector2(810, 150),
		Vector2(420, 225), Vector2(480, 220), Vector2(540, 225),
		Vector2(120, 310), Vector2(170, 305), Vector2(220, 310),
		Vector2(740, 310), Vector2(790, 305), Vector2(840, 310),
		Vector2(340, 395), Vector2(480, 390), Vector2(620, 395),
		Vector2(110, 480), Vector2(480, 475), Vector2(850, 480)
	],
	6: [
		Vector2(430, 88), Vector2(480, 82), Vector2(530, 88),
		Vector2(160, 160), Vector2(220, 155), Vector2(280, 160),
		Vector2(680, 160), Vector2(740, 155), Vector2(800, 160),
		Vector2(415, 240), Vector2(480, 235), Vector2(545, 240),
		Vector2(130, 315), Vector2(190, 312), Vector2(250, 315),
		Vector2(710, 315), Vector2(770, 312), Vector2(830, 315),
		Vector2(415, 390), Vector2(480, 385), Vector2(545, 390),
		Vector2(120, 480), Vector2(480, 475), Vector2(840, 480)
	],
	7: [
		Vector2(170, 78), Vector2(230, 74), Vector2(290, 78),
		Vector2(670, 78), Vector2(730, 74), Vector2(790, 78),
		Vector2(410, 140), Vector2(480, 136), Vector2(550, 140),
		Vector2(130, 215), Vector2(180, 210), Vector2(230, 215),
		Vector2(730, 215), Vector2(780, 210), Vector2(830, 215),
		Vector2(420, 305), Vector2(480, 300), Vector2(540, 305),
		Vector2(160, 385), Vector2(210, 385), Vector2(260, 385),
		Vector2(700, 385), Vector2(750, 385), Vector2(800, 385)
	],
	8: [
		Vector2(435, 86), Vector2(480, 82), Vector2(525, 86),
		Vector2(155, 155), Vector2(205, 150), Vector2(255, 155),
		Vector2(705, 155), Vector2(755, 150), Vector2(805, 155),
		Vector2(420, 235), Vector2(480, 230), Vector2(540, 235),
		Vector2(125, 315), Vector2(175, 310), Vector2(225, 315),
		Vector2(735, 315), Vector2(785, 310), Vector2(835, 315),
		Vector2(330, 395), Vector2(480, 390), Vector2(630, 395),
		Vector2(130, 480), Vector2(480, 475), Vector2(830, 480)
	],
	9: [
		Vector2(435, 92), Vector2(480, 88), Vector2(525, 92),
		Vector2(145, 162), Vector2(185, 158), Vector2(225, 162),
		Vector2(735, 162), Vector2(775, 158), Vector2(815, 162),
		Vector2(420, 242), Vector2(480, 236), Vector2(540, 242),
		Vector2(155, 318), Vector2(200, 314), Vector2(245, 318),
		Vector2(715, 318), Vector2(760, 314), Vector2(805, 318),
		Vector2(410, 392), Vector2(480, 388), Vector2(550, 392),
		Vector2(140, 480), Vector2(480, 475), Vector2(820, 480)
	],
	10: [
		Vector2(440, 85), Vector2(480, 80), Vector2(520, 85),
		Vector2(155, 152), Vector2(205, 148), Vector2(255, 152),
		Vector2(705, 152), Vector2(755, 148), Vector2(805, 152),
		Vector2(420, 228), Vector2(480, 222), Vector2(540, 228),
		Vector2(125, 312), Vector2(175, 306), Vector2(225, 312),
		Vector2(735, 312), Vector2(785, 306), Vector2(835, 312),
		Vector2(345, 395), Vector2(480, 390), Vector2(615, 395),
		Vector2(115, 480), Vector2(480, 475), Vector2(845, 480)
	],
	11: [
		Vector2(440, 88), Vector2(480, 84), Vector2(520, 88),
		Vector2(155, 158), Vector2(215, 152), Vector2(275, 158),
		Vector2(685, 158), Vector2(745, 152), Vector2(805, 158),
		Vector2(415, 236), Vector2(480, 230), Vector2(545, 236),
		Vector2(125, 312), Vector2(185, 310), Vector2(245, 312),
		Vector2(715, 312), Vector2(775, 310), Vector2(835, 312),
		Vector2(410, 388), Vector2(480, 382), Vector2(550, 388),
		Vector2(110, 480), Vector2(480, 475), Vector2(850, 480)
	],
	12: [
		Vector2(175, 76), Vector2(225, 72), Vector2(275, 76),
		Vector2(685, 76), Vector2(735, 72), Vector2(785, 76),
		Vector2(405, 138), Vector2(480, 134), Vector2(555, 138),
		Vector2(125, 212), Vector2(175, 210), Vector2(225, 212),
		Vector2(735, 212), Vector2(785, 210), Vector2(835, 212),
		Vector2(420, 302), Vector2(480, 296), Vector2(540, 302),
		Vector2(155, 388), Vector2(205, 388), Vector2(255, 388),
		Vector2(705, 382), Vector2(755, 382), Vector2(805, 382)
	],
	13: [
		Vector2(440, 90), Vector2(480, 85), Vector2(520, 90),
		Vector2(160, 155), Vector2(210, 150), Vector2(260, 155),
		Vector2(700, 155), Vector2(750, 150), Vector2(800, 155),
		Vector2(420, 235), Vector2(480, 230), Vector2(540, 235),
		Vector2(130, 315), Vector2(180, 310), Vector2(230, 315),
		Vector2(730, 315), Vector2(780, 310), Vector2(830, 315),
		Vector2(335, 395), Vector2(480, 390), Vector2(625, 395),
		Vector2(125, 480), Vector2(480, 475), Vector2(835, 480)
	],
	14: [
		Vector2(440, 98), Vector2(480, 94), Vector2(520, 98),
		Vector2(150, 164), Vector2(190, 160), Vector2(230, 164),
		Vector2(730, 164), Vector2(770, 160), Vector2(810, 164),
		Vector2(420, 240), Vector2(480, 235), Vector2(540, 240),
		Vector2(160, 320), Vector2(205, 315), Vector2(250, 320),
		Vector2(710, 320), Vector2(755, 315), Vector2(800, 320),
		Vector2(410, 394), Vector2(480, 390), Vector2(550, 394),
		Vector2(135, 480), Vector2(480, 475), Vector2(825, 480)
	],
	15: [
		Vector2(440, 85), Vector2(480, 80), Vector2(520, 85),
		Vector2(150, 150), Vector2(200, 145), Vector2(250, 150),
		Vector2(710, 150), Vector2(760, 145), Vector2(810, 150),
		Vector2(420, 225), Vector2(480, 220), Vector2(540, 225),
		Vector2(120, 310), Vector2(170, 305), Vector2(220, 310),
		Vector2(740, 310), Vector2(790, 305), Vector2(840, 310),
		Vector2(340, 395), Vector2(480, 390), Vector2(620, 395),
		Vector2(115, 480), Vector2(480, 475), Vector2(845, 480)
	],
	16: [
		Vector2(435, 90), Vector2(480, 85), Vector2(525, 90),
		Vector2(150, 155), Vector2(210, 150), Vector2(270, 155),
		Vector2(690, 155), Vector2(750, 150), Vector2(810, 155),
		Vector2(410, 235), Vector2(480, 230), Vector2(550, 235),
		Vector2(120, 310), Vector2(180, 310), Vector2(240, 310),
		Vector2(720, 310), Vector2(780, 310), Vector2(840, 310),
		Vector2(410, 385), Vector2(480, 380), Vector2(550, 385),
		Vector2(105, 480), Vector2(480, 475), Vector2(855, 480)
	],
	17: [
		Vector2(105, 70), Vector2(220, 60), Vector2(350, 75), Vector2(480, 95), Vector2(610, 75), Vector2(740, 60), Vector2(855, 70),
		Vector2(400, 140), Vector2(480, 135), Vector2(560, 140),
		Vector2(120, 210), Vector2(170, 210), Vector2(220, 210),
		Vector2(740, 210), Vector2(790, 210), Vector2(840, 210),
		Vector2(420, 300), Vector2(480, 295), Vector2(540, 300),
		Vector2(150, 390), Vector2(200, 390), Vector2(250, 390),
		Vector2(710, 380), Vector2(760, 380), Vector2(810, 380)
	],
	18: [
		Vector2(440, 90), Vector2(480, 85), Vector2(520, 90),
		Vector2(160, 155), Vector2(210, 150), Vector2(260, 155),
		Vector2(700, 155), Vector2(750, 150), Vector2(800, 155),
		Vector2(420, 235), Vector2(480, 230), Vector2(540, 235),
		Vector2(130, 315), Vector2(180, 310), Vector2(230, 315),
		Vector2(730, 315), Vector2(780, 310), Vector2(830, 315),
		Vector2(340, 395), Vector2(480, 390), Vector2(620, 395),
		Vector2(120, 480), Vector2(480, 475), Vector2(840, 480)
	],
	19: [
		Vector2(440, 100), Vector2(480, 95), Vector2(520, 100),
		Vector2(150, 165), Vector2(190, 160), Vector2(230, 165),
		Vector2(730, 165), Vector2(770, 160), Vector2(810, 165),
		Vector2(420, 240), Vector2(480, 235), Vector2(540, 240),
		Vector2(160, 320), Vector2(210, 315), Vector2(260, 320),
		Vector2(700, 320), Vector2(750, 315), Vector2(800, 320),
		Vector2(410, 395), Vector2(480, 390), Vector2(550, 395),
		Vector2(130, 480), Vector2(480, 475), Vector2(830, 480)
	],
	20: [
		Vector2(440, 85), Vector2(480, 80), Vector2(520, 85),
		Vector2(150, 150), Vector2(200, 145), Vector2(250, 150),
		Vector2(710, 150), Vector2(760, 145), Vector2(810, 150),
		Vector2(420, 225), Vector2(480, 220), Vector2(540, 225),
		Vector2(120, 310), Vector2(170, 305), Vector2(220, 310),
		Vector2(740, 310), Vector2(790, 305), Vector2(840, 310),
		Vector2(340, 395), Vector2(480, 390), Vector2(620, 395),
		Vector2(110, 480), Vector2(480, 475), Vector2(850, 480)
	]
}

func _setup_level() -> void:
	if background_visual:
		background_visual.current_level = level
	
	_setup_platforms_for_level()
	
	# Clear existing bombs if any
	for child in bombs_node.get_children():
		bombs_node.remove_child(child)
		child.queue_free()
	
	# Clear existing enemies and magical items
	if enemies_node:
		for child in enemies_node.get_children():
			enemies_node.remove_child(child)
			child.queue_free()
	if items_node:
		for child in items_node.get_children():
			items_node.remove_child(child)
			child.queue_free()
	
	# Clear previous allies if any
	if qirimli_ally and is_instance_valid(qirimli_ally):
		qirimli_ally.queue_free()
		qirimli_ally = null
	for h in hutsul_allies:
		if h and is_instance_valid(h):
			h.queue_free()
	hutsul_allies.clear()
	if hutsul_ally and is_instance_valid(hutsul_ally):
		hutsul_ally.queue_free()
	hutsul_ally = null
	
	if mavka_ally and is_instance_valid(mavka_ally):
		mavka_ally.queue_free()
	mavka_ally = null
	mavka_spawned_this_level = false
	var stage_in_series := ((level - 1) % _Difficulty.SERIES_LENGTH) + 1
	level_offset = _LevelDifficulty.offset(stage_in_series)
	if adaptive_enabled and player_model != null:
		difficulty_k = player_model.recommend(level, level_offset)
	else:
		difficulty_k = _Difficulty.coefficient(level, prev_quality)
	level_started_ms = Time.get_ticks_msec()
	if telemetry_engine:
		telemetry_engine.begin_level_tracking(level)
	hits_this_level = 0
	max_lit_streak_level = 1
	bombs_collected_on_level = 0
	hutsul_spawned_this_level = false
	hutsul_waves_spawned = 0
	qirimli_spawned_this_level = false
	
	# Союзні NPC (Гуцули і Киримли) прибувають прогресивно по мірі перших успіхів Джури
	# та пропорційно до кількості ворожих NPC для балансу сил (_check_progressive_ally_arrival)!
	
	# Spawn folklore enemies according to level theme & age 8+ clarity
	_spawn_folklore_enemies()
	level_enemy_count_start = enemies_node.get_child_count() if enemies_node else 0
	level_in_progress = true
	if telemetry != null:
		telemetry.log_event("level_start", {"level": level, "k": difficulty_k, "enemies": level_enemy_count_start, "target": player_model.target_success() if player_model != null else 0.0})
	
	lit_streak = 1
	_spawn_bomb_grid()
	
	# Friendly folklore lore tips for players
	_show_level_lore_tip()
	
	# Guaranteed Horseshoe gift from Blacksmith Vakula on all levels after 3.2s
	get_tree().create_timer(3.2).timeout.connect(func():
		if not is_transitioning_level and items_node and items_node.get_children().is_empty() and player and not player.has_vakula_shoes:
			_spawn_vakula_horseshoe()
	)
	
	# Light up first bomb after a short delay
	await get_tree().create_timer(0.3).timeout
	_light_next_bomb()

func _check_progressive_ally_arrival() -> void:
	var enemy_count := enemies_node.get_child_count() if enemies_node else 0
	
	# 1. Перший Карпатський Гуцул з барткою прибуває після перших успіхів Джури (2+ ядра або комбо >= 2)
	if not hutsul_spawned_this_level and enemy_count >= 1 and _Difficulty.ally_available("HUTSUL", level):
		if bombs_collected_on_level >= _Difficulty.ally_threshold(2, difficulty_k, prev_quality) or lit_streak >= 2:
			_spawn_hutsul_ally()
			hud.show_message("ПІДМОГА З КАРПАТ! ГУЦУЛ З БАРТКОЮ ВСТУПАЄ В БІЙ!", 2.8, Color(1.0, 0.86, 0.25))
	
	# 2. Другий Гуцул прибуває лише на старших рівнях (рівні 3..5, коли ворогів багато) після 6+ ядер (на 30% менше союзників!)
	if hutsul_waves_spawned == 1 and level >= 3 and enemy_count >= 3 and bombs_collected_on_level >= 6:
		hutsul_waves_spawned = 2
		_spawn_single_hutsul(Vector2(760, 220), -1.0)
		hud.show_message("ЩЕ ОДИН ГУЦУЛ-ОПРИШОК ПРИБУВ З ЧОРНОГОРИ НА ПІДМОГУ!", 2.4, Color(1.0, 0.88, 0.30))
	
	# 3. Побратим Киримли з Луком і Соколом прибуває далі по ходу прогресу (4+ ядра або комбо >= 3, рівні 3..5)
	if not qirimli_spawned_this_level and _Difficulty.ally_available("QIRIMLI", level) and enemy_count >= 3:
		if bombs_collected_on_level >= _Difficulty.ally_threshold(4, difficulty_k, prev_quality) or lit_streak >= 3:
			_spawn_qirimli_ally()
			hud.show_message("ПІДМОГА КИРИМЛИ! СТЕПОВИЙ ЛУЧНИК І СОКІЛ ПРИКРИВАЮТЬ ДЖУРУ!", 3.0, Color(0.28, 1.0, 0.56))
	
	# 4. Третій гуцул лише за високої складності (серії 2+ або дуже якісне проходження)
	if hutsul_waves_spawned == 2 and _Difficulty.allows_third_hutsul(difficulty_k) and enemy_count >= 4 and bombs_collected_on_level >= 9:
		hutsul_waves_spawned = 3
		_spawn_single_hutsul(Vector2(200, 220), 1.0)
		hud.show_message("ГУЦУЛИ ПРИВЕЛИ ЩЕ ОДНОГО ОПРИШКА!", 2.4, Color(1.0, 0.88, 0.30))
	
	# 5. Мавка (новий союзник рівня 5): лісова чарівниця лякає ворогів чарами
	if not mavka_spawned_this_level and _Difficulty.ally_available("MAVKA", level) and enemy_count >= 3:
		if bombs_collected_on_level >= _Difficulty.ally_threshold(3, difficulty_k, prev_quality):
			_spawn_mavka_ally()
			hud.show_message("МАВКА ПРИЙШЛА НА ДОПОМОГУ! ЇЇ ЧАРИ ЛЯКАЮТЬ ВОРОГІВ!", 3.0, Color(0.6, 1.0, 0.85))

func _spawn_mavka_ally() -> void:
	if mavka_spawned_this_level:
		return
	mavka_spawned_this_level = true
	var m: Node2D = _MavkaAlly.new()
	if level == 15:
		m.ally_kind = "DOMOVYK"
	elif level == 16:
		m.ally_kind = "KOBZAR"
	elif level == 17:
		m.ally_kind = "VAKULA"
	m.position = Vector2(140, 150)
	cast_node.add_child(m)
	mavka_ally = m

func _spawn_hutsul_ally() -> void:
	if hutsul_spawned_this_level:
		return
	hutsul_spawned_this_level = true
	hutsul_waves_spawned = 1
	
	var pos_left := Vector2(190, 185)
	if level == 2:
		pos_left = Vector2(180, 220)
	elif level == 3:
		pos_left = Vector2(200, 170)
	elif level == 4:
		pos_left = Vector2(200, 330)
	elif level >= 5:
		pos_left = Vector2(200, 165)
	
	var first_hutsul := _spawn_single_hutsul(pos_left, 1.0)
	hutsul_ally = first_hutsul

func _spawn_single_hutsul(spawn_pos: Vector2, initial_dir: float = 1.0) -> Node2D:
	var ally = hutsul_scene.instantiate()
	ally.position = spawn_pos
	ally.facing_dir = initial_dir
	ally.velocity = Vector2(initial_dir * 155.0, 0.0)
	if ally.has_signal("exited_scene"):
		ally.exited_scene.connect(_on_hutsul_exited_scene.bind(ally))
	cast_node.add_child(ally)
	hutsul_allies.append(ally)
	hutsul_ally = ally
	return ally

func _on_hutsul_exited_scene(exited_ally: Node2D) -> void:
	hutsul_allies.erase(exited_ally)
	# Якщо на сцені не залишилося жодного гуцула, через 5 секунд із гір неквапливо приходить один побратим на зміну
	if not is_transitioning_level:
		var current_lvl := level
		get_tree().create_timer(5.0).timeout.connect(func():
			if not is_transitioning_level and level == current_lvl and _get_valid_hutsul_count() == 0:
				var side_x := 170.0 if randf() < 0.5 else 790.0
				var dir := 1.0 if side_x < 480.0 else -1.0
				_spawn_single_hutsul(Vector2(side_x, 220.0), dir)
		)

func _get_valid_hutsul_count() -> int:
	var cnt := 0
	for h in hutsul_allies:
		if h and is_instance_valid(h) and not h.is_queued_for_deletion():
			cnt += 1
	return cnt

func _ensure_hutsul_victory_dancers() -> void:
	# Очищуємо недійсні посилання
	var valid_list: Array[Node2D] = []
	for h in hutsul_allies:
		if h and is_instance_valid(h) and not h.is_queued_for_deletion():
			valid_list.append(h)
	hutsul_allies = valid_list
	
	# На Переможний Аркан стають 1–2 гуцули (стримано та збалансовано!)
	var target_dancers := 1 if level <= 2 else 2
	var dance_spots: Array[Vector2] = [Vector2(340, 494), Vector2(620, 494)]
	while hutsul_allies.size() < target_dancers:
		var spot := dance_spots[hutsul_allies.size() % dance_spots.size()]
		var dancer := _spawn_single_hutsul(spot, 1.0 if spot.x < 480.0 else -1.0)
		dancer.on_ground = true

func _spawn_qirimli_ally() -> void:
	if level < 2 or qirimli_spawned_this_level:
		return
	qirimli_spawned_this_level = true
	var ally = qirimli_scene.instantiate()
	if level == 2:
		ally.position = Vector2(760, 190)
	elif level == 3:
		# Вбігає з вежі Кам'янецької фортеці праворуч
		ally.position = Vector2(750, 170)
	elif level == 4:
		# Вбігає з тераси Батуринського палацу ліворуч
		ally.position = Vector2(190, 180)
	else:
		# Вбігає з вапнякового муру Ор-Капу (Перекоп)
		ally.position = Vector2(760, 165)
	cast_node.add_child(ally)
	qirimli_ally = ally

func _setup_platforms_for_level() -> void:
	if not platforms_node:
		return
	
	var stage_key := ((level - 1) % 20) + 1
	var plat_configs: Array = LEVEL_PLATFORMS.get(stage_key, LEVEL_PLATFORMS[1])
	var style_idx := (level - 1) % 5
	var shoes_active := player.has_vakula_shoes if player else false
	
	# Clear previous platforms
	for child in platforms_node.get_children():
		platforms_node.remove_child(child)
		child.queue_free()
	
	for cfg in plat_configs:
		var plat = platform_scene.instantiate() as BombJackPlatform
		plat.position = cfg["pos"]
		plat.width = cfg["width"]
		plat.platform_style = style_idx
		plat.is_one_way = shoes_active
		platforms_node.add_child(plat)

func _on_vakula_shoes_state_changed(is_active: bool) -> void:
	if not platforms_node:
		return
	for plat in platforms_node.get_children():
		if plat is BombJackPlatform:
			plat.is_one_way = is_active

const LEVEL_LORE_20: Dictionary = {
	1: "РІВЕНЬ 1 (ЗАПОРОЗЬКА СІЧ): «СТРИБАЙ, ДЖУРО! ЗБЕРИ 24 ЯДРА Й ШИРЯЙ НА КИРЕЇ МАМАЯ!»",
	2: "РІВЕНЬ 2 (ДИКАНСЬКИЙ ХУТІР): «КОВАЛЬ ВАКУЛА ДАРУЄ ЗОЛОТІ ПІДКІВКИ! ЗАПАЛИ ЧУМАЦЬКИЙ ШЛЯХ!»",
	3: "РІВЕНЬ 3 (КАМ'ЯНЕЦЬКА ТВЕРДИНЯ): «КИРИМЛИ ТА ГУЦУЛ Б'ЮТЬ БОЛОТНИХ ШИШІВ ТА КИКИМОР МОСКОВЩИНИ!»",
	4: "РІВЕНЬ 4 (ГЕТЬМАНСЬКИЙ БАТУРИН): «ЗАХИСТИМО СКАРБНИЦЮ ТА КЛЕЙНОДИ ВІД ЛИХА ОДНООКОГО Й ОПРИЧНИКІВ!»",
	5: "РІВЕНЬ 5 (ПЕРЕКОПСЬКИЙ ВАЛ — БРАМА ОР-КАПУ): «СТЕПОВИЙ ОБУР І БОЛОТНІ ШИШІ ТІКАЮТЬ ВІД ОБ'ЄДНАНИХ БРАТІВ!»",
	6: "РІВЕНЬ 6 (ХАНСЬКИЙ БАХЧИСАРАЙ ТА ЧУФУТ-КАЛЕ): «СОЛЯНІ ДЖИННИ СИВАША ТА ПЕЧЕРНІ АЖДАХИ ВІДСТУПАЮТЬ ПЕРЕД СОКОЛОМ КИРИМЛИ!»",
	7: "РІВЕНЬ 7 (КОНОТОПСЬКА ПЕРЕПРАВА): «КОЗАКИ Й ЛИТВИНИ ТОПЛЯТЬ ЦАРСЬКОГО ДЯКА, ОПРИЧНИКІВ ТА ТАЙШІВ У БОЛОТІ!»",
	8: "РІВЕНЬ 8 (СТАРОДАВНІЙ ПОЛОЦЬК І ПУЩА): «ПОБРАТИМИ-ЛИТВИНИ З ПОГОНЕЮ ТА ЧАРОДІЙ ВСЕСЛАВ ВИГАНЯЮТЬ БАГНИКІВ!»",
	9: "РІВЕНЬ 9 (ЧОРНОГОРА — СКЕЛІ ДОВБУША): «ЧУГАЙСТЕР І МОЛЬФАР ВЕДУТЬ ТАНОК — ПЕСИГОЛОВЦІ Й ЩЕЗНИКИ РОЗБІГАЮТЬСЯ!»",
	10: "РІВЕНЬ 10 (ЗОЛОТІ ВОРОТА КИЄВА): «ГЕНЕРАЛЬНИЙ БІЙ ЧОТИРЬОХ НАРОДІВ ПРОТИ ЦАР-МОРТИРИ ТА ЛИХА!»",
	11: "РІВЕНЬ 11 (ОЛЕШКІВСЬКА СІЧ): «КОШОВИЙ СІРКО Й СОКІЛЬНИКИ КРИМУ БОРОНЯТЬ ДНІПРОВСЬКІ ПЛАВНІ ВІД АЛБАСТИ!»",
	12: "РІВЕНЬ 12 (ЗАМКОВА ГОРА І ТРОКИ): «КРИЛАТІ ГУСАРИ ВКЛ ЗДІЙМАЮТЬ ВИХОР СВОБОДИ!»",
	13: "РІВЕНЬ 13 (ХОЛОДНИЙ ЯР): «ПІД ДУБОМ ЗАЛІЗНЯКА ЗВУЧИТЬ КОБЗА — КИКИМОРИ Й ВОЄВОДИ ТІКАЮТЬ БЕЗ ЛАПТІВ!»",
	14: "РІВЕНЬ 14 (АККЕРМАНСЬКА ФОРТЕЦЯ): «МУРЗА У СРІБНІЙ КОЛЬЧУЗІ Й ДЖУРА ДОЛАЮТЬ БАСАВРЮКА ТА ОБУРА!»",
	15: "РІВЕНЬ 15 (ПІДЗЕМЕЛЛЯ ХОТИНА): «КАРПАТСЬКИЙ АРІДНИК ТА ВІЙ СЛІПНУТЬ ВІД СОНЯЧНОГО СЯЙВА ЦВІТУ ПАПОРОТІ!»",
	16: "РІВЕНЬ 16 (ЗАДУНАЙСЬКА СІЧ): «КОЗАЦЬКІ ЧАЙКИ ТА ЧОРА-КИРИМЛИ ВІДБИВАЮТЬ ШТУРМ НА ДУНАЇ!»",
	17: "РІВЕНЬ 17 (ПУЩА КАСТУСЯ КАЛИНОВСЬКОГО): «ЗА НАШУ І ВАШУ СВОБОДУ! ЛИТВИНИ Й ДЖУРА ГРОМЛЯТЬ КАРАТЕЛІВ!»",
	18: "РІВЕНЬ 18 (ВЕРХОВИНА Й ПИСАНИЙ КАМІНЬ): «ІВАН СИЛА ТА ТРЕМБІТИ КАРПАТ СКИДАЮТЬ ПЕСИГОЛОВЦІВ З КРУЧ!»",
	19: "РІВЕНЬ 19 (ГЕЗЛЬОВ ТА ХАН-ДЖАМІ): «СТЕПОВІ ВИХОРИ ОБУРА ТА ДЕВ БАЙДАРСЬКИХ СКЕЛЬ СКЛАДАЮТЬ ЗБРОЮ ПЕРЕД ДЖУРОЮ!»",
	20: "РІВЕНЬ 20 (ТАРАСОВА ГОРА У КАНЕВІ): «СОБОР ЧОТИРЬОХ НАРОДІВ! І НА ОНОВЛЕНІЙ ЗЕМЛІ ВРАГА НЕ БУДЕ!»"
}

func _show_level_lore_tip() -> void:
	var current_lvl := level
	await get_tree().create_timer(2.4).timeout
	if is_transitioning_level or level != current_lvl:
		return
	
	var campaign_idx := ((level - 1) % 20) + 1
	var msg: String = LEVEL_LORE_20.get(campaign_idx, LEVEL_LORE_20[1])
	hud.show_message(msg, 4.2, Color(0.35, 0.96, 0.72))

# Склад ворогів кампанії 20 рівнів як дані (T-021, T-023; SHR-001 I-1, I-6).
# Кожен рівень 1–20 вводить рівно нових NPC із Difficulty.NPC_INTRO[level], не більше одного нового EnemyType на рівень,
# і завжди зберігає інваріант I-6: (відьми + відьмаки) * 2 <= чортики. Після рівня 20 нових NPC немає.
const LEVEL_COMPOSITIONS: Dictionary = {
	1: [
		{"pos": Vector2(210, 155), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(750, 155), "type": FolkloreEnemy.EnemyType.CHORT},
	],
	2: [
		{"pos": Vector2(200, 210), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(760, 210), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(480, 75), "type": FolkloreEnemy.EnemyType.VIDMA},
	],
	3: [
		{"pos": Vector2(340, 400), "type": FolkloreEnemy.EnemyType.MOSKAL, "rank": FolkloreEnemy.MoskalRank.STRELETS},
		{"pos": Vector2(210, 155), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(750, 155), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(480, 85), "type": FolkloreEnemy.EnemyType.VIDMA},
	],
	4: [
		{"pos": Vector2(240, 400), "type": FolkloreEnemy.EnemyType.MOSKAL, "rank": FolkloreEnemy.MoskalRank.STRELETS},
		{"pos": Vector2(720, 400), "type": FolkloreEnemy.EnemyType.MOSKAL, "rank": FolkloreEnemy.MoskalRank.STRELETS},
		{"pos": Vector2(480, 85), "type": FolkloreEnemy.EnemyType.VIDMA},
		{"pos": Vector2(210, 165), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(750, 165), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(480, 315), "type": FolkloreEnemy.EnemyType.VOGNYK},
	],
	5: [
		{"pos": Vector2(220, 400), "type": FolkloreEnemy.EnemyType.MOSKAL, "rank": FolkloreEnemy.MoskalRank.STRELETS},
		{"pos": Vector2(480, 235), "type": FolkloreEnemy.EnemyType.MOSKAL, "rank": FolkloreEnemy.MoskalRank.STRELETS},
		{"pos": Vector2(740, 400), "type": FolkloreEnemy.EnemyType.MOSKAL, "rank": FolkloreEnemy.MoskalRank.STRELETS},
		{"pos": Vector2(200, 140), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(760, 140), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(480, 75), "type": FolkloreEnemy.EnemyType.VIDMA},
		{"pos": Vector2(480, 315), "type": FolkloreEnemy.EnemyType.VOGNYK},
	],
	6: [
		{"pos": Vector2(240, 400), "type": FolkloreEnemy.EnemyType.MOSKAL, "rank": FolkloreEnemy.MoskalRank.SHYSH},
		{"pos": Vector2(720, 400), "type": FolkloreEnemy.EnemyType.MOSKAL, "rank": FolkloreEnemy.MoskalRank.STRELETS},
		{"pos": Vector2(210, 155), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(750, 155), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(480, 80), "type": FolkloreEnemy.EnemyType.VIDMA},
	],
	7: [
		{"pos": Vector2(240, 400), "type": FolkloreEnemy.EnemyType.MOSKAL, "rank": FolkloreEnemy.MoskalRank.DYAK},
		{"pos": Vector2(720, 400), "type": FolkloreEnemy.EnemyType.MOSKAL, "rank": FolkloreEnemy.MoskalRank.SHYSH},
		{"pos": Vector2(210, 155), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(750, 155), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(480, 80), "type": FolkloreEnemy.EnemyType.VIDMA},
	],
	8: [
		{"pos": Vector2(240, 400), "type": FolkloreEnemy.EnemyType.MOSKAL, "rank": FolkloreEnemy.MoskalRank.OPRYCHNYK},
		{"pos": Vector2(720, 400), "type": FolkloreEnemy.EnemyType.MOSKAL, "rank": FolkloreEnemy.MoskalRank.DYAK},
		{"pos": Vector2(210, 165), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(750, 165), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(480, 85), "type": FolkloreEnemy.EnemyType.VIDMA},
		{"pos": Vector2(480, 315), "type": FolkloreEnemy.EnemyType.VOGNYK},
	],
	9: [
		{"pos": Vector2(240, 400), "type": FolkloreEnemy.EnemyType.MOSKAL, "rank": FolkloreEnemy.MoskalRank.VOYEVODA},
		{"pos": Vector2(720, 400), "type": FolkloreEnemy.EnemyType.MOSKAL, "rank": FolkloreEnemy.MoskalRank.OPRYCHNYK},
		{"pos": Vector2(210, 165), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(750, 165), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(480, 85), "type": FolkloreEnemy.EnemyType.VIDMA},
		{"pos": Vector2(480, 315), "type": FolkloreEnemy.EnemyType.VOGNYK},
	],
	10: [
		{"pos": Vector2(220, 400), "type": FolkloreEnemy.EnemyType.MOSKAL, "rank": FolkloreEnemy.MoskalRank.TSAR_GENERAL},
		{"pos": Vector2(480, 235), "type": FolkloreEnemy.EnemyType.MOSKAL, "rank": FolkloreEnemy.MoskalRank.VOYEVODA},
		{"pos": Vector2(740, 400), "type": FolkloreEnemy.EnemyType.MOSKAL, "rank": FolkloreEnemy.MoskalRank.SHYSH},
		{"pos": Vector2(200, 140), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(760, 140), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(480, 75), "type": FolkloreEnemy.EnemyType.VIDMA},
		{"pos": Vector2(480, 315), "type": FolkloreEnemy.EnemyType.VOGNYK},
	],
	11: [
		{"pos": Vector2(240, 400), "type": FolkloreEnemy.EnemyType.MOSKAL, "rank": FolkloreEnemy.MoskalRank.MONGOL_NUKER},
		{"pos": Vector2(720, 400), "type": FolkloreEnemy.EnemyType.MOSKAL, "rank": FolkloreEnemy.MoskalRank.OPRYCHNYK},
		{"pos": Vector2(210, 165), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(750, 165), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(480, 85), "type": FolkloreEnemy.EnemyType.VIDMA},
		{"pos": Vector2(480, 315), "type": FolkloreEnemy.EnemyType.VOGNYK},
	],
	12: [
		{"pos": Vector2(240, 400), "type": FolkloreEnemy.EnemyType.MOSKAL, "rank": FolkloreEnemy.MoskalRank.MONGOL_SHAMAN},
		{"pos": Vector2(720, 400), "type": FolkloreEnemy.EnemyType.MOSKAL, "rank": FolkloreEnemy.MoskalRank.MONGOL_NUKER},
		{"pos": Vector2(210, 165), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(750, 165), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(480, 85), "type": FolkloreEnemy.EnemyType.VIDMA},
		{"pos": Vector2(480, 315), "type": FolkloreEnemy.EnemyType.VOGNYK},
	],
	13: [
		{"pos": Vector2(300, 400), "type": FolkloreEnemy.EnemyType.ZLYDNI},
		{"pos": Vector2(700, 400), "type": FolkloreEnemy.EnemyType.MOSKAL, "rank": FolkloreEnemy.MoskalRank.MONGOL_SHAMAN},
		{"pos": Vector2(210, 165), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(750, 165), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(480, 85), "type": FolkloreEnemy.EnemyType.VIDMA},
		{"pos": Vector2(480, 315), "type": FolkloreEnemy.EnemyType.VOGNYK},
	],
	14: [
		{"pos": Vector2(260, 400), "type": FolkloreEnemy.EnemyType.BASAVRIUK},
		{"pos": Vector2(700, 400), "type": FolkloreEnemy.EnemyType.ZLYDNI},
		{"pos": Vector2(210, 165), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(750, 165), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(480, 85), "type": FolkloreEnemy.EnemyType.VIDMA},
		{"pos": Vector2(480, 315), "type": FolkloreEnemy.EnemyType.VOGNYK},
	],
	15: [
		{"pos": Vector2(240, 400), "type": FolkloreEnemy.EnemyType.BASAVRIUK},
		{"pos": Vector2(480, 235), "type": FolkloreEnemy.EnemyType.ZLYDNI},
		{"pos": Vector2(720, 400), "type": FolkloreEnemy.EnemyType.MOSKAL, "rank": FolkloreEnemy.MoskalRank.MONGOL_NUKER},
		{"pos": Vector2(200, 140), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(760, 140), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(480, 75), "type": FolkloreEnemy.EnemyType.VIDMA},
		{"pos": Vector2(480, 315), "type": FolkloreEnemy.EnemyType.VOGNYK},
	],
	16: [
		{"pos": Vector2(240, 400), "type": FolkloreEnemy.EnemyType.BASAVRIUK},
		{"pos": Vector2(480, 235), "type": FolkloreEnemy.EnemyType.ZLYDNI},
		{"pos": Vector2(720, 400), "type": FolkloreEnemy.EnemyType.MOSKAL, "rank": FolkloreEnemy.MoskalRank.MONGOL_SHAMAN},
		{"pos": Vector2(200, 140), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(760, 140), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(480, 75), "type": FolkloreEnemy.EnemyType.VIDMA},
		{"pos": Vector2(480, 315), "type": FolkloreEnemy.EnemyType.VOGNYK},
	],
	17: [
		{"pos": Vector2(240, 400), "type": FolkloreEnemy.EnemyType.BASAVRIUK},
		{"pos": Vector2(480, 235), "type": FolkloreEnemy.EnemyType.ZLYDNI},
		{"pos": Vector2(720, 400), "type": FolkloreEnemy.EnemyType.MOSKAL, "rank": FolkloreEnemy.MoskalRank.VOYEVODA},
		{"pos": Vector2(200, 140), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(760, 140), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(480, 75), "type": FolkloreEnemy.EnemyType.VIDMA},
		{"pos": Vector2(480, 315), "type": FolkloreEnemy.EnemyType.VOGNYK},
	],
	18: [
		{"pos": Vector2(480, 420), "type": FolkloreEnemy.EnemyType.VIJ},
		{"pos": Vector2(240, 400), "type": FolkloreEnemy.EnemyType.BASAVRIUK},
		{"pos": Vector2(720, 400), "type": FolkloreEnemy.EnemyType.ZLYDNI},
		{"pos": Vector2(200, 140), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(760, 140), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(480, 75), "type": FolkloreEnemy.EnemyType.VIDMA},
		{"pos": Vector2(480, 315), "type": FolkloreEnemy.EnemyType.VOGNYK},
	],
	19: [
		{"pos": Vector2(320, 85), "type": FolkloreEnemy.EnemyType.VIDMAK},
		{"pos": Vector2(640, 85), "type": FolkloreEnemy.EnemyType.VIDMA},
		{"pos": Vector2(480, 420), "type": FolkloreEnemy.EnemyType.VIJ},
		{"pos": Vector2(240, 400), "type": FolkloreEnemy.EnemyType.BASAVRIUK},
		{"pos": Vector2(180, 155), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(380, 210), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(580, 210), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(780, 155), "type": FolkloreEnemy.EnemyType.CHORT},
	],
	20: [
		{"pos": Vector2(480, 410), "type": FolkloreEnemy.EnemyType.FINAL_BOSS},
		{"pos": Vector2(320, 85), "type": FolkloreEnemy.EnemyType.VIDMAK},
		{"pos": Vector2(640, 85), "type": FolkloreEnemy.EnemyType.VIDMA},
		{"pos": Vector2(240, 400), "type": FolkloreEnemy.EnemyType.VIJ},
		{"pos": Vector2(180, 155), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(380, 210), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(580, 210), "type": FolkloreEnemy.EnemyType.CHORT},
		{"pos": Vector2(780, 155), "type": FolkloreEnemy.EnemyType.CHORT},
	],
}

# Склад рівня + коефіцієнт складності: додаткові вороги вже введених типів і швидкість (difficulty.gd)
func _spawn_folklore_enemies() -> void:
	_spawn_base_enemies()
	if not enemies_node:
		return
	var present: Array = []
	var present_ranks: Array[FolkloreEnemy.MoskalRank] = []
	var engineers_count := 0
	var chorts_count := 0
	for e in enemies_node.get_children():
		if e.enemy_type == FolkloreEnemy.EnemyType.VIDMA or e.enemy_type == FolkloreEnemy.EnemyType.VIDMAK:
			engineers_count += 1
		else:
			if e.enemy_type == FolkloreEnemy.EnemyType.CHORT:
				chorts_count += 1
			if e.enemy_type != FolkloreEnemy.EnemyType.FINAL_BOSS and not present.has(e.enemy_type):
				present.append(e.enemy_type)
			if e.enemy_type == FolkloreEnemy.EnemyType.MOSKAL and not present_ranks.has(e.moskal_rank):
				present_ranks.append(e.moskal_rank)
	if present.is_empty():
		present.append(FolkloreEnemy.EnemyType.CHORT)
	if present_ranks.is_empty():
		present_ranks.append(FolkloreEnemy.MoskalRank.STRELETS)
	var extra_spots: Array[Vector2] = [Vector2(120, 135), Vector2(840, 135), Vector2(480, 215), Vector2(300, 335), Vector2(660, 335)]
	var extras: int = _Difficulty.extra_enemies(enemies_node.get_child_count(), difficulty_k)
	if extras < 0:
		# Полегшення для слабкого гравця: прибрати до |extras| дублів, не порушуючи I-1 (новий NPC рівня) та I-6 (чортиків >= 2x інженерів)
		var to_remove := -extras
		var intro_list: Array = _Difficulty.NPC_INTRO.get(level, [])
		for kind in [FolkloreEnemy.EnemyType.CHORT, FolkloreEnemy.EnemyType.MOSKAL, FolkloreEnemy.EnemyType.VOGNYK, FolkloreEnemy.EnemyType.ZLYDNI]:
			while to_remove > 0:
				var same: Array = []
				for e in enemies_node.get_children():
					if e.enemy_type == kind:
						same.append(e)
				if same.size() < 2:
					break
				var candidate: FolkloreEnemy = null
				for idx in range(same.size() - 1, -1, -1):
					var cand: FolkloreEnemy = same[idx]
					if cand.npc_id() in intro_list:
						var id_cnt := 0
						for other in same:
							if other.npc_id() == cand.npc_id():
								id_cnt += 1
						if id_cnt < 2:
							continue
					candidate = cand
					break
				if candidate == null:
					break
				enemies_node.remove_child(candidate)
				candidate.free()
				to_remove -= 1
	else:
		extras = mini(extras, maxi(0, _Difficulty.MAX_ALIVE_ENEMIES - enemies_node.get_child_count()))
		for i in extras:
			var etype: FolkloreEnemy.EnemyType = present[i % present.size()]
			var erank: FolkloreEnemy.MoskalRank = present_ranks[i % present_ranks.size()]
			_create_enemy(extra_spots[i % extra_spots.size()], etype, erank)
	var speed_mult: float = _Difficulty.speed_multiplier(difficulty_k)
	for e in enemies_node.get_children():
		e.base_speed *= speed_mult

func _spawn_base_enemies() -> void:
	if not enemies_node:
		return
	var comp_key := ((level - 1) % _Difficulty.CAMPAIGN_LEVELS) + 1
	var configs: Array = LEVEL_COMPOSITIONS.get(comp_key, LEVEL_COMPOSITIONS[1])
	for cfg in configs:
		_create_enemy(cfg["pos"], cfg["type"], cfg.get("rank", FolkloreEnemy.MoskalRank.STRELETS))

func _create_enemy(pos: Vector2, type: FolkloreEnemy.EnemyType, rank: FolkloreEnemy.MoskalRank = FolkloreEnemy.MoskalRank.STRELETS) -> void:
	var enemy = enemy_scene.instantiate() as FolkloreEnemy
	enemy.position = pos
	enemy.enemy_type = type
	enemy.moskal_rank = rank
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.hit_player.connect(_on_player_hit_by_enemy)
	enemy.stolen_artifact_dropped.connect(_on_enemy_dropped_stolen_artifact)
	enemies_node.add_child(enemy)
	if type == FolkloreEnemy.EnemyType.MOSKAL:
		enemy.set_moskal_rank(rank)

func _on_enemy_dropped_stolen_artifact(drop_pos: Vector2) -> void:
	if not items_node:
		return
	var shoe = horseshoe_scene.instantiate() as VakulaHorseshoeItem
	shoe.position = drop_pos
	shoe.enemy_grab_grace_timer = 3.0
	shoe.collected.connect(_on_horseshoe_collected)
	shoe.stolen_by_enemy.connect(_on_artifact_stolen_by_enemy)
	items_node.add_child(shoe)
	hud.show_message("АРТЕФАКТ ВИБИТО З РУК ЗЛОДІЯ! ЛОВИ ЙОГО!", 2.2, Color(1.0, 0.92, 0.25))

func _on_artifact_stolen_by_enemy(_item: Node2D, _enemy: Node2D) -> void:
	if telemetry_engine:
		telemetry_engine.record_artifact_stolen()
	if player:
		player.say("Ах ти злодюжка! Віддай козацький скарб!", 2.2)
	hud.show_message("ЗЛОДІЙ ПЕРЕХОПИВ АРТЕФАКТ! ВДАР ЙОГО, ЩОБ ВІДІБРАТИ!", 2.8, Color(1.0, 0.45, 0.25))

func _spawn_fern_flower() -> void:
	if not items_node or not items_node.get_children().is_empty():
		return
	var flower = flower_scene.instantiate() as FernFlowerItem
	flower.position = Vector2(480, 150)
	flower.collected.connect(_on_flower_collected)
	flower.stolen_by_enemy.connect(_on_artifact_stolen_by_enemy)
	items_node.add_child(flower)
	hud.show_message("З'ЯВИВСЯ ЦВІТ ПАПОРОТІ!", 2.2, Color(1.0, 0.85, 0.2))

func _spawn_vakula_horseshoe() -> void:
	if not items_node or not items_node.get_children().is_empty():
		return
	var shoe = horseshoe_scene.instantiate() as VakulaHorseshoeItem
	shoe.position = Vector2(480, 145)
	shoe.collected.connect(_on_horseshoe_collected)
	shoe.stolen_by_enemy.connect(_on_artifact_stolen_by_enemy)
	items_node.add_child(shoe)
	hud.show_message("КОВАЛЬ ВАКУЛА НАДІСЛАВ ЗОЛОТУ ПІДКІВКУ!", 2.4, Color(1.0, 0.85, 0.2))

func _on_horseshoe_collected(shoe: VakulaHorseshoeItem) -> void:
	if telemetry_engine:
		telemetry_engine.record_artifact_collected()
	player.activate_vakula_shoes(10.0)
	hud.show_message("ЧАРІВНІ ПІДКІВКИ ВАКУЛИ! ПРОСТРИБУВАННЯ КРІЗЬ БАЛКИ!", 2.8, Color(1.0, 0.92, 0.25))
	score += 1500
	if score > high_score:
		high_score = score
		hud.update_highscore(high_score)
	hud.update_score(score)

func _on_flower_collected(flower: FernFlowerItem) -> void:
	if telemetry_engine:
		telemetry_engine.record_artifact_collected()
	player.activate_charakterite(8.0)
	hud.show_message("ЧАРИ ХАРАКТЕРНИКА! РОЗІЖЕНИ НЕЧИСТЬ!", 2.5, Color(0.2, 1.0, 0.45))
	score += 1000
	if score > high_score:
		high_score = score
		hud.update_highscore(high_score)
	hud.update_score(score)
	if enemies_node:
		for e in enemies_node.get_children():
			if e is FolkloreEnemy:
				e.make_scared(8.0)

func _on_player_hit_by_enemy(_enemy: FolkloreEnemy) -> void:
	hits_this_level += 1
	if telemetry != null:
		telemetry.log_event("hit", {"level": level, "hits": hits_this_level})

# Профіль, модель гравця й телеметрія (SHR-003, SWR-002). Вік і досвід задаються батьками: параметри запуску
# `--age=8-10|11-14|15+` і `--exp=novice|casual|experienced` або збережений профіль; модель сама виправляє хибний апріор за 2–3 рівні.
func _init_adaptation() -> void:
	player_model = _PlayerModel.new()
	var age := "11-14"
	var exp_level := "casual"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--age="):
			age = a.substr(6)
		elif a.begins_with("--exp="):
			exp_level = a.substr(6)
	var loaded := false
	if not _Telemetry.is_headless() and FileAccess.file_exists(PROFILE_PATH):
		var f := FileAccess.open(PROFILE_PATH, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			f.close()
			if parsed is Dictionary:
				player_model.from_dict(parsed)
				loaded = true
	telemetry = _Telemetry.new(player_model.player_id if loaded else "")
	if not loaded:
		player_model.setup(age, exp_level, int(Time.get_unix_time_from_system()) % 100000, telemetry.player_id)
	telemetry.log_event("session_start", {"age_band": player_model.age_band, "experience": player_model.experience,
		"mu": player_model.mu, "sigma": sqrt(player_model.sigma2)})
	if hud and hud.has_method("update_profile_display"):
		hud.update_profile_display(player_model.age_band, player_model.experience)

func _save_profile() -> void:
	if player_model == null or _Telemetry.is_headless():
		return
	var f := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(player_model.to_dict()))
		f.close()

func set_player_profile(age: String, exp_level: String) -> void:
	if player_model == null:
		player_model = _PlayerModel.new()
	player_model.setup(age, exp_level, int(Time.get_unix_time_from_system()) % 100000, telemetry.player_id if telemetry != null else "")
	_save_profile()
	if telemetry != null:
		telemetry.log_event("session_start", {
			"age_band": player_model.age_band,
			"experience": player_model.experience,
			"mu": player_model.mu,
			"sigma": sqrt(player_model.sigma2)
		})
	if hud and hud.has_method("update_profile_display"):
		hud.update_profile_display(player_model.age_band, player_model.experience)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and telemetry != null:
		if level_in_progress and not is_transitioning_level:
			var elapsed := float(Time.get_ticks_msec() - level_started_ms) / 1000.0
			if adaptive_enabled and player_model != null:
				var obs: Dictionary = player_model.observe_abandon(elapsed)
				telemetry.log_event("abandon", {"level": level, "time_s": elapsed, "hits": hits_this_level, "mu": obs["mu"], "reward": obs["reward"], "completed": false})
			else:
				telemetry.log_event("abandon", {"level": level, "time_s": elapsed, "hits": hits_this_level, "completed": false})
		telemetry.log_event("session_end", {"level": level})
		_save_profile()

# Вороги (чортики, москалі) повертаються через час, обернено пропорційний K (частота; K ≈ 1: без повернення)
func _schedule_enemy_respawn(kind: FolkloreEnemy.EnemyType) -> void:
	if kind != FolkloreEnemy.EnemyType.CHORT and kind != FolkloreEnemy.EnemyType.MOSKAL:
		return
	var delay: float = _Difficulty.respawn_delay(difficulty_k)
	if delay < 0.0 or is_transitioning_level:
		return
	var for_level := level
	get_tree().create_timer(delay).timeout.connect(func():
		if is_transitioning_level or level != for_level or not enemies_node:
			return
		if enemies_node.get_child_count() >= _Difficulty.MAX_ALIVE_ENEMIES:
			return
		var spots := [Vector2(120, 135), Vector2(840, 135), Vector2(480, 215)]
		_create_enemy(spots[randi() % spots.size()], kind)
	)

func _on_enemy_defeated(enemy: FolkloreEnemy, points: int) -> void:
	if telemetry_engine:
		telemetry_engine.record_enemy_defeated()
	if telemetry != null:
		telemetry.log_event("enemy_defeated", {"level": level, "enemy": enemy.get_enemy_type_name(), "points": points})
	_schedule_enemy_respawn(enemy.enemy_type)
	score += points
	if score > high_score:
		high_score = score
		hud.update_highscore(high_score)
	hud.update_score(score)
	hud.show_message("НЕЧИСТЬ РОЗІГНАНО! +%d" % points, 1.4, Color(1.0, 0.92, 0.25))

func _spawn_bomb_grid() -> void:
	var stage_key := ((level - 1) % 20) + 1
	var bomb_positions: Array = LEVEL_BOMBS.get(stage_key, LEVEL_BOMBS[1])
	
	for pos in bomb_positions:
		var bomb = bomb_scene.instantiate() as BombItem
		bomb.position = pos
		bomb.collected.connect(_on_bomb_collected)
		bomb.exploded.connect(_on_bomb_exploded)
		bombs_node.add_child(bomb)
	
	hud.update_bombs(bomb_positions.size(), bomb_positions.size())

func _light_next_bomb() -> void:
	var remaining_bombs: Array[BombItem] = []
	for child in bombs_node.get_children():
		if child is BombItem and not child.is_queued_for_deletion():
			remaining_bombs.append(child)
	
	if remaining_bombs.is_empty():
		return
	
	# Pick a random unlit bomb to light up
	var unlit_bombs = remaining_bombs.filter(func(b): return not b.is_lit)
	if not unlit_bombs.is_empty():
		var chosen: BombItem = unlit_bombs.pick_random()
		chosen.is_lit = true

func _on_bomb_collected(bomb: BombItem, was_lit: bool) -> void:
	if is_transitioning_level:
		return
	
	bombs_collected_on_level += 1
	if telemetry_engine:
		telemetry_engine.record_bomb_picked(was_lit)
	if telemetry != null:
		telemetry.log_event("bomb", {"level": level, "lit": was_lit, "streak": lit_streak})
	
	var bonus := 0
	var bomb_pos := bomb.global_position
	if was_lit:
		bonus = 200 * lit_streak
		score += bonus
		hud.show_combo(lit_streak, bonus)
		# Ascending pitch scale based on combo streak with positional audio!
		var pitch = clamp(1.0 + (lit_streak - 1) * 0.05, 1.0, 1.8)
		_play_sfx_at(snd_bomb_lit, bomb_pos, pitch)
		lit_streak += 1
		max_lit_streak_level = maxi(max_lit_streak_level, lit_streak)
		if lit_streak == 3:
			player.say("Гей-га!", 1.4)
		elif lit_streak == 6:
			player.say("Козацькому роду нема переводу!", 1.8)
		elif lit_streak == 10:
			player.say("Оце так вогонь!", 1.6)
		
		# Гарантована доставка чарівних підківок Вакули або цвіту папороті
		if lit_streak >= 3 and level >= 2:
			call_deferred("_spawn_vakula_horseshoe")
		elif lit_streak == 5:
			call_deferred("_spawn_fern_flower")
		elif lit_streak == 10:
			call_deferred("_spawn_fern_flower")
		# Chain continues: light up next bomb
		call_deferred("_light_next_bomb")
	else:
		bonus = 100
		score += bonus
		_play_sfx_at(snd_bomb_regular, bomb_pos)
		lit_streak = 1 # Reset chain multiplier
	
	# Прогресивне прибуття союзних NPC (Гуцула і Киримли) по мірі перших успіхів Джури та балансу сил!
	_check_progressive_ally_arrival()
	
	if score > high_score:
		high_score = score
		hud.update_highscore(high_score)
	
	hud.update_score(score)
	
	# Count remaining
	var remaining_count := 0
	for child in bombs_node.get_children():
		if child is BombItem and child != bomb and not child.is_queued_for_deletion():
			remaining_count += 1
	
	hud.update_bombs(remaining_count, 24)
	
	# Гарантована доставка підківок Вакули після збору перших 3 будь-яких ядер на всіх рівнях
	if remaining_count == 21:
		call_deferred("_spawn_vakula_horseshoe")
	
	# Motivational folklore guidance cues for age 8+ clarity
	if remaining_count == 10:
		hud.show_message("ЗАЛИШИЛОСЯ 10 ЯДЕР! ТРИМАЙСЯ, ДЖУРО!", 2.2, Color(1.0, 0.85, 0.2))
	elif remaining_count == 5:
		hud.show_message("ЩЕ 5 ЯДЕР ДО ПЕРЕМОГИ!", 2.2, Color(1.0, 0.92, 0.25))
	elif remaining_count == 1:
		hud.show_message("ОСТАННЄ ЯДРО! ЗБЕРИ ЙОГО ТА ТАНЦЮЙ ГОПАК!", 3.2, Color(0.35, 1.0, 0.55))
		player.say("Останнє ядро лишилося! Бачу його!", 2.0)
	elif remaining_count == 0:
		hud.show_message("УСІ 24 ЯДРА ЗІБРАНО! ПЕРЕМОЖНИЙ ГОПАК!", 3.5, Color(0.25, 1.0, 0.50))
		player.say("Усі ядра в арсеналі! Перемога!", 2.0)
		_on_level_complete()

func _on_bomb_exploded(bomb: BombItem) -> void:
	if is_transitioning_level:
		return
	
	# Скидання стріку комбо палаючих бомб та штраф слави
	lit_streak = 1
	var penalty := 150
	score = maxi(0, score - penalty)
	hud.update_score(score)
	hud.show_message("БОМБА ЗДЕТОНУВАЛА! -%d СЛАВИ!" % penalty, 2.0, Color(1.0, 0.35, 0.2))
	
	if player:
		player.say("Ой лишенько, порох згорів!", 1.8)
	
	_play_sfx_at(snd_poof, bomb.global_position, 0.8)
	
	# Рахуємо залишок бомб
	var remaining_count := 0
	for child in bombs_node.get_children():
		if child is BombItem and child != bomb and not child.is_queued_for_deletion():
			remaining_count += 1
	
	hud.update_bombs(remaining_count, 24)
	if remaining_count == 0:
		hud.show_message("РІВЕНЬ ЗАВЕРШЕНО!", 3.0, Color(0.25, 1.0, 0.50))
		_on_level_complete()
	else:
		_light_next_bomb()

func _on_level_complete() -> void:
	if is_transitioning_level:
		return
	is_transitioning_level = true
	
	# Якість проходження → бонус і коефіцієнт складності наступного рівня (difficulty.gd, SHR-001 I-7)
	var clear_time_s := float(Time.get_ticks_msec() - level_started_ms) / 1000.0
	var level_quality: float = _Difficulty.quality(clear_time_s, hits_this_level, max_lit_streak_level)
	prev_quality = _Difficulty.smooth_quality(prev_quality, level_quality)
	var clear_bonus: int = _Difficulty.bonus_points(clear_time_s, hits_this_level, level_quality)
	level_in_progress = false
	var ep_summary: Dictionary = telemetry_engine.summarize_level_episode(clear_time_s, hits_this_level) if telemetry_engine else {}
	var interest_bonus: float = float(ep_summary.get("interest_bonus", 0.0))
	if adaptive_enabled and player_model != null:
		var obs: Dictionary = player_model.observe(level_quality, hits_this_level, clear_time_s, true, interest_bonus)
		if telemetry != null:
			telemetry.log_event("level_end", {"level": level, "k": difficulty_k, "time_s": clear_time_s, "hits": hits_this_level, "streak": max_lit_streak_level,
				"quality": level_quality, "bonus": clear_bonus, "enemies": level_enemy_count_start, "mu": obs["mu"], "sigma": obs["sigma"], "p_pred": obs["p_pred"],
				"reward": obs["reward"], "arm": obs["arm"], "frustration": obs["frustration"], "boredom": obs["boredom"], "completed": true,
				"persona": ep_summary.get("persona", ""), "near_misses": ep_summary.get("near_misses", 0), "strikes": ep_summary.get("strikes", 0),
				"rhythm_cv": ep_summary.get("rhythm_cv", 0.0), "idle_ratio": ep_summary.get("idle_ratio", 0.0)})
		_save_profile()
	elif telemetry != null:
		telemetry.log_event("level_end", {"level": level, "k": difficulty_k, "time_s": clear_time_s, "hits": hits_this_level, "streak": max_lit_streak_level,
			"quality": level_quality, "bonus": clear_bonus, "enemies": level_enemy_count_start, "completed": true,
			"persona": ep_summary.get("persona", ""), "near_misses": ep_summary.get("near_misses", 0), "strikes": ep_summary.get("strikes", 0),
			"rhythm_cv": ep_summary.get("rhythm_cv", 0.0), "idle_ratio": ep_summary.get("idle_ratio", 0.0)})
	score += clear_bonus
	if score > high_score:
		high_score = score
		hud.update_highscore(high_score)
	hud.update_score(score)
	
	# Ворожі NPC-злодії не зникають миттєво, а танцюють свій комічний національний танок невдачі!
	if enemies_node:
		for child in enemies_node.get_children():
			if child is FolkloreEnemy and child.has_method("start_defeat_dance"):
				child.start_defeat_dance()
	if items_node:
		for child in items_node.get_children():
			child.queue_free()
	
	# Мавка, Домовик, Кобзар і Вакула танцюють свій особистий переможний танок!
	if (mavka_ally == null or not is_instance_valid(mavka_ally)) and _Difficulty.ally_available("MAVKA", level):
		_spawn_mavka_ally()
	if mavka_ally and is_instance_valid(mavka_ally) and mavka_ally.has_method("celebrate_victory"):
		mavka_ally.celebrate_victory()
	
	# Qirimli ally joins the joyous celebration with Crimean Tatar Horan / Qaytarma dance!
	if qirimli_ally and is_instance_valid(qirimli_ally) and qirimli_ally.has_method("celebrate_victory"):
		qirimli_ally.celebrate_victory()
	
	# Carpathian Hutsul & Lytvyn band gathers and dances their personal Arkan / Liavonicha victory dance!
	_ensure_hutsul_victory_dancers()
	for h in hutsul_allies:
		if h and is_instance_valid(h) and h.has_method("celebrate_victory"):
			h.celebrate_victory()
	
	# 1. Stop space background music immediately
	bgm_player.stop()
	
	# 2. Initiate Dzhura's victory sequence (lands on floor first if airborne)
	player.celebrate_victory(4.10)
	if player.hopak_waiting_for_floor:
		await player.hopak_started
	
	# 3. Play authentic Ukrainian folklore Hopak celebration music & banner in sync with dance
	_play_sfx(snd_hopak_music)
	hud.show_message("ПЕРЕМОЖНИЙ БОЙОВИЙ ГОПАК!", 3.95, Color(0.25, 1.0, 0.50, 1.0))
	
	# 4. Wait until Dzhura completely finishes all 6 phases of the Combat Hopak
	await player.hopak_finished
	await get_tree().create_timer(0.15).timeout
	
	# 4.5. Бонус за швидке й якісне проходження
	hud.show_message("БОНУС ЗА ПРОХОДЖЕННЯ +%d (ЯКІСТЬ %d%%, %d с)" % [clear_bonus, int(round(level_quality * 100.0)), int(round(clear_time_s))], 2.4, Color(0.55, 1.0, 0.65))
	
	# 5. Reset Dzhura to clean normal state at starting position before spawning next level
	var prev_lvl := level
	level += 1
	
	if prev_lvl == 1:
		player.unlock_champion_skill(JackPlayer.ChampionSkill.STEELHAMMER_JAB)
		_queue_combat_hint_front("steelhammer_jab")
		hud.show_message("НОВИЙ НАВИК: СТАЛЕВИЙ ДЖЕБ ВОЛОДИМИРА КЛИЧКА! [X / J / CTRL] ДЛЯ УДАРУ!", 3.8, Color(1.0, 0.88, 0.25))
	elif prev_lvl == 2:
		player.unlock_champion_skill(JackPlayer.ChampionSkill.IRONFIST_HOOK)
		_queue_combat_hint_front("ironfist_hook")
		hud.show_message("НОВИЙ НАВИК: ЗАЛІЗНИЙ ОВЕРХЕНД ВІТАЛІЯ КЛИЧКА! УДАР ЗГОРИ!", 3.8, Color(1.0, 0.88, 0.25))
	elif prev_lvl == 3:
		player.unlock_champion_skill(JackPlayer.ChampionSkill.USYK_SLIP_COUNTER)
		_queue_combat_hint_front("usyk_slip_counter")
		hud.show_message("НОВИЙ НАВИК: ЧОВНИК ТА УХИЛ ОЛЕКСАНДРА УСИКА! ПЕРЕКАТ + КОНТРАТАКА!", 3.8, Color(1.0, 0.88, 0.25))
	elif prev_lvl == 4:
		player.unlock_champion_skill(JackPlayer.ChampionSkill.UNDISPUTED_TRIO)
		_queue_combat_hint_front("undisputed_trio")
		hud.show_message("ТИ АБСОЛЮТНИЙ ЧЕМПІОН! ЗОЛОТІ ПОЯСИ ТРЬОХ ЛЕГЕНД УКРАЇНИ!", 4.2, Color(1.0, 0.95, 0.35))
	
	player.reset_to_normal_state(Vector2(480, 494))
	_setup_level()
	
	# Show comic story cards for the next level before launching gameplay
	if story_cards and story_cards.has_story_for_level(level):
		story_cards.show_story_for_level(level)
		await story_cards.story_finished
	
	# 6. Resume stage background music & show classic center-screen level announcement with fade-out
	bgm_player.play()
	hud.announce_level(level, 2.5)
	is_transitioning_level = false
