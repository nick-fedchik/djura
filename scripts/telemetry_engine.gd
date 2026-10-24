extends Node

class_name TelemetryEngine

## Незалежна підсистема телеметрії, статистичного моделювання гравця та нейро-символічної
## адаптивної складності (2026 Modern DDA Architecture: IRT + 1D Kalman Filter + PID Flow Controller
## + Persona Classifier + Non-blocking Ollama Heuristic Advisor).
##
## Дотримується інваріанта Relevance vs Eligibility:
## - Евристичний радник Ollama (System 1) пропонує інтерпретацію стилю гравця, персоналізовану пораду
##   Козака Мамая та м'яку поправку ΔK_ollama.
## - Детерміноване математичне ядро (System 2) перевіряє межі Ляпунова/BIBO, обмежує поправку
##   інтервалом [-MAX_OLLAMA_DELTA, +MAX_OLLAMA_DELTA] і гарантує дотримання інваріантів I-1..I-7.

signal telemetry_recorded(episode: Dictionary)
signal persona_updated(persona_name: String, profile: Dictionary)
signal ollama_advice_received(advice: Dictionary)

enum PlayerPersona {
	YOUNG_COSSACK_8PLUS, # Юний козачок (6–10 років): досліджує світ, потребує ранньої підмоги друзів
	STORY_EXPLORER,      # Сімейний мандрівник: помірний темп, любить сюжет і фольклорних союзників
	COMBAT_BRAWLER,      # Богатир Гопака: активно б'є ворогів руками й ногами, любить дуелі з воєводами
	COMBO_STRATEGIST,    # Майстер Вогняних Комбо: планує маршрут суворо за запаленими ядрами
	ARCADE_SPEEDRUNNER   # Віртуоз-Характерник: блискавичне бездоганне проходження на високій швидкості
}

enum FlowState {
	FLOW_ZONE,           # Оптимальний канал потоку Чіксентмігаї (виклик == майстерність)
	FRUSTRATION_RISK,    # Перевантаження / тривога (забагато ударів або повільне проходження)
	BOREDOM_RISK,        # Занадто легко (нудьга — гравець проходить без напруги)
	NOVICE_DISCOVERY     # Початкове освоєння керування (дитина або новий гравець)
}

const TELEMETRY_PATH: String = "user://telemetry.jsonl"
const PROFILE_PATH: String = "user://player_adaptive_profile.json"

# Параметри 1D Фільтра Калмана та IRT (Item Response Theory 2PL)
const PRIOR_SKILL_MU: float = 0.50
const PRIOR_SKILL_VAR: float = 0.12
const PROCESS_NOISE_Q: float = 0.015
const MEASUREMENT_NOISE_R: float = 0.045
const IRT_DISCRIMINATION_BETA: float = 4.0
const REGIME_SWITCH_THRESHOLD: float = 0.36 # Поріг виявлення зміни гравця за геймпадом (напр., тато передав дитині)

# Параметри ПІД-регулятора (PID Flow Controller) навколо оптимальної точки виклику Вілсона (q* = 0.65)
const TARGET_FLOW_QUALITY: float = 0.65
const PID_KP: float = 0.28
const PID_KI: float = 0.09
const PID_KD: float = 0.12
const PID_INTEGRAL_MAX: float = 0.85
const MAX_OLLAMA_DELTA: float = 0.12 # Жорстке обмеження System 2 на евристичну поправку Ollama

# Налаштування Ollama (за замовчуванням вимкнено в циклі гри для приватності SHR-003 A-6 / SWR-002-08; вмикається прапорцем --ollama-live)
var ollama_enabled: bool = false
var ollama_endpoint: String = "http://127.0.0.1:11434/api/generate"
var ollama_model: String = "phi4-mini:3.8b"
var ollama_timeout_s: float = 3.5

# Поточний стан Байєсівського профілю гравця
var skill_mu: float = PRIOR_SKILL_MU
var skill_var: float = PRIOR_SKILL_VAR
var pid_integral: float = 0.0
var pid_prev_error: float = 0.0
var current_persona: PlayerPersona = PlayerPersona.STORY_EXPLORER
var current_flow_state: FlowState = FlowState.FLOW_ZONE
var last_ollama_delta_k: float = 0.0
var last_mamay_tip: String = ""
var episodes_history: Array[Dictionary] = []

# Лічильники поточного рівня (високочастотна телеметрія в реальному часі)
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

