extends RefCounted
# Прогресія складності та введення нових NPC (SHR-001 I-1, I-7; GDD «Прогресія рівнів»).
# Чисті функції без стану: легко тестуються (test/test_difficulty_coefficient.gd) і не залежать від сцени.

const SERIES_LENGTH: int = 5          # рівнів у серії; після неї серія повторюється складніше
const SERIES_GROWTH: float = 0.30     # +30% складності за кожну пройдену серію
const PAR_TIME_S: float = 90.0        # «еталонний» час проходження рівня (калібрується плейтестами)
const K_MIN: float = 0.8
const K_MAX: float = 2.5
const MAX_EXTRA_ENEMIES: int = 4
const NEUTRAL_QUALITY: float = 0.5    # якість «до першого рівня»: коефіцієнт рівня 1 = 1.0

# Хто з NPC вперше з'являється на якому рівні серії (ворог чи союзник); кожен рівень вводить щонайменше одного
const NPC_INTRO: Dictionary = {
	1: ["CHORT", "HUTSUL"],
	2: ["VIDMA"],
	3: ["MOSKAL", "QIRIMLI"],
	4: ["VOGNYK"],
	5: ["MAVKA"],
}

static func series_index(level: int) -> int:
	return maxi(0, (level - 1) / SERIES_LENGTH)

static func ally_first_level(kind: String) -> int:
	for lvl in NPC_INTRO.keys():
		if kind in NPC_INTRO[lvl]:
			return lvl
	return 1

static func ally_available(kind: String, level: int) -> bool:
	return level >= ally_first_level(kind)

# Якість проходження 0..1: швидкість (40%), відсутність ударів (40%), серія запалених ядер (20%)
static func quality(time_s: float, hits: int, max_lit_streak: int) -> float:
	var speed_q := clampf((PAR_TIME_S * 1.5 - time_s) / (PAR_TIME_S * 0.9), 0.0, 1.0)
	var hit_q := clampf(1.0 - 0.34 * float(hits), 0.0, 1.0)
	var streak_q := clampf(float(max_lit_streak - 1) / 7.0, 0.0, 1.0)
	return 0.4 * speed_q + 0.4 * hit_q + 0.2 * streak_q

# Коефіцієнт складності рівня: зростає з серіями й підлаштовується під якість проходження попереднього рівня
static func coefficient(level: int, prev_quality: float) -> float:
	var base := 1.0 + SERIES_GROWTH * float(series_index(level))
	return clampf(base * (0.85 + 0.30 * clampf(prev_quality, 0.0, 1.0)), K_MIN, K_MAX)

# Додаткові вороги понад базовий склад рівня (базовий склад із новим NPC не зменшується)
static func extra_enemies(base_count: int, k: float) -> int:
	return clampi(int(round(float(base_count) * (k - 1.0))), 0, MAX_EXTRA_ENEMIES)

# Швидкість ворогів («частота»): +50% від надлишку коефіцієнта
static func speed_multiplier(k: float) -> float:
	return clampf(1.0 + 0.5 * (k - 1.0), 0.85, 1.6)

# Поріг (ядер) для прибуття союзника: чим складніше, тим раніше приходить допомога
static func ally_threshold(base: int, k: float) -> int:
	return maxi(1, int(round(float(base) / k)))

# Третій гуцул прибуває лише за високої складності
static func allows_third_hutsul(k: float) -> bool:
	return k >= 1.5

# Бонус за проходження: якість (до 5000), швидкість (50 очок за кожну секунду під еталон), бездоганність (+1000)
static func bonus_points(time_s: float, hits: int, q: float) -> int:
	var b := int(round(q * 5000.0)) + int(maxf(0.0, PAR_TIME_S - time_s)) * 50
	if hits == 0:
		b += 1000
	return b
