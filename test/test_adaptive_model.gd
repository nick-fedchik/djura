extends SceneTree
# SWR-002-01..06: байєсівська модель, бандит, детектори, захисні межі, телеметрія, статична складність. Симуляція синтетичних гравців.
const PM = preload("res://scripts/player_model.gd")
const T = preload("res://scripts/telemetry.gd")
const LD = preload("res://scripts/level_difficulty.gd")
const D = preload("res://scripts/difficulty.gd")

func _fail(msg: String) -> void:
	printerr("[FAIL] ", msg)
	quit(1)

# Синтетичний гравець: справжнє вміння θ (з навчанням), результат = σ(θ − b) + шум; удари й час із виконання
func _play(model, theta: float, level: int, rng: RandomNumberGenerator, learn: float) -> Dictionary:
	var off := LD.offset((level - 1) % 5 + 1)
	var k: float = model.recommend(level, off)
	var b := log(k) / log(2.0) + off
	var p := PM.logistic(theta - b)
	var q := clampf(p + rng.randfn(0.0, 0.08), 0.0, 1.0)
	var hits := int(round((1.0 - q) * 4.0))
	var time_s: float = D.PAR_TIME_S * (1.6 - 0.9 * q)
	var res: Dictionary = model.observe(q, hits, time_s, true)
	res["k"] = k
	res["p"] = p
	res["theta"] = theta + learn
	return res