func _ready() -> void:
	_load_persistent_profile()

## Скидання та старт збору телеметрії на початку рівня
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

## Поframe-трекінг кінематичної активності, простою (idle) та гострих розминань із ворогами (near-miss thrill)
func sample_frame(delta: float, player: Node2D, enemies_node: Node2D) -> void:
	if _near_miss_cooldown > 0.0:
		_near_miss_cooldown -= delta
	if player == null or not is_instance_valid(player):
		return
	var vel: Vector2 = player.get("velocity") if "velocity" in player else Vector2.ZERO
	if vel.length() < 8.0:
		_idle_time_s += delta
	if enemies_node and _near_miss_cooldown <= 0.0:
		for e in enemies_node.get_children():
			if e is Node2D and is_instance_valid(e):
				var is_scared_flag: bool = bool(e.get("is_scared"))
				if not is_scared_flag:
					var d := player.global_position.distance_to(e.global_position)
					if d > 21.0 and d < 46.0:
						_near_misses_count += 1
						_near_miss_cooldown = 0.65
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

# ============================================================================
# ЧИСТІ МАТЕМАТИЧНІ ФУНКЦІЇ (ДЕТЕРМІНОВАНЕ ЯДРО SYSTEM 2 — ТЕСТУЮТЬСЯ ОКРЕМО)
# ============================================================================

## 1. Імовірність успіху за логістичною моделлю Раша (IRT 2PL):
## P(q | skill_mu, level_difficulty) = 1 / (1 + exp(-beta * (skill_mu - d_level)))
static func irt_expected_quality(p_skill_mu: float, difficulty_k: float) -> float:
	var d_norm := clampf((difficulty_k - 0.70) / 1.80, 0.0, 1.0)
	return 1.0 / (1.0 + exp(-IRT_DISCRIMINATION_BETA * (clampf(p_skill_mu, 0.0, 1.0) - d_norm)))

## 2. Одновимірний Байєсівський фільтр Калмана з автоматичним детектором зміни гравця (Adaptive Covariance Reset):
## Повертає Dictionary {"mu": float, "var": float, "kalman_gain": float, "innovation": float, "regime_switched": bool}
static func kalman_skill_update(prev_mu: float, prev_var: float, observed_q: float, difficulty_k: float) -> Dictionary:
	var expected_q := irt_expected_quality(prev_mu, difficulty_k)
	var innovation := clampf(observed_q, 0.0, 1.0) - expected_q
	var pred_var := clampf(prev_var + PROCESS_NOISE_Q, 0.005, 0.35)
	var regime_switched := false
	# Якщо інновація занадто велика (наприклад, геймпад взяла дитина або навпаки досвідчений гравець) — розширюємо дисперсію!
	if absf(innovation) > REGIME_SWITCH_THRESHOLD:
		pred_var = maxf(pred_var, 0.14)
		regime_switched = true
	var kalman_gain := pred_var / (pred_var + MEASUREMENT_NOISE_R)
	var post_mu := clampf(prev_mu + kalman_gain * innovation, 0.05, 0.98)
	var post_var := clampf((1.0 - kalman_gain) * pred_var, 0.005, 0.30)
	return {
		"mu": post_mu,
		"var": post_var,
		"kalman_gain": kalman_gain,
		"innovation": innovation,
		"regime_switched": regime_switched
	}

## 3. Коефіцієнт варіації темпу збору ядер (CV = sigma / mean) та індекс ритмічності потоку:
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
	return {
		"mean_s": mean_v,
		"std_s": std_v,
		"cv": cv,
		"rhythm_score": rhythm_score
	}

## 4. Багатофакторний індекс залученості та стану Потоку Чіксентмігаї (Flow Index in [0, 1]):
static func evaluate_flow_state(
	clear_time_s: float,
	hits: int,
	near_misses: int,
	idle_ratio: float,
	skill_est: float,
	difficulty_k: float
) -> Dictionary:
	var challenge_norm := clampf((difficulty_k - 0.70) / 1.50, 0.0, 1.0)
	var gap := challenge_norm - skill_est
	var thrill_factor := clampf(float(near_misses) / 6.0, 0.0, 1.0)
	var stress_penalty := clampf(float(hits) * 0.28 + maxf(0.0, clear_time_s - 110.0) / 90.0, 0.0, 1.0)
	
	var state: FlowState = FlowState.FLOW_ZONE
	if hits >= 3 or (clear_time_s > 125.0 and hits >= 2) or gap > 0.30:
		state = FlowState.FRUSTRATION_RISK
	elif idle_ratio > 0.28 and clear_time_s > 85.0:
		state = FlowState.NOVICE_DISCOVERY
	elif hits == 0 and clear_time_s < 48.0 and gap < -0.22:
		state = FlowState.BOREDOM_RISK
	else:
		state = FlowState.FLOW_ZONE
	
	var flow_index := clampf(1.0 - absf(gap) * 0.9 - stress_penalty * 0.55 + thrill_factor * 0.20, 0.05, 1.0)
	return {
		"flow_state": state,
		"flow_state_name": FlowState.keys()[state],
		"flow_index": flow_index,
		"challenge_skill_gap": gap,
		"thrill_factor": thrill_factor
	}

