extends SceneTree
# SHR-001 I-1/I-7: кожен рівень серії вводить нового NPC; коефіцієнт складності впливає на склад рівня та допомогу.
const D = preload("res://scripts/difficulty.gd")
var mgr = null

func _fail(msg: String) -> void:
	printerr("[FAIL] ", msg)
	quit(1)

func _initialize() -> void:
	mgr = load("res://scenes/main.tscn").instantiate()
	root.add_child(mgr)
	await process_frame
	await process_frame
	print("--- Прогресія NPC та складності ---")
	# 1) кожен із 20 рівнів кампанії вводить нового NPC; таблиця D.NPC_INTRO збігається з реальним складом,
	# і не більше одного нового ТИПУ ворога на рівень (чини рахуємо як нових NPC: e.npc_id())
	var seen := {}
	var seen_types := {}
	for level in range(1, D.CAMPAIGN_LEVELS + 1):
		mgr.difficulty_k = 1.0
		for e in mgr.enemies_node.get_children():
			mgr.enemies_node.remove_child(e)
			e.free()
		mgr.level = level
		mgr._spawn_folklore_enemies()
		var fresh: Array = []
		var fresh_types: Array = []
		for e in mgr.enemies_node.get_children():
			var n: String = e.npc_id()
			if not seen.has(n):
				seen[n] = true
				fresh.append(n)
			if not seen_types.has(e.enemy_type):
				seen_types[e.enemy_type] = true
				fresh_types.append(FolkloreEnemy.EnemyType.keys()[e.enemy_type])
		for ally in ["HUTSUL", "QIRIMLI", "MAVKA", "DOMOVYK", "KOBZAR", "VAKULA"]:
			if D.ally_first_level(ally) == level:
				seen[ally] = true
				fresh.append(ally)
		fresh.sort()
		var want: Array = D.NPC_INTRO[level].duplicate()
		want.sort()
		print("Рівень %d: нові NPC %s (нові типи ворога: %s)" % [level, fresh, fresh_types])
		if fresh.is_empty():
			return _fail("рівень %d не вводить нового NPC" % level)
		if fresh != want:
			return _fail("рівень %d: реальні нові NPC %s не збігаються з таблицею %s" % [level, fresh, want])
		if fresh_types.size() > 1:
			return _fail("рівень %d вводить більше одного нового типу ворога: %s" % [level, fresh_types])
	# Після рівня 20 нових NPC немає
	mgr.difficulty_k = 1.0
	for e in mgr.enemies_node.get_children():
		mgr.enemies_node.remove_child(e)
		e.free()
	mgr.level = 21
	mgr._spawn_folklore_enemies()
	for e in mgr.enemies_node.get_children():
		if not seen.has(e.npc_id()):
			return _fail("рівень 21 не має вводити нового NPC: %s" % e.npc_id())
	# 2) коефіцієнт змінює склад: серія 2 має більше ворогів, ніж серія 1 (та сама позиція, та сама якість)
	mgr.difficulty_k = D.coefficient(3, 0.5)
	for e in mgr.enemies_node.get_children():
		mgr.enemies_node.remove_child(e); e.free()
	mgr.level = 3
	mgr._spawn_folklore_enemies()
	var base_n: int = mgr.enemies_node.get_child_count()
	var base_speed: float = mgr.enemies_node.get_child(0).base_speed
	mgr.difficulty_k = D.coefficient(8, 0.9)
	for e in mgr.enemies_node.get_children():
		mgr.enemies_node.remove_child(e); e.free()
	mgr.level = 8
	mgr._spawn_folklore_enemies()
	var hard_n: int = mgr.enemies_node.get_child_count()
	var hard_speed: float = mgr.enemies_node.get_child(0).base_speed
	print("Рівень 3 (k=%.2f): %d ворогів; рівень 8, якісний гравець (k=%.2f): %d ворогів, швидкість ×%.2f" % [D.coefficient(3, 0.5), base_n, mgr.difficulty_k, hard_n, hard_speed / base_speed])
	if hard_n <= base_n or hard_speed <= base_speed:
		return _fail("складніша серія має давати більше й швидших ворогів")
	var vidmas := 0
	var chorts := 0
	for e in mgr.enemies_node.get_children():
		if e.enemy_type == FolkloreEnemy.EnemyType.VIDMA: vidmas += 1
		if e.enemy_type == FolkloreEnemy.EnemyType.CHORT: chorts += 1
	if vidmas * 2 > chorts:
		return _fail("додаткові вороги не мають порушувати рідкість відьом")
	# 2б) полегшення для слабкого гравця: на одного ворога менше, новий NPC рівня та відьма лишаються
	mgr.difficulty_k = D.coefficient(3, 0.0)
	for e in mgr.enemies_node.get_children():
		mgr.enemies_node.remove_child(e); e.free()
	mgr.level = 3
	mgr._spawn_folklore_enemies()
	var relief_n: int = mgr.enemies_node.get_child_count()
	var has_moskal := false
	var has_vidma := false
	for e in mgr.enemies_node.get_children():
		if e.enemy_type == FolkloreEnemy.EnemyType.MOSKAL: has_moskal = true
		if e.enemy_type == FolkloreEnemy.EnemyType.VIDMA: has_vidma = true
	print("Рівень 3, слабкий гравець (k=%.2f): %d ворогів (базово %d)" % [mgr.difficulty_k, relief_n, base_n])
	if relief_n != base_n - 1 or not has_moskal or not has_vidma:
		return _fail("слабкий гравець має отримати на одного ворога менше, не втрачаючи нового NPC рівня")
	# 2в) стеля одночасних ворогів
	mgr.difficulty_k = D.K_MAX
	for e in mgr.enemies_node.get_children():
		mgr.enemies_node.remove_child(e); e.free()
	mgr.level = 5
	mgr._spawn_folklore_enemies()
	if mgr.enemies_node.get_child_count() > D.MAX_ALIVE_ENEMIES:
		return _fail("ворогів більше за стелю MAX_ALIVE_ENEMIES")
	# 3) Мавка: з'являється лише з рівня 5 і після успіхів; чари лякають ворога
	mgr.difficulty_k = 1.0
	for lvl in [4, 5]:
		mgr.level = lvl
		mgr.mavka_spawned_this_level = false
		mgr.mavka_ally = null
		for e in mgr.enemies_node.get_children():
			mgr.enemies_node.remove_child(e); e.free()
		mgr._spawn_folklore_enemies()
		mgr.bombs_collected_on_level = 5
		mgr._check_progressive_ally_arrival()
		var has: bool = mgr.mavka_ally != null
		if lvl == 4 and has:
			return _fail("Мавка не має з'являтися до рівня 5")
		if lvl == 5 and not has:
			return _fail("Мавка має з'явитися на рівні 5")
	await process_frame
	var scared_before := 0
	for e in mgr.enemies_node.get_children():
		if e.is_scared: scared_before += 1
	var cast_ok: bool = mgr.mavka_ally.cast_spell()
	var scared_after := 0
	for e in mgr.enemies_node.get_children():
		if e.is_scared: scared_after += 1
	if not cast_ok or scared_after != scared_before + 1:
		return _fail("чари Мавки мають налякати одного ворога")
	# 3б) план 20 рівнів кампанії: кожен рівень вводить нового NPC, жоден NPC не вводиться двічі, є 20 рівнів, ескалація далі
	var plan_seen := {}
	for lvl in range(1, D.CAMPAIGN_LEVELS + 1):
		if not D.NPC_INTRO.has(lvl) or D.NPC_INTRO[lvl].is_empty():
			return _fail("рівень %d кампанії не вводить нового NPC у плані" % lvl)
		for n in D.NPC_INTRO[lvl]:
			if plan_seen.has(n):
				return _fail("NPC %s вводиться двічі (рівні %d і %d)" % [n, plan_seen[n], lvl])
			plan_seen[n] = lvl
	if D.NPC_INTRO.size() != D.CAMPAIGN_LEVELS:
		return _fail("план має охоплювати рівно %d рівнів кампанії" % D.CAMPAIGN_LEVELS)
	var planned_levels: Array = []
	for lvl in D.NPC_INTRO.keys():
		for n in D.NPC_INTRO[lvl]:
			if n in D.NPC_PLANNED:
				planned_levels.append(lvl)
	print("План кампанії: %d рівнів, нових NPC %d; ще не реалізовано (рівні): %s" % [D.NPC_INTRO.size(), plan_seen.size(), planned_levels])
	# 4) адаптація увімкнена: «середній» гравець у першій серії отримує склад не далі ніж на одного ворога від бази
	mgr.adaptive_enabled = true
	var fresh_model = load("res://scripts/player_model.gd").new()
	fresh_model.setup("11-14", "casual", 5)
	mgr.player_model = fresh_model
	for lvl in range(1, 6):
		mgr.adaptive_enabled = false
		mgr.difficulty_k = 1.0
		for e in mgr.enemies_node.get_children():
			mgr.enemies_node.remove_child(e); e.free()
		mgr.level = lvl
		mgr._spawn_folklore_enemies()
		var baseline: int = mgr.enemies_node.get_child_count()
		mgr.adaptive_enabled = true
		for e in mgr.enemies_node.get_children():
			mgr.enemies_node.remove_child(e); e.free()
		mgr.difficulty_k = fresh_model.recommend(lvl, load("res://scripts/level_difficulty.gd").offset(lvl))
		mgr._spawn_folklore_enemies()
		var adapted: int = mgr.enemies_node.get_child_count()
		if absi(adapted - baseline) > 1:
			return _fail("рівень %d: адаптація змінила склад більш ніж на одного ворога (%d → %d)" % [lvl, baseline, adapted])
	# 5) особисті переможні танці Мавки й усіх союзників та національні танці невдачі ворожих NPC-злодіїв
	var mavka_dances := {}
	for kind in ["MAVKA", "DOMOVYK", "KOBZAR", "VAKULA"]:
		mgr.mavka_ally.ally_kind = kind
		mgr.mavka_ally.celebrate_victory()
		if not mgr.mavka_ally.is_celebrating_victory:
			return _fail("союзник %s має входити у стан переможного танцю" % kind)
		var d_name: String = mgr.mavka_ally.get_victory_dance_name()
		if d_name.is_empty() or mavka_dances.has(d_name):
			return _fail("союзник %s має мати унікальний особистий переможний танок (отримано %s)" % [kind, d_name])
		mavka_dances[d_name] = kind
	var sample_enemy: FolkloreEnemy = mgr.enemies_node.get_child(0) as FolkloreEnemy
	sample_enemy.enemy_type = FolkloreEnemy.EnemyType.MOSKAL
	sample_enemy.set_moskal_rank(FolkloreEnemy.MoskalRank.STRELETS)
	sample_enemy.start_defeat_dance()
	if not sample_enemy.is_dancing_defeat or sample_enemy.get_defeat_dance_name() != "moskal_komarynska_fail":
		return _fail("москаль має танцювати національний танок невдачі moskal_komarynska_fail")
	sample_enemy.set_moskal_rank(FolkloreEnemy.MoskalRank.MONGOL_NUKER)
	if sample_enemy.get_defeat_dance_name() != "horde_buran_stumble":
		return _fail("ординський нукер має танцювати танок невдачі horde_buran_stumble")
	print("[OK] кожен рівень вводить нового NPC; складність, Мавка та переможні/невдалі танці працюють")
	quit(0)
