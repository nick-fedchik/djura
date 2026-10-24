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
		print("--- Running Test for Level 1 and Level 2 ---")
		assert(mgr != null, "GameManager must exist")
		assert(mgr.level == 1, "Initial level must be 1")
		
		print("[OK] Level 1 initialized: %d platforms, %d enemies" % [
			mgr.platforms_node.get_child_count(),
			mgr.enemies_node.get_child_count()
		])
		assert(mgr.enemies_node.get_child_count() == 2, "Level 1 must have exactly 2 enemies (Chorty)")
		for e in mgr.enemies_node.get_children():
			assert(e.enemy_type == FolkloreEnemy.EnemyType.CHORT, "Level 1 enemies must be CHORT")
		
		print("[OK] Level 1 enemies verified: Only Chorty imps for 8+ kids friendliness!")
		
		# Simulate level 1 completion to test Level 2 transition
		print("Simulating transition to Level 2...")
		mgr.level = 2
		mgr._setup_level()
		
		assert(mgr.level == 2, "Level should now be 2")
		print("[OK] Level 2 initialized: %d platforms, %d enemies" % [
			mgr.platforms_node.get_child_count(),
			mgr.enemies_node.get_child_count()
		])
		assert(mgr.enemies_node.get_child_count() == 3, "Level 2 must have 3 enemies (2 Chorts, 1 Vidma engineer)")
		
		var has_chort := false
		var has_vidma := false
		for e in mgr.enemies_node.get_children():
			if e.enemy_type == FolkloreEnemy.EnemyType.CHORT:
				has_chort = true
			elif e.enemy_type == FolkloreEnemy.EnemyType.VIDMA:
				has_vidma = true
		
		assert(has_chort, "Level 2 must have Chort")
		assert(has_vidma, "Level 2 must have Vidma")
		assert(not mgr.enemies_node.get_children().any(func(e): return e.enemy_type == FolkloreEnemy.EnemyType.VOGNYK), "Vognyk is introduced at level 4 (SHR-001 I-1)")
		print("[OK] Level 2 enemy composition verified: 2 Chorts, 1 Vidma!")
		
		# Simulate level 2 completion to test Level 3 transition (Kamianets Fortress)
		print("Simulating transition to Level 3 (Kamianets Fortress)...")
		mgr.level = 3
		mgr._setup_level()
		
		assert(mgr.level == 3, "Level should now be 3")
		print("[OK] Level 3 initialized: %d platforms, %d bombs, %d enemies" % [
			mgr.platforms_node.get_child_count(),
			mgr.bombs_node.get_child_count(),
			mgr.enemies_node.get_child_count()
		])
		assert(mgr.platforms_node.get_child_count() == 8, "Level 3 must have 8 fortress platforms")
		assert(mgr.bombs_node.get_child_count() == 24, "Level 3 must have 24 bombs")
		assert(mgr.enemies_node.get_child_count() == 4, "Level 3 must have 4 enemies")
		
		# Verify progressive ally arrival on Level 3 (not at t=0, only after Dzhura's first successes, -30% balanced count)
		assert(mgr.hutsul_ally == null, "Allies must not spawn immediately at t=0 before Dzhura's first successes")
		assert(mgr.qirimli_ally == null, "Qirimli must not spawn immediately at t=0 before Dzhura's first successes")
		mgr.bombs_collected_on_level = 2
		mgr._check_progressive_ally_arrival()
		assert(mgr.hutsul_ally != null, "Level 3 must progressively spawn Hutsul ally after 2 bombs collected")
		assert(mgr.hutsul_allies.size() == 1, "Wave 1 must spawn 1 Carpathian Hutsul (-30% balanced count)")
		mgr.bombs_collected_on_level = 6
		mgr._check_progressive_ally_arrival()
		assert(mgr.hutsul_allies.size() == 2, "Wave 2 must spawn a 2nd Carpathian Hutsul ally on Level 3+")
		assert(mgr.qirimli_ally != null, "Level 3 must progressively spawn Qirimli ally after 4+ bombs collected")
		assert(is_equal_approx(mgr.hutsul_ally.MOVE_SPEED, 155.0), "Hutsul MOVE_SPEED must be 20% slower (155.0)")
		assert(is_equal_approx(mgr.qirimli_ally.MOVE_SPEED, 148.0), "Qirimli MOVE_SPEED must be 20% slower (148.0)")
		for h in mgr.hutsul_allies:
			h.celebrate_victory()
			assert(h.is_celebrating_victory == true, "All Hutsul allies must perform their Arkan victory dance")
		var has_moskal_lvl3 := false
		for e in mgr.enemies_node.get_children():
			if e.enemy_type == FolkloreEnemy.EnemyType.MOSKAL:
				has_moskal_lvl3 = true
		assert(has_moskal_lvl3, "Level 3 must feature Moskal strelets enemy")
		print("[OK] Level 3 progressive arrival of Hutsul & Qirimli allies and Moskal strelets verified!")
		
		# Test Level 4 (Baturyn Hetmanate)
		print("Simulating transition to Level 4 (Baturyn Hetmanate)...")
		mgr.level = 4
		mgr._setup_level()
		assert(mgr.level == 4, "Level should now be 4")
		assert(mgr.platforms_node.get_child_count() == 7, "Level 4 must have 7 palace platforms")
		assert(mgr.bombs_node.get_child_count() == 24, "Level 4 must have 24 bombs")
		assert(mgr.qirimli_ally == null, "Level 4 Qirimli ally waits for progressive arrival")
		mgr.bombs_collected_on_level = 4
		mgr._check_progressive_ally_arrival()
		assert(mgr.hutsul_ally != null and mgr.qirimli_ally != null, "Level 4 must progressively spawn both allies")
		var moskal_count_lvl4 := 0
		for e in mgr.enemies_node.get_children():
			if e.enemy_type == FolkloreEnemy.EnemyType.MOSKAL:
				moskal_count_lvl4 += 1
		assert(moskal_count_lvl4 >= 2, "Level 4 must feature at least 2 Moskal enemies")
		assert(mgr.story_cards.has_story_for_level(4), "Level 4 must have story cards")
		print("[OK] Level 4 Baturyn Hetmanate verified: Progressive allies, 2 Moskals, Story Cards!")
		
		# Test Level 5 (Perekop & Bakhchysarai)
		print("Simulating transition to Level 5 (Perekop & Bakhchysarai)...")
		mgr.level = 5
		mgr._setup_level()
		assert(mgr.level == 5, "Level should now be 5")
		assert(mgr.platforms_node.get_child_count() == 8, "Level 5 must have 8 rampart platforms")
		assert(mgr.bombs_node.get_child_count() == 24, "Level 5 must have 24 bombs")
		mgr.bombs_collected_on_level = 4
		mgr._check_progressive_ally_arrival()
		assert(mgr.qirimli_ally != null, "Level 5 must progressively spawn Qirimli ally")
		assert(mgr.hutsul_ally != null, "Level 5 must progressively spawn Carpathian Hutsul ally with Bartka")
		
		# Test autonomous jumping of both allies (just like Dzhura)
		mgr.hutsul_ally._perform_jump()
		assert(mgr.hutsul_ally.velocity.y < 0.0, "Hutsul ally must jump upward autonomously")
		mgr.qirimli_ally._perform_jump()
		assert(mgr.qirimli_ally.velocity.y < 0.0, "Qirimli ally must jump upward autonomously")
		print("[OK] Autonomous platformer movement and jumping for Hutsul & Qirimli allies verified!")
		
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
		print("[OK] Carpathian Hutsul melee Bartka strike, one-time Bartka throw, and scene exit verified!")
		
		# Test Qirimli one-time Steppe Falcon launch against Unclean Forces
		assert(mgr.qirimli_ally.has_launched_falcon == false, "Falcon must not be launched before trigger")
		var first_launch: bool = mgr.qirimli_ally.launch_falcon()
		assert(first_launch == true, "First falcon launch must succeed")
		assert(mgr.qirimli_ally.has_launched_falcon == true, "has_launched_falcon must be true after launch")
		var second_launch: bool = mgr.qirimli_ally.launch_falcon()
		assert(second_launch == false, "Second falcon launch on same level must be blocked (one-time invariant)")
		print("[OK] Qirimli one-time Steppe Falcon launch against Unclean Forces verified!")
		
		var moskal_count_lvl5 := 0
		for e in mgr.enemies_node.get_children():
			if e.enemy_type == FolkloreEnemy.EnemyType.MOSKAL:
				moskal_count_lvl5 += 1
		assert(moskal_count_lvl5 >= 3, "Level 5 must feature 3 Moskal enemies")
		assert(mgr.story_cards.has_story_for_level(5), "Level 5 must have story cards")
		print("[OK] Level 5 Perekop & Bakhchysarai verified: Qirimli ally, 3 Moskals, Story Cards!")
		
		# Test story cards for level 3 (Qirimli ally)
		print("Testing Story Cards for Level 3...")
		assert(mgr.story_cards.has_story_for_level(3), "Level 3 must have story cards")
		mgr.story_cards.show_story_for_level(3)
		assert(mgr.story_cards.is_active, "StoryCards must be active for level 3")
		assert(mgr.story_cards.slides.size() == 3, "Level 3 must have 3 story slides")
		mgr.story_cards._finish_story()
		assert(not mgr.story_cards.is_active, "StoryCards must close after finish")
		print("[OK] Level 3 Story Cards (Qirimli & Kamianets) verified!")
		
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

		# Test 2K 16:9 Widescreen Viewport
		var v_size = root.get_viewport().get_visible_rect().size
		print("[OK] 2K 16:9 Viewport resolution: %s (Aspect: %.4f)" % [v_size, v_size.x / v_size.y])
		assert(is_equal_approx(v_size.x / v_size.y, 16.0 / 9.0), "Aspect ratio must be 16:9 2K")
		
		print("--- ALL LEVEL 1 & LEVEL 2 TESTS PASSED! ---")
		quit(0)
		return true
	return false
