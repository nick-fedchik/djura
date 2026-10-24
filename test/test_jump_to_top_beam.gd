extends SceneTree

var frame_count: int = 0
var mgr = null

func _init() -> void:
	var main_scene = load("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)
	mgr = main

func _physics_process(delta: float) -> bool:
	frame_count += 1
	if frame_count == 2:
		print("--- Testing Jump Physics & Top Beam Reachability ---")
		var player: JackPlayer = mgr.player
		assert(player != null, "Player must exist")
		
		# Платформи Рівня 1
		# Ліва верхня тераса: pos = Vector2(210, 195), width = 190.0 (краї [115, 305])
		# Центральна найвища балка: pos = Vector2(480, 125), width = 280.0 (краї [340, 620])
		
		# 1. Поставимо Джуру на край лівої тераси (x=290, y=179)
		player.position = Vector2(290, 179)
		player.velocity = Vector2(player.SPEED, player.JUMP_VELOCITY)
		
		var reached_top_beam := false
		
		# Симулюємо політ з урахуванням стелі (y = 52 для ніг гравця)
		var p := player.position
		var v := player.velocity
		
		for step in range(60):
			var dt := 1.0 / 60.0
			# Гравітація з утриманням стрибка
			if v.y < 0:
				v.y += player.NORMAL_GRAVITY * 0.85 * dt
			else:
				v.y += player.NORMAL_GRAVITY * dt
			
			p += v * dt
			
			# Стеля (колізія: верх тіла y-22 <= 30 => p.y <= 52)
			if p.y <= 52.0:
				p.y = 52.0
				v.y = 0.0 # М'яке ковзання вздовж стелі, горизонтальна швидкість зберігається!
			
			# Перевірка приземлення на верхню балку (x in [340, 620], y in [105, 125])
			if p.x >= 340.0 and p.x <= 620.0 and p.y >= 105.0 and p.y <= 130.0 and v.y >= 0.0:
				reached_top_beam = true
				print("[SUCCESS] Dzhura landed smoothly on top beam at x=%.1f, y=%.1f!" % [p.x, p.y])
				break
		
		print("[OK] Jump from side terrace to top beam reached: %s" % reached_top_beam)
		assert(reached_top_beam, "Dzhura must smoothly reach top beam from side terrace with ceiling sliding!")
		
		# 2. Тест: Стрибок напряму знизу з тераси y=275 на y=125
		player.position = Vector2(480, 259)
		var p_vert := player.position.y
		var v_vert := player.JUMP_VELOCITY
		var min_y := p_vert
		for step in range(40):
			var dt := 1.0 / 60.0
			v_vert += player.NORMAL_GRAVITY * 0.85 * dt
			p_vert += v_vert * dt
			if p_vert < min_y:
				min_y = p_vert
			if v_vert >= 0:
				break
		
		print("[OK] Direct vertical jump from y=275 reaches peak y=%.1f (Target beam top is at y=119.0)" % min_y)
		assert(min_y <= 119.0, "Vertical jump must rise above top beam!")
		
		print("--- ALL TOP BEAM REACHABILITY TESTS PASSED! ---")
		quit(0)
		return true
	return false