## 5. ПІД-регулятор (PID Controller) із захистом від насичення інтегратора (Anti-Windup):
static func pid_difficulty_step(
	observed_q: float,
	prev_integral: float,
	prev_error: float
) -> Dictionary:
	var error := clampf(observed_q, 0.0, 1.0) - TARGET_FLOW_QUALITY
	var new_integral := clampf(prev_integral * 0.85 + error, -PID_INTEGRAL_MAX, PID_INTEGRAL_MAX)
	var derivative := error - prev_error
	var control_u := clampf(PID_KP * error + PID_KI * new_integral + PID_KD * derivative, -0.35, 0.35)
	return {
		"control_u": control_u,
		"integral": new_integral,
		"error": error
	}

## 6. Детермінований класифікатор архетипу та вікової/моторної групи гравця (PlayerPersona):
static func classify_player_persona(features: Dictionary) -> PlayerPersona:
	var clear_time_s: float = float(features.get("clear_time_s", 75.0))
	var hits: int = int(features.get("hits", 0))
	var lit_ratio: float = float(features.get("lit_ratio", 0.3))
	var strike_count: int = int(features.get("strikes", 0))
	var enemies_ko: int = int(features.get("enemies_defeated", 0))
	var idle_ratio: float = float(features.get("idle_ratio", 0.05))
	var bonks: int = int(features.get("bonks", 0))
	
	# 1. Віртуоз-спідранер: швидкий час, без ударів, висока точність
	if clear_time_s <= 48.0 and hits == 0 and lit_ratio >= 0.55:
		return PlayerPersona.ARCADE_SPEEDRUNNER
	# 2. Юний козачок (6–10 років) або новачок: багато пауз на роздуми, ударів об стелю або отриманих хітів
	if idle_ratio >= 0.22 or (clear_time_s >= 98.0 and strike_count <= 2) or (hits >= 3 and bonks >= 3):
		return PlayerPersona.YOUNG_COSSACK_8PLUS
	# 3. Богатир Гопака (Combat Brawler): активно застосовує боксерські удари й удари ногами Гопака
	if strike_count >= 6 or enemies_ko >= 3:
		return PlayerPersona.COMBAT_BRAWLER
	# 4. Майстер Вогняних Комбо: цілеспрямовано збирає запалені ядра по черзі
	if lit_ratio >= 0.65:
		return PlayerPersona.COMBO_STRATEGIST
	# 5. Сімейний дослідник казки
	return PlayerPersona.STORY_EXPLORER

## 7. Комбінований нейро-символічний розрахунок скоригованої якості для Difficulty.coefficient():
static func compute_adaptive_effective_quality(
	raw_quality: float,
	kalman_mu: float,
	pid_u: float,
	flow_state: FlowState,
	ollama_delta_k: float = 0.0
) -> float:
	# Поєднуємо Байєсівську оцінку майстерності (60%), поточну якість (40%) та ПІД-корекцію
	var blended := 0.60 * kalman_mu + 0.40 * raw_quality + 0.35 * pid_u
	if flow_state == FlowState.FRUSTRATION_RISK:
		blended -= 0.14 # Негайне полегшення, щоб дитина не засмучувалася!
	elif flow_state == FlowState.NOVICE_DISCOVERY:
		blended -= 0.08
	elif flow_state == FlowState.BOREDOM_RISK:
		blended += 0.10
	# Додаємо обмежену System 2 поправку від Ollama (якщо є)
	var safe_ollama := clampf(ollama_delta_k, -MAX_OLLAMA_DELTA, MAX_OLLAMA_DELTA)
	return clampf(blended + safe_ollama, 0.0, 1.0)