func _initialize() -> void:
	print("--- Адаптивна модель гравця ---")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	# 1) збіжність: p ≈ ціль за профілем незалежно від справжнього вміння (середнє останніх 10 рівнів із 40)
	var rows: Array = []
	for exp_level in ["novice", "casual", "experienced"]:
		for theta0 in [-1.5, 0.0, 1.5]:
			var m := PM.new()
			m.setup("11-14", exp_level, 11)
			var theta: float = theta0
			var ps: Array[float] = []
			var ks: Array[float] = []
			for lvl in range(1, 41):
				var r := _play(m, theta, lvl, rng, 0.02)
				theta = r["theta"]
				if lvl > 10:
					ps.append(r["p"])
				ks.append(r["k"])
			var mean_p := 0.0
			for x in ps: mean_p += x
			mean_p /= ps.size()
			var target: float = PM.TARGETS[exp_level]
			rows.append([exp_level, theta0, mean_p, ks[-1]])
			# допуск ±0.12 (бандит додає ±0.5 логіта, K обмежений межами); межі K можуть заважати крайнім гравцям
			var bounded: bool = ks[-1] <= m.k_cap() + 1e-6 and ks[-1] >= D.K_MIN - 1e-6
			if not bounded:
				return _fail("K поза межами (%s, θ0=%s)" % [exp_level, theta0])
			print("    ", exp_level, theta0, " p=", snappedf(mean_p, 0.01), " K=", snappedf(ks[-1], 0.01))
			var at_limit: bool = ks[-1] >= m.k_cap() - 0.02 or ks[-1] <= D.K_MIN + 0.02
			if not at_limit and absf(mean_p - target) > 0.12:
				return _fail("p не сходиться до цілі %.2f: %.2f (%s, θ0=%s)" % [target, mean_p, exp_level, theta0])
	for r in rows:
		print("  профіль %s, θ0=%+.1f: середнє p=%.2f, K=%.2f" % r)
	# 2) K монотонний за вмінням: сильніший гравець отримує не легший рівень
	var k_by_theta: Array[float] = []
	for theta0 in [-1.5, -0.5, 0.5, 1.5]:
		var m2 := PM.new()
		m2.setup("11-14", "casual", 3)
		var rng2 := RandomNumberGenerator.new()
		rng2.seed = 5
		var th: float = theta0
		var last_k := 0.0
		for lvl in range(1, 21):
			var r2 := _play(m2, th, lvl, rng2, 0.0)
			last_k = r2["k"]
		k_by_theta.append(last_k)
	for i in range(1, k_by_theta.size()):
		if k_by_theta[i] + 0.02 < k_by_theta[i - 1]:
			return _fail("K має бути монотонним за вмінням: %s" % [k_by_theta])
	# 3) обмеження швидкості зміни, межі за віком і відсутність розгойдування (випадкові послідовності)
	var worst_step := 0.0
	for seed_i in range(20):
		var rng3 := RandomNumberGenerator.new()
		rng3.seed = 100 + seed_i
		var m3 := PM.new()
		m3.setup(["8-10", "11-14", "15+"][seed_i % 3], ["novice", "casual", "experienced"][seed_i % 3], seed_i)
		var prev := -1.0
		for lvl in range(1, 31):
			var k: float = m3.recommend(lvl, LD.offset((lvl - 1) % 5 + 1))
			if prev > 0.0:
				worst_step = maxf(worst_step, absf(k - prev))
			if k > m3.k_cap() + 1e-6 or k < D.K_MIN - 1e-6:
				return _fail("K поза межами віку (вік %s)" % m3.age_band)
			prev = k
			m3.observe(rng3.randf(), rng3.randi_range(0, 4), rng3.randf_range(30.0, 200.0), rng3.randf() > 0.1)
	if worst_step > PM.SLEW + 1e-6:
		return _fail("перевищено обмеження швидкості зміни: %.3f" % worst_step)
	# 4) бандит: гравець, якому «подобається» складніше, зрештою віддає перевагу відповідній руці
	var rng4 := RandomNumberGenerator.new()
	rng4.seed = 9
	var m4 := PM.new()
	m4.setup("15+", "casual", 21)
	var counts := [0, 0, 0]
	for lvl in range(1, 121):
		m4.recommend(lvl, 0.0)
		counts[m4.arm] += 1
		# синтетична «цікавість»: найкраща рука 2 (складніше), потім 1, найгірша 0
		var reward_prob: float = [0.15, 0.45, 0.85][m4.arm]
		var flow: bool = rng4.randf() < reward_prob
		m4.arm_alpha[m4.arm] += 1.0 if flow else 0.0
		m4.arm_beta[m4.arm] += 0.0 if flow else 1.0
		m4.levels_played += 1
	if counts[2] <= counts[1] or counts[2] <= counts[0]:
		return _fail("бандит має віддавати перевагу найкращій руці: %s" % [counts])
	# 5) детектори нудьги й фрустрації
	if PM.boredom_index(1.0, 0, 40.0, 90.0) < 0.99 or PM.boredom_index(1.0, 1, 40.0, 90.0) != 0.0:
		return _fail("нудьга: швидке бездоганне проходження має давати високий індекс, удар скидає")
	if PM.frustration_index(3, 200.0, 90.0, true) < 0.99 or PM.frustration_index(0, 50.0, 90.0, true) > 0.01:
		return _fail("фрустрація: удари й повільність підвищують індекс, швидке без ударів ≈ 0")
	var mf := PM.new()
	mf.setup("11-14", "casual", 2)
	mf.recommend(1)
	var before_target: float = mf.target_success()
	mf.observe_abandon(60.0)
	if mf.target_success() <= before_target:
		return _fail("після залишення рівня ціль має стати легшою (вища ймовірність успіху)")
	# 6) збереження/відновлення стану дає однакові подальші рішення
	var ma := PM.new(); ma.setup("8-10", "novice", 4)
	for lvl in range(1, 6):
		ma.recommend(lvl, 0.0); ma.observe(0.5, 1, 80.0)
	var mb := PM.new(); mb.from_dict(ma.to_dict())
	if absf(ma.recommend(6, 0.1) - mb.recommend(6, 0.1)) > 1e-9:
		return _fail("відновлений профіль має давати те саме рішення")
	# 7) телеметрія: білий список ключів, ніяких зайвих даних
	var tel := T.new("abc123")
	var ev := tel.log_event("level_end", {"level": 3, "k": 1.2345678, "player_name": "Ivan", "home_dir": "/home/x", "quality": 0.7})
	if ev.has("player_name") or ev.has("home_dir") or not ev.has("pid") or ev["k"] != 1.235:
		return _fail("телеметрія пропустила зайві ключі: %s" % [ev])
	if not tel.log_event("secret_event").is_empty():
		return _fail("невідомий тип події має відкидатися")
	for key in ev.keys():
		if not (key in T.ALLOWED_KEYS):
			return _fail("ключ поза білим списком: " + key)
	# 8) статична складність: детермінована, нульова середня
	var sum := 0.0
	var offs: Array[float] = []
	for s in range(1, 6):
		offs.append(LD.offset(s))
		sum += offs[-1]
	if absf(sum) > 1e-6:
		return _fail("зсуви етапів мають мати нульову середню")
	print("  статичні зсуви етапів (логіти): ", offs.map(func(x): return snappedf(x, 0.01)))
	# 9) T-C02: вік 8–10, рівні 1–2 — K у зоні комфорту 0.85..1.0, помилка лише м'яко знижує темп (не нижче 0.85)
	for exp_i in ["novice", "casual", "experienced"]:
		for sd in range(1, 9):
			var mk := PM.new(); mk.setup("8-10", exp_i, sd)
			var k1 := mk.recommend(1)
			mk.observe(0.2, 3, 200.0, false)
			var k2 := mk.recommend(2)
			var me := PM.new(); me.setup("8-10", exp_i, sd)
			var e1 := me.recommend(1)
			me.observe(0.7, 0, 70.0)
			var e2 := me.recommend(2)
			for kv in [k1, k2, e1, e2]:
				if kv < D.KID_COMFORT_K.x - 1e-9 or kv > D.KID_COMFORT_K.y + 1e-9:
					return _fail("вік 8–10, рівні 1–2: K=%.3f поза зоною комфорту (%s, зерно %d)" % [kv, exp_i, sd])
			if k2 > k1 + 1e-9:
				return _fail("після помилки K на рівні 2 не має зростати (%.3f → %.3f)" % [k1, k2])
	var mt := PM.new(); mt.setup("8-10", "casual", 3)
	mt.recommend(1); mt.observe(0.2, 3, 200.0, false)
	if mt.arm_beta[mt.arm] <= 1.0 or mt.arm_alpha[mt.arm] < 1.0:
		return _fail("beta-розподіл бандита має оновлюватися після помилки")
	print("[OK] збіжність до цілі, монотонність, межі, бандит, детектори, відновлення профілю, телеметрія, статична складність")
	quit(0)
