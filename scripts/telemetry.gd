extends RefCounted
# Незалежна локальна телеметрія (SHR-003 A-1, A-6; SWR-002-01). Без мережі, без персональних даних:
# лише події гри за білим списком ключів і випадковий локальний ідентифікатор. У headless-режимі не пишеться.

const SCHEMA_VERSION: int = 1
const MAX_FILE_BYTES: int = 2_000_000
const MAX_STRING_LEN: int = 32
const PATH: String = "user://telemetry/events.jsonl"
const ALLOWED_TYPES: Array[String] = ["session_start", "level_start", "hit", "bomb", "enemy_defeated", "level_end", "abandon", "session_end"]
# Єдиний білий список ключів події; усе інше відкидається (захист від випадкового витоку даних)
const ALLOWED_KEYS: Array[String] = [
	"v", "t", "sid", "pid", "type", "level", "k", "time_s", "hits", "streak", "quality", "bonus", "enemies",
	"age_band", "experience", "mu", "sigma", "p_pred", "reward", "arm", "target", "lit", "points", "enemy",
	"frustration", "boredom", "completed", "reason",
]

var enabled: bool = true
var session_id: String = ""
var player_id: String = ""
var events: Array[Dictionary] = []   # останні події в пам'яті (для тестів і звітів)
var _t0_ms: int = 0

func _init(pid: String = "") -> void:
	player_id = pid if pid != "" else _random_id()
	session_id = _random_id()
	_t0_ms = Time.get_ticks_msec()

static func _random_id() -> String:
	var c := Crypto.new()
	return c.generate_random_bytes(8).hex_encode()

static func is_headless() -> bool:
	return DisplayServer.get_name() == "headless"

# Залишає лише дозволені ключі й прості типи; рядки обрізає
static func sanitize(event: Dictionary) -> Dictionary:
	var out := {}
	for key in event.keys():
		if not (key in ALLOWED_KEYS):
			continue
		var v = event[key]
		match typeof(v):
			TYPE_INT, TYPE_BOOL:
				out[key] = v
			TYPE_FLOAT:
				out[key] = snappedf(v, 0.001)
			TYPE_STRING:
				out[key] = String(v).substr(0, MAX_STRING_LEN)
	return out

func log_event(type: String, fields: Dictionary = {}) -> Dictionary:
	if not (type in ALLOWED_TYPES):
		return {}
	var e := {"v": SCHEMA_VERSION, "t": Time.get_ticks_msec() - _t0_ms, "sid": session_id, "pid": player_id, "type": type}
	e.merge(fields, true)
	e = sanitize(e)
	events.append(e)
	if events.size() > 500:
		events.pop_front()
	if enabled and not is_headless():
		_append_to_file(e)
	return e

func _append_to_file(e: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(PATH.get_base_dir())
	if FileAccess.file_exists(PATH):
		var size := 0
		var probe := FileAccess.open(PATH, FileAccess.READ)
		if probe:
			size = probe.get_length()
			probe.close()
		if size > MAX_FILE_BYTES:
			DirAccess.rename_absolute(PATH, PATH.get_base_dir() + "/events.1.jsonl")
	var f := FileAccess.open(PATH, FileAccess.READ_WRITE if FileAccess.file_exists(PATH) else FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line(JSON.stringify(e))
	f.close()