## Завершення рівня: обчислення всіх метрик, оновлення Калмана/ПІД, запис JSONL та асинхронний запит до Ollama
func complete_level_episode(
	level: int,
	difficulty_k: float,
	clear_time_s: float,
	hits: int,
	max_lit_streak: int,
	raw_quality: float,
	bonus: int,
	enemies_start: int
) -> Dictionary:
	var total_b := maxi(1, _total_bombs_collected)
	var lit_ratio := float(_lit_bombs_collected) / float(total_b)
	var idle_ratio := clampf(_idle_time_s / maxf(1.0, clear_time_s), 0.0, 1.0)
	var rhythm := compute_rhythm_metrics(_inter_bomb_intervals)
	
	# 1. Оновлюємо Байєсівський фільтр Калмана (System 2)
	var kf := kalman_skill_update(skill_mu, skill_var, raw_quality, difficulty_k)
	skill_mu = float(kf["mu"])
	skill_var = float(kf["var"])
	
	# 2. Оновлюємо ПІД-регулятор потоку
	var pid := pid_difficulty_step(raw_quality, pid_integral, pid_prev_error)
	pid_integral = float(pid["integral"])
	pid_prev_error = float(pid["error"])
	
	# 3. Оцінюємо стан Потоку Чіксентмігаї та Персону гравця
	var flow := evaluate_flow_state(clear_time_s, hits, _near_misses_count, idle_ratio, skill_mu, difficulty_k)
	current_flow_state = flow["flow_state"]
	
	var feat := {
		"clear_time_s": clear_time_s,
		"hits": hits,
		"lit_ratio": lit_ratio,
		"strikes": _punches_count + _kicks_count,
		"enemies_defeated": _enemies_defeated,
		"idle_ratio": idle_ratio,
		"bonks": _bonks_count
	}
	current_persona = classify_player_persona(feat)
	var persona_name: String = PlayerPersona.keys()[current_persona]
	
	var adaptive_q := compute_adaptive_effective_quality(
		raw_quality, skill_mu, float(pid["control_u"]), current_flow_state, last_ollama_delta_k
	)
	
	var episode := {
		"timestamp": Time.get_datetime_string_from_system(true),
		"level": level,
		"k": snappedf(difficulty_k, 0.01),
		"time_s": snappedf(clear_time_s, 0.1),
		"hits": hits,
		"near_misses": _near_misses_count,
		"max_lit_streak": max_lit_streak,
		"lit_ratio": snappedf(lit_ratio, 0.01),
		"rhythm_cv": snappedf(float(rhythm["cv"]), 0.01),
		"rhythm_score": snappedf(float(rhythm["rhythm_score"]), 0.01),
		"jumps": _jumps_count,
		"glides": _glides_count,
		"fast_drops": _fast_drops_count,
		"rolls": _rolls_count,
		"punches": _punches_count,
		"kicks": _kicks_count,
		"bonks": _bonks_count,
		"enemies_defeated": _enemies_defeated,
		"artifacts_collected": _artifacts_collected,
		"artifacts_stolen": _artifacts_stolen,
		"idle_ratio": snappedf(idle_ratio, 0.01),
		"quality": snappedf(raw_quality, 0.01),
		"kalman_skill_mu": snappedf(skill_mu, 0.01),
		"kalman_skill_sigma": snappedf(sqrt(skill_var), 0.01),
		"regime_switched": bool(kf["regime_switched"]),
		"pid_u": snappedf(float(pid["control_u"]), 0.01),
		"flow_state": String(flow["flow_state_name"]),
		"flow_index": snappedf(float(flow["flow_index"]), 0.01),
		"persona": persona_name,
		"quality_smoothed": snappedf(adaptive_q, 0.01),
		"ollama_delta_k": snappedf(last_ollama_delta_k, 0.01),
		"bonus": bonus,
		"enemies_start": enemies_start
	}
	
	episodes_history.append(episode)
	if episodes_history.size() > 30:
		episodes_history.pop_front()
	
	_write_episode_jsonl(episode)
	_save_persistent_profile()
	telemetry_recorded.emit(episode)
	persona_updated.emit(persona_name, episode)
	
	# 4. Запускаємо асинхронну евристичну оцінку через Ollama (System 1 Advisory), якщо не в headless-тесті
	if ollama_enabled and DisplayServer.get_name() != "headless":
		_request_ollama_heuristic_evaluation(episode)
	
	return episode

