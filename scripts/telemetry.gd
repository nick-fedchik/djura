extends RefCounted
# Незалежна локальна телеметрія (SHR-003 A-1, A-6; SWR-002-01). Без мережі, без персональних даних:
# лише події гри за білим списком ключів і випадковий локальний ідентифікатор. У headless-режимі не пишеться.

const SCHEMA_VERSION: int = 1
const MAX_FILE_BYTES: int = 2_000_000
const MAX_STRING_LEN: int = 32
const PATH: String = "user://telemetry/events.jsonl"
const FLUSH_INTERVAL_MS: int = 5000  # ADP-04: не частіше одного відкриття файлу за 5 с
# Події, після яких буфер скидається одразу (кінець рівня/сесії не мають загубитися)
const FLUSH_NOW_TYPES: Array[String] = ["level_end", "abandon", "session_end"]
const ALLOWED_TYPES: Array[String] = [
	"session_start", "level_start", "hit", "bomb", "enemy_defeated", "level_end", "abandon", "session_end"
]
# Єдиний білий список ключів події; усе інше відкидається (захист від випадкового витоку даних)
const ALLOWED_KEYS: Array[String] = [
	"v",
	"t",
	"sid",
	"pid",
	"type",
	"level",
	"k",
	"time_s",
	"hits",
	"streak",
	"quality",
	"bonus",
	"enemies",
	"age_band",
	"experience",
	"mu",
	"sigma",
	"p_pred",
	"reward",
	"arm",
	"target",
	"lit",
	"points",
	"enemy",
	"frustration",
	"boredom",
	"completed",
	"reason",
	"persona",
	"near_misses",
	"strikes",
	"rhythm_cv",
	"idle_ratio",
]

var enabled: bool = true
var session_id: String = ""
var player_id: String = ""
var events: Array[Dictionary] = []  # останні події в пам'яті (для тестів і звітів)
var _t0_ms: int = 0
var _pending: Array[String] = []  # серіалізовані рядки, ще не записані на диск
var _last_flush_ms: int = 0
var path: String = PATH
var file_opens: int = 0  # лічильник відкриттів файлу (для тесту ADP-04)


func _init(pid: String = "") -> void:
	player_id = pid if pid != "" else _random_id()
	session_id = _random_id()
	_t0_ms = Time.get_ticks_msec()
	_last_flush_ms = _t0_ms


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
		buffer_event(e, Time.get_ticks_msec())
	return e


# Кладе подію в буфер і скидає його за таймером або для підсумкових подій (now_ms параметром для тесту)
func buffer_event(e: Dictionary, now_ms: int) -> void:
	_pending.append(JSON.stringify(e))
	if str(e.get("type", "")) in FLUSH_NOW_TYPES or now_ms - _last_flush_ms >= FLUSH_INTERVAL_MS:
		flush(now_ms)


# Записує накопичені події одним відкриттям файлу
func flush(now_ms: int = -1) -> void:
	if _pending.is_empty():
		return
	var lines := _pending
	_pending = []
	_last_flush_ms = now_ms if now_ms >= 0 else Time.get_ticks_msec()
	_append_lines(lines)


func _append_lines(lines: Array[String]) -> void:
	file_opens += 1
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if FileAccess.file_exists(path):
		var size := 0
		var probe := FileAccess.open(path, FileAccess.READ)
		if probe:
			size = probe.get_length()
			probe.close()
		if size > MAX_FILE_BYTES:
			DirAccess.rename_absolute(path, path.get_base_dir() + "/events.1.jsonl")
	var f := FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	for line in lines:
		f.store_line(line)
	f.close()
