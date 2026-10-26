extends SceneTree
# TST-04: димовий тест. Головна сцена живе 120 кадрів, потім кожен із 20 рівнів кампанії
# ініціалізується й відпрацьовує по 15 кадрів. Помилки рушія (ERROR:) у виводі валять запуск
# через tools/run_tests.sh, тож тест ловить збої в _ready/_process/_physics_process та сигналах.
const WARMUP_FRAMES := 120
const FRAMES_PER_LEVEL := 15
const LEVELS := 20

var mgr = null
var frame := 0
var level := 0
var level_frame := 0

func _init() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	mgr = main

func _fail(msg: String) -> void:
	printerr("[FAIL] ", msg)
	quit(1)

func _physics_process(_delta: float) -> bool:
	frame += 1
	if frame < WARMUP_FRAMES:
		return false
	if frame == WARMUP_FRAMES:
		if mgr == null or mgr.level != 1:
			_fail("Головна сцена не ініціалізувала рівень 1")
			return true
		print("[OK] Головна сцена пропрацювала %d кадрів" % WARMUP_FRAMES)
		mgr.adaptive_enabled = false
		level = 1
		level_frame = FRAMES_PER_LEVEL  # одразу перейти до рівня 2 (рівень 1 уже пройдено прогрівом)
	level_frame += 1
	if level_frame > FRAMES_PER_LEVEL:
		level += 1
		if level > LEVELS:
			print("[OK] Усі %d рівнів кампанії відпрацювали по %d кадрів без збоїв" % [LEVELS, FRAMES_PER_LEVEL])
			print("--- SMOKE TEST PASSED ---")
			quit(0)
			return true
		mgr.level = level
		mgr._setup_level()
		if mgr.enemies_node.get_child_count() < 1:
			_fail("Рівень %d без жодного ворога" % level)
			return true
		level_frame = 1
	return false