func _write_episode_jsonl(episode: Dictionary) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(TELEMETRY_PATH) else FileAccess.WRITE
	var f := FileAccess.open(TELEMETRY_PATH, mode)
	if f == null:
		return
	f.seek_end()
	f.store_line(JSON.stringify(episode))

func _save_persistent_profile() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var f := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if f == null:
		return
	var data := {
		"skill_mu": skill_mu,
		"skill_var": skill_var,
		"pid_integral": pid_integral,
		"pid_prev_error": pid_prev_error,
		"persona": PlayerPersona.keys()[current_persona],
		"flow_state": FlowState.keys()[current_flow_state],
		"last_ollama_delta_k": last_ollama_delta_k,
		"last_mamay_tip": last_mamay_tip
	}
	f.store_string(JSON.stringify(data, "\t"))

func _load_persistent_profile() -> void:
	if DisplayServer.get_name() == "headless" or not FileAccess.file_exists(PROFILE_PATH):
		return
	var f := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		skill_mu = clampf(float(parsed.get("skill_mu", PRIOR_SKILL_MU)), 0.05, 0.98)
		skill_var = clampf(float(parsed.get("skill_var", PRIOR_SKILL_VAR)), 0.005, 0.30)
		pid_integral = clampf(float(parsed.get("pid_integral", 0.0)), -PID_INTEGRAL_MAX, PID_INTEGRAL_MAX)
		pid_prev_error = clampf(float(parsed.get("pid_prev_error", 0.0)), -1.0, 1.0)
		last_ollama_delta_k = clampf(float(parsed.get("last_ollama_delta_k", 0.0)), -MAX_OLLAMA_DELTA, MAX_OLLAMA_DELTA)
		last_mamay_tip = String(parsed.get("last_mamay_tip", ""))

# ============================================================================
# SYSTEM 1: АСИНХРОННИЙ ЕВРИСТИЧНИЙ РАДНИК OLLAMA (RELEVANCE ONLY, FAIL-SAFE)
# ============================================================================
func _request_ollama_heuristic_evaluation(episode: Dictionary) -> void:
	var http := HTTPRequest.new()
	http.timeout = ollama_timeout_s
	add_child(http)
	http.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		http.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
			return
		var resp_text := body.get_string_from_utf8()
		var outer = JSON.parse_string(resp_text)
		if not (outer is Dictionary) or not outer.has("response"):
			return
		var inner = JSON.parse_string(String(outer["response"]))
		if inner is Dictionary:
			_apply_validated_ollama_advice(inner)
	)
	
	var prompt := (
		"Ти — мудрий Козак Мамай, евристичний аналітик дитячої аркадної гри 'Geek Jack: Джура'. " +
		"Проаналізуй телеметрію рівня гравця: " + JSON.stringify(episode) + ". " +
		"Поверни СУВОРО JSON з полями: " +
		"{\"delta_k\": число від -0.12 до 0.12, \"focus\": \"more_allies\"|\"more_brawlers\"|\"calm_pace\"|\"speed_challenge\", " +
		"\"mamay_tip\": \"коротка тепла порада Джурі українською мовою до 90 символів\"}."
	)
	var payload := JSON.stringify({
		"model": ollama_model,
		"prompt": prompt,
		"format": "json",
		"stream": false,
		"options": {"temperature": 0.2, "num_predict": 120}
	})
	http.request(ollama_endpoint, ["Content-Type: application/json"], HTTPClient.Method.METHOD_POST, payload)

## Детермінований шлюз безпеки System 2 для перевірки поради від Ollama:
func _apply_validated_ollama_advice(advice: Dictionary) -> void:
	var raw_delta := float(advice.get("delta_k", 0.0))
	if is_nan(raw_delta) or is_inf(raw_delta):
		raw_delta = 0.0
	# Жорстке відсікання System 2: жодна галюцинація LLM не може змінити K більше ніж на ±0.12
	last_ollama_delta_k = clampf(raw_delta, -MAX_OLLAMA_DELTA, MAX_OLLAMA_DELTA)
	var tip := String(advice.get("mamay_tip", "")).strip_edges()
	if tip.length() > 0 and tip.length() <= 140:
		last_mamay_tip = tip
	_save_persistent_profile()
	ollama_advice_received.emit({
		"delta_k": last_ollama_delta_k,
		"focus": String(advice.get("focus", "balanced")),
		"mamay_tip": last_mamay_tip
	})
