extends SceneTree
# ADP-01/04/05/06: параметри профілю (CLI/URL), буферизація запису телеметрії, інваріант K.
const T = preload("res://scripts/telemetry.gd")
const GM = preload("res://scripts/game_manager.gd")
const TE = preload("res://scripts/telemetry_engine.gd")

const TMP_PATH := "user://test_adp_tmp/events.jsonl"


func _fail(msg: String) -> void:
	printerr("[FAIL] ", msg)
	quit(1)


func _initialize() -> void:
	print("--- Профіль, буферизація телеметрії, інваріант K (ADP-01/04/05/06) ---")

	# ADP-01/06: валідація параметрів профілю
	var ok := GM._validate_profile_params({"age": "8-10", "exp": "novice", "seed": "42"})
	if ok.get("age") != "8-10" or ok.get("exp") != "novice" or ok.get("seed") != 42:
		return _fail("коректні параметри мають проходити: %s" % [ok])
	var bad := GM._validate_profile_params({"age": "7", "exp": "pro", "seed": "x1"})
	if not bad.is_empty():
		return _fail("некоректні параметри мають відкидатися: %s" % [bad])
	print("[OK] параметри профілю валідуються")

	# ADP-04: 100 подій за 4 с дають не більше одного відкриття файлу
	var t := T.new("testpid")
	t.path = TMP_PATH
	t._last_flush_ms = 0
	for i in 100:
		t.buffer_event({"type": "hit", "level": 1}, 40 * i)  # 0..3960 мс
	if t.file_opens != 0:
		return _fail("до спливу 5 с файл не мав відкриватися, відкриттів: %d" % t.file_opens)
	t.buffer_event({"type": "hit", "level": 1}, 5000)
	if t.file_opens != 1:
		return _fail("через 5 с очікується рівно 1 відкриття, є %d" % t.file_opens)
	t.buffer_event({"type": "level_end", "level": 1}, 5100)
	if t.file_opens != 2:
		return _fail("level_end має скидати буфер одразу")
	var f := FileAccess.open(TMP_PATH, FileAccess.READ)
	var lines := 0
	while f != null and not f.eof_reached():
		if f.get_line() != "":
			lines += 1
	if lines != 102:
		return _fail("у файлі мало бути 102 події, є %d" % lines)
	f.close()
	DirAccess.remove_absolute(TMP_PATH)
	DirAccess.remove_absolute(TMP_PATH.get_base_dir())
	print("[OK] буферизація: 102 події за 2 відкриття файлу")

	# ADP-05: рушій поведінкового аналізу не змінює K
	var src := FileAccess.get_file_as_string("res://scripts/telemetry_engine.gd")
	if src.contains("difficulty_k"):
		return _fail("telemetry_engine.gd не має звертатися до difficulty_k")
	print("[OK] telemetry_engine.gd не торкається difficulty_k")

	print("--- ADP PASSED ---")
	quit(0)
