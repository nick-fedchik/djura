extends SceneTree
# SWR-001-03 / SHR-001 I-1: кожен рівень вводить не більше одного нового типу ворога (рішення власника 2026-10-24).
# Типи беруться з реального кадру гри: рівень виставляється, ворогів створює сам game_manager.

var mgr = null

func _initialize() -> void:
	mgr = load("res://scenes/main.tscn").instantiate()
	root.add_child(mgr)
	await process_frame
	await process_frame
	print("--- Крива складності: нові типи ворогів за рівнями ---")
	var seen := {}
	var failed := false
	for level in range(1, 21):
		for e in mgr.enemies_node.get_children():
			mgr.enemies_node.remove_child(e)
			e.free()
		mgr.level = level
		mgr._spawn_folklore_enemies()
		var types := {}
		for e in mgr.enemies_node.get_children():
			types[e.enemy_type] = true
		var fresh: Array = []
		for t in types.keys():
			if not seen.has(t):
				fresh.append(FolkloreEnemy.EnemyType.keys()[t])
				seen[t] = true
		var all_names: Array = []
		for t in types.keys():
			all_names.append(FolkloreEnemy.EnemyType.keys()[t])
		print("Рівень %d: типи %s; нові: %s" % [level, all_names, fresh])
		if fresh.size() > 1:
			failed = true
			printerr("[FAIL] рівень %d вводить %d нових типів ворога (дозволено не більше 1): %s" % [level, fresh.size(), fresh])
	if failed:
		quit(1)
	else:
		print("[OK] жоден рівень не вводить більше одного нового типу ворога")
		quit(0)
