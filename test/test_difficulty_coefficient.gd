extends SceneTree
# SHR-001 I-7: коефіцієнт складності зростає з серіями рівнів і підлаштовується під якість проходження; бонуси за швидкість і якість.
const D = preload("res://scripts/difficulty.gd")

func _fail(msg: String) -> void:
	printerr("[FAIL] ", msg)
	quit(1)

func _initialize() -> void:
	print("--- Коефіцієнт складності ---")
	if not is_equal_approx(D.coefficient(1, D.NEUTRAL_QUALITY), 1.0):
		return _fail("рівень 1 із нейтральною якістю має давати коефіцієнт 1.0")
	# зростання за серіями (та сама якість)
	for q in [0.0, 0.5, 1.0]:
		var prev := 0.0
		for series in range(0, 5):
			var k := D.coefficient(1 + series * D.SERIES_LENGTH, q)
			if k < prev:
				return _fail("коефіцієнт має зростати з серіями (q=%s, серія %d)" % [q, series])
			prev = k
	# зростання за якістю (той самий рівень)
	for level in [1, 3, 7, 12]:
		var prev := 0.0
		for q in [0.0, 0.25, 0.5, 0.75, 1.0]:
			var k := D.coefficient(level, q)
			if k < prev:
				return _fail("кращий гравець має отримувати не легший рівень (рівень %d, q=%s)" % [level, q])
			prev = k
	# межі
	if D.coefficient(1000, 1.0) > D.K_MAX or D.coefficient(1, -5.0) < D.K_MIN:
		return _fail("коефіцієнт поза межами K_MIN..K_MAX")
	# вороги, швидкість, союзники
	if D.extra_enemies(7, 1.0) != 0 or D.extra_enemies(7, 0.8) != 0:
		return _fail("за K ≤ 1 додаткових ворогів немає")
	if D.extra_enemies(7, 2.5) != D.MAX_EXTRA_ENEMIES:
		return _fail("кількість додаткових ворогів обмежена MAX_EXTRA_ENEMIES")
	if D.extra_enemies(7, 1.3) < 1:
		return _fail("серія 2 мусить додавати ворогів")
	if D.speed_multiplier(1.0) != 1.0 or D.speed_multiplier(2.0) <= D.speed_multiplier(1.2):
		return _fail("швидкість ворогів має зростати з коефіцієнтом")
	if D.ally_threshold(4, 2.0) >= D.ally_threshold(4, 1.0) or D.ally_threshold(1, 5.0) < 1:
		return _fail("чим складніше, тим раніше допомога, але поріг не менший за 1")
	if D.allows_third_hutsul(1.0) or not D.allows_third_hutsul(1.6):
		return _fail("третій гуцул лише за високої складності")
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
	print("[OK] k(1)=%.2f k(6,q=.5)=%.2f k(11,q=1)=%.2f; бонус швидкого бездоганного %d" % [D.coefficient(1, 0.5), D.coefficient(6, 0.5), D.coefficient(11, 1.0), fast_flawless])
	quit(0)
