extends SceneTree
# SWR-001-04 / SHR-001 I-4 (Anti-Clipping): ріжки чортика не пронизують голову.
#  1) основа ріжка лежить усередині овала голови неглибоко (її закриває тіло, зазору немає);
#  2) середина і кінчик лежать поза овалом, тобто ріг виходить назовні, а не йде крізь голову;
#  3) ріжки розходяться в сторони: кінчик далі від осі, ніж основа;
#  4) у коді ріжки малюються ПЕРЕД тілом (позаду нього).

func _inside_head(p: Vector2, bob: float) -> float:
	var q := p - Vector2(0.0, bob)
	return (q.x * q.x) / (FolkloreEnemy.CHORT_HEAD_RX * FolkloreEnemy.CHORT_HEAD_RX) + (q.y * q.y) / (FolkloreEnemy.CHORT_HEAD_RY * FolkloreEnemy.CHORT_HEAD_RY)

func _fail(msg: String) -> void:
	printerr("[FAIL] ", msg)
	quit(1)

func _initialize() -> void:
	print("--- Anti-Clipping: ріжки чортика ---")
	for fwd in [1.0, -1.0]:
		for bob in [-2.0, 0.0, 2.0]:
			for jiggle in [0.0, 1.5, -1.5]:
				var horns := FolkloreEnemy.chort_horn_points(fwd, bob, jiggle)
				if horns.size() != 2:
					return _fail("очікується 2 ріжки")
				for h in horns:
					var base_k := _inside_head(h[0], bob)
					if base_k > 1.0 or base_k < 0.35:
						return _fail("основа ріжка має бути неглибоко всередині голови (k=%.2f, fwd=%s, bob=%s)" % [base_k, fwd, bob])
					if _inside_head(h[1], bob) <= 1.0 or _inside_head(h[2], bob) <= 1.0:
						return _fail("середина й кінчик ріжка мають бути поза головою (fwd=%s, bob=%s, jiggle=%s)" % [fwd, bob, jiggle])
					if absf(h[2].x) <= absf(h[0].x):
						return _fail("ріжок має розходитися в сторону")
	var src := FileAccess.get_file_as_string("res://scripts/enemy.gd")
	var fn := src.find("func _draw_chort()")
	var horns_at := src.find("chort_horn_points(fwd, bob, jiggle)", fn)
	var body_at := src.find("_draw_oval(Vector2(0, bob), CHORT_HEAD_RX, CHORT_HEAD_RY", fn)
	if fn < 0 or horns_at < 0 or body_at < 0 or horns_at > body_at:
		return _fail("ріжки мають малюватися до тіла")
	# Перевірка нових NPC рівнів 13–20 (T-023: ZLYDNI, BASAVRIUK, VIJ, VIDMAK, FINAL_BOSS, DOMOVYK, KOBZAR, VAKULA)
	var mavka_script = load("res://scripts/mavka_ally.gd")
	var new_checks := [
		["ZLYDNI", Callable(FolkloreEnemy, "zlydni_ear_points"), Vector2(0.0, -3.0), FolkloreEnemy.ZLYDNI_HEAD_RX, FolkloreEnemy.ZLYDNI_HEAD_RY, "func _draw_zlydni()", "zlydni_ear_points", "ZLYDNI_HEAD_RX", src],
		["BASAVRIUK", Callable(FolkloreEnemy, "basavriuk_horn_points"), Vector2(0.0, -3.5), FolkloreEnemy.BASAVRIUK_HEAD_RX, FolkloreEnemy.BASAVRIUK_HEAD_RY, "func _draw_basavriuk()", "basavriuk_horn_points", "BASAVRIUK_HEAD_RX", src],
		["VIJ", Callable(FolkloreEnemy, "vij_brow_points"), Vector2(0.0, 2.0), FolkloreEnemy.VIJ_HEAD_RX, FolkloreEnemy.VIJ_HEAD_RY, "func _draw_vij()", "vij_brow_points", "VIJ_HEAD_RX", src],
		["VIDMAK", Callable(FolkloreEnemy, "vidmak_wrench_points"), Vector2(0.0, -4.5), FolkloreEnemy.VIDMAK_HEAD_RX, FolkloreEnemy.VIDMAK_HEAD_RY, "func _draw_vidmak()", "vidmak_wrench_points", "VIDMAK_HEAD_RX", src],
		["FINAL_BOSS", Callable(FolkloreEnemy, "boss_crown_points"), Vector2(0.0, -3.0), FolkloreEnemy.BOSS_HEAD_RX, FolkloreEnemy.BOSS_HEAD_RY, "func _draw_final_boss()", "boss_crown_points", "BOSS_HEAD_RX", src],
	]
	var mavka_src := FileAccess.get_file_as_string("res://scripts/mavka_ally.gd")
	var ally_checks := [
		["DOMOVYK", Callable(mavka_script, "domovyk_ears_points"), Vector2(0.0, -9.0), mavka_script.ALLY_HEAD_RX, mavka_script.ALLY_HEAD_RY, "func _draw_domovyk()", "domovyk_ears_points", "ALLY_HEAD_RX", mavka_src],
		["KOBZAR", Callable(mavka_script, "kobzar_bandura_points"), Vector2(0.0, -9.0), mavka_script.ALLY_HEAD_RX, mavka_script.ALLY_HEAD_RY, "func _draw_kobzar()", "kobzar_bandura_points", "ALLY_HEAD_RX", mavka_src],
		["VAKULA", Callable(mavka_script, "vakula_hammer_points"), Vector2(0.0, -9.0), mavka_script.ALLY_HEAD_RX, mavka_script.ALLY_HEAD_RY, "func _draw_vakula()", "vakula_hammer_points", "ALLY_HEAD_RX", mavka_src],
	]
	for item in new_checks + ally_checks:
		var npc_name: String = item[0]
		var cb: Callable = item[1]
		var center0: Vector2 = item[2]
		var rx: float = item[3]
		var ry: float = item[4]
		var fn_sig: String = item[5]
		var pts_call: String = item[6]
		var body_call: String = item[7]
		var code_str: String = item[8]
		for fwd in [1.0, -1.0]:
			for bob in [-1.5, 0.0, 1.5]:
				var parts: Array = cb.call(fwd, bob)
				if parts.size() != 2:
					return _fail("%s: очікується 2 симетричні виступи" % npc_name)
				for p in parts:
					var q0: Vector2 = p[0] - (center0 + Vector2(0.0, bob))
					var k0 := (q0.x * q0.x) / (rx * rx) + (q0.y * q0.y) / (ry * ry)
					var q1: Vector2 = p[1] - (center0 + Vector2(0.0, bob))
					var k1 := (q1.x * q1.x) / (rx * rx) + (q1.y * q1.y) / (ry * ry)
					var q2: Vector2 = p[2] - (center0 + Vector2(0.0, bob))
					var k2 := (q2.x * q2.x) / (rx * rx) + (q2.y * q2.y) / (ry * ry)
					if k0 > 1.0 or k0 < 0.25:
						return _fail("%s: основа виступу поза контуром голови (k=%.2f)" % [npc_name, k0])
					if k1 <= 1.0 or k2 <= 1.0 or absf(p[2].x) <= absf(p[0].x):
						return _fail("%s: середина й кінчик мають виходити назовні" % npc_name)
		var f_idx := code_str.find(fn_sig)
		var p_idx := code_str.find(pts_call, f_idx)
		var b_idx := code_str.find(body_call, f_idx)
		if f_idx < 0 or p_idx < 0 or b_idx < 0 or p_idx > b_idx:
			return _fail("%s: виступи мають малюватися до голови/тіла" % npc_name)
	print("[OK] ріжки та виступи всіх нових NPC (Чортик, Злидні, Басаврюк, Вій, Відьмак, Бос, Домовик, Кобзар, Вакула): основа під тілом, кінчики назовні, позаду тіла")
	quit(0)
