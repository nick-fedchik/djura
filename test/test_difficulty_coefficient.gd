extends SceneTree
# SHR-001 I-7: коефіцієнт складності зростає з серіями рівнів (повільніше за лінійне) і підлаштовується під згладжену
# якість проходження; слабкий гравець отримує полегшення й ранішу допомогу; бонуси за швидкість і якість.
const D = preload("res://scripts/difficulty.gd")

func _fail(msg: String) -> void:
	printerr("[FAIL] ", msg)
	quit(1)

func _initialize() -> void:
	print("--- Коефіцієнт складності ---")
	if not is_equal_approx(D.coefficient(1, D.NEUTRAL_QUALITY), 1.0):
		return _fail("рівень 1 із нейтральною якістю має давати коефіцієнт 1.0")
	# зростання за серіями (та сама якість), але повільніше за лінійне
	for q in [0.0, 0.5, 1.0]:
		var prev := 0.0
		for series in range(0, 8):
			var k := D.coefficient(1 + series * D.SERIES_LENGTH, q)
			if k < prev:
				return _fail("коефіцієнт має зростати з серіями (q=%s, серія %d)" % [q, series])
			prev = k
	# у кампанії приріст за акт сповільнюється (log); ескалація лінійна й повільніша за стартовий приріст
	var a1 := D.series_base(6) - D.series_base(1)
	var a2 := D.series_base(11) - D.series_base(6)
	var a3 := D.series_base(16) - D.series_base(11)
	if not (a1 > a2 and a2 > a3):
		return _fail("приріст за акт кампанії має сповільнюватися (%.3f, %.3f, %.3f)" % [a1, a2, a3])
	# базова кампанія 20 рівнів: коефіцієнт не спадає від рівня до рівня (для кожної якості), після 20 — ескалація, що строго зростає
	for q in [0.0, 0.5, 1.0]:
		var prev_k := 0.0
		for lvl in range(1, 61):
			var k := D.coefficient(lvl, q)
			if k + 1e-9 < prev_k:
				return _fail("коефіцієнт не має спадати між рівнями (рівень %d, q=%s)" % [lvl, q])
			if lvl > D.CAMPAIGN_LEVELS and k < D.K_MAX - 1e-6 and k <= prev_k:
				return _fail("після кампанії складність має наростати (рівень %d, q=%s)" % [lvl, q])
			prev_k = k
	if D.series_base(20) > D.series_base(21) or absf(D.series_base(21) - D.series_base(20) - D.ESCALATION_STEP / D.SERIES_LENGTH) > 1e-9:
		return _fail("ескалація має починатися безперервно після рівня 20")
	if not D.is_escalation(21) or D.is_escalation(20):
		return _fail("ескалація починається з рівня 21")
	# середній гравець не впирається в стелю раніше за рівень 45 (ескалація довга)
	if D.coefficient(45, 0.5) >= D.K_MAX:
		return _fail("середній гравець не має впиратися в стелю складності раніше рівня 45")
	# зростання за якістю (той самий рівень)
	for level in [1, 3, 7, 12, 30]:
		var prev := 0.0
		for q in [0.0, 0.25, 0.5, 0.75, 1.0]:
			var k := D.coefficient(level, q)
			if k < prev:
				return _fail("кращий гравець має отримувати не легший рівень (рівень %d, q=%s)" % [level, q])
			prev = k
	# діапазон адаптивності: ±30% навколо бази серії
	var lo := D.coefficient(1, 0.0)
	var hi := D.coefficient(1, 1.0)
	if lo > 0.75 or hi < 1.25:
		return _fail("діапазон адаптивності замалий: %.2f…%.2f" % [lo, hi])
	# мертва зона навколо нейтральної якості: безперервна й без впливу
	if D.coefficient(1, 0.5 - D.QUALITY_DEAD_ZONE) != D.coefficient(1, 0.5 + D.QUALITY_DEAD_ZONE):
		return _fail("у мертвій зоні коефіцієнт не має змінюватися")
	# межі
	if D.coefficient(1000, 1.0) > D.K_MAX or D.coefficient(1, -5.0) < D.K_MIN:
		return _fail("коефіцієнт поза межами K_MIN..K_MAX")
	# згладжування якості: один невдалий рівень не обвалює середнє
	var sm := D.smooth_quality(0.8, 0.0)
	if sm <= 0.3 or sm >= 0.8:
		return _fail("згладжування має зсувати якість частково (%.2f)" % sm)
	# вороги: сильним більше, слабким на одного менше, стеля
	if D.extra_enemies(7, 1.0) != 0:
		return _fail("за K = 1 змін складу немає")
	if D.extra_enemies(7, 0.8) != -1 or D.extra_enemies(7, 0.55) != -2:
		return _fail("слабкому гравцеві прибирається один ворог (K < 0,9), дуже слабкому два (K < 0,65)")
	if D.extra_enemies(7, 2.5) != D.MAX_EXTRA_ENEMIES:
		return _fail("кількість додаткових ворогів обмежена MAX_EXTRA_ENEMIES")
	if D.extra_enemies(2, 1.3) < 1:
		return _fail("адаптивність має бути помітна вже в першій серії (2 вороги, K=1.3)")
	# швидкість зростає
	if D.speed_multiplier(1.0) != 1.0 or D.speed_multiplier(2.0) <= D.speed_multiplier(1.2):
		return _fail("швидкість ворогів має зростати з коефіцієнтом")
	# допомога: слабкому гравцеві не пізніше, ніж сильному; складніше й слабше → раніше; поріг ≥ 1
	for k in [0.8, 1.0, 1.5, 2.2]:
		for base in [2, 3, 4]:
			if D.ally_threshold(base, k, 0.2) > D.ally_threshold(base, k, 0.8):
				return _fail("слабкий гравець не має отримувати допомогу пізніше за сильного (K=%s, base=%d)" % [k, base])
	if D.ally_threshold(4, 2.0, 0.5) >= D.ally_threshold(4, 1.0, 0.5) or D.ally_threshold(1, 5.0, 0.0) < 1:
		return _fail("за вищої складності допомога раніше, але поріг не менший за 1")
	if D.allows_third_hutsul(1.0) or not D.allows_third_hutsul(1.6):
		return _fail("третій гуцул лише за високої складності")
	# частота: без повернення за K ≤ 1.05; далі швидше зі зростанням K; у межах
	if D.respawn_delay(1.0) >= 0.0 or D.respawn_delay(1.05) >= 0.0:
		return _fail("за K ≈ 1 вороги не повертаються")
	if D.respawn_delay(2.0) >= D.respawn_delay(1.3) or D.respawn_delay(1.3) > 90.0 or D.respawn_delay(2.5) < 8.0:
		return _fail("повернення ворогів має прискорюватися з K в межах 8…90 с")
	# якість і бонуси
	var best := D.quality(D.PAR_TIME_S * 0.5, 0, 8)
	var worst := D.quality(D.PAR_TIME_S * 2.0, 5, 1)
	if best < 0.99 or worst > 0.01:
		return _fail("якість: найкраще має бути ≈1, найгірше ≈0 (%.2f / %.2f)" % [best, worst])
	if D.quality(60.0, 0, 5) <= D.quality(120.0, 0, 5) or D.quality(60.0, 0, 5) <= D.quality(60.0, 2, 5):
		return _fail("швидкість і відсутність ударів мають підвищувати якість")
	var fast_flawless := D.bonus_points(50.0, 0, best)
	var slow_hit := D.bonus_points(200.0, 3, worst)
	if fast_flawless <= slow_hit or slow_hit != 0:
		return _fail("бонус за швидке й бездоганне проходження має бути більшим; за повільне й невдале 0 (%d / %d)" % [fast_flawless, slow_hit])
	# замкнена модель: Q = skill − 0.35·(K−1) сходиться без розгойдування; K розрізняє гравців
	var ks := {}
	for skill in [0.3, 0.6, 0.9]:
		var q := 0.5
		var k := 1.0
		var hist: Array = []
		for lvl in range(1, 16):
			k = D.coefficient(lvl, q)
			q = D.smooth_quality(q, clampf(skill - 0.35 * (k - 1.0), 0.0, 1.0))
			hist.append(k)
		ks[skill] = k
		for i in range(1, hist.size()):
			if absf(hist[i] - hist[i - 1]) > 0.5:
				return _fail("коефіцієнт розгойдується (skill=%s)" % skill)
	if not (ks[0.3] < ks[0.6] and ks[0.6] < ks[0.9]) or ks[0.9] - ks[0.3] < 0.3:
		return _fail("коефіцієнт має помітно розрізняти слабкого й сильного гравця (%s)" % ks)
	print("[OK] k(1)=%.2f; діапазон у серії 1: %.2f…%.2f; k(рівень 15): слабкий %.2f, середній %.2f, сильний %.2f; бонус швидкого бездоганного %d" % [D.coefficient(1, 0.5), lo, hi, ks[0.3], ks[0.6], ks[0.9], fast_flawless])
	quit(0)
