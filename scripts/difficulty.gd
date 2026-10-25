extends RefCounted
# Прогресія складності та введення нових NPC (SHR-001 I-1, I-7; GDD «Прогресія рівнів»).
# Чисті функції без стану: легко тестуються (test/test_difficulty_coefficient.gd) і не залежать від сцени.

const SERIES_LENGTH: int = 5          # рівнів в акті (серії): 4 акти = базова кампанія
const CAMPAIGN_LEVELS: int = 20       # базова кампанія (рішення власника 2026-10-24); далі — ескалація без стелі за сюжетом
const ESCALATION_STEP: float = 0.12   # приріст бази складності за кожні 5 рівнів після кампанії (лінійно, швидше за log)
const SERIES_GROWTH: float = 0.35     # зростання бази за серіями: 1 + 0.35 · log2(1 + номер_серії) (повільніше за лінійне)
const PAR_TIME_S: float = 90.0        # «еталонний» час проходження рівня (калібрується плейтестами, див. телеметрію)
const K_MIN: float = 0.5               # низ діапазону: слабкий гравець (вік 8, новачок) має куди спускатися
const K_MAX: float = 2.5
const QUALITY_BASE: float = 0.7       # множник коефіцієнта за якості 0: 0.7; за 0.5: 1.0; за 1: 1.3 (±30%)
const QUALITY_SWING: float = 0.6
const QUALITY_SMOOTHING: float = 0.5  # згладжування якості між рівнями (середнє ковзне)
const QUALITY_DEAD_ZONE: float = 0.08 # навколо нейтральної якості рівень не змінюється
const MAX_EXTRA_ENEMIES: int = 4
const MAX_ALIVE_ENEMIES: int = 12     # стеля одночасних ворогів у арені 960×540
const RELIEF_BELOW_K: float = 0.85    # нижче цього K слабкому гравцеві прибирається один ворог
const NEUTRAL_QUALITY: float = 0.5    # якість «до першого рівня»: коефіцієнт рівня 1 = 1.0

# План введення NPC базової кампанії: кожен із 20 рівнів вводить щонайменше одного нового NPC (ворога чи союзника).
# Рівні 1–5 реалізовано й перевіряється складом гри; рівні 6–20 — план (чини москалів і найманці Орди існують у коді,
# але ще не розставлені за цим планом; NPC_PLANNED ще не реалізовано). Див. LEVEL_PROGRESSION_STORY_8PLUS.md.
const NPC_INTRO: Dictionary = {
	1: ["VOGNYK"],
	2: ["VOGNYK_SPARK"],
	3: ["CHORT"],
	4: ["VOGNYK_EMBER"],
	5: ["VIDMA"],
	6: ["MOSKAL_SHYSH", "QIRIMLI"],
	7: ["MOSKAL_DYAK"],
	8: ["MOSKAL_OPRYCHNYK"],
	9: ["MOSKAL_VOYEVODA"],
	10: ["MOSKAL_TSAR_GENERAL"],
	11: ["HUTSUL", "MONGOL_NUKER"],
	12: ["MAVKA", "MONGOL_SHAMAN"],
	13: ["ZLYDNI"],
	14: ["BASAVRIUK"],
	15: ["DOMOVYK"],
	16: ["KOBZAR"],
	17: ["VAKULA"],
	18: ["VIJ"],
	19: ["VIDMAK"],
	20: ["FINAL_BOSS"],
}
const NPC_PLANNED: Array[String] = []

static func series_index(level: int) -> int:
	return maxi(0, (level - 1) / SERIES_LENGTH)

static func is_escalation(level: int) -> bool:
	return level > CAMPAIGN_LEVELS

# База складності: у кампанії (рівні 1–20) зростає повільніше за лінійне (log2 за актами), після кампанії
# наростає лінійно далі (ескалація), безперервно й монотонно
static func series_base(level: int) -> float:
	var act := mini(series_index(level), series_index(CAMPAIGN_LEVELS))
	var base := 1.0 + SERIES_GROWTH * log(1.0 + float(act)) / log(2.0)
	if is_escalation(level):
		base += ESCALATION_STEP * float(level - CAMPAIGN_LEVELS) / float(SERIES_LENGTH)
	return base

