extends Node

class_name TelemetryEngine

## Поведінковий трекер дій гравця, класифікатор архетипу (PlayerPersona), оцінювач ознак інтересу
## для бандита в `scripts/player_model.gd` та генератор контекстних порад Козака Мамая (T-024).
##
## Розподіл відповідальності (T-024, SHR-003, ADR-002):
## - Єдиний контролер коефіцієнта складності K — `scripts/player_model.gd` (цей вузол K не змінює).
## - Єдиний писач телеметрії на диск — `scripts/telemetry.gd` (`user://telemetry/events.jsonl`, схема v1).
## - Жодних мережевих викликів із циклу гри за замовчуванням (SHR-003 A-6: приватність дітей).

signal episode_summarized(summary: Dictionary)
signal mamay_tip_ready(tip: String)

enum PlayerPersona {
	YOUNG_COSSACK_8PLUS, # Юний козачок (8–10 років): досліджує світ, потребує ранньої підмоги друзів
	STORY_EXPLORER,      # Сімейний мандрівник: помірний темп, любить сюжет і фольклорних союзників
	COMBAT_BRAWLER,      # Богатир Гопака: активно б'є ворогів руками й ногами, любить поєдинки
	COMBO_STRATEGIST,    # Майстер Вогняних Комбо: планує маршрут суворо за запаленими ядрами
	ARCADE_SPEEDRUNNER   # Віртуоз-Характерник: блискавичне бездоганне проходження на високій швидкості
}

var current_persona: PlayerPersona = PlayerPersona.STORY_EXPLORER
var last_mamay_tip: String = ""

# Лічильники дій поточного рівня
var _level_start_ms: int = 0
var _last_bomb_ms: int = 0
var _inter_bomb_intervals: Array[float] = []
var _jumps_count: int = 0
var _glides_count: int = 0
var _fast_drops_count: int = 0
var _rolls_count: int = 0
var _punches_count: int = 0
var _kicks_count: int = 0
var _bonks_count: int = 0
var _enemies_defeated: int = 0
var _artifacts_collected: int = 0
var _artifacts_stolen: int = 0
var _lit_bombs_collected: int = 0
var _total_bombs_collected: int = 0
var _near_misses_count: int = 0
var _idle_time_s: float = 0.0
var _near_miss_cooldown: float = 0.0

## Скидання та старт збору лічильників на початку рівня
func begin_level_tracking(_level: int) -> void:
	var now := Time.get_ticks_msec()
	_level_start_ms = now
	_last_bomb_ms = now
	_inter_bomb_intervals.clear()
	_jumps_count = 0
	_glides_count = 0
	_fast_drops_count = 0
	_rolls_count = 0
	_punches_count = 0
	_kicks_count = 0
	_bonks_count = 0
	_enemies_defeated = 0
	_artifacts_collected = 0
	_artifacts_stolen = 0
	_lit_bombs_collected = 0
	_total_bombs_collected = 0
	_near_misses_count = 0
	_idle_time_s = 0.0
	_near_miss_cooldown = 0.0

## Поframe-трекінг кінематичної активності, простою (idle) та гострих розминань із ворогами (near-miss)
func sample_frame(delta: float, player: Node2D, enemies_node: Node2D) -> void:
	if _near_miss_cooldown > 0.0:
		_near_miss_cooldown -= delta
	if player == null or not is_instance_valid(player):
		return
	if "velocity" in player:
		var vel: Vector2 = player.velocity
		if vel.length_squared() < 16.0:
			_idle_time_s += delta
	if _near_miss_cooldown <= 0.0 and enemies_node != null and is_instance_valid(enemies_node):
		var p_pos := player.global_position
		for child in enemies_node.get_children():
			if child is Node2D and is_instance_valid(child):
				var dist := p_pos.distance_to(child.global_position)
				if dist > 26.0 and dist < 58.0:
					_near_misses_count += 1
					_near_miss_cooldown = 0.85
					break

func record_jump() -> void: _jumps_count += 1
func record_glide() -> void: _glides_count += 1
func record_fast_drop() -> void: _fast_drops_count += 1
func record_roll() -> void: _rolls_count += 1
func record_punch() -> void: _punches_count += 1
func record_kick() -> void: _kicks_count += 1
func record_ceiling_bonk() -> void: _bonks_count += 1
func record_enemy_defeated() -> void: _enemies_defeated += 1
func record_artifact_collected() -> void: _artifacts_collected += 1
func record_artifact_stolen() -> void: _artifacts_stolen += 1

func record_bomb_picked(was_lit: bool) -> void:
	var now := Time.get_ticks_msec()
	var dt := maxf(0.05, float(now - _last_bomb_ms) / 1000.0)
	_last_bomb_ms = now
	_inter_bomb_intervals.append(dt)
	_total_bombs_collected += 1
	if was_lit:
		_lit_bombs_collected += 1

## Коефіцієнт варіації темпу збору ядер (CV = sigma / mean) та індекс ритмічності:
static func compute_rhythm_metrics(intervals: Array) -> Dictionary:
	if intervals.is_empty():
		return {"mean_s": 3.5, "std_s": 0.0, "cv": 0.0, "rhythm_score": 0.5}
	var sum_v := 0.0
	for v in intervals:
		sum_v += float(v)
	var mean_v := sum_v / float(intervals.size())
	var var_sum := 0.0
	for v in intervals:
		var diff := float(v) - mean_v
		var_sum += diff * diff
	var std_v := sqrt(var_sum / float(intervals.size()))
	var cv := std_v / maxf(0.1, mean_v)
	var rhythm_score := clampf(1.0 - cv * 0.55, 0.0, 1.0)
	return {"mean_s": mean_v, "std_s": std_v, "cv": cv, "rhythm_score": rhythm_score}

