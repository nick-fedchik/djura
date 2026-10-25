extends SceneTree
# SHR-001 I-6 (GDD §1.2): чортики-роботи численні й прості, відьми й відьмаки (їхні інженери) рідкі, міцніші й розумніші.

func _fail(msg: String) -> void:
	printerr("[FAIL] ", msg)
	quit(1)

func _initialize() -> void:
	print("--- Інженери та роботи ---")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	# 1) рідкість: на кожному з 20 рівнів кампанії інженерів (відьом і відьмаків) не більше половини від чортиків
	for level in range(1, 21):
		for e in main.enemies_node.get_children():
			main.enemies_node.remove_child(e)
			e.free()
		main.level = level
		main._spawn_folklore_enemies()
		var chorts := 0
		var vidmas := 0
		for e in main.enemies_node.get_children():
			if e.enemy_type == FolkloreEnemy.EnemyType.CHORT: chorts += 1
			elif e.enemy_type == FolkloreEnemy.EnemyType.VIDMA or e.enemy_type == FolkloreEnemy.EnemyType.VIDMAK: vidmas += 1
		print("Рівень %d: чортиків %d, інженерів (відьом/відьмаків) %d" % [level, chorts, vidmas])
		if vidmas * 2 > chorts:
			return _fail("рівень %d: інженерів (%d) більше половини чортиків (%d)" % [level, vidmas, chorts])
	# 2) міцність: відьма поглинає удари щитом, чортик ні
	var vidma := FolkloreEnemy.new()
	vidma.enemy_type = FolkloreEnemy.EnemyType.VIDMA
	root.add_child(vidma)
	var chort := FolkloreEnemy.new()
	chort.enemy_type = FolkloreEnemy.EnemyType.CHORT
	root.add_child(chort)
	if chort.absorb_strike():
		return _fail("чортик не має щита")
	var absorbed := 0
	while vidma.absorb_strike() and absorbed < 10:
		absorbed += 1
	if absorbed != FolkloreEnemy.VIDMA_ARMOR or absorbed < 2:
		return _fail("відьма має поглинати %d удари(ів), поглинула %d" % [FolkloreEnemy.VIDMA_ARMOR, absorbed])
	# 2б) двофазна броня відьми: перший удар знімає щит, другий — перемагає (щита вже нема)
	if FolkloreEnemy.VIDMA_ARMOR != 2:
		return _fail("VIDMA_ARMOR має дорівнювати 2")
	var vidma2 := FolkloreEnemy.new()
	vidma2.enemy_type = FolkloreEnemy.EnemyType.VIDMA
	root.add_child(vidma2)
	if vidma2.armor != 2:
		return _fail("свіжа відьма має armor == 2, є %d" % vidma2.armor)
	if not vidma2.absorb_strike() or vidma2.armor != 1 or vidma2.is_scared:
		return _fail("перший удар має зняти лише 1 шар броні й не перемогти відьму")
	if not vidma2.absorb_strike() or vidma2.armor != 0:
		return _fail("другий удар має зняти останній шар")
	if vidma2.absorb_strike():
		return _fail("третій удар має пройти крізь зруйнований щит (поразка)")
	# 2в) чортик-злодій скидає ядро і панікує 2.5 с, тікаючи від гравця
	var thief := FolkloreEnemy.new()
	thief.enemy_type = FolkloreEnemy.EnemyType.CHORT
	root.add_child(thief)
	var drops: Array = []
	thief.stolen_artifact_dropped.connect(func(p: Vector2): drops.append(p))
	if chort.strike_thief(1.0):
		return _fail("чортик без ядра не є злодієм")
	thief.apply_stolen_artifact_buff()
	thief.velocity = Vector2(-100.0, 0.0)
	if not thief.strike_thief(1.0):
		return _fail("удар по злодію має бути оброблено")
	if drops.size() != 1 or thief.has_stolen_artifact:
		return _fail("злодій мав скинути ядро рівно один раз")
	if not thief.is_scared or not is_equal_approx(thief.scared_timer, 2.5):
		return _fail("злодій мав запанікувати на 2.5 с")
	if thief.velocity.x <= 0.0:
		return _fail("злодій має тікати геть від гравця (удар зліва → вправо)")
	print("[OK] броня відьми двофазна; чортик-злодій скидає ядро й панікує")
	# 3) цінність: відьма вартує більше, ніж чортик (500)
	if FolkloreEnemy.VIDMA_REWARD <= 600:
		return _fail("нагорода за відьму має перевищувати нагороду за чортика й москаля")
	print("[OK] відьми рідкі, міцніші (щит %d) і цінніші (%d очок)" % [FolkloreEnemy.VIDMA_ARMOR, FolkloreEnemy.VIDMA_REWARD])
	quit(0)