static func ally_first_level(kind: String) -> int:
	for lvl in NPC_INTRO.keys():
		if kind in NPC_INTRO[lvl]:
			return lvl
	return 999

static func ally_available(kind: String, level: int) -> bool:
	return level >= ally_first_level(kind)

# Якість проходження 0..1: швидкість (40%), відсутність ударів (40%), серія запалених ядер (20%)
static func quality(time_s: float, hits: int, max_lit_streak: int) -> float:
	var speed_q := clampf((PAR_TIME_S * 1.5 - time_s) / (PAR_TIME_S * 0.9), 0.0, 1.0)
	var hit_q := clampf(1.0 - 0.34 * float(hits), 0.0, 1.0)
	var streak_q := clampf(float(max_lit_streak - 1) / 7.0, 0.0, 1.0)
	return 0.4 * speed_q + 0.4 * hit_q + 0.2 * streak_q

# Згладжена якість: середнє ковзне між попередніми рівнями й новим результатом (один невдалий рівень не обвалює складність)
static func smooth_quality(prev_smoothed: float, new_quality: float) -> float:
	return prev_smoothed + QUALITY_SMOOTHING * (clampf(new_quality, 0.0, 1.0) - prev_smoothed)

# Якість із мертвою зоною навколо нейтральної: безперервно, без стрибка
static func effective_quality(q: float) -> float:
	var d := clampf(q, 0.0, 1.0) - NEUTRAL_QUALITY
	if absf(d) <= QUALITY_DEAD_ZONE:
		return NEUTRAL_QUALITY
	return NEUTRAL_QUALITY + signf(d) * (absf(d) - QUALITY_DEAD_ZONE) / (NEUTRAL_QUALITY - QUALITY_DEAD_ZONE) * NEUTRAL_QUALITY

# Коефіцієнт складності рівня: зростає з серіями й підлаштовується під (згладжену) якість проходження
static func coefficient(level: int, quality_smoothed: float) -> float:
	return clampf(series_base(level) * (QUALITY_BASE + QUALITY_SWING * effective_quality(quality_smoothed)), K_MIN, K_MAX)

# Зміна кількості ворогів відносно базового складу: + для сильних, −1 для слабких (K < RELIEF_BELOW_K), −2 для дуже слабких (K < 0,65);
# базовий склад із новим NPC не зменшується (видаляється лише дубль типу)
static func extra_enemies(base_count: int, k: float) -> int:
	if k < 0.65:
		return -2
	if k < RELIEF_BELOW_K:
		return -1
	return clampi(int(round(float(base_count) * (k - 1.0))), 0, MAX_EXTRA_ENEMIES)

# Швидкість ворогів («частота»): +50% від надлишку коефіцієнта
static func speed_multiplier(k: float) -> float:
	return clampf(1.0 + 0.5 * (k - 1.0), 0.7, 1.6)

# Поріг (ядер) для прибуття союзника: допомога приходить раніше і за вищої складності (більше ворогів),
# і слабкому гравцеві (низька якість); ніколи пізніше, ніж у сильного
static func ally_threshold(base: int, k: float, quality_smoothed: float) -> int:
	var help := sqrt(maxf(k, 1.0)) * (1.0 + 0.6 * (NEUTRAL_QUALITY - clampf(quality_smoothed, 0.0, 1.0)))
	return maxi(1, int(round(float(base) / help)))

# Затримка (с) повернення переможеного ворога («частота» ворогів); −1: без повернення (K ≈ 1 і нижче)
static func respawn_delay(k: float) -> float:
	if k <= 1.05:
		return -1.0
	return clampf(14.0 / (k - 1.0), 8.0, 90.0)

# Третій гуцул прибуває лише за високої складності
static func allows_third_hutsul(k: float) -> bool:
	return k >= 1.5

# Бонус за проходження: якість (до 5000), швидкість (50 очок за кожну секунду під еталон), бездоганність (+1000)
static func bonus_points(time_s: float, hits: int, q: float) -> int:
	var b := int(round(q * 5000.0)) + int(maxf(0.0, PAR_TIME_S - time_s)) * 50
	if hits == 0:
		b += 1000
	return b
