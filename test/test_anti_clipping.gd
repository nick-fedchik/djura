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
	print("[OK] ріжки: основа під тілом, кінчики назовні, малюються позаду тіла")
	quit(0)
