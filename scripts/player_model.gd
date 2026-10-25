extends RefCounted
# Модель гравця й адаптація складності (SHR-003, SWR-002, ADR-002): байєсівський фільтр вміння (гауссівська
# щільність у логітах), ціль «потоку», бандит (Thompson sampling) для інтересу, детектори нудьги й фрустрації,
# контролер із обмеженням швидкості зміни. Детерміновано: рішення залежать від збереженого стану й зерна.

const D = preload("res://scripts/difficulty.gd")

const TARGETS: Dictionary = {"novice": 0.78, "casual": 0.70, "experienced": 0.62}   # цільове очікуване виконання p*
const AGE_PRIOR: Dictionary = {"8-10": -0.6, "11-14": 0.0, "15+": 0.3}              # апріорне вміння за віком (логіти)
const EXP_PRIOR: Dictionary = {"novice": -0.5, "casual": 0.0, "experienced": 0.8}
const AGE_K_MAX: Dictionary = {"8-10": 1.8, "11-14": 2.2, "15+": 2.5}             # стеля складності за віком (SHR-003 A-7)
const BASE_PRIOR: float = 0.85          # logit(0.70): «середній» гравець 11–14 років починає з K = 1,0
const FIRST_LEVEL_K: Vector2 = Vector2(0.7, 1.3)   # перший рівень — навчальний: без різких стартів
const SIGMA2_0: float = 1.0
const SIGMA2_MAX: float = 1.5
const PROCESS_NOISE: float = 0.06       # дисперсія навчання гравця за рівень (швидше стежимо за зростанням вміння)
const MIN_VAR_P: float = 0.02
const SLEW: float = 0.25                # макс. зміна K за рівень
const CURRICULUM_BETA: float = 0.3      # вага повільної навчальної кривої (база серії)
const ARMS: Array[float] = [-0.5, 0.0, 0.5]   # зсув цілі (логіти): м'якше / як є / складніше
const BANDIT_DISCOUNT: float = 0.97     # забування (нестаціонарність інтересу)
const FLOW_Q_LOW: float = 0.30
const FLOW_Q_HIGH: float = 0.92

var age_band: String = "11-14"
var experience: String = "casual"
var player_id: String = ""
var mu: float = 0.0
var sigma2: float = SIGMA2_0
var k_prev: float = -1.0        # <0: ще не рекомендували
var k_before: float = -1.0
var levels_played: int = 0
var consecutive_up: int = 0
var frustration: float = 0.0
var boredom: float = 0.0
var arm: int = 1
var arm_alpha: Array[float] = [1.0, 1.0, 1.0]
var arm_beta: Array[float] = [1.0, 1.0, 1.0]
var level_offset_prev: float = 0.0
var rng_seed: int = 1
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

static func logistic(x: float) -> float:
	return 1.0 / (1.0 + exp(-x))

static func logit(p: float) -> float:
	var q := clampf(p, 0.001, 0.999)
	return log(q / (1.0 - q))

func setup(age: String, exp_level: String, seed_value: int = 1, pid: String = "") -> void:
	age_band = age if AGE_PRIOR.has(age) else "11-14"
	experience = exp_level if EXP_PRIOR.has(exp_level) else "casual"
	player_id = pid
	mu = BASE_PRIOR + float(AGE_PRIOR[age_band]) + float(EXP_PRIOR[experience])
	sigma2 = SIGMA2_0
	rng_seed = seed_value
	_rng.seed = seed_value

func k_cap() -> float:
	return minf(D.K_MAX, float(AGE_K_MAX[age_band]))

# Ціль виконання: за профілем, з поправкою на нудьгу (складніше) й фрустрацію (легше)
func target_success() -> float:
	return clampf(float(TARGETS[experience]) + 0.08 * frustration - 0.06 * boredom, 0.5, 0.9)

func _gamma(shape: float) -> float:
	if shape < 1.0:
		return _gamma(shape + 1.0) * pow(maxf(_rng.randf(), 1e-9), 1.0 / shape)
	var d := shape - 1.0 / 3.0
	var c := 1.0 / sqrt(9.0 * d)
	for _i in 200:
		var x := _rng.randfn(0.0, 1.0)
		var v := pow(1.0 + c * x, 3.0)
		if v <= 0.0:
			continue
		var u := maxf(_rng.randf(), 1e-12)
		if log(u) < 0.5 * x * x + d - d * v + d * log(v):
			return d * v
	return d

func _beta_sample(a: float, b: float) -> float:
	var ga := _gamma(a)
	var gb := _gamma(b)
	return ga / maxf(ga + gb, 1e-12)

# Thompson sampling: вибір руки (зсуву цілі) за постеріорами винагороди «потоку»
func choose_arm() -> int:
	var best := 0
	var best_s := -1.0
	for i in ARMS.size():
		var s := _beta_sample(arm_alpha[i], arm_beta[i])
		if s > best_s:
			best_s = s
			best = i
	arm = best
	return arm

