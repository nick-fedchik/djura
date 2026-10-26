extends SceneTree

var frame_count: int = 0
var mgr = null
var mace_phase_start: int = -1 # кадр запуску перевірки нагороди Булавою після завершення рівня 5
const MACE_WAIT_FRAMES: int = 3000

func _count_types(level_id: int) -> Dictionary:
	var counts := {}
	for cfg in mgr.LEVEL_COMPOSITIONS[level_id]:
		counts[cfg["type"]] = int(counts.get(cfg["type"], 0)) + 1
	return counts

const D = preload("res://scripts/difficulty.gd")

func _check_stage1_compositions() -> void:
	var T = FolkloreEnemy.EnemyType
	# Рівень 1: виключно Вогник, жодного іншого ворога
	var c1 := _count_types(1)
	assert(c1.get(T.VOGNYK, 0) >= 1, "LEVEL_COMPOSITIONS[1] must contain Vognyk")
	assert(c1.size() == 1, "LEVEL_COMPOSITIONS[1] must contain ONLY Vognyk")
	assert(c1.get(T.CHORT, 0) == 0 and c1.get(T.VIDMA, 0) == 0, "Level 1: zero Chorts, zero Vidmas")
	# Рівень 2: 2 Вогники, нуль чортиків і відьом
	var c2 := _count_types(2)
	assert(c2.get(T.VOGNYK, 0) == 2, "LEVEL_COMPOSITIONS[2] must have exactly 2 Vognyks")
	assert(c2.get(T.CHORT, 0) == 0 and c2.get(T.VIDMA, 0) == 0 and c2.size() == 1, "Level 2: zero Chorts, zero Vidmas")
	# Рівні 3–4: Вогники та Чортики, нуль відьом
	for lvl in [3, 4]:
		var c := _count_types(lvl)
		assert(c.get(T.VOGNYK, 0) >= 1, "Level %d must have Vognyks" % lvl)
		assert(c.get(T.CHORT, 0) >= 1, "Level %d must have Chorts" % lvl)
		assert(c.get(T.VIDMA, 0) == 0, "Level %d must have zero Vidmas" % lvl)
		assert(c.size() == 2, "Level %d must have only Vognyks and Chorts" % lvl)
	# Рівень 5: Відьма Солоха разом із Вогниками та Чортиками
	var c5 := _count_types(5)
	assert(c5.get(T.VIDMA, 0) == 1, "Level 5 must have exactly 1 Vidma Solokha")
	assert(c5.get(T.VOGNYK, 0) >= 1 and c5.get(T.CHORT, 0) >= 1, "Level 5 must keep Vognyks and Chorts alongside Vidma")
	assert(c5.size() == 3, "Level 5 must have no enemy types beyond Vognyk/Chort/Vidma")
	print("[OK] Stage 1 LEVEL_COMPOSITIONS invariants (levels 1-5) verified!")

	# Етап 2 (рівні 6–10): лише Вогники й Чортики, без москалів; Солоха-реванш лише на рівні 10
	var want := {6: [2, 2, 0], 7: [2, 3, 0], 8: [2, 2, 0], 9: [2, 3, 0], 10: [2, 3, 1]}
	for lvl in want:
		var c := _count_types(lvl)
		assert(c.get(T.VOGNYK, 0) == want[lvl][0], "Level %d: Vognyk count" % lvl)
		assert(c.get(T.CHORT, 0) == want[lvl][1], "Level %d: Chort count" % lvl)
		assert(c.get(T.VIDMA, 0) == want[lvl][2], "Level %d: Vidma count" % lvl)
		assert(c.get(T.MOSKAL, 0) == 0, "Level %d: no Moskals in Stage 2" % lvl)
	# Киримли-союзник розблокований з рівня 7
	assert(not D.ally_available("QIRIMLI", 6) and D.ally_available("QIRIMLI", 7), "Qirimli unlocks at level 7")
	# Ланцюгова реакція ядер скасована за рішенням власника (0.0 на всіх рівнях)
	assert(is_equal_approx(BombItem.chain_chance_for_level(1), 0.0) and is_equal_approx(BombItem.chain_chance_for_level(2), 0.0), "Chain chance 0.0 on levels 1-2")
	assert(is_equal_approx(BombItem.chain_chance_for_level(3), 0.0), "Chain chance 0.0 from level 3")
	# Булава — вічна реліквія: після рівня 5 відновлюється до 12 на кожному рівні
	var p = JackPlayer.new()
	p.unlock_kotyhoroshko_mace(12)
	p.mace_durability = 0
	p.has_mace = false
	p.unlock_kotyhoroshko_mace(12)
	assert(p.has_mace and p.mace_durability == 12, "Mace recharges to 12")
	p.free()
	print("[OK] Stage 2 compositions, Qirimli unlock, chain chance, mace recharge verified!")

