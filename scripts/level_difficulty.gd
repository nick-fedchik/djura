extends RefCounted
# Статична оцінка складності рівня за геометрією (SWR-002-06): до появи даних гравців дає апріорний зсув b у логітах.
# Детермінована; константи беруться з коду гри. Емпіричну калібровку див. tools/analyze_telemetry.py.

const FLOOR_TOP: float = 510.0
const SCALE: float = 0.15   # розмах зсуву між етапами (логіти): помітно, але не штовхає «середнього» гравця в полегшення

static func _consts() -> Dictionary:
	var pc: Dictionary = load("res://scripts/player.gd").get_script_constant_map()
	var gc: Dictionary = load("res://scripts/game_manager.gd").get_script_constant_map()
	return {"jump": pc["JUMP_VELOCITY"], "g": pc["NORMAL_GRAVITY"], "plats": gc["LEVEL_PLATFORMS"], "bombs": gc["LEVEL_BOMBS"]}

# Показники геометрії етапу: висота найбільшого кроку відносно стрибка, середня ширина платформ, кількість і висота ядер
static func metrics(stage: int) -> Dictionary:
	var c := _consts()
	var jump_h: float = float(c["jump"]) * float(c["jump"]) / (2.0 * float(c["g"]))
	var tops: Array[float] = [FLOOR_TOP]
	var widths: Array[float] = []
	for p in c["plats"][stage]:
		tops.append(float(p["pos"].y) - 6.0)
		widths.append(float(p["width"]))
	tops.sort()
	tops.reverse()   # від підлоги вгору
	var max_step := 0.0
	for i in range(1, tops.size()):
		max_step = maxf(max_step, tops[i - 1] - tops[i])
	var mean_w := 0.0
	for w in widths:
		mean_w += w
	mean_w /= maxf(widths.size(), 1)
	var high_bombs := 0
	for b in c["bombs"][stage]:
		if b.y < 160.0:
			high_bombs += 1
	return {"step_ratio": max_step / jump_h, "mean_width": mean_w, "bombs": c["bombs"][stage].size(), "high_bombs": high_bombs, "jump_h": jump_h}

static func raw_score(stage: int) -> float:
	var m := metrics(stage)
	return 1.2 * float(m["step_ratio"]) + 0.8 * (1.0 - float(m["mean_width"]) / 300.0) + 0.6 * float(m["high_bombs"]) / 8.0

# Зсув складності етапу в логітах: нульова середня за етапами серії, розмах ±SCALE·z
static func offset(stage: int) -> float:
	var raws: Array[float] = []
	var mean := 0.0
	for s in range(1, 6):
		raws.append(raw_score(s))
		mean += raws[-1]
	mean /= 5.0
	var var_sum := 0.0
	for r in raws:
		var_sum += (r - mean) * (r - mean)
	var sd := maxf(sqrt(var_sum / 5.0), 1e-6)
	return SCALE * (raws[clampi(stage, 1, 5) - 1] - mean) / sd