# Рекомендований коефіцієнт складності рівня. level_offset — статичний зсув рівня в логітах (level_difficulty.gd).
func recommend(level: int, level_offset: float = 0.0) -> float:
	if levels_played == 0:
		arm = 1   # без даних не експериментуємо: нейтральна рука
	else:
		choose_arm()
	var b_star := mu - logit(target_success()) + ARMS[arm] + CURRICULUM_BETA * (log(D.series_base(level)) / log(2.0))
	var k := pow(2.0, b_star - level_offset)
	var cap := k_cap()
	k = clampf(k, D.K_MIN, cap)
	if levels_played == 0:
		k = clampf(k, FIRST_LEVEL_K.x, FIRST_LEVEL_K.y)
	if k_prev > 0.0:
		k = clampf(k, k_prev - SLEW, k_prev + SLEW)
		if consecutive_up >= 2 and frustration > 0.5:
			k = minf(k, k_prev)   # не підвищувати втретє поспіль, поки гравець фрустрований
	k = clampf(k, D.K_MIN, cap)
	k_before = k_prev
	if k_prev > 0.0 and k > k_prev + 1e-6:
		consecutive_up += 1
	elif k_prev > 0.0:
		consecutive_up = 0
	k_prev = k
	level_offset_prev = level_offset
	return k

# Індекси нудьги й фрустрації з результату рівня (детерміновані, 0..1)
static func frustration_index(hits: int, time_s: float, par_s: float, completed: bool) -> float:
	# Один удар і помірна повільність — норма; фрустрація — повторні удари й дуже довге проходження
	var f := 0.5 * clampf(float(hits - 1) / 2.0, 0.0, 1.0) + 0.5 * clampf((time_s / par_s - 1.4) / 0.8, 0.0, 1.0)
	return clampf(f + (0.0 if completed else 0.4), 0.0, 1.0)

static func boredom_index(quality: float, hits: int, time_s: float, par_s: float) -> float:
	if hits > 0:
		return 0.0
	var fast := clampf((0.8 - time_s / par_s) / 0.3, 0.0, 1.0)
	return clampf((quality - 0.85) / 0.15, 0.0, 1.0) * fast

# Спостереження результату рівня: оновлення вміння, індексів і бандита (interest_bonus — ознака інтересу з telemetry_engine.gd)
func observe(quality: float, hits: int, time_s: float, completed: bool = true, interest_bonus: float = 0.0) -> Dictionary:
	var b := log(maxf(k_prev, 0.01)) / log(2.0) + level_offset_prev
	var p := logistic(mu - b)
	var v := maxf(p * (1.0 - p), MIN_VAR_P)
	var y := clampf(quality, 0.0, 1.0)
	var post := sigma2 / (1.0 + sigma2 * v)
	var p_pred := p
	mu += post * (y - p)
	sigma2 = minf(post + PROCESS_NOISE, SIGMA2_MAX)
	frustration = frustration_index(hits, time_s, D.PAR_TIME_S, completed)
	boredom = boredom_index(y, hits, time_s, D.PAR_TIME_S)
	var flow := completed and y >= FLOW_Q_LOW and y <= FLOW_Q_HIGH and hits <= 2 and time_s <= 2.0 * D.PAR_TIME_S
	var reward := clampf((1.0 if flow else (0.3 if completed else 0.0)) + interest_bonus, 0.0, 1.0)
	for i in ARMS.size():
		arm_alpha[i] = 1.0 + (arm_alpha[i] - 1.0) * BANDIT_DISCOUNT
		arm_beta[i] = 1.0 + (arm_beta[i] - 1.0) * BANDIT_DISCOUNT
	arm_alpha[arm] += reward
	arm_beta[arm] += 1.0 - reward
	levels_played += 1
	return {"p_pred": p_pred, "mu": mu, "sigma": sqrt(sigma2), "reward": reward, "frustration": frustration, "boredom": boredom, "arm": arm}

# Гравець залишив рівень: сильний негативний сигнал (низька якість, фрустрація, нульова винагорода)
func observe_abandon(elapsed_s: float) -> Dictionary:
	return observe(0.1, 3, maxf(elapsed_s, D.PAR_TIME_S), false)

func to_dict() -> Dictionary:
	return {"v": 1, "age_band": age_band, "experience": experience, "player_id": player_id, "mu": mu, "sigma2": sigma2,
		"k_prev": k_prev, "levels_played": levels_played, "consecutive_up": consecutive_up, "frustration": frustration, "boredom": boredom,
		"arm": arm, "arm_alpha": arm_alpha, "arm_beta": arm_beta, "rng_seed": rng_seed, "rng_state": str(_rng.state), "level_offset_prev": level_offset_prev}

func from_dict(d: Dictionary) -> void:
	setup(str(d.get("age_band", "11-14")), str(d.get("experience", "casual")), int(d.get("rng_seed", 1)), str(d.get("player_id", "")))
	mu = clampf(float(d.get("mu", mu)), -4.0, 4.0)
	sigma2 = clampf(float(d.get("sigma2", sigma2)), 0.01, SIGMA2_MAX)
	k_prev = float(d.get("k_prev", -1.0))
	levels_played = int(d.get("levels_played", 0))
	consecutive_up = int(d.get("consecutive_up", 0))
	frustration = clampf(float(d.get("frustration", 0.0)), 0.0, 1.0)
	boredom = clampf(float(d.get("boredom", 0.0)), 0.0, 1.0)
	arm = clampi(int(d.get("arm", 1)), 0, ARMS.size() - 1)
	level_offset_prev = float(d.get("level_offset_prev", 0.0))
	var a: Array = d.get("arm_alpha", [1.0, 1.0, 1.0])
	var bb: Array = d.get("arm_beta", [1.0, 1.0, 1.0])
	if a.size() == ARMS.size() and bb.size() == ARMS.size():
		for i in ARMS.size():
			arm_alpha[i] = clampf(float(a[i]), 0.5, 200.0)
			arm_beta[i] = clampf(float(bb[i]), 0.5, 200.0)
	_rng.state = int(str(d.get("rng_state", str(_rng.state))))