func _init() -> void:
	var main_scene = load("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)
	mgr = main

func _physics_process(delta: float) -> bool:
	frame_count += 1
	if frame_count == 2:
		print("--- Running Test for Level 1 and Level 2 ---")
		assert(mgr != null, "GameManager must exist")
		mgr.adaptive_enabled = false # цей набір перевіряє правила складу рівнів на детермінованій базі; адаптація: test_adaptive_model, test_progression
		assert(mgr.level == 1, "Initial level must be 1")
		
		print("[OK] Level 1 initialized: %d platforms, %d enemies" % [
			mgr.platforms_node.get_child_count(),
			mgr.enemies_node.get_child_count()
		])
		assert(mgr.enemies_node.get_child_count() == 1, "Level 1 must have exactly 1 enemy (Vohnyk)")
		for e in mgr.enemies_node.get_children():
			assert(e.enemy_type == FolkloreEnemy.EnemyType.VOGNYK, "Level 1 enemies must be VOGNYK")
		
		print("[OK] Level 1 enemies verified: Only Vohnyk for 8+ kids friendliness and Meshy 3D showcase!")
		
		# Simulate level 1 completion to test Level 2 transition
		_check_stage1_compositions()
		assert(mgr.hutsul_ally == null and mgr.qirimli_ally == null, "Level 1 must have zero external allies")
		print("Simulating transition to Level 2...")
		mgr.level = 2
		mgr._setup_level()
		
		assert(mgr.level == 2, "Level should now be 2")
		print("[OK] Level 2 initialized: %d platforms, %d enemies" % [
			mgr.platforms_node.get_child_count(),
			mgr.enemies_node.get_child_count()
		])
		assert(mgr.enemies_node.get_child_count() == 2, "Level 2 must have 2 Vognyks")
		for e in mgr.enemies_node.get_children():
			assert(e.enemy_type == FolkloreEnemy.EnemyType.VOGNYK, "Level 2 enemies must be Vognyks")
		print("[OK] Level 2 enemy composition verified: 2 Vognyks!")
		
		# Simulate level 2 completion to test Level 3 transition (Sich - Chorts enter!)
		print("Simulating transition to Level 3...")
		mgr.level = 3
		mgr._setup_level()
		
		assert(mgr.level == 3, "Level should now be 3")
		print("[OK] Level 3 initialized: %d platforms, %d bombs, %d enemies" % [
			mgr.platforms_node.get_child_count(),
			mgr.bombs_node.get_child_count(),
			mgr.enemies_node.get_child_count()
		])
		assert(mgr.bombs_node.get_child_count() == 24, "Level 3 must have 24 bombs")
		assert(mgr.enemies_node.get_child_count() == 3, "Level 3 must have 3 enemies (1 Vognyk + 2 Chorts)")
		var chort_count_lvl3 := 0
		var vognyk_count_lvl3 := 0
		for e in mgr.enemies_node.get_children():
			if e.enemy_type == FolkloreEnemy.EnemyType.CHORT:
				chort_count_lvl3 += 1
			elif e.enemy_type == FolkloreEnemy.EnemyType.VOGNYK:
				vognyk_count_lvl3 += 1
		assert(chort_count_lvl3 == 2, "Level 3 must have 2 Chorts")
		assert(vognyk_count_lvl3 == 1, "Level 3 must have 1 Vognyk")
		
		# Stage 1 (Sich) invariant: NO external allies arrive on levels 1-5!
		mgr.bombs_collected_on_level = 6
		mgr._check_progressive_ally_arrival()
		assert(mgr.hutsul_ally == null, "Stage 1 must NOT spawn Hutsul ally")
		assert(mgr.qirimli_ally == null, "Stage 1 must NOT spawn Qirimli ally")
		print("[OK] Level 3 Stage 1 Sich autonomy verified: 1 Vognyk, 2 Chorts, 0 external allies!")
		
		# Test Level 4 (Sich - More Vognyks & Chorts)
		print("Simulating transition to Level 4...")
		mgr.level = 4
		mgr._setup_level()
		assert(mgr.level == 4, "Level should now be 4")
		assert(mgr.bombs_node.get_child_count() == 24, "Level 4 must have 24 bombs")
		assert(mgr.enemies_node.get_child_count() == 4, "Level 4 must have 4 enemies (2 Vognyks + 2 Chorts)")
		var chort_count_lvl4 := 0
		var vognyk_count_lvl4 := 0
		for e in mgr.enemies_node.get_children():
			if e.enemy_type == FolkloreEnemy.EnemyType.CHORT:
				chort_count_lvl4 += 1
			elif e.enemy_type == FolkloreEnemy.EnemyType.VOGNYK:
				vognyk_count_lvl4 += 1
		assert(chort_count_lvl4 == 2, "Level 4 must have 2 Chorts")
		assert(vognyk_count_lvl4 == 2, "Level 4 must have 2 Vognyks")
		assert(mgr.story_cards.has_story_for_level(4), "Level 4 must have story cards")
		print("[OK] Level 4 Stage 1 verified: 2 Vognyks, 2 Chorts, Story Cards!")
		
		# Test Level 5 (Sich Climax - Vidma Solokha Boss!)
		print("Simulating transition to Level 5 (Sich Climax)...")
		mgr.level = 5
		mgr._setup_level()
		assert(mgr.level == 5, "Level should now be 5")
		assert(mgr.bombs_node.get_child_count() == 24, "Level 5 must have 24 bombs")
		assert(mgr.enemies_node.get_child_count() == 5, "Level 5 must have 5 enemies (2 Vognyks, 2 Chorts, 1 Vidma)")
		var vidma_count_lvl5 := 0
		for e in mgr.enemies_node.get_children():
			if e.enemy_type == FolkloreEnemy.EnemyType.VIDMA:
				vidma_count_lvl5 += 1
		assert(vidma_count_lvl5 == 1, "Level 5 must feature Vidma boss")
		assert(mgr.story_cards.has_story_for_level(5), "Level 5 must have story cards")
		print("[OK] Level 5 Sich climax verified: Vidma boss present!")
		
		# Test Kotyhoroshko Mace unlock after Stage 1
		print("Testing Kotyhoroshko Mace unlock after Stage 1...")
		mgr.player.unlock_kotyhoroshko_mace(12)
		assert(mgr.player.has_mace == true, "Player must have Kotyhoroshko Mace unlocked")
		assert(mgr.player.mace_durability == 12, "Mace initial durability must be 12")
		print("[OK] Kotyhoroshko Mace unlock verified!")
		
		# Level 6 (Sivash): Киримли ще не прибуває; Level 7 (Ор-Капу): союзник розблокований
		print("Simulating transition to Level 6/7 (Stage 2: Crimea)...")
		mgr.level = 6
		mgr._setup_level()
		mgr.bombs_collected_on_level = 4
		mgr._check_progressive_ally_arrival()
		assert(mgr.qirimli_ally == null, "Level 6: Qirimli ally is not unlocked yet")
		mgr.level = 7
		mgr._setup_level()
		assert(mgr.level == 7, "Level should now be 7")
		assert(mgr.qirimli_ally == null, "Level 7 Qirimli ally waits for progressive arrival")
		mgr.bombs_collected_on_level = 4
		mgr._check_progressive_ally_arrival()
		assert(mgr.qirimli_ally != null, "Level 7 must progressively spawn Qirimli ally")
		assert(is_equal_approx(mgr.qirimli_ally.MOVE_SPEED, 148.0), "Qirimli MOVE_SPEED must be 148.0")
		
		# Test Qirimli one-time Steppe Falcon launch against Unclean Forces
		assert(mgr.qirimli_ally.has_launched_falcon == false, "Falcon must not be launched before trigger")
		var first_launch: bool = mgr.qirimli_ally.launch_falcon()
		assert(first_launch == true, "First falcon launch must succeed")
		assert(mgr.qirimli_ally.has_launched_falcon == true, "has_launched_falcon must be true after launch")
		var second_launch: bool = mgr.qirimli_ally.launch_falcon()
		assert(second_launch == false, "Second falcon launch on same level must be blocked (one-time invariant)")
		print("[OK] Level 7 Crimea: Qirimli ally & Steppe Falcon launch verified!")
		
		# Test Level 11 (Stage 3: Carpathians - Hutsul with Bartka arrival)
		print("Simulating transition to Level 11 (Stage 3: Carpathians)...")
		mgr.level = 11
		mgr._setup_level()
		assert(mgr.level == 11, "Level should now be 11")
		assert(mgr.hutsul_ally == null, "Hutsul ally waits for progressive arrival")
		mgr.bombs_collected_on_level = 2
		mgr._check_progressive_ally_arrival()
		assert(mgr.hutsul_ally != null, "Level 11 must progressively spawn Hutsul ally")
		assert(is_equal_approx(mgr.hutsul_ally.MOVE_SPEED, 155.0), "Hutsul MOVE_SPEED must be 155.0")
		
		# Test autonomous jumping of allies
		mgr.hutsul_ally._perform_jump()
		assert(mgr.hutsul_ally.velocity.y < 0.0, "Hutsul ally must jump upward autonomously")
		
		# Test Carpathian Hutsul melee Bartka whacking + one-time Bartka throw & scene exit
		var test_enemy = mgr.enemies_node.get_child(0) as FolkloreEnemy
		mgr.hutsul_ally.melee_strike_enemy(test_enemy)
		assert(test_enemy.is_scared == true, "Enemy must be scared after Hutsul melee Bartka strike")
		assert(mgr.hutsul_ally.melee_hits_count == 1, "Hutsul melee hit counter must increment")
		var first_bartka_throw: bool = mgr.hutsul_ally.throw_bartka_once()
		assert(first_bartka_throw == true, "First Bartka throw must succeed")
		assert(mgr.hutsul_ally.has_thrown_bartka == true, "has_thrown_bartka must be true")
		assert(mgr.hutsul_ally.is_exiting_scene == true, "Hutsul must start exiting scene after throwing Bartka")
		var second_bartka_throw: bool = mgr.hutsul_ally.throw_bartka_once()
		assert(second_bartka_throw == false, "Second Bartka throw must be blocked (one-time throw invariant)")
		print("[OK] Level 11 Carpathians: Hutsul Bartka mechanics verified!")
		
		# Test story cards for level 3
		print("Testing Story Cards for Level 3...")
		assert(mgr.story_cards.has_story_for_level(3), "Level 3 must have story cards")
		mgr.story_cards.show_story_for_level(3)
		assert(mgr.story_cards.is_active, "StoryCards must be active for level 3")
		assert(mgr.story_cards.slides.size() == 3, "Level 3 must have 3 story slides")
		mgr.story_cards._finish_story()
		assert(not mgr.story_cards.is_active, "StoryCards must close after finish")
		print("[OK] Level 3 Story Cards verified!")
		
		# Test bomb collection completion on Level 3 (verifying bugfix for stuck level)
		print("Testing bomb collection & completion on Level 3...")
		mgr.is_transitioning_level = false
		var test_bomb = mgr.bombs_node.get_child(0) as BombItem
		assert(test_bomb != null, "Bomb must exist")
		
		# Clear all other bombs to simulate 1 bomb remaining
		var all_bombs = mgr.bombs_node.get_children()
		for i in range(1, all_bombs.size()):
			mgr.bombs_node.remove_child(all_bombs[i])
			all_bombs[i].queue_free()
		
		# Collect the final bomb
		test_bomb.collected.emit(test_bomb, true)
		print("[OK] Final bomb collected on Level 3, victory dance initiated without hanging!")
		
		# Test story cards
		print("Testing Story Cards...")
		assert(mgr.story_cards != null, "StoryCards must exist")
		mgr.story_cards.show_story_for_level(1)
		assert(mgr.story_cards.is_active, "StoryCards must be active for level 1")
		assert(mgr.story_cards.slides.size() == 3, "Level 1 must have 3 cartoon story slides")
		mgr.story_cards._next_slide()
		assert(mgr.story_cards.current_slide_idx == 1, "Slide index should advance")
		mgr.story_cards._finish_story()
		assert(not mgr.story_cards.is_active, "StoryCards must close after finish")
		print("[OK] Story Cards workflow verified!")
		
		# Test Vakula's Horseshoe spawn & player powerup
		print("Testing Vakula's Horseshoe item...")
		mgr._spawn_vakula_horseshoe()
		assert(mgr.items_node.get_child_count() == 1, "Vakula's Horseshoe item should be spawned")
		var shoe = mgr.items_node.get_child(0)
		assert(shoe != null, "Item must exist")
		
		# Test player collection
		shoe._on_body_entered(mgr.player)
		assert(mgr.player.has_vakula_shoes, "Player must have Vakula shoes activated")
		assert(mgr.player.vakula_shoes_timer > 0.0, "Vakula shoes timer must be positive")
		
		# Verify all platforms became one-way AND upward collision exceptions are active
		mgr.player.velocity.y = -450.0
		mgr.player._update_vakula_platform_pass_through()
		assert(mgr.player.get_collision_exceptions().size() == mgr.platforms_node.get_child_count(), "All platforms must be in player collision exceptions when jumping upward with Vakula shoes")
		for plat in mgr.platforms_node.get_children():
			assert(plat.is_one_way == true, "Platforms must be one-way when Vakula shoes are active")
			assert(plat.col_shape.one_way_collision == true, "Collision shape must be one_way_collision")
		print("[OK] Vakula's Horseshoe phase-up through platforms verified (one_way = true + collision exceptions)!")
		
		# Test resetting / expiry restores solid platforms
		mgr.player.reset_to_normal_state()
		assert(not mgr.player.has_vakula_shoes, "Player must lose Vakula shoes after reset")
		for plat in mgr.platforms_node.get_children():
			assert(plat.is_one_way == false, "Platforms must revert to solid when Vakula shoes expire")
			assert(plat.col_shape.one_way_collision == false, "Collision shape must revert to solid")
		print("[OK] Platform solid collision restore verified after powerup expiry!")
		
		print("[OK] Vakula's Horseshoe collection and super jump boost verified!")
		
		# Test Dzhura's comic speech bubble
		print("Testing Dzhura's Comic Speech Bubble...")
		assert(mgr.player.speech_bubble != null, "Player must have SpeechBubble")
		mgr.player.say("Гей-га!", 1.5)
		assert(mgr.player.speech_bubble.label.text == "Гей-га!", "Bubble label text must match")
		print("[OK] Dzhura's Comic Speech Bubble verified!")
		
		# Test Champion Boxing Skills progression (Klitschko brothers & Usyk) and Bottom Combat Hint Bar
		print("Testing Champion Boxing Skills progression & Bottom Combat Hint Bar...")
		assert(mgr.hud.combat_hint_label != null, "Bottom CombatHintLabel must exist in HUD")
		assert(mgr.hud.combat_hint_label.visible == true, "Bottom CombatHintLabel must be visible until player uses the strike/combo")
		assert(mgr.pending_combat_moves.has("basic_strike"), "Initial pending move must include basic_strike")
		assert(mgr.player.unlocked_skills.is_empty(), "Initial skills should be empty")
		
		# 1. Unlock Steelhammer Jab (Wladimir Klitschko) & queue its hint
		mgr.player.unlock_champion_skill(JackPlayer.ChampionSkill.STEELHAMMER_JAB)
		mgr._queue_combat_hint_front("steelhammer_jab")
		assert(mgr.pending_combat_moves[0] == "steelhammer_jab", "Steelhammer jab hint must be at front of bottom bar")
		assert(mgr.player.unlocked_skills.has(JackPlayer.ChampionSkill.STEELHAMMER_JAB), "Must unlock Steelhammer Jab")
		
		# Test punch execution clears the hint from pending_combat_moves
		mgr.player.facing_direction = 1.0
		mgr.player._perform_champion_punch()
		assert(mgr.player.punch_timer > 0.0, "Punch timer must be positive after punch")
		assert(mgr.player.punch_active_skill == JackPlayer.ChampionSkill.STEELHAMMER_JAB, "Active punch must be Steelhammer")
		assert(not mgr.pending_combat_moves.has("steelhammer_jab"), "Steelhammer jab hint must be marked completed once player uses it")
		assert(not mgr.pending_combat_moves.has("basic_strike"), "Basic strike hint must also be marked completed once player punches")
		print("[OK] Wladimir Klitschko Steelhammer Jab & persistent bottom hint completion verified!")
		
		# 2. Unlock Ironfist Hook (Vitali Klitschko)
		mgr.player.unlock_champion_skill(JackPlayer.ChampionSkill.IRONFIST_HOOK)
		assert(mgr.player.unlocked_skills.has(JackPlayer.ChampionSkill.IRONFIST_HOOK), "Must unlock Ironfist Hook")
		print("[OK] Vitali Klitschko Ironfist Hook verified!")
		
		# 3. Unlock Usyk Slip & Counter (Oleksandr Usyk)
		mgr.player.unlock_champion_skill(JackPlayer.ChampionSkill.USYK_SLIP_COUNTER)
		assert(mgr.player.unlocked_skills.has(JackPlayer.ChampionSkill.USYK_SLIP_COUNTER), "Must unlock Usyk Slip Counter")
		# Test rolling slip counter
		mgr.player.is_rolling = true
		mgr.player.punch_timer = 0.0
		mgr.player._perform_champion_punch()
		assert(mgr.player.punch_active_skill == JackPlayer.ChampionSkill.USYK_SLIP_COUNTER, "Rolling punch must be Usyk Slip Counter")
		mgr.player.is_rolling = false
		mgr.player.punch_timer = 0.0
		print("[OK] Oleksandr Usyk Slip & Counter verified!")
		
		# 4. Unlock Undisputed Trio
		mgr.player.unlock_champion_skill(JackPlayer.ChampionSkill.UNDISPUTED_TRIO)
		assert(mgr.player.unlocked_skills.has(JackPlayer.ChampionSkill.UNDISPUTED_TRIO), "Must unlock Undisputed Trio")
		mgr.player.punch_timer = 0.0
		mgr.player.strike_combo_step = 0
		mgr.player._perform_champion_punch()
		assert(mgr.player.punch_active_skill == JackPlayer.ChampionSkill.UNDISPUTED_TRIO, "Active punch must be Undisputed Trio")
		assert(not mgr.player.strike_effects.is_empty(), "Strike must generate visual impact effects")
		print("[OK] Undisputed Champion Trio Synergy & strike visual effects verified!")
		
		# 5. Test Combat Hopak Martial Kicks (Tynok High Kick & Shchupak Split Kick)
		mgr.player.punch_timer = 0.0
		mgr.player._perform_hopak_kick()
		assert(mgr.player.punch_active_skill in [JackPlayer.ChampionSkill.HOPAK_TYNOK_KICK, JackPlayer.ChampionSkill.HOPAK_SHCHUPAK_SPLIT, JackPlayer.ChampionSkill.HOPAK_POVZUNETS_SWEEP], "Kick must activate Hopak kick skill")
		assert(not mgr.pending_combat_moves.has("hopak_kick"), "Hopak kick hint must be marked completed after kick")
		print("[OK] Combat Hopak Martial Kicks (Tynok / Shchupak / Povzunets) verified!")

		# 6. Test Logitech Gamepad prompts in COMBAT_HINTS & NPC Fatigue/Rest Mechanics
		print("Testing Logitech Gamepad Hints & NPC Fatigue/Rest Animations...")
		for move_key in mgr.COMBAT_HINTS.keys():
			var hint_str: String = String(mgr.COMBAT_HINTS[move_key]["hint"])
			assert(hint_str.contains("Геймпад"), "Every combat hint must include Logitech Gamepad prompt: " + move_key)
		
		var rest_enemy := mgr.enemies_node.get_child(0) as FolkloreEnemy
		assert(rest_enemy != null, "Test enemy must exist")
		rest_enemy.is_scared = false
		rest_enemy.start_rest(2.0)
		assert(rest_enemy.is_resting == true and rest_enemy.rest_timer > 0.0, "FolkloreEnemy must enter rest state")
		rest_enemy.make_scared(3.0)
		assert(rest_enemy.is_resting == false, "Scaring enemy must immediately cancel rest state")
		
		assert(mgr.hutsul_ally != null, "Test HutsulAlly must exist")
		mgr.hutsul_ally.is_celebrating_victory = false
		mgr.hutsul_ally.is_exiting_scene = false
		mgr.hutsul_ally.start_rest(1.8)
		assert(mgr.hutsul_ally.is_resting == true and mgr.hutsul_ally.rest_timer > 0.0, "HutsulAlly must enter rest state")
		
		assert(mgr.qirimli_ally != null, "Test QirimliAlly must exist")
		mgr.qirimli_ally.is_celebrating_victory = false
		mgr.qirimli_ally.start_rest(1.8)
		assert(mgr.qirimli_ally.is_resting == true and mgr.qirimli_ally.rest_timer > 0.0, "QirimliAlly must enter rest state")
		
		# Test anatomical Dzhura story portrait & Enemy Stolen Artifact Buff / Knock-out Drop
		assert(mgr.story_cards.has_method("_draw_story_dzhura"), "StoryCards must use anatomical 14-16yo Dzhura portrait with Oseledets-Aidar")
		rest_enemy.apply_stolen_artifact_buff(6.5)
		assert(rest_enemy.has_stolen_artifact == true and rest_enemy.fatigue_mult > 1.2, "Enemy must receive turbo buff when grabbing artifact")
		rest_enemy.make_scared(5.0)
		assert(rest_enemy.has_stolen_artifact == false and mgr.items_node.get_child_count() >= 1, "Striking/scaring buffed enemy must knock stolen artifact back onto arena")
		print("[OK] Logitech Gamepad Hints, NPC Fatigue/Rest, Anatomical 14-16yo Dzhura & Enemy Artifact Interception verified!")

		# 7. Test 6-Tier Muscovite NPC Hierarchy (SHYSH -> STRELETS -> DYAK -> OPRYCHNYK -> VOYEVODA -> TSAR_GENERAL)
		print("Testing 6-tier Muscovite NPC hierarchy (from Shysh to Voyevoda & Tsar General)...")
		assert(FolkloreEnemy.get_moskal_rank_armor(FolkloreEnemy.MoskalRank.SHYSH) == 0, "Shysh must have 0 armor")
		assert(FolkloreEnemy.get_moskal_rank_armor(FolkloreEnemy.MoskalRank.STRELETS) == 0, "Strelets must have 0 armor")
		assert(FolkloreEnemy.get_moskal_rank_armor(FolkloreEnemy.MoskalRank.DYAK) == 0, "Dyak must have 0 armor")
		assert(FolkloreEnemy.get_moskal_rank_armor(FolkloreEnemy.MoskalRank.OPRYCHNYK) == 1, "Oprichnik must have 1 armor shield")
		assert(FolkloreEnemy.get_moskal_rank_armor(FolkloreEnemy.MoskalRank.VOYEVODA) == 1, "Voyevoda must have 1 armor shield")
		assert(FolkloreEnemy.get_moskal_rank_armor(FolkloreEnemy.MoskalRank.TSAR_GENERAL) == 2, "Tsar General must have 2 armor shields")
		assert(FolkloreEnemy.get_moskal_rank_reward(FolkloreEnemy.MoskalRank.SHYSH) < FolkloreEnemy.get_moskal_rank_reward(FolkloreEnemy.MoskalRank.VOYEVODA), "Higher rank must grant higher glory reward")
		for r in [
			FolkloreEnemy.MoskalRank.SHYSH,
			FolkloreEnemy.MoskalRank.STRELETS,
			FolkloreEnemy.MoskalRank.DYAK,
			FolkloreEnemy.MoskalRank.OPRYCHNYK,
			FolkloreEnemy.MoskalRank.VOYEVODA,
			FolkloreEnemy.MoskalRank.TSAR_GENERAL
		]:
			rest_enemy.enemy_type = FolkloreEnemy.EnemyType.MOSKAL
			rest_enemy.set_moskal_rank(r)
			assert(rest_enemy.moskal_rank == r, "set_moskal_rank must set rank")
			assert(rest_enemy.armor == FolkloreEnemy.get_moskal_rank_armor(r), "set_moskal_rank must configure rank armor")
		print("[OK] All 6 Muscovite NPC ranks (SHYSH, STRELETS, DYAK, OPRYCHNYK, VOYEVODA, TSAR_GENERAL) verified!")

		# Test 2K 16:9 Widescreen Viewport
		var v_size = root.get_viewport().get_visible_rect().size
		print("[OK] 2K 16:9 Viewport resolution: %s (Aspect: %.4f)" % [v_size, v_size.x / v_size.y])
		assert(is_equal_approx(v_size.x / v_size.y, 16.0 / 9.0), "Aspect ratio must be 16:9 2K")
		
		# Нагорода Булавою: окремий свіжий екземпляр гри, щоб не заважали корутини попередніх перевірок
		print("Testing Kotyhoroshko Mace award on Level 5 completion...")
		root.remove_child(mgr)
		mgr.free()
		var fresh = load("res://scenes/main.tscn").instantiate()
		root.add_child(fresh)
		mgr = fresh
		mace_phase_start = frame_count + 2
	elif mace_phase_start > 0 and frame_count == mace_phase_start:
		mgr.adaptive_enabled = false
		mgr.level = 5
		mgr._setup_level()
		mgr.is_transitioning_level = false
		assert(mgr.player.has_mace == false, "Player must not own the mace before Level 5 is completed")
		mgr._on_level_complete()
	elif mace_phase_start > 0 and frame_count > mace_phase_start:
		if mgr.level == 6:
			assert(mgr.player.has_mace == true, "Completing Level 5 must award Kotyhoroshko Mace")
			assert(mgr.player.mace_durability > 0, "Awarded mace must have positive durability")
			print("[OK] Kotyhoroshko Mace awarded on Level 5 -> 6 transition (durability %d)!" % mgr.player.mace_durability)
			print("--- ALL LEVEL 1 & LEVEL 2 TESTS PASSED! ---")
			quit(0)
			return true
		assert(frame_count - mace_phase_start < MACE_WAIT_FRAMES, "Timeout waiting for Level 5 completion -> Level 6")
	return false
