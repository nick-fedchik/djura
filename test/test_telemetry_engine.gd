extends SceneTree
# T-024: поведінковий трекер TelemetryEngine (класифікація типу гравця, лічильники дій, ритмічність,
# ознака інтересу для бандита player_model.gd, поради Козака Мамая, єдина схема телеметрії telemetry.gd).
const TE = preload("res://scripts/telemetry_engine.gd")
const T = preload("res://scripts/telemetry.gd")
const PM = preload("res://scripts/player_model.gd")

func _fail(msg: String) -> void:
	printerr("[FAIL] ", msg)
	quit(1)

func _initialize() -> void:
	print("--- Поведінковий трекер TelemetryEngine (T-024) ---")
	# 1) Класифікатор усіх 5 персон гравця
	var p_kid := TE.classify_player_persona({"clear_time_s": 135.0, "hits": 3, "lit_ratio": 0.25, "strikes": 2, "enemies_defeated": 0, "idle_ratio": 0.22, "bonks": 0})
	var p_speed := TE.classify_player_persona({"clear_time_s": 46.0, "hits": 0, "lit_ratio": 0.65, "strikes": 4, "enemies_defeated": 2, "idle_ratio": 0.01, "bonks": 0})
	var p_brawl := TE.classify_player_persona({"clear_time_s": 72.0, "hits": 1, "lit_ratio": 0.40, "strikes": 16, "enemies_defeated": 5, "idle_ratio": 0.02, "bonks": 1})
	var p_combo := TE.classify_player_persona({"clear_time_s": 78.0, "hits": 1, "lit_ratio": 0.85, "strikes": 3, "enemies_defeated": 1, "idle_ratio": 0.03, "bonks": 0})
	var p_story := TE.classify_player_persona({"clear_time_s": 82.0, "hits": 1, "lit_ratio": 0.45, "strikes": 4, "enemies_defeated": 1, "idle_ratio": 0.06, "bonks": 1})
	if p_kid != TE.PlayerPersona.YOUNG_COSSACK_8PLUS or p_speed != TE.PlayerPersona.ARCADE_SPEEDRUNNER \
		or p_brawl != TE.PlayerPersona.COMBAT_BRAWLER or p_combo != TE.PlayerPersona.COMBO_STRATEGIST \
		or p_story != TE.PlayerPersona.STORY_EXPLORER:
		return _fail("класифікатор персони дав хибний результат: %s" % [[p_kid, p_speed, p_brawl, p_combo, p_story]])

	# 2) Метрики ритму та ознака інтересу для бандита
	var r_steady := TE.compute_rhythm_metrics([2.5, 2.5, 2.5, 2.5])
	var r_erratic := TE.compute_rhythm_metrics([0.5, 9.0, 0.4, 11.0])
	if float(r_steady["rhythm_score"]) <= float(r_erratic["rhythm_score"]):
		return _fail("рівномірний темп збору ядер має давати вищий rhythm_score")
	var sig_engaged := TE.interest_signal({"rhythm_score": 0.95, "near_misses": 4, "lit_ratio": 0.80, "idle_ratio": 0.01})
	var sig_idle := TE.interest_signal({"rhythm_score": 0.20, "near_misses": 0, "lit_ratio": 0.10, "idle_ratio": 0.65})
	if sig_engaged <= 0.0 or sig_idle >= 0.0 or absf(sig_engaged) > 0.20 + 1e-6 or absf(sig_idle) > 0.20 + 1e-6:
		return _fail("ознака інтересу поза межами або неправильний знак: %.3f / %.3f" % [sig_engaged, sig_idle])

	# 3) Лічильники вузла, порада Мамая та інтеграція зі схемою telemetry.gd і player_model.gd
	var te := TE.new()
	te.begin_level_tracking(1)
	for _i in 6:
		te.record_punch()
		te.record_kick()
		te.record_bomb_picked(true)
	te.record_enemy_defeated()
	var summary := te.summarize_level_episode(68.0, 1)
	if summary["strikes"] != 12 or String(summary["mamay_tip"]).is_empty():
		return _fail("підсумок рівня має рахувати удари й генерувати пораду Мамая: %s" % [summary])
	te.free()

	# 3а) Поради Наставника щодо механік Етапу 1 (T-C01)
	var tip_l1 := TE.mamay_mechanic_tip(1, {})
	var tip_l2 := TE.mamay_mechanic_tip(2, {})
	if tip_l1.is_empty() or tip_l1 != tip_l2 or not ("сім секунд" in tip_l1 and "БАХ" in tip_l1):
		return _fail("поради рівнів 1–2 мають згадувати 7 секунд до «БАХ!»: %s" % [tip_l1])
	for lvl in [3, 4]:
		var tip_k := TE.mamay_mechanic_tip(lvl, {"glides": 0})
		if not ("кирея" in tip_k.to_lower() or "киреї" in tip_k.to_lower()) or not ("утримуй" in tip_k):
			return _fail("порада рівня %d має пояснювати ширяння на киреї: %s" % [lvl, tip_k])
		if not TE.mamay_mechanic_tip(lvl, {"glides": 3}).is_empty():
			return _fail("порада про кирею не потрібна, якщо гравець уже ширяє (рівень %d)" % lvl)
	var tip_l5 := TE.mamay_mechanic_tip(5, {})
	if not ("Котигорошк" in tip_l5 and "Булав" in tip_l5):
		return _fail("порада рівня 5 має згадувати Котигорошка й Булаву: %s" % [tip_l5])
	for banned in ["джеб", "хук", "оверхенд", "аперкот", "сліп", "деш", "комбо"]:
		for t in [tip_l1, tip_l5, TE.mamay_mechanic_tip(3, {})]:
			if banned in t.to_lower():
				return _fail("англіцизм «%s» у пораді: %s" % [banned, t])

	var tel := T.new("p_test")
	var ev := tel.log_event("level_end", {
		"level": 1, "k": 1.0, "persona": summary["persona"], "near_misses": summary["near_misses"],
		"strikes": summary["strikes"], "rhythm_cv": summary["rhythm_cv"], "idle_ratio": summary["idle_ratio"]
	})
	for k_name in ["persona", "near_misses", "strikes", "rhythm_cv", "idle_ratio"]:
		if not ev.has(k_name):
			return _fail("telemetry.gd відкинув ключ %s: %s" % [k_name, ev])

	var pm := PM.new()
	pm.setup("11-14", "casual", 5)
	pm.recommend(1, 0.0)
	var obs := pm.observe(0.6, 1, 70.0, true, float(summary["interest_bonus"]))
	if float(obs["reward"]) < 0.0 or float(obs["reward"]) > 1.0:
		return _fail("винагорода бандита поза [0, 1]")

	print("[OK] класифікація 5 персон, ритмічність, ознака інтересу бандита, поради Мамая, єдина схема телеметрії")
	quit(0)