## Детермінований класифікатор типу гравця (PlayerPersona) за поведінковими ознаками рівня:
static func classify_player_persona(features: Dictionary) -> PlayerPersona:
	var clear_time_s: float = float(features.get("clear_time_s", 75.0))
	var hits: int = int(features.get("hits", 0))
	var lit_ratio: float = float(features.get("lit_ratio", 0.35))
	var strikes: int = int(features.get("strikes", 0))
	var enemies_defeated: int = int(features.get("enemies_defeated", 0))
	var idle_ratio: float = float(features.get("idle_ratio", 0.05))
	var bonks: int = int(features.get("bonks", 0))

	if clear_time_s > 105.0 or hits >= 3 or idle_ratio > 0.20 or bonks >= 8:
		return PlayerPersona.YOUNG_COSSACK_8PLUS
	if clear_time_s <= 54.0 and hits == 0 and lit_ratio >= 0.55:
		return PlayerPersona.ARCADE_SPEEDRUNNER
	if strikes >= 12 or enemies_defeated >= 4:
		return PlayerPersona.COMBAT_BRAWLER
	if lit_ratio >= 0.72:
		return PlayerPersona.COMBO_STRATEGIST
	return PlayerPersona.STORY_EXPLORER

## Оцінка поведінкового інтересу [-0.20, +0.20] як додаткова ознака для винагороди бандита в player_model.gd:
## Ритмічний рух, гострі розминання (near-miss thrill), активні удари й збір вогняних ядер підвищують інтерес;
## тривалий простій і часті удари головою об склепіння знижують.
static func interest_signal(features: Dictionary) -> float:
	var rhythm_score: float = clampf(float(features.get("rhythm_score", 0.5)), 0.0, 1.0)
	var near_misses: int = int(features.get("near_misses", 0))
	var lit_ratio: float = clampf(float(features.get("lit_ratio", 0.3)), 0.0, 1.0)
	var idle_ratio: float = clampf(float(features.get("idle_ratio", 0.0)), 0.0, 1.0)
	var thrill := clampf(float(near_misses) / 5.0, 0.0, 1.0)
	var bonus := 0.10 * (rhythm_score - 0.5) + 0.08 * thrill + 0.06 * (lit_ratio - 0.35) - 0.15 * idle_ratio
	return clampf(bonus, -0.20, 0.20)

## Детермінована тепла порада Козака Мамая відповідно до типу гравця та дій на рівні (без мережі):
static func mamay_tip_for_episode(persona: PlayerPersona, features: Dictionary) -> String:
	var hits: int = int(features.get("hits", 0))
	var bonks: int = int(features.get("bonks", 0))
	if bonks >= 4:
		return "Обережно з кам'яним склепінням, козаче! Оминай балки збоку або бери Підківки Вакули!"
	if hits >= 2:
		return "Не поспішай на багнети, Джуро! Ширяй на киреї й чекай підмоги побратимів!"
	match persona:
		PlayerPersona.YOUNG_COSSACK_8PLUS:
			return "Гарно тримаєшся, юний Джуро! Збирай іскристі ядра — друзі вже поспішають на поміч!"
		PlayerPersona.COMBAT_BRAWLER:
			return "Оце так бойовий гопак! Твої удари розганяють ворогів, мов вітер полову!"
		PlayerPersona.COMBO_STRATEGIST:
			return "Пильне око характерника! Вогняна серія ядер запалює небо над Січчю!"
		PlayerPersona.ARCADE_SPEEDRUNNER:
			return "Блискавичний політ, козаче! Жоден ворог не встигає за твоїм вітром!"
		_:
			return "Козацькому роду нема переводу! Разом із побратимами здолаємо будь-яку темряву!"

## Підсумок дій за рівень: повертає словник поведінкових ознак для `player_model.observe()` і `telemetry.log_event("level_end", ...)`
func summarize_level_episode(clear_time_s: float, hits: int) -> Dictionary:
	var total_b := maxi(1, _total_bombs_collected)
	var lit_ratio := float(_lit_bombs_collected) / float(total_b)
	var idle_ratio := clampf(_idle_time_s / maxf(1.0, clear_time_s), 0.0, 1.0)
	var rhythm := compute_rhythm_metrics(_inter_bomb_intervals)
	var strikes := _punches_count + _kicks_count
	var feat := {
		"clear_time_s": clear_time_s,
		"hits": hits,
		"lit_ratio": lit_ratio,
		"strikes": strikes,
		"enemies_defeated": _enemies_defeated,
		"idle_ratio": idle_ratio,
		"bonks": _bonks_count,
		"near_misses": _near_misses_count,
		"rhythm_cv": float(rhythm["cv"]),
		"rhythm_score": float(rhythm["rhythm_score"]),
	}
	current_persona = classify_player_persona(feat)
	var persona_name: String = PlayerPersona.keys()[current_persona]
	var interest_bonus := interest_signal(feat)
	last_mamay_tip = mamay_tip_for_episode(current_persona, feat)
	var summary := {
		"persona": persona_name,
		"interest_bonus": interest_bonus,
		"near_misses": _near_misses_count,
		"strikes": strikes,
		"jumps": _jumps_count,
		"glides": _glides_count,
		"rolls": _rolls_count,
		"bonks": _bonks_count,
		"rhythm_cv": snappedf(float(rhythm["cv"]), 0.001),
		"idle_ratio": snappedf(idle_ratio, 0.001),
		"mamay_tip": last_mamay_tip,
	}
	episode_summarized.emit(summary)
	mamay_tip_ready.emit(last_mamay_tip)
	return summary
