extends SceneTree
# SWR-001-02 / SHR-001 I-2 (прохідність): кожна платформа й кожне ядро рівнів 1–5 досяжні для Джури.
# Консервативна модель: стрибок на повну висоту, горизонтальна швидкість SPEED сталa протягом польоту
# (без планерування, змахів і підкрутки в повітрі); платформи суцільні (без підківок Вакули; «тверда стеля»).
# Константи беруться з коду гри (player.gd, game_manager.gd), а не копіюються.

const DT := 1.0 / 60.0
const MAX_STEPS := 240
const HALF_W := 9.0     # половина ширини колайдера Джури (18x38, центр зсунуто на -3)
const FEET := 16.0      # від центру тіла до ступень
const HEAD := 22.0      # від центру тіла до тімені
const PLAT_H := 12.0
const WALL_L := 0.0
const WALL_R := 960.0
const CEIL_Y := 30.0    # нижня грань стелі (позиція 20, висота 20)
const FLOOR_TOP := 510.0
const SAMPLE_STEP := 6.0
const BOMB_R := 11.0
const SAFETY := 2.0

var speed: float
var jump_v: float
var gravity: float

func _initialize() -> void:
	var pc: Dictionary = load("res://scripts/player.gd").get_script_constant_map()
	var gc: Dictionary = load("res://scripts/game_manager.gd").get_script_constant_map()
	speed = pc["SPEED"]; jump_v = pc["JUMP_VELOCITY"]; gravity = pc["NORMAL_GRAVITY"]
	print("--- Прохідність рівнів (SPEED=%s, JUMP=%s, g=%s) ---" % [speed, jump_v, gravity])
	var failed := false
	for level in gc["LEVEL_PLATFORMS"].keys():
		var res := _check_level(gc["LEVEL_PLATFORMS"][level], gc["LEVEL_BOMBS"][level])
		print("Рівень %d: платформ %d (недосяжних %d), ядер %d (недосяжних %d)" % [level, res.plats, res.bad_plats.size(), res.bombs, res.bad_bombs.size()])
		for b in res.bad_plats: print("   недосяжна платформа: ", b)
		for b in res.bad_bombs: print("   недосяжне ядро: ", b)
		if not res.bad_plats.is_empty() or not res.bad_bombs.is_empty():
			failed = true
	if failed:
		printerr("[FAIL] є недосяжні платформи або ядра")
		quit(1)
	else:
		print("[OK] усі платформи й ядра досяжні")
		quit(0)

# Поверхні: індекс 0 = підлога, далі платформи. Rect2 тіла платформи для зіткнень.
func _check_level(plats: Array, bombs: Array) -> Dictionary:
	var rects: Array[Rect2] = [Rect2(WALL_L, FLOOR_TOP, WALL_R - WALL_L, 30.0)]
	for p in plats:
		var pos: Vector2 = p["pos"]; var w: float = p["width"]
		rects.append(Rect2(pos.x - w * 0.5, pos.y - PLAT_H * 0.5, w, PLAT_H))
	var reach := {0: true}
	var visited_positions: Array[Vector2] = []
	var changed := true
	while changed:
		changed = false
		for s in reach.keys():
			for land in _launches(rects, s, false):
				if not reach.has(land):
					reach[land] = true
					changed = true
	# ядра: усі позиції польотів і ходьби з досяжних поверхонь
	for s in reach.keys():
		_launches(rects, s, true, visited_positions)
	var bad_plats: Array = []
	for i in range(1, rects.size()):
		if not reach.has(i):
			bad_plats.append("#%d x=%.0f..%.0f y=%.0f" % [i, rects[i].position.x, rects[i].end.x, rects[i].position.y + PLAT_H * 0.5])
	var bad_bombs: Array = []
	for b in bombs:
		if not _collectable(b, visited_positions):
			bad_bombs.append(b)
	return {"plats": plats.size(), "bombs": bombs.size(), "bad_plats": bad_plats, "bad_bombs": bad_bombs}

func _collectable(bomb: Vector2, positions: Array[Vector2]) -> bool:
	for p in positions:
		var body := Rect2(p.x - HALF_W, p.y - HEAD, HALF_W * 2.0, HEAD + FEET)
		var cx := clampf(bomb.x, body.position.x, body.end.x)
		var cy := clampf(bomb.y, body.position.y, body.end.y)
		if Vector2(cx, cy).distance_to(bomb) <= BOMB_R - SAFETY:
			return true
	return false

# Усі зльоти з поверхні s: повертає індекси поверхонь, на які можна приземлитись.
func _launches(rects: Array[Rect2], s: int, record: bool, out: Array[Vector2] = []) -> Array:
	var lands: Array = []
	var top := rects[s].position.y
	var x0 := rects[s].position.x
	var x1 := rects[s].end.x
	var x := x0
	while x <= x1 + 0.01:
		var cx := clampf(x, WALL_L + HALF_W, WALL_R - HALF_W)
		if record:
			out.append(Vector2(cx, top - FEET)) # стоїть/йде по поверхні
		for dir in [-1.0, 0.0, 1.0]:
			var l := _simulate(rects, Vector2(cx, top - FEET), dir * speed, jump_v, s, record, out)
			if l >= 0: lands.append(l)
		x += SAMPLE_STEP
	# зійти з краю без стрибка
	for edge in [[x0 - HALF_W - 0.5, -1.0], [x1 + HALF_W + 0.5, 1.0]]:
		var ex: float = edge[0]
		if ex > WALL_L + HALF_W and ex < WALL_R - HALF_W:
			var l := _simulate(rects, Vector2(ex, top - FEET), edge[1] * speed, 0.0, s, record, out)
			if l >= 0: lands.append(l)
	return lands

func _simulate(rects: Array[Rect2], start: Vector2, vx: float, vy: float, from: int, record: bool, out: Array[Vector2]) -> int:
	var p := start
	var v := Vector2(vx, vy)
	for step in MAX_STEPS:
		v.y += gravity * DT
		# X
		p.x = clampf(p.x + v.x * DT, WALL_L + HALF_W, WALL_R - HALF_W)
		var body := Rect2(p.x - HALF_W, p.y - HEAD, HALF_W * 2.0, HEAD + FEET)
		for i in rects.size():
			if i == 0 and p.y + FEET > FLOOR_TOP: continue
			var r := rects[i]
			if i == from and absf((p.y + FEET) - r.position.y) < 0.5: continue
			if body.intersects(r.grow(-0.01)):
				p.x = p.x - v.x * DT
				break
		# Y
		var prev_feet := p.y + FEET
		p.y += v.y * DT
		body = Rect2(p.x - HALF_W, p.y - HEAD, HALF_W * 2.0, HEAD + FEET)
		if record: out.append(p)
		if v.y < 0.0 and p.y - HEAD < CEIL_Y:
			p.y = CEIL_Y + HEAD; v.y = 0.0
		for i in rects.size():
			var r := rects[i]
			if not body.grow(-SAFETY * 0.0).intersects(r): continue
			if v.y >= 0.0 and prev_feet <= r.position.y + 0.5 and body.end.x - SAFETY > r.position.x and body.position.x + SAFETY < r.end.x:
				if i == from and step < 3: continue
				return i
			elif v.y < 0.0 and p.y - HEAD < r.end.y and prev_feet - (HEAD + FEET) >= r.end.y - 0.5:
				p.y = r.end.y + HEAD; v.y = 0.0
	return -1
