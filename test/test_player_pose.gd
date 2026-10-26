extends SceneTree
# COD-01: Pose.compute (винесено з player.gd). Еталонний хеш 600 поз зафіксовано після перевірки, що стара
# реалізація `_compute_skeletal_pose` давала ті самі словники на тих самих станах (test від 2026-10-26).
const GOLDEN_HASH := 2524235364
const PlayerScene = preload("res://scripts/player.gd")
const Pose = preload("res://scripts/player_pose.gd")


func _fail(msg: String) -> void:
	printerr("[FAIL] ", msg)
	quit(1)


func _initialize() -> void:
	print("--- Скелетна поза Джури (COD-01) ---")
	var p: JackPlayer = PlayerScene.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var skills := JackPlayer.ChampionSkill.values()
	var checked := 0
	var acc := ""
	for i in 600:
		p.is_hopak = rng.randf() < 0.3
		p.hopak_waiting_for_floor = rng.randf() < 0.2
		p.hopak_time = rng.randf() * 1.6
		p.is_rolling = rng.randf() < 0.2
		p.roll_timer = rng.randf() * 0.36
		p.roll_dir = 1.0 if rng.randf() < 0.5 else -1.0
		p.squat_timer = rng.randf() * 0.3
		p.is_gliding = rng.randf() < 0.2
		p.is_fast_dropping = rng.randf() < 0.1
		p.flap_timer = rng.randf() * 0.3
		p.bonk_timer = rng.randf() * 0.4
		p.punch_timer = rng.randf() * 0.5 if rng.randf() < 0.6 else 0.0
		p.punch_active_skill = skills[rng.randi() % skills.size()]
		p.punch_facing = 1.0 if rng.randf() < 0.5 else -1.0
		p.time_passed = rng.randf() * 20.0
		p.velocity = Vector2(rng.randf_range(-300.0, 300.0), rng.randf_range(-500.0, 500.0))
		p.unlocked_skills.clear()
		for s in skills:
			if rng.randf() < 0.5:
				p.unlocked_skills.append(s)
		var flip := 1.0 if rng.randf() < 0.5 else -1.0
		var run := rng.randf_range(-1.0, 1.0)
		var ground := rng.randf() < 0.6
		acc += str(Pose.compute(p, flip, run, ground))
		checked += 1
	var h := acc.hash()
	if h != GOLDEN_HASH:
		return _fail("хеш поз %d != еталонного %d" % [h, GOLDEN_HASH])
	print("[OK] %d випадкових станів: поза збігається з еталоном" % checked)
	p.free()
	print("--- POSE PASSED ---")
	quit(0)
