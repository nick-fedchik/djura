extends CharacterBody2D

class_name JackPlayer
const _LevelRoot = preload("res://scripts/level_root.gd")

signal collected_bomb(bomb)
signal died
signal hopak_started
signal hopak_finished
signal vakula_shoes_state_changed(is_active: bool)
signal combat_move_performed(move_id: String)

const SPEED: float = 240.0
const JUMP_VELOCITY: float = -620.0
const NORMAL_GRAVITY: float = 1100.0
const GLIDE_FALL_SPEED: float = 75.0
const GLIDE_DECEL: float = 1400.0
const FLAP_BOOST: float = -190.0
const FAST_DROP_SPEED: float = 650.0

var facing_direction: float = 1.0
var is_gliding: bool = false
var is_fast_dropping: bool = false
var flap_timer: float = 0.0
var run_cycle: float = 0.0
var step_accumulator: float = 0.0
var step_alternate: bool = false
var was_on_floor: bool = true

# Responsive Platformer Timers (Coyote time & Jump buffer)
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

# Parkour Landing & Acrobatic Rolls
var is_rolling: bool = false
var roll_timer: float = 0.0
var roll_duration: float = 0.36
var roll_dir: float = 1.0
var squat_timer: float = 0.0
var prev_velocity_y: float = 0.0

# Combat Hopak Victory Celebration
var is_hopak: bool = false
var hopak_waiting_for_floor: bool = false
var hopak_wait_timer: float = 0.0
var hopak_time: float = 0.0
var hopak_duration: float = 4.10
var hopak_sfx_played: Dictionary = {}

# 3D Animation & Secondary Physics
var time_passed: float = 0.0
var squash_stretch: Vector2 = Vector2.ONE
var body_tilt: float = 0.0
var chub_lag: float = 0.0
var chub_vel: float = 0.0
var cape_wave: float = 0.0
var tassel_swing: float = 0.0
var tassel_vel: float = 0.0
var blink_timer: float = 2.8
var is_blinking: bool = false

var snd_jump = preload("res://assets/audio/jump.wav")
var snd_flap = preload("res://assets/audio/flap.wav")
var snd_drop = preload("res://assets/audio/drop.wav")
var snd_step1 = preload("res://assets/audio/step1.wav")
var snd_step2 = preload("res://assets/audio/step2.wav")
var snd_land = preload("res://assets/audio/land.wav")
var snd_roll = preload("res://assets/audio/roll.wav")
var snd_hopak_punch = preload("res://assets/audio/hopak_punch.wav")
var snd_hopak_kick = preload("res://assets/audio/hopak_kick.wav")
var snd_bonk = preload("res://assets/audio/bonk.wav")
var snd_magic_flower = preload("res://assets/audio/magic_flower.wav")

var bonk_timer: float = 0.0
var is_charakterite: bool = false
var charakterite_timer: float = 0.0
var has_vakula_shoes: bool = false
var vakula_shoes_timer: float = 0.0
var invulnerable_timer: float = 0.0

# Чемпіонські навички боксу (Клички та Усик) + Козацькі удари ногами з Бойового Гопака!
enum ChampionSkill {
	STEELHAMMER_JAB,       # Володимир Кличко: нищівний сталевий джеб з ударною хвилею
	IRONFIST_HOOK,         # Віталій Кличко: залізний хук/оверхенд згори
	USYK_SLIP_COUNTER,     # Олександр Усик: човник, нирок та серійний контрудар
	UNDISPUTED_TRIO,       # Абсолютний Чемпіон (Тріумф трьох легенд — Золота Хвиля Тризуба)
	HOPAK_TYNOK_KICK,      # Бойовий Гопак: високий прямий удар ногою «Тинок» у сап'янці з золотою підковою!
	HOPAK_SHCHUPAK_SPLIT,  # Бойовий Гопак: подвійний удар двома ногами в стрибку «Щупак / Різножка»!
	HOPAK_POVZUNETS_SWEEP  # Бойовий Гопак: низька обертова підсічка ногою «Повзунець / Коса»!
}

var unlocked_skills: Array[ChampionSkill] = []
var punch_timer: float = 0.0
var punch_active_skill: ChampionSkill = ChampionSkill.STEELHAMMER_JAB
var punch_facing: float = 1.0
var strike_combo_step: int = 0
var strike_combo_reset_timer: float = 0.0
var strike_effects: Array[Dictionary] = []

func unlock_champion_skill(skill: ChampionSkill) -> void:
	if not unlocked_skills.has(skill):
		unlocked_skills.append(skill)

var audio_player: AudioStreamPlayer

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var speech_bubble: SpeechBubble = get_node_or_null("SpeechBubble")
@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "Master"
	add_child(audio_player)
	_init_animated_sprite()

func _init_animated_sprite() -> void:
	if not animated_sprite:
		return
	
	if ResourceLoader.exists("res://assets/sprites/djura_frames.tres"):
		var tres = load("res://assets/sprites/djura_frames.tres") as SpriteFrames
		if tres != null:
			animated_sprite.sprite_frames = tres
			animated_sprite.play("idle")
			return

	# Фолбек на пряме завантаження з assets/sprites/djura_sheet.png
	if FileAccess.file_exists("res://assets/sprites/djura_sheet.png") and FileAccess.file_exists("res://assets/sprites/djura_manifest.json"):
		var img := Image.load_from_file("res://assets/sprites/djura_sheet.png")
		var json_str := FileAccess.get_file_as_string("res://assets/sprites/djura_manifest.json")
		var manifest = JSON.parse_string(json_str)
		if img != null and manifest is Dictionary and manifest.has("frames"):
			var tex := ImageTexture.create_from_image(img)
			var sf := SpriteFrames.new()
			var fps: float = float(manifest.get("fps", 12))
			for fr in manifest["frames"]:
				var anim_name: String = fr["animation"]
				if not sf.has_animation(anim_name):
					sf.add_animation(anim_name)
					sf.set_animation_speed(anim_name, fps)
					sf.set_animation_loop(anim_name, (anim_name != "bonk"))
				var at := AtlasTexture.new()
				at.atlas = tex
				at.region = Rect2(float(fr["x"]), float(fr["y"]), float(fr["w"]), float(fr["h"]))
				sf.add_frame(anim_name, at)
			animated_sprite.sprite_frames = sf
			animated_sprite.play("idle")
			return

func _play_sfx(stream: AudioStream, pitch_scale: float = 1.0) -> void:
	var sfx := AudioStreamPlayer2D.new()
	sfx.bus = "Master"
	sfx.stream = stream
	sfx.pitch_scale = pitch_scale
	sfx.max_distance = 1500.0
	sfx.attenuation = 0.3
	sfx.finished.connect(sfx.queue_free)
	add_child(sfx)
	sfx.play()

func reset_to_normal_state(spawn_pos: Vector2 = Vector2(480, 494)) -> void:
	is_hopak = false
	hopak_waiting_for_floor = false
	hopak_wait_timer = 0.0
	hopak_time = 0.0
	hopak_sfx_played.clear()
	bonk_timer = 0.0
	is_charakterite = false
	charakterite_timer = 0.0
	if has_vakula_shoes:
		has_vakula_shoes = false
		_clear_vakula_platform_exceptions()
		vakula_shoes_state_changed.emit(false)
	vakula_shoes_timer = 0.0
	invulnerable_timer = 0.0
	is_gliding = false
	is_fast_dropping = false
	is_rolling = false
	roll_timer = 0.0
	squat_timer = 0.0
	flap_timer = 0.0
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	run_cycle = 0.0
	step_accumulator = 0.0
	velocity = Vector2.ZERO
	prev_velocity_y = 0.0
	body_tilt = 0.0
	squash_stretch = Vector2.ONE
	chub_lag = 0.0
	facing_direction = 1.0
	position = spawn_pos
	was_on_floor = true
	queue_redraw()

func say(text: String, duration: float = 1.8) -> void:
	if not speech_bubble:
		speech_bubble = get_node_or_null("SpeechBubble")
	if speech_bubble:
		speech_bubble.say(text, duration)

func activate_charakterite(duration: float = 8.0) -> void:
	is_charakterite = true
	charakterite_timer = duration
	_play_sfx(snd_magic_flower)
	var phrases: Array[String] = ["Ану, чортяки, начувайтеся!", "Чари Характерника!", "Дзуськи, нечиста сило!"]
	say(phrases.pick_random(), 2.0)

func activate_vakula_shoes(duration: float = 14.0) -> void:
	has_vakula_shoes = true
	vakula_shoes_timer = duration
	vakula_shoes_state_changed.emit(true)
	_update_vakula_platform_pass_through()
	var phrases: Array[String] = [
		"Підківки Вакули! Прострибую крізь балки!",
		"Оце так підкували! Стрибаю вище зірок!",
		"Дякую, майстре Вакуло! Балки не перепона!"
	]
	say(phrases.pick_random(), 2.2)

func _update_vakula_platform_pass_through() -> void:
	var par = _LevelRoot.of(self)
	if not par or not par.has_node("Platforms"):
		return
	var player_feet_y := global_position.y + 16.0
	for plat in par.get_node("Platforms").get_children():
		if plat is BombJackPlatform and is_instance_valid(plat):
			var plat_top_y: float = plat.global_position.y - plat.height * 0.5
			if has_vakula_shoes and (velocity.y < 0.0 or player_feet_y > plat_top_y + 3.0):
				add_collision_exception_with(plat)
			else:
				remove_collision_exception_with(plat)

func _clear_vakula_platform_exceptions() -> void:
	var par = _LevelRoot.of(self)
	if not par or not par.has_node("Platforms"):
		return
	for plat in par.get_node("Platforms").get_children():
		if plat is PhysicsBody2D and is_instance_valid(plat):
			remove_collision_exception_with(plat)

func take_hit(from_pos: Vector2) -> void:
	if is_charakterite or invulnerable_timer > 0.0 or is_hopak:
		return
	invulnerable_timer = 1.2
	var dir := signf(global_position.x - from_pos.x)
	if absf(dir) < 0.1:
		dir = 1.0
	velocity = Vector2(dir * 280.0, -320.0)
	squash_stretch = Vector2(1.25, 0.75)
	_play_sfx(snd_bonk, 0.85)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C or event.keycode == KEY_K or event.keycode == KEY_Z:
			_perform_hopak_kick()
			return
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_B or event.button_index == JOY_BUTTON_Y or event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			_perform_hopak_kick()
			return
		if event.button_index == JOY_BUTTON_X or event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			_perform_champion_punch()
			return
	if event.is_action_pressed("attack") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_X or event.keycode == KEY_J or event.keycode == KEY_CTRL)):
		_perform_champion_punch()

func _spawn_strike_effect(local_pos: Vector2, col: Color, is_kick: bool = false, is_hit: bool = false) -> void:
	strike_effects.append({
		"pos": local_pos,
		"color": col,
		"is_kick": is_kick,
		"is_hit": is_hit,
		"dir": punch_facing,
		"time": 0.0,
		"duration": 0.38 if is_hit else 0.28
	})

func _perform_hopak_kick() -> void:
	if punch_timer > 0.0 or is_hopak or bonk_timer > 0.0:
		return
	punch_timer = 0.35
	punch_facing = facing_direction
	
	if not is_on_floor():
		punch_active_skill = ChampionSkill.HOPAK_SHCHUPAK_SPLIT
		_play_sfx(snd_hopak_kick, 1.25)
		say("Бойовий Гопак: Повітряна Різножка — Щупак!", 1.5)
		_spawn_strike_effect(Vector2(28.0, 2.0), Color(1.0, 0.86, 0.20), true, false)
		_spawn_strike_effect(Vector2(-28.0, 2.0), Color(1.0, 0.86, 0.20), true, false)
		combat_move_performed.emit("hopak_kick")
		combat_move_performed.emit("air_slam_combo")
	elif Input.is_action_pressed("move_down"):
		punch_active_skill = ChampionSkill.HOPAK_POVZUNETS_SWEEP
		_play_sfx(snd_hopak_kick, 0.92)
		say("Бойовий Гопак: Підсічка Повзунець!", 1.5)
		_spawn_strike_effect(Vector2(28.0 * punch_facing, 13.0), Color(1.0, 0.65, 0.15), true, false)
		combat_move_performed.emit("hopak_kick")
		combat_move_performed.emit("roll_strike_combo")
	else:
		punch_active_skill = ChampionSkill.HOPAK_TYNOK_KICK
		_play_sfx(snd_hopak_kick, 1.12)
		say("Бойовий Гопак: Високий удар ногою — Тинок!", 1.5)
		_spawn_strike_effect(Vector2(30.0 * punch_facing, -6.0), Color(1.0, 0.35, 0.22), true, false)
		combat_move_performed.emit("hopak_kick")
		combat_move_performed.emit("basic_strike")
	
	_check_strike_hitbox()
	queue_redraw()

func _perform_champion_punch() -> void:
	if punch_timer > 0.0 or is_hopak or bonk_timer > 0.0:
		return
	
	# Якщо гравець натискає [Вниз ↓ + Удар] на землі — виконуємо козацький перекат «Повзунець» / «Човник Усика» або підсічку ногою!
	if is_on_floor() and not is_rolling and Input.is_action_pressed("move_down"):
		if strike_combo_step % 2 == 1:
			strike_combo_step += 1
			strike_combo_reset_timer = 1.2
			_perform_hopak_kick()
			return
		is_rolling = true
		roll_duration = 0.36
		roll_timer = roll_duration
		var move_in := Input.get_axis("move_left", "move_right")
		roll_dir = facing_direction if absf(move_in) <= 0.15 else signf(move_in)
		facing_direction = roll_dir
		_play_sfx(snd_roll)
	
	punch_timer = 0.32
	punch_facing = facing_direction
	var current_step := strike_combo_step
	strike_combo_step = (strike_combo_step + 1) % 3
	strike_combo_reset_timer = 1.2
	
	# Select active strike based on state, combo chain step, and unlocked skills
	if is_rolling:
		combat_move_performed.emit("roll_strike_combo")
		if ChampionSkill.USYK_SLIP_COUNTER in unlocked_skills:
			punch_active_skill = ChampionSkill.USYK_SLIP_COUNTER
			_play_sfx(snd_hopak_punch, 1.35)
			say("Усик: Човник та ухил!", 1.4)
			_spawn_strike_effect(Vector2(28.0 * punch_facing, -9.0), Color(0.20, 0.95, 0.85), false, false)
			combat_move_performed.emit("usyk_slip_counter")
		else:
			punch_active_skill = ChampionSkill.HOPAK_POVZUNETS_SWEEP
			_play_sfx(snd_hopak_kick, 1.05)
			say("Козацький Повзунець з підсічкою ногою!", 1.4)
			_spawn_strike_effect(Vector2(28.0 * punch_facing, 11.0), Color(1.0, 0.72, 0.18), true, false)
			combat_move_performed.emit("hopak_kick")
	elif not is_on_floor() or is_fast_dropping:
		combat_move_performed.emit("air_slam_combo")
		if current_step == 2 and not (ChampionSkill.IRONFIST_HOOK in unlocked_skills and strike_combo_step == 1):
			# У повітрі кожен 3-й удар серії — подвійний шпагат двома ногами «Щупак / Різножка»!
			punch_active_skill = ChampionSkill.HOPAK_SHCHUPAK_SPLIT
			_play_sfx(snd_hopak_kick, 1.28)
			say("Бойовий Гопак: Повітряний Щупак двома ногами!", 1.4)
			_spawn_strike_effect(Vector2(28.0, 2.0), Color(1.0, 0.88, 0.22), true, false)
			_spawn_strike_effect(Vector2(-28.0, 2.0), Color(1.0, 0.88, 0.22), true, false)
			combat_move_performed.emit("hopak_kick")
		elif ChampionSkill.IRONFIST_HOOK in unlocked_skills:
			punch_active_skill = ChampionSkill.IRONFIST_HOOK
			_play_sfx(snd_hopak_punch, 0.95)
			say("Віталій: Залізний оверхенд!", 1.4)
			_spawn_strike_effect(Vector2(24.0 * punch_facing, 4.0), Color(1.0, 0.55, 0.15), false, false)
			combat_move_performed.emit("ironfist_hook")
		else:
			punch_active_skill = ChampionSkill.HOPAK_SHCHUPAK_SPLIT
			_play_sfx(snd_hopak_kick, 1.22)
			say("Повітряний удар ногами — Щупак!", 1.4)
			_spawn_strike_effect(Vector2(26.0, 2.0), Color(1.0, 0.85, 0.20), true, false)
			_spawn_strike_effect(Vector2(-26.0, 2.0), Color(1.0, 0.85, 0.20), true, false)
			combat_move_performed.emit("hopak_kick")
	elif current_step == 2 and unlocked_skills.is_empty():
		# На землі у серії ударів Джура завершує комбо високим ударом ноги «Тинок»!
		punch_active_skill = ChampionSkill.HOPAK_TYNOK_KICK
		_play_sfx(snd_hopak_kick, 1.15)
		say("Бойовий Гопак: Удар чоботом — Тинок!", 1.4)
		_spawn_strike_effect(Vector2(30.0 * punch_facing, -6.0), Color(1.0, 0.38, 0.22), true, false)
		combat_move_performed.emit("basic_strike")
		combat_move_performed.emit("hopak_kick")
	elif ChampionSkill.UNDISPUTED_TRIO in unlocked_skills:
		punch_active_skill = ChampionSkill.UNDISPUTED_TRIO
		_play_sfx(snd_hopak_punch, 1.25)
		say("Абсолютна чемпіонська серія!", 1.4)
		_spawn_strike_effect(Vector2(32.0 * punch_facing, -8.0), Color(1.0, 0.92, 0.25), false, false)
		combat_move_performed.emit("basic_strike")
		combat_move_performed.emit("steelhammer_jab")
		combat_move_performed.emit("undisputed_trio")
	elif ChampionSkill.STEELHAMMER_JAB in unlocked_skills:
		punch_active_skill = ChampionSkill.STEELHAMMER_JAB
		_play_sfx(snd_hopak_punch, 1.10)
		say("Володимир: Сталевий джеб!", 1.4)
		_spawn_strike_effect(Vector2(28.0 * punch_facing, -10.0), Color(0.35, 0.82, 1.0), false, false)
		combat_move_performed.emit("basic_strike")
		combat_move_performed.emit("steelhammer_jab")
	else:
		punch_active_skill = ChampionSkill.STEELHAMMER_JAB
		_play_sfx(snd_hopak_punch, 1.08)
		say("Козацький прямий удар — Тичок!", 1.4)
		_spawn_strike_effect(Vector2(25.0 * punch_facing, -10.0), Color(1.0, 0.85, 0.25), false, false)
		combat_move_performed.emit("basic_strike")
	
	_check_strike_hitbox()
	queue_redraw()

func _check_strike_hitbox() -> void:
	var strike_reach := 72.0
	var is_split_kick := (punch_active_skill == ChampionSkill.HOPAK_SHCHUPAK_SPLIT)
	var is_sweep_kick := (punch_active_skill == ChampionSkill.HOPAK_POVZUNETS_SWEEP)
	var is_kick := is_split_kick or is_sweep_kick or (punch_active_skill == ChampionSkill.HOPAK_TYNOK_KICK)
	if punch_active_skill == ChampionSkill.UNDISPUTED_TRIO:
		strike_reach = 98.0
	elif is_split_kick:
		strike_reach = 84.0
	elif is_kick:
		strike_reach = 78.0
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		var par = _LevelRoot.of(self)
		if par and par.has_node("Enemies"):
			for c in par.get_node("Enemies").get_children():
				if c is FolkloreEnemy and not c.is_queued_for_deletion():
					enemies.append(c)
	
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			var dist := global_position.distance_to(enemy.global_position)
			var in_front := is_split_kick or (signf(enemy.global_position.x - global_position.x) == punch_facing)
			if dist <= strike_reach and (in_front or dist < 34.0):
				var hit_local: Vector2 = enemy.global_position - global_position
				_spawn_strike_effect(hit_local, Color(1.0, 0.92, 0.22), is_kick, true)
				var push_x := signf(hit_local.x) if absf(hit_local.x) > 4.0 else punch_facing
				# Successful punch or kick hit on enemy!
				if enemy.enemy_type == FolkloreEnemy.EnemyType.MOSKAL:
					if enemy.absorb_strike():
						enemy.velocity.x = push_x * 165.0
						_play_sfx(snd_bonk, 0.90) # Збили панцир/шапку з Опричника, Воєводи чи Генерала!
						continue
					enemy.make_scared(9.0)
					enemy.velocity.x = push_x * (320.0 if is_kick else 270.0)
					if is_sweep_kick:
						enemy.position.y -= 18.0
					_play_sfx(snd_bonk, 1.25)
				elif enemy.enemy_type == FolkloreEnemy.EnemyType.CHORT:
					enemy._play_poof()
					enemy.defeated.emit(enemy, 600 if is_kick else 500)
					enemy.queue_free()
				else:
					if enemy.absorb_strike():
						_play_sfx(snd_bonk, 0.85) # щит відьми-інженера поглинув удар
						continue
					enemy.make_scared(7.5)
					enemy.velocity = Vector2(push_x * 280.0, -220.0 if is_sweep_kick else -120.0)
					_play_sfx(snd_bonk, 1.15)

func celebrate_victory(duration: float = 4.10) -> void:
	is_hopak = true
	hopak_time = 0.0
	hopak_duration = duration
	hopak_sfx_played.clear()
	bonk_timer = 0.0
	velocity.x = 0.0
	is_gliding = false
	is_fast_dropping = false
	is_rolling = false
	roll_timer = 0.0
	squat_timer = 0.0
	flap_timer = 0.0
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	run_cycle = 0.0
	body_tilt = 0.0
	squash_stretch = Vector2.ONE
	
	if not is_on_floor():
		hopak_waiting_for_floor = true
		hopak_wait_timer = 0.0
		velocity.y = max(velocity.y, 480.0)
	else:
		hopak_waiting_for_floor = false
		hopak_wait_timer = 0.0
		velocity.y = 0.0
		call_deferred("emit_signal", "hopak_started")
	queue_redraw()

func _physics_process(delta: float) -> void:
	time_passed += delta
	
	if punch_timer > 0.0:
		punch_timer -= delta
	if strike_combo_reset_timer > 0.0:
		strike_combo_reset_timer -= delta
		if strike_combo_reset_timer <= 0.0:
			strike_combo_step = 0
	
	var active_fx: Array[Dictionary] = []
	for fx in strike_effects:
		fx["time"] = float(fx["time"]) + delta
		if float(fx["time"]) < float(fx["duration"]):
			active_fx.append(fx)
	strike_effects = active_fx
	
	if charakterite_timer > 0.0:
		charakterite_timer -= delta
		if charakterite_timer <= 0.0:
			is_charakterite = false
	
	if has_vakula_shoes:
		vakula_shoes_timer -= delta
		if vakula_shoes_timer <= 0.0:
			has_vakula_shoes = false
			_clear_vakula_platform_exceptions()
			vakula_shoes_state_changed.emit(false)
	
	if invulnerable_timer > 0.0:
		invulnerable_timer -= delta
	
	if is_hopak:
		velocity.x = 0.0
		if hopak_waiting_for_floor:
			hopak_wait_timer += delta
			velocity.y = max(velocity.y + NORMAL_GRAVITY * 1.8 * delta, 520.0)
			move_and_slide()
			if is_on_floor() or hopak_wait_timer >= 0.48:
				hopak_waiting_for_floor = false
				velocity.y = 0.0
				squash_stretch = Vector2(1.22, 0.82)
				_play_sfx(snd_land, 1.0)
				hopak_started.emit()
			queue_redraw()
			return
		
		hopak_time += delta
		if not is_on_floor():
			velocity.y += NORMAL_GRAVITY * delta
		else:
			velocity.y = 0.0
		
		squash_stretch = squash_stretch.lerp(Vector2.ONE, delta * 14.0)
		body_tilt = lerp_angle(body_tilt, 0.0, delta * 14.0)
		cape_wave += delta * 16.0
		
		# Trigger 6-Phase Combat Hopak sound effects at precise choreographic beats
		# Phase 1: Straight Punch Left ("Тичок")
		if hopak_time >= 0.14 and not hopak_sfx_played.get("punch1", false):
			hopak_sfx_played["punch1"] = true
			_play_sfx(snd_hopak_punch, 1.05)
		# Phase 2: Cross Punch Right ("Козацький хрест")
		if hopak_time >= 0.82 and not hopak_sfx_played.get("punch2", false):
			hopak_sfx_played["punch2"] = true
			_play_sfx(snd_hopak_punch, 1.18)
		# Phase 3: High Flying Kick ("Тинок")
		if hopak_time >= 1.50 and not hopak_sfx_played.get("kick1", false):
			hopak_sfx_played["kick1"] = true
			_play_sfx(snd_hopak_kick, 1.10)
		# Phase 4: Airborne Split Kick ("Щупак / Різножка")
		if hopak_time >= 2.20 and not hopak_sfx_played.get("kick_split", false):
			hopak_sfx_played["kick_split"] = true
			_play_sfx(snd_hopak_kick, 1.28)
		# Phase 5: Low Squat Sweep Kick ("Пістоль / Повзунець")
		if hopak_time >= 2.90 and not hopak_sfx_played.get("kick2", false):
			hopak_sfx_played["kick2"] = true
			_play_sfx(snd_hopak_kick, 0.90)
		# Phase 6: Final Boots Stomp ("Козак у поли")
		if hopak_time >= 3.52 and not hopak_sfx_played.get("stomp", false):
			hopak_sfx_played["stomp"] = true
			_play_sfx(snd_land, 1.12)
		
		move_and_slide()
		
		if hopak_time >= hopak_duration:
			is_hopak = false
			hopak_time = 0.0
			hopak_waiting_for_floor = false
			body_tilt = 0.0
			squash_stretch = Vector2.ONE
			velocity = Vector2.ZERO
			queue_redraw()
			hopak_finished.emit()
			return
		
		queue_redraw()
		return
	
	var move_input := Input.get_axis("move_left", "move_right")
	
	if is_rolling:
		roll_timer -= delta
		var p: float = 1.0 - (roll_timer / roll_duration)
		body_tilt = roll_dir * p * TAU
		velocity.x = roll_dir * SPEED * 1.15
		squash_stretch = Vector2(0.92, 0.92)
		if roll_timer <= 0.0:
			is_rolling = false
			body_tilt = 0.0
	else:
		if squat_timer > 0.0:
			squat_timer -= delta
			if abs(move_input) > 0.15:
				facing_direction = sign(move_input)
				velocity.x = move_input * SPEED * 0.45
			else:
				velocity.x = move_toward(velocity.x, 0.0, SPEED * 10.0 * delta)
		else:
			if abs(move_input) > 0.15:
				facing_direction = sign(move_input)
				velocity.x = move_input * SPEED
				run_cycle += delta * 15.0
			else:
				velocity.x = move_toward(velocity.x, 0.0, SPEED * 8.0 * delta)
				run_cycle = move_toward(run_cycle, 0.0, delta * 8.0)
		
		# Smooth squash and stretch relaxation
		squash_stretch = squash_stretch.lerp(Vector2.ONE, delta * 12.0)
		
		# Parkour forward lean
		var target_tilt = (velocity.x / SPEED) * 0.16
		body_tilt = lerp_angle(body_tilt, target_tilt, delta * 14.0)
	
	# Secondary spring-damper motion for Cossack hair chub, sash tassels and cape
	var target_chub := -velocity.x * 0.045 - (velocity.y * 0.022)
	var chub_force := (target_chub - chub_lag) * 140.0 - chub_vel * 12.0
	chub_vel += chub_force * delta
	chub_lag = clampf(chub_lag + chub_vel * delta, -14.0, 14.0)
	
	var target_tassel := -velocity.x * 0.025 + sin(time_passed * 7.5) * 1.6
	var tassel_force := (target_tassel - tassel_swing) * 120.0 - tassel_vel * 10.0
	tassel_vel += tassel_force * delta
	tassel_swing = clampf(tassel_swing + tassel_vel * delta, -9.0, 9.0)
	
	cape_wave += delta * (18.0 if is_gliding else 10.0)
	
	# Natural cartoon eye blinking cycle
	blink_timer -= delta
	if blink_timer <= 0.0:
		if is_blinking:
			is_blinking = false
			blink_timer = randf_range(2.6, 4.4)
		else:
			is_blinking = true
			blink_timer = 0.11
	
	var is_jumping := Input.is_action_just_pressed("jump")
	var is_jump_held := Input.is_action_pressed("jump")
	var is_down_pressed := Input.is_action_pressed("move_down")
	var is_down_just_pressed := Input.is_action_just_pressed("move_down")
	
	var currently_on_floor := is_on_floor()
	if currently_on_floor:
		coyote_timer = 0.08
	elif coyote_timer > 0.0:
		coyote_timer -= delta
	
	if is_jumping:
		jump_buffer_timer = 0.10
	elif jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta
	
	if currently_on_floor:
		# Landing from airborne state
		if not was_on_floor:
			is_gliding = false
			is_fast_dropping = false
			if prev_velocity_y > 330.0:
				# High impact fall
				if abs(move_input) > 0.15 or abs(velocity.x) > 40.0:
					# DIRECTIONAL IMPACT -> PARKOUR ROLL!
					is_rolling = true
					roll_duration = 0.36
					roll_timer = roll_duration
					roll_dir = facing_direction if abs(move_input) <= 0.15 else sign(move_input)
					facing_direction = roll_dir
					squat_timer = 0.0
					_play_sfx(snd_roll)
				else:
					# VERTICAL IMPACT -> DEEP ABSORPTION SQUAT!
					squat_timer = 0.24
					squash_stretch = Vector2(1.52, 0.48)
					_play_sfx(snd_land, 0.85)
			else:
				# Light jump landing
				squash_stretch = Vector2(1.22, 0.82)
				_play_sfx(snd_land, randf_range(0.98, 1.05))
		
		is_gliding = false
		is_fast_dropping = false
		
		# Footsteps during ground sprint (only when not rolling or deep squatting)
		if not is_rolling and squat_timer <= 0.0 and abs(move_input) > 0.15:
			step_accumulator += abs(velocity.x) * delta
			if step_accumulator >= 32.0:
				step_accumulator = 0.0
				var step_sfx = snd_step1 if step_alternate else snd_step2
				step_alternate = not step_alternate
				_play_sfx(step_sfx, randf_range(0.92, 1.08))
		else:
			step_accumulator = 20.0
		
		if not is_rolling and jump_buffer_timer > 0.0:
			jump_buffer_timer = 0.0
			coyote_timer = 0.0
			var jump_power := JUMP_VELOCITY * (1.18 if has_vakula_shoes else 1.0)
			velocity.y = jump_power
			squash_stretch = Vector2(0.82, 1.25)
			squat_timer = 0.0
			_play_sfx(snd_jump)
	else:
		step_accumulator = 0.0
		is_rolling = false
		squat_timer = 0.0
		
		# Coyote time jump from edge
		if not is_rolling and jump_buffer_timer > 0.0 and coyote_timer > 0.0:
			jump_buffer_timer = 0.0
			coyote_timer = 0.0
			var jump_power := JUMP_VELOCITY * (1.18 if has_vakula_shoes else 1.0)
			velocity.y = jump_power
			squash_stretch = Vector2(0.82, 1.25)
			_play_sfx(snd_jump)
		elif bonk_timer > 0.0:
			# Falling naturally after head collision with platform underside / ceiling
			is_gliding = false
			is_fast_dropping = false
			velocity.y += NORMAL_GRAVITY * delta
		elif is_down_pressed:
			if not is_fast_dropping and is_down_just_pressed:
				_play_sfx(snd_drop)
			is_fast_dropping = true
			is_gliding = false
			velocity.y = max(velocity.y, FAST_DROP_SPEED)
			squash_stretch = Vector2(0.88, 1.18)
		else:
			is_fast_dropping = false
			
			# Airborne Flap & Flutter mechanics
			if is_jumping:
				# Flap wing-cape boost mid-air
				velocity.y = min(velocity.y, 0.0) + FLAP_BOOST
				is_gliding = true
				flap_timer = 0.18
				squash_stretch = Vector2(1.15, 0.90)
				_play_sfx(snd_flap, randf_range(0.95, 1.05))
			elif velocity.y < 0.0:
				# Ascending phase: variable jump height control
				if is_jump_held:
					velocity.y += NORMAL_GRAVITY * 0.85 * delta
				elif velocity.y < -120.0:
					velocity.y = move_toward(velocity.y, -120.0, 1600.0 * delta)
				else:
					velocity.y += NORMAL_GRAVITY * delta
			else:
				# Descending phase: glide or fall
				if is_jump_held:
					is_gliding = true
					velocity.y = move_toward(velocity.y, GLIDE_FALL_SPEED, GLIDE_DECEL * delta)
				else:
					is_gliding = false
					velocity.y += NORMAL_GRAVITY * delta
	
	if flap_timer > 0.0:
		flap_timer -= delta
	if bonk_timer > 0.0:
		bonk_timer -= delta
	
	# Track vertical velocity just before impact
	prev_velocity_y = velocity.y
	if has_vakula_shoes:
		_update_vakula_platform_pass_through()
	move_and_slide()
	position.x = clamp(position.x, 16.0, 944.0)
	was_on_floor = currently_on_floor
	
	# Detect collision with ceiling or underside of solid platforms
	if is_on_ceiling():
		var is_moving_sideways := absf(velocity.x) > 40.0 or absf(move_input) > 0.15
		if prev_velocity_y < -320.0 and not is_moving_sideways:
			# Heavy vertical impact against ceiling / beam when jumping in place!
			_play_sfx(snd_bonk, randf_range(0.95, 1.05))
			velocity.y = max(80.0, -prev_velocity_y * 0.18)
			squash_stretch = Vector2(1.36, 0.66)
			bonk_timer = 0.22
			is_gliding = false
			flap_timer = 0.0
			chub_lag = 9.0
			var bonk_phrases: Array[String] = ["Ой, ґуля буде!", "Оце так стеля!", "Хто тут балку поклав?!"]
			if has_vakula_shoes:
				bonk_phrases.append("Дотягнувся аж до самого неба!")
			say(bonk_phrases.pick_random(), 1.5)
		else:
			# Smooth ceiling sliding: horizontal trajectory preserved, zero bonk penalty
			velocity.y = 0.0
	
	_update_animated_sprite()
	queue_redraw()

func _update_animated_sprite() -> void:
	if not animated_sprite:
		return
	if invulnerable_timer > 0.0 and fmod(invulnerable_timer, 0.14) > 0.07:
		animated_sprite.visible = false
	else:
		animated_sprite.visible = true

	animated_sprite.flip_h = (facing_direction < 0)

	if bonk_timer > 0.0:
		if animated_sprite.animation != "bonk":
			animated_sprite.play("bonk")
	elif is_hopak:
		if animated_sprite.animation != "victory":
			animated_sprite.play("victory")
	elif punch_timer > 0.0:
		if animated_sprite.animation != "hopak_kick":
			animated_sprite.play("hopak_kick")
	elif not is_on_floor():
		if is_gliding:
			if animated_sprite.animation != "glide":
				animated_sprite.play("glide")
		else:
			if animated_sprite.animation != "jump":
				animated_sprite.play("jump")
	elif is_rolling:
		if animated_sprite.animation != "run":
			animated_sprite.play("run")
	elif absf(velocity.x) > 10.0:
		if animated_sprite.animation != "run":
			animated_sprite.play("run")
	else:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")

# Analytical 2-Bone Inverse Kinematics solver (Law of Cosines) for natural limb arcs
func _solve_2bone_ik(root: Vector2, target: Vector2, len1: float, len2: float, bend_sign: float) -> Vector2:
	var diff := target - root
	var dist := clampf(diff.length(), 0.5, len1 + len2 - 0.05)
	var dir := diff / maxf(diff.length(), 0.001)
	var perp := Vector2(-dir.y, dir.x) * bend_sign
	var cos_a := clampf((len1 * len1 + dist * dist - len2 * len2) / (2.0 * len1 * dist), -1.0, 1.0)
	var sin_a := sqrt(maxf(0.0, 1.0 - cos_a * cos_a))
	return root + dir * (len1 * cos_a) + perp * (len1 * sin_a)

# Computes continuous, smoothly interpolated 2026 anatomical skeletal joint positions
func _compute_skeletal_pose(flip: float, run_anim: float, on_ground: bool) -> Dictionary:
	# Base neutral standing pose (relative to character origin)
	var pelvis := Vector2(0.0, 0.0)
	var torso_angle := 0.0
	var torso_twist := 0.0
	var head_offset := Vector2(0.0, 0.0)
	var punch_streak := Vector2.ZERO
	
	var hip_l := Vector2(-3.5 * flip, 2.5)
	var hip_r := Vector2(3.5 * flip, 2.5)
	var knee_l := Vector2(-5.5 * flip, 7.5)
	var knee_r := Vector2(5.5 * flip, 7.5)
	var ankle_l := Vector2(-5.5 * flip, 12.2)
	var ankle_r := Vector2(5.5 * flip, 12.2)
	var foot_ang_l := 0.0
	var foot_ang_r := 0.0
	
	var shoulder_l := Vector2(-4.8 * flip, -8.5)
	var shoulder_r := Vector2(4.8 * flip, -8.5)
	var elbow_l := Vector2(-7.5 * flip, -3.0)
	var elbow_r := Vector2(7.5 * flip, -3.0)
	var wrist_l := Vector2(-6.5 * flip, 2.0)
	var wrist_r := Vector2(6.5 * flip, 2.0)
	var fist_l := false
	var fist_r := false
	var head_facing: float = flip
	
	if is_hopak and not hopak_waiting_for_floor:
		var t := hopak_time
		if t < 0.68:
			# PHASE 1 (0.00 - 0.68s): "Тичок лівою" - Athletic Horse Stance & Strike to the LEFT!
			var u := clampf(t / 0.68, 0.0, 1.0)
			var strike := sin(pow(u, 0.75) * PI)
			var stance := sin(minf(u * 2.2, 1.0) * PI * 0.5) if u < 0.8 else sin((1.0 - u) / 0.2 * PI * 0.5)
			
			# Head turns decisively to the LEFT (-1.0)
			head_facing = lerp(0.0, -1.0, smoothstep(0.0, 0.22, u))
			head_offset = Vector2(-2.2 * strike, 0.5 * strike)
			
			pelvis = Vector2(-2.0 * strike, 3.2 * stance)
			torso_angle = -0.11 * strike
			torso_twist = -0.65 * strike
			
			# Wide horse-stance articulated legs
			knee_l = pelvis + Vector2(-11.5, 5.0)
			ankle_l = Vector2(-11.0, 12.2)
			knee_r = pelvis + Vector2(10.0, 5.0)
			ankle_r = Vector2(9.5, 12.2)
			
			# Lead LEFT arm uncoils from guard into a straight punch to the LEFT!
			# Посилення розмаху та ударної хвилі при вивченні Сталевого Джебу Володимира Кличка
			var jab_reach := 29.5 if ChampionSkill.STEELHAMMER_JAB in unlocked_skills else 22.5
			elbow_l = pelvis + Vector2(-3.0, -3.5).lerp(Vector2(-12.5, -9.2), strike)
			wrist_l = pelvis + Vector2(-2.0, -7.5).lerp(Vector2(-jab_reach, -9.5), strike)
			fist_l = true
			if strike > 0.65:
				punch_streak = pelvis + Vector2(-jab_reach - 3.0, -9.5)
			
			# Rear RIGHT arm chambers tightly at ribs on the right
			elbow_r = pelvis + Vector2(6.0, -3.0).lerp(Vector2(9.5, -2.5), strike)
			wrist_r = pelvis + Vector2(5.0, 1.0).lerp(Vector2(2.5, -4.5), strike)
			fist_r = true
			
		elif t < 1.36:
			# PHASE 2 (0.68 - 1.36s): "Козацький хрест правою" - Strike to the RIGHT!
			var u := clampf((t - 0.68) / 0.68, 0.0, 1.0)
			var strike := sin(pow(u, 0.72) * PI)
			
			# Head whips dynamically from LEFT (-1.0) to the RIGHT (+1.0)!
			head_facing = lerp(-1.0, 1.0, smoothstep(0.0, 0.28, u))
			head_offset = Vector2(2.2 * strike, 0.8 * strike)
			
			pelvis = Vector2(3.5 * strike, 3.8 * strike)
			torso_angle = 0.15 * strike
			torso_twist = 0.80 * strike
			
			# Rear knee drives forward as hip pivots into the cross
			knee_l = pelvis + Vector2(-7.5, 5.5)
			ankle_l = Vector2(-11.0, 12.2)
			foot_ang_l = -0.18 * strike
			knee_r = pelvis + Vector2(11.5, 4.8)
			ankle_r = Vector2(10.5, 12.2)
			
			# Lead LEFT arm retracts to high cheek guard on the left
			elbow_l = pelvis + Vector2(-8.5, -2.0)
			wrist_l = pelvis + Vector2(-1.5, -9.0)
			fist_l = true
			
			# Rear RIGHT arm unleashes full cross punch to the RIGHT!
			# Посилення розмаху при вивченні Залізного Хука Віталія Кличка
			var cross_reach := 31.5 if ChampionSkill.IRONFIST_HOOK in unlocked_skills else 23.0
			elbow_r = pelvis + Vector2(3.0, -3.0).lerp(Vector2(12.5, -8.8), strike)
			wrist_r = pelvis + Vector2(1.0, -5.0).lerp(Vector2(cross_reach, -8.8), strike)
			fist_r = true
			if strike > 0.65:
				punch_streak = pelvis + Vector2(cross_reach + 3.0, -8.8)
				
		elif t < 2.06:
			# PHASE 3 (1.36 - 2.06s): "Тинок лівою" - High Flying Kick to the LEFT!
			var u := clampf((t - 1.36) / 0.70, 0.0, 1.0)
			var jump_arc := sin(u * PI)
			var kick_ext := sin(clampf((u - 0.08) / 0.84, 0.0, 1.0) * PI)
			
			# Head turns sharply to the LEFT (-1.0) tracking the high kick
			head_facing = lerp(1.0, -1.0, smoothstep(0.0, 0.25, u))
			head_offset = Vector2(-1.5 * kick_ext, -1.0 * jump_arc)
			
			# Whole body leaps 26px into the air!
			pelvis = Vector2(1.5 * kick_ext, -25.0 * jump_arc)
			torso_angle = 0.26 * kick_ext
			torso_twist = 0.35 * kick_ext
			
			# Supporting RIGHT leg tucks athletically under the airborne pelvis
			knee_r = pelvis + Vector2(5.5, 7.5).lerp(Vector2(8.5, 5.5), jump_arc)
			ankle_r = pelvis + Vector2(5.5, 12.2).lerp(Vector2(11.5, 10.5), jump_arc)
			foot_ang_r = -0.45 * jump_arc
			
			# LEFT kicking leg chambers high and snaps shin & boot to the LEFT!
			knee_l = pelvis + Vector2(-5.5, 7.5).lerp(Vector2(-10.5, -4.5), kick_ext)
			ankle_l = pelvis + Vector2(-5.5, 12.2).lerp(Vector2(-20.5, -12.5), kick_ext)
			foot_ang_l = 0.72 * kick_ext
			
			# Arms sweep wide like eagle wings for mid-air balance
			elbow_l = pelvis + Vector2(-12.5, -10.5 * jump_arc - 3.0)
			wrist_l = pelvis + Vector2(-20.0, -14.5 * jump_arc - 2.0)
			elbow_r = pelvis + Vector2(10.5, -9.5 * jump_arc - 3.0)
			wrist_r = pelvis + Vector2(17.5, -12.0 * jump_arc - 2.0)
			
		elif t < 2.76:
			# PHASE 4 (2.06 - 2.76s): "Повітряний Щупак / Різножка 180°" - Symmetrical Leap!
			var u := clampf((t - 2.06) / 0.70, 0.0, 1.0)
			var jump_arc := sin(u * PI)
			var split_ext := sin(clampf((u - 0.06) / 0.88, 0.0, 1.0) * PI)
			
			# Head centers proudly forward (0.0) facing the audience/screen!
			head_facing = lerp(-1.0, 0.0, smoothstep(0.0, 0.30, u))
			head_offset = Vector2(0.0, 1.4 * split_ext)
			
			# Explosive leap into the air (посилений олімпійський стрибок Олександра Усика)!
			var leap_height := 38.0 if ChampionSkill.USYK_SLIP_COUNTER in unlocked_skills else 31.0
			pelvis = Vector2(0.0, -leap_height * jump_arc)
			torso_angle = 0.0
			torso_twist = 0.0
			
			# Symmetrical 180-degree horizontal split (both left and right)!
			knee_l = pelvis + Vector2(-5.5, 7.5).lerp(Vector2(-12.0, 1.5), split_ext)
			ankle_l = pelvis + Vector2(-5.5, 12.2).lerp(Vector2(-22.5, -1.5), split_ext)
			foot_ang_l = -0.65 * split_ext
			
			knee_r = pelvis + Vector2(5.5, 7.5).lerp(Vector2(12.0, 1.5), split_ext)
			ankle_r = pelvis + Vector2(5.5, 12.2).lerp(Vector2(22.5, -1.5), split_ext)
			foot_ang_r = 0.65 * split_ext
			
			# Both articulated arms reach down & outward to touch both boot tips
			elbow_l = pelvis + Vector2(-10.5, -4.5)
			wrist_l = pelvis + Vector2(-7.0, 1.0).lerp(Vector2(-18.5, -2.5), split_ext)
			elbow_r = pelvis + Vector2(10.5, -4.5)
			wrist_r = pelvis + Vector2(7.0, 1.0).lerp(Vector2(18.5, -2.5), split_ext)
			
		elif t < 3.44:
			# PHASE 5 (2.76 - 3.44s): "Низький Повзунець / Пістоль правою" - Sweep to the RIGHT!
			var u := clampf((t - 2.76) / 0.68, 0.0, 1.0)
			var squat_ext := sin(u * PI)
			
			# Head turns decisively to the RIGHT (+1.0) tracking the ground sweep
			head_facing = lerp(0.0, 1.0, smoothstep(0.0, 0.28, u))
			head_offset = Vector2(1.8 * squat_ext, 0.0)
			
			# Pelvis drops deeply down (+8.2px) over supporting left heel
			pelvis = Vector2(-2.0 * squat_ext, 8.2 * squat_ext)
			torso_angle = 0.08 * squat_ext
			torso_twist = 0.35 * squat_ext
			
			# Supporting left leg deeply flexed
			knee_l = Vector2(-5.5, 7.5).lerp(Vector2(-11.5, 6.5), squat_ext)
			ankle_l = Vector2(-5.5, 12.2).lerp(Vector2(-4.5, 12.4), squat_ext)
			
			# Right leg shoots straight out horizontally to the RIGHT
			knee_r = Vector2(5.5, 7.5).lerp(Vector2(11.0, 11.2), squat_ext)
			ankle_r = Vector2(5.5, 12.2).lerp(Vector2(21.5, 12.0), squat_ext)
			foot_ang_r = 0.45 * squat_ext
			
			# Proud Cossack crossed arms over the chest ("Руки хрестом на грудях")
			elbow_l = pelvis + Vector2(-7.5, -3.0).lerp(Vector2(-10.5, -2.5), squat_ext)
			wrist_l = pelvis + Vector2(-6.5, 2.0).lerp(Vector2(4.0, -3.8), squat_ext)
			fist_l = true
			elbow_r = pelvis + Vector2(7.5, -3.0).lerp(Vector2(10.5, -2.5), squat_ext)
			wrist_r = pelvis + Vector2(6.5, 2.0).lerp(Vector2(-4.0, -3.2), squat_ext)
			fist_r = true
			
		else:
			# PHASE 6 (3.44 - 4.10s): "Козак у поли / Руки в боки" - Symmetrical Victory Stance!
			var u := clampf((t - 3.44) / 0.66, 0.0, 1.0)
			var pose_hold := sin(minf(u * 2.5, 1.0) * PI * 0.5)
			if u > 0.85:
				pose_hold *= (1.0 - (u - 0.85) / 0.15)
			var breath := sin(u * PI * 2.0) * 0.8
			
			# Head returns to CENTER (0.0), nodding proudly at the player!
			head_facing = lerp(1.0, 0.0, smoothstep(0.0, 0.32, u))
			head_offset = Vector2(0.0, -0.8 * pose_hold)
			
			pelvis = Vector2(0.0, -0.8 * pose_hold + breath * 0.4)
			torso_angle = 0.0
			torso_twist = 0.0
			
			# Proud symmetrical athletic stance
			knee_l = Vector2(-6.5, 7.2)
			ankle_l = Vector2(-6.0, 12.2)
			knee_r = Vector2(6.5, 7.2)
			ankle_r = Vector2(6.0, 12.2)
			
			# Symmetrical "Руки в боки" (Both hands on golden sash, sharp flared elbows)
			elbow_l = pelvis + Vector2(-7.5, -3.0).lerp(Vector2(-12.5, -3.8), pose_hold)
			wrist_l = pelvis + Vector2(-6.5, 2.0).lerp(Vector2(-6.2, 1.2), pose_hold)
			fist_l = true
			elbow_r = pelvis + Vector2(7.5, -3.0).lerp(Vector2(12.5, -3.8), pose_hold)
			wrist_r = pelvis + Vector2(6.5, 2.0).lerp(Vector2(6.2, 1.2), pose_hold)
			fist_r = true
			
	elif is_gliding or flap_timer > 0.0:
		var flap_lift := sin(time_passed * 24.0) * 2.5
		pelvis = Vector2(0.0, -1.0)
		knee_l = Vector2(-5.5 * flip, 6.5)
		ankle_l = Vector2(-7.5 * flip, 11.5)
		foot_ang_l = 0.25 * flip
		knee_r = Vector2(5.5 * flip, 6.5)
		ankle_r = Vector2(4.0 * flip, 11.5)
		foot_ang_r = 0.20 * flip
		
		elbow_l = Vector2(-13.0 * flip, -12.0 + flap_lift * 0.5)
		wrist_l = Vector2(-24.0 * flip, -16.0 + flap_lift)
		elbow_r = Vector2(13.0 * flip, -10.0 + flap_lift * 0.5)
		wrist_r = Vector2(24.0 * flip, -12.0 + flap_lift)
		
	elif is_fast_dropping:
		pelvis = Vector2(0.0, 1.0)
		knee_l = Vector2(-5.0 * flip, 6.0)
		ankle_l = Vector2(-4.0 * flip, 12.0)
		knee_r = Vector2(5.0 * flip, 6.0)
		ankle_r = Vector2(4.0 * flip, 12.0)
		elbow_l = Vector2(-8.0 * flip, -12.0)
		wrist_l = Vector2(-6.0 * flip, -18.5)
		elbow_r = Vector2(8.0 * flip, -12.0)
		wrist_r = Vector2(6.0 * flip, -18.5)
		
	elif is_rolling:
		# Акробатичний козацький перекат після падіння (групування тіла в колесо)
		var roll_prog := clampf(1.0 - (roll_timer / maxf(roll_duration, 0.01)), 0.0, 1.0)
		torso_angle = roll_prog * TAU * roll_dir
		pelvis = Vector2(0.0, 3.5)
		head_offset = Vector2(0.0, 2.0)
		
		# Підібгані до грудей козацькі ноги в шароварах
		knee_l = pelvis + Vector2(-6.0 * roll_dir, 4.0)
		ankle_l = pelvis + Vector2(-2.5 * roll_dir, 2.0)
		foot_ang_l = 0.45 * roll_dir
		knee_r = pelvis + Vector2(6.0 * roll_dir, 4.0)
		ankle_r = pelvis + Vector2(2.5 * roll_dir, 2.0)
		foot_ang_r = -0.45 * roll_dir
		
		# Руки охоплюють коліна для перекату
		elbow_l = pelvis + Vector2(-8.0 * roll_dir, -2.0)
		wrist_l = pelvis + Vector2(-2.0 * roll_dir, 3.0)
		fist_l = true
		elbow_r = pelvis + Vector2(8.0 * roll_dir, -2.0)
		wrist_r = pelvis + Vector2(2.0 * roll_dir, 3.0)
		fist_r = true
		
	elif squat_timer > 0.0:
		# Deep 3-point parkour superhero landing
		pelvis = Vector2(1.0 * flip, 5.5)
		torso_angle = 0.22 * flip
		knee_l = Vector2(-9.5 * flip, 8.5)
		ankle_l = Vector2(-7.5 * flip, 12.4)
		knee_r = Vector2(10.5 * flip, 7.5)
		ankle_r = Vector2(8.5 * flip, 12.4)
		
		# Right hand planted on ground, left arm counter-balancing back
		elbow_r = pelvis + Vector2(6.5 * flip, 1.0)
		wrist_r = Vector2(7.5 * flip, 14.5)
		elbow_l = pelvis + Vector2(-8.5 * flip, -4.0)
		wrist_l = pelvis + Vector2(-13.5 * flip, -1.0)
		
	elif not on_ground:
		# Athletic airborne parkour jump pose (one knee tucked high, one trailing)
		pelvis = Vector2(0.0, -1.5)
		knee_l = Vector2(-6.0 * flip, 6.5)
		ankle_l = Vector2(-9.5 * flip, 11.5)
		foot_ang_l = 0.30 * flip
		knee_r = Vector2(8.5 * flip, 4.0)
		ankle_r = Vector2(6.0 * flip, 9.5)
		foot_ang_r = 0.15 * flip
		
		elbow_l = Vector2(-9.5 * flip, -5.0)
		wrist_l = Vector2(-12.5 * flip, -1.0)
		elbow_r = Vector2(8.5 * flip, -6.5)
		wrist_r = Vector2(12.5 * flip, -9.5)
		
	else:
		# Dynamic anatomical ground sprint / idle breathing
		var is_running := absf(velocity.x) > 15.0
		var idle_breath := sin(time_passed * 3.8) * 0.6 if not is_running else 0.0
		var bounce := absf(run_anim) * -1.8 if is_running else idle_breath
		pelvis = Vector2(0.0, bounce)
		
		# 2-joint running stride with realistic knee lift
		var stride_l := run_anim
		var stride_r := -run_anim
		knee_l = pelvis + Vector2((-4.5 + stride_l * 6.5) * flip, 7.2 - maxf(0.0, stride_l) * 2.5)
		ankle_l = Vector2((-4.8 + stride_l * 8.0) * flip, 12.2 - maxf(0.0, stride_l) * 2.2)
		foot_ang_l = stride_l * -0.25 * flip
		
		knee_r = pelvis + Vector2((4.5 + stride_r * 6.5) * flip, 7.2 - maxf(0.0, stride_r) * 2.5)
		ankle_r = Vector2((4.8 + stride_r * 8.0) * flip, 12.2 - maxf(0.0, stride_r) * 2.2)
		foot_ang_r = stride_r * -0.25 * flip
		
		# Counter-swinging 2-joint arms with bent elbows during sprint
		var arm_swing_l := -run_anim
		var arm_swing_r := run_anim
		elbow_l = pelvis + Vector2((-6.5 + arm_swing_l * 4.5) * flip, -3.0)
		wrist_l = pelvis + Vector2((-5.0 + arm_swing_l * 8.5) * flip, 1.8 - maxf(0.0, arm_swing_l) * 3.5)
		fist_l = is_running
		
		elbow_r = pelvis + Vector2((6.5 + arm_swing_r * 4.5) * flip, -3.0)
		wrist_r = pelvis + Vector2((5.0 + arm_swing_r * 8.5) * flip, 1.8 - maxf(0.0, arm_swing_r) * 3.5)
		fist_r = is_running
	
	# Recompute hip & shoulder anchors from pelvis + torso_angle + torso_twist
	var torso_up := Vector2(sin(torso_angle), -cos(torso_angle))
	var torso_right := Vector2(cos(torso_angle), sin(torso_angle))
	var chest_center := pelvis + torso_up * 8.5
	
	hip_l = pelvis + torso_right * (-3.5 * flip) + Vector2(0, 2.5)
	hip_r = pelvis + torso_right * (3.5 * flip) + Vector2(0, 2.5)
	var twist_shift := torso_twist * 2.2 * flip
	shoulder_l = chest_center + torso_right * (-5.0 * flip + twist_shift)
	shoulder_r = chest_center + torso_right * (5.0 * flip - twist_shift)
	
	# Apply Analytical 2-Bone IK to legs when not in specialized Hopak split
	if not is_hopak:
		knee_l = knee_l.lerp(_solve_2bone_ik(hip_l, ankle_l, 5.8, 5.8, flip), 0.65)
		knee_r = knee_r.lerp(_solve_2bone_ik(hip_r, ankle_r, 5.8, 5.8, flip), 0.65)
		elbow_l = elbow_l.lerp(_solve_2bone_ik(shoulder_l, wrist_l, 6.2, 6.0, -flip), 0.55)
		elbow_r = elbow_r.lerp(_solve_2bone_ik(shoulder_r, wrist_r, 6.2, 6.0, -flip), 0.55)
	
	if bonk_timer > 0.0:
		head_offset.y += 2.2
	
	# Champion Boxing Strike Active Arm & Torso Override
	if punch_timer > 0.0:
		var p_ratio: float = punch_timer / 0.32
		var p_ext: float = sin(p_ratio * PI)
		fist_r = true
		fist_l = true
		head_facing = punch_facing
		head_offset = Vector2(2.2 * punch_facing * p_ext, 0.5 * p_ext)
		
		match punch_active_skill:
			ChampionSkill.STEELHAMMER_JAB:
				torso_twist = 0.42 * punch_facing
				wrist_r = pelvis + Vector2((18.0 + p_ext * 15.0) * punch_facing, -12.0)
				elbow_r = _solve_2bone_ik(shoulder_r, wrist_r, 8.5, 8.5, -punch_facing)
				punch_streak = wrist_r + Vector2(8.5 * punch_facing, 0.0)
				wrist_l = pelvis + Vector2(2.0 * punch_facing, -12.0)
				elbow_l = _solve_2bone_ik(shoulder_l, wrist_l, 6.5, 6.5, punch_facing)
			ChampionSkill.IRONFIST_HOOK:
				torso_angle = 0.22 * punch_facing * p_ext
				wrist_r = pelvis + Vector2(17.0 * punch_facing, (-5.0 + p_ext * 17.0))
				elbow_r = _solve_2bone_ik(shoulder_r, wrist_r, 8.5, 8.5, -punch_facing)
				punch_streak = wrist_r + Vector2(4.5 * punch_facing, 6.0)
				wrist_l = pelvis + Vector2(2.0 * punch_facing, -12.0)
				elbow_l = _solve_2bone_ik(shoulder_l, wrist_l, 6.5, 6.5, punch_facing)
			ChampionSkill.USYK_SLIP_COUNTER:
				torso_angle = -0.18 * punch_facing * p_ext
				torso_twist = -0.45 * punch_facing
				wrist_l = pelvis + Vector2((16.0 + p_ext * 13.0) * punch_facing, -8.0)
				elbow_l = _solve_2bone_ik(shoulder_l, wrist_l, 8.0, 8.0, -punch_facing)
				wrist_r = pelvis + Vector2((21.0 + p_ext * 15.0) * punch_facing, -11.5)
				elbow_r = _solve_2bone_ik(shoulder_r, wrist_r, 8.5, 8.5, -punch_facing)
				punch_streak = wrist_r + Vector2(8.5 * punch_facing, -2.0)
			ChampionSkill.UNDISPUTED_TRIO:
				torso_twist = sin(time_passed * 32.0) * 0.48
				wrist_r = pelvis + Vector2((22.0 + p_ext * 16.5) * punch_facing, -10.5)
				elbow_r = _solve_2bone_ik(shoulder_r, wrist_r, 8.8, 8.8, -punch_facing)
				wrist_l = pelvis + Vector2((16.0 + p_ext * 13.0) * punch_facing, -6.5)
				elbow_l = _solve_2bone_ik(shoulder_l, wrist_l, 8.0, 8.0, -punch_facing)
				punch_streak = wrist_r + Vector2(10.5 * punch_facing, 0.0)
			ChampionSkill.HOPAK_TYNOK_KICK:
				# Високий прямий удар ногою «Тинок» у червоному сап'янці вперед на рівні грудей/голови!
				torso_angle = -0.26 * punch_facing * p_ext
				pelvis += Vector2(-2.0 * punch_facing * p_ext, -1.5 * p_ext)
				ankle_r = pelvis + Vector2((14.0 + p_ext * 16.0) * punch_facing, -6.0 * p_ext + 2.0)
				knee_r = _solve_2bone_ik(hip_r, ankle_r, 8.5, 8.5, -punch_facing)
				foot_ang_r = -0.85 * punch_facing * p_ext
				ankle_l = Vector2(-5.5 * punch_facing, 12.2)
				knee_l = _solve_2bone_ik(hip_l, ankle_l, 6.2, 6.2, punch_facing)
				wrist_l = pelvis + Vector2(-11.0 * punch_facing, -10.0)
				wrist_r = pelvis + Vector2(9.0 * punch_facing, -8.0)
				punch_streak = ankle_r + Vector2(9.0 * punch_facing, -2.0)
			ChampionSkill.HOPAK_SHCHUPAK_SPLIT:
				# Повітряний шпагат двома ногами «Щупак / Різножка» на 180 градусів у обидва боки!
				pelvis += Vector2(0.0, -6.0 * p_ext)
				torso_angle = 0.0
				head_facing = 0.0
				ankle_l = pelvis + Vector2(-15.0 - p_ext * 13.0, 1.5)
				knee_l = pelvis + Vector2(-8.5 - p_ext * 5.0, 0.5)
				foot_ang_l = 0.45
				ankle_r = pelvis + Vector2(15.0 + p_ext * 13.0, 1.5)
				knee_r = pelvis + Vector2(8.5 + p_ext * 5.0, 0.5)
				foot_ang_r = -0.45
				wrist_l = pelvis + Vector2(-14.5, -16.0 * p_ext - 4.0)
				elbow_l = pelvis + Vector2(-9.0, -9.0)
				wrist_r = pelvis + Vector2(14.5, -16.0 * p_ext - 4.0)
				elbow_r = pelvis + Vector2(9.0, -9.0)
				punch_streak = ankle_r + Vector2(7.0, 0.0)
			ChampionSkill.HOPAK_POVZUNETS_SWEEP:
				# Низька обертова підсічка ногою «Повзунець / Коса» вздовж балки!
				pelvis += Vector2(2.5 * punch_facing * p_ext, 5.2 * p_ext)
				torso_angle = -0.22 * punch_facing * p_ext
				ankle_l = pelvis + Vector2(-6.5 * punch_facing, 7.0)
				knee_l = pelvis + Vector2(-9.5 * punch_facing, 2.0)
				ankle_r = pelvis + Vector2((14.0 + p_ext * 15.0) * punch_facing, 7.0)
				knee_r = pelvis + Vector2((7.5 + p_ext * 6.5) * punch_facing, 5.0)
				foot_ang_r = -0.35 * punch_facing
				wrist_l = pelvis + Vector2(-9.0 * punch_facing, 4.0)
				wrist_r = pelvis + Vector2(11.0 * punch_facing, -4.0)
				punch_streak = ankle_r + Vector2(8.0 * punch_facing, 0.0)
	
	return {
		"pelvis": pelvis,
		"chest": chest_center,
		"torso_angle": torso_angle,
		"torso_twist": torso_twist,
		"head_facing": head_facing,
		"head_offset": head_offset,
		"punch_streak": punch_streak,
		"hip_l": hip_l, "knee_l": knee_l, "ankle_l": ankle_l, "foot_ang_l": foot_ang_l,
		"hip_r": hip_r, "knee_r": knee_r, "ankle_r": ankle_r, "foot_ang_r": foot_ang_r,
		"shoulder_l": shoulder_l, "elbow_l": elbow_l, "wrist_l": wrist_l, "fist_l": fist_l,
		"shoulder_r": shoulder_r, "elbow_r": elbow_r, "wrist_r": wrist_r, "fist_r": fist_r
	}

func _draw() -> void:
	var flip: float = facing_direction
	var run_anim := sin(run_cycle)
	var on_ground := is_on_floor()
	var pose := _compute_skeletal_pose(flip, run_anim, on_ground)
	
	var pelvis: Vector2 = pose["pelvis"]
	var chest: Vector2 = pose["chest"]
	var torso_angle: float = pose["torso_angle"]
	var torso_up := Vector2(sin(torso_angle), -cos(torso_angle))
	var torso_right := Vector2(cos(torso_angle), sin(torso_angle))
	
	# Apply 3D parkour transform (Tilt + Squash & Stretch)
	draw_set_transform(Vector2.ZERO, body_tilt, squash_stretch)
	
	# If flashing after hit, skip rendering half the frames for arcade iframes
	if invulnerable_timer > 0.0 and fmod(invulnerable_timer, 0.14) > 0.07:
		return
	
	# --- 0. КОЗАЦЬКА ХАРАКТЕРНИЦЬКА АУРА (Charakterite Magic Aura) ---
	if is_charakterite:
		var aura_pulse := 1.0 + sin(time_passed * 16.0) * 0.16
		var center_pt := pelvis + Vector2(0.0, -8.0)
		draw_circle(center_pt, 28.0 * aura_pulse, Color(1.0, 0.85, 0.20, 0.20))
		draw_circle(center_pt, 22.0 * aura_pulse, Color(0.20, 0.65, 1.0, 0.25))
		var rot_a := time_passed * 8.0
		for k in range(6):
			var a := rot_a + k * (PI / 3.0)
			var ray_end := center_pt + Vector2(cos(a), sin(a)) * (32.0 * aura_pulse)
			draw_line(center_pt, ray_end, Color(1.0, 0.95, 0.50, 0.40), 1.5)
	
	# --- 1. PSEUDO-3D GROUND CONTACT SHADOW (Scales dynamically with jump height!) ---
	if on_ground or is_hopak:
		var height_factor := clampf(1.0 + pelvis.y / 48.0, 0.42, 1.15)
		_draw_oval(Vector2(pelvis.x * 0.5, 16.0), 13.5 * height_factor, 4.5 * height_factor, Color(0.0, 0.0, 0.05, 0.38 * height_factor))
		_draw_oval(Vector2(pelvis.x * 0.5, 16.0), 8.2 * height_factor, 2.5 * height_factor, Color(0.0, 0.0, 0.05, 0.58 * height_factor))
	
	# --- 2. 3D DOUBLE-SIDED BILLOWING KYREYA (Cossack Parkour Wing-Cape) ---
	var wave := sin(cape_wave) * 4.0
	var outer_blue := Color(0.10, 0.22, 0.65)
	var outer_blue_hi := Color(0.18, 0.38, 0.88)
	var inner_gold := Color(0.85, 0.65, 0.12)
	var border_gold := Color(0.98, 0.85, 0.25)
	
	if is_gliding or flap_timer > 0.0:
		var flap_lift := sin(time_passed * 24.0) * 3.5
		var wing_l = PackedVector2Array([
			chest + Vector2(-2 * flip, -1.5),
			chest + Vector2(-26 * flip, -9.5 + flap_lift),
			chest + Vector2(-24 * flip, 16.5 + flap_lift * 0.5),
			pelvis + Vector2(-4 * flip, 4)
		])
		draw_colored_polygon(wing_l, outer_blue)
		draw_colored_polygon(PackedVector2Array([
			chest + Vector2(-2 * flip, -1.5),
			chest + Vector2(-12 * flip, -5.5),
			pelvis + Vector2(-10 * flip, 6),
			pelvis + Vector2(-4 * flip, 4)
		]), outer_blue_hi)
		draw_line(chest + Vector2(-2 * flip, -1.5), chest + Vector2(-26 * flip, -9.5 + flap_lift), border_gold, 2.5)
		
		var wing_r = PackedVector2Array([
			chest + Vector2(2 * flip, -1.5),
			chest + Vector2(26 * flip, -5.5 + flap_lift),
			chest + Vector2(22 * flip, 18.5 + flap_lift * 0.5),
			pelvis + Vector2(4 * flip, 4)
		])
		draw_colored_polygon(wing_r, outer_blue_hi)
		draw_line(chest + Vector2(2 * flip, -1.5), chest + Vector2(26 * flip, -5.5 + flap_lift), border_gold, 2.5)
	elif is_fast_dropping:
		var drop_pts = PackedVector2Array([
			chest + Vector2(-5 * flip, -1.5),
			chest + Vector2(-10 * flip, -23.5 + wave),
			chest + Vector2(0, -17.5),
			chest + Vector2(5 * flip, -1.5)
		])
		draw_colored_polygon(drop_pts, outer_blue)
		draw_line(chest + Vector2(-5 * flip, -1.5), chest + Vector2(-10 * flip, -23.5 + wave), border_gold, 2.0)
	else:
		var cape_x := pelvis.x - 16.0 * flip + (run_anim * 4.0 * flip if on_ground and not is_hopak else 0.0) + wave
		var cape_bottom_y := pelvis.y + 12.5 + clampf(-pelvis.y * 0.25, 0.0, 6.0)
		var cape_outer = PackedVector2Array([
			chest + Vector2(-3 * flip, -2.5),
			Vector2(cape_x, cape_bottom_y),
			Vector2(cape_x + 5 * flip, cape_bottom_y + 3.0),
			chest + Vector2(2 * flip, 1.5)
		])
		draw_colored_polygon(cape_outer, outer_blue)
		var cape_inner = PackedVector2Array([
			Vector2(cape_x, cape_bottom_y),
			Vector2(cape_x + 5 * flip, cape_bottom_y + 3.0),
			Vector2(cape_x + 2 * flip, cape_bottom_y - 2.0)
		])
		draw_colored_polygon(cape_inner, inner_gold)
		draw_line(chest + Vector2(-3 * flip, -2.5), Vector2(cape_x, cape_bottom_y), border_gold, 2.0)
	
	# Determine anatomical boot orientation for both legs
	var leg_flip_l: float = -1.0 if (is_hopak and pose["ankle_l"].x <= pelvis.x) else flip
	var leg_flip_r: float = 1.0 if (is_hopak and pose["ankle_r"].x >= pelvis.x) else flip

	# --- 3. BACK ARM (Articulated 2-Segment Shoulder -> Elbow -> Wrist) ---
	if is_hopak and hopak_time < 0.68:
		# In Phase 1 (striking left with left arm), right arm is chambered in the background
		_draw_articulated_arm(pose["shoulder_r"], pose["elbow_r"], pose["wrist_r"], 1.0, true, pose["fist_r"])
	elif is_hopak and hopak_time < 1.36:
		# In Phase 2 (striking right with right arm), left arm is guarding in the background
		_draw_articulated_arm(pose["shoulder_l"], pose["elbow_l"], pose["wrist_l"], -1.0, true, pose["fist_l"])
	else:
		_draw_articulated_arm(pose["shoulder_l"], pose["elbow_l"], pose["wrist_l"], -1.0 if (is_hopak and pose["wrist_l"].x < chest.x) else flip, true, pose["fist_l"])
	
	# --- 4. ARTICULATED LEGS & SAPYANTSI BOOTS (2-Bone Hip -> Knee -> Ankle + Foot Angle) ---
	_draw_articulated_leg(pose["hip_l"], pose["knee_l"], pose["ankle_l"], pose["foot_ang_l"], leg_flip_l, true)
	_draw_articulated_leg(pose["hip_r"], pose["knee_r"], pose["ankle_r"], pose["foot_ang_r"], leg_flip_r, false)
	
	# Center pelvic bridge of the sharovary trousers
	_draw_oval(pelvis + Vector2(0.0, 4.2), 5.8, 3.8, Color(0.68, 0.08, 0.14))
	draw_line(pelvis + Vector2(0.0, 2.5), pelvis + Vector2(0.0, 7.5), Color(0.45, 0.04, 0.08), 1.6)
	
	# --- 5. 3D VYSHYVANKA TORSO (Rotated & Shaded with Chest Twist) ---
	var shirt_shadow := Color(0.76, 0.79, 0.86)
	var shirt_mid := Color(0.94, 0.95, 0.98)
	var shirt_hi := Color(1.0, 1.0, 1.0)
	
	var t_top_l := chest + torso_right * -7.2 + torso_up * 2.5
	var t_top_r := chest + torso_right * 7.2 + torso_up * 2.5
	var t_bot_r := pelvis + torso_right * 6.0 + torso_up * -2.0
	var t_bot_l := pelvis + torso_right * -6.0 + torso_up * -2.0
	
	draw_colored_polygon(PackedVector2Array([t_top_l, t_top_r, t_bot_r, t_bot_l]), shirt_mid)
	draw_line(t_top_l + torso_right * 1.2, t_bot_l + torso_right * 1.2, shirt_shadow, 2.2)
	draw_line(chest + torso_right * (2.2 * flip) + torso_up * 2.0, pelvis + torso_right * (2.0 * flip), shirt_hi, 2.4)
	
	# Traditional Ukrainian Cross-Stitch Embroidery Placket (Маніжка з ромбами-берегинями) shifted by torso_twist
	var torso_twist_val: float = pose["torso_twist"]
	var emb_shift: Vector2 = torso_right * (torso_twist_val * -1.8 * flip)
	var emb_top: Vector2 = chest + torso_up * 2.4 + emb_shift
	var emb_bot: Vector2 = pelvis + torso_up * -1.0 + emb_shift
	draw_line(emb_top, emb_bot, Color(0.85, 0.12, 0.15), 5.2)
	draw_line(emb_top + torso_up * -0.6, emb_bot + torso_up * 1.0, Color(0.12, 0.12, 0.16), 2.8)
	# Три автентичні вишиті ромби-обереги на маніжці
	for dm in range(3):
		var dm_c := emb_top.lerp(emb_bot, 0.22 + float(dm) * 0.28)
		draw_colored_polygon(PackedVector2Array([
			dm_c + torso_up * 1.3,
			dm_c + torso_right * 1.4,
			dm_c - torso_up * 1.3,
			dm_c - torso_right * 1.4
		]), Color.WHITE)
		draw_circle(dm_c, 0.55, Color(0.85, 0.12, 0.15))
	# Вишитий комір-стійка та золоті китички під шиєю
	draw_line(chest + torso_up * 2.5 - torso_right * 3.2, chest + torso_up * 2.5 + torso_right * 3.2, Color(0.85, 0.12, 0.15), 2.0)
	draw_circle(emb_top + torso_up * -0.4 + torso_right * 2.0, 0.8, Color(0.96, 0.82, 0.16))
	draw_circle(emb_top + torso_up * -0.4 - torso_right * 2.0, 0.8, Color(0.96, 0.82, 0.16))
	
	# --- 6. 3D GOLDEN SILK SASH (Кушак із парними китицями на пружинній фізиці) ---
	var sash_c := pelvis + Vector2(0.0, 2.0)
	_draw_oval(sash_c, 7.8, 2.7, Color(0.78, 0.60, 0.08))
	_draw_oval(sash_c + Vector2(-0.8 * flip, -0.4), 6.6, 2.1, Color(0.96, 0.82, 0.16))
	draw_line(sash_c + Vector2(-6.2, -0.5), sash_c + Vector2(6.2, -0.5), Color(0.85, 0.12, 0.15), 1.0)
	draw_line(sash_c + Vector2(-6.2, 0.4), sash_c + Vector2(6.2, 0.4), Color(1.0, 0.92, 0.35), 1.2)
	
	var tassel_base := sash_c + Vector2(-5.2 * flip, 0.5)
	var tassel_mid := tassel_base + Vector2(-1.6 * flip + tassel_swing * 0.5, 4.2)
	var tassel_end := tassel_base + Vector2(-2.8 * flip + tassel_swing, 8.6)
	var tassel_end2 := tassel_base + Vector2(-1.0 * flip + tassel_swing * 0.85, 7.6)
	draw_line(tassel_base, tassel_mid, Color(0.96, 0.82, 0.16), 2.2)
	draw_line(tassel_mid, tassel_end, Color(0.96, 0.82, 0.16), 2.0)
	draw_line(tassel_base, tassel_end2, Color(0.85, 0.65, 0.10), 1.6)
	draw_circle(tassel_end, 2.0, Color(0.85, 0.12, 0.15))
	draw_circle(tassel_end2, 1.6, Color(0.96, 0.82, 0.16))
	
	# 4 Чемпіонські пояси абсолютного переможця (WBC, WBA, WBO, IBF)
	if ChampionSkill.UNDISPUTED_TRIO in unlocked_skills or (is_hopak and hopak_time >= 3.44):
		var belt_cols = [
			Color(0.12, 0.68, 0.28), # WBC (зелений)
			Color(0.14, 0.14, 0.18), # WBA (чорний з золотом)
			Color(0.85, 0.12, 0.18), # IBF (червоний)
			Color(0.55, 0.10, 0.22)  # WBO (бордовий)
		]
		for bi in range(4):
			var b_ang := time_passed * 4.0 + float(bi) * (TAU / 4.0)
			var b_pos := sash_c + Vector2(cos(b_ang) * 9.5, sin(b_ang) * 3.0)
			_draw_oval(b_pos, 2.4, 1.8, belt_cols[bi])
			draw_circle(b_pos, 1.0, Color(1.0, 0.88, 0.22)) # Золота медаль
	
	# --- 7. КИЇВНАУКФІЛЬМ: АВТЕНТИЧНА ГОЛОВА, ОБЛИЧЧЯ ТА МІМІКА КОЗАКА ДЖУРИ ---
	var neck_pos := chest + torso_up * 3.8
	draw_line(chest + torso_up * 1.5, neck_pos, Color(0.84, 0.66, 0.54), 4.2)
	
	var head_c: Vector2 = chest + torso_up * 8.5 + pose["head_offset"]
	var head_facing: float = float(pose["head_facing"])
	var h_dir: float = signf(head_facing) if absf(head_facing) > 0.15 else flip
	
	# Форма голови: м'який, живий контур із пухкими козацькими щоками (Київнаукфільм)
	_draw_oval(head_c, 7.2, 7.8, Color(0.82, 0.64, 0.50)) # Контурна тінь
	_draw_oval(head_c + Vector2(-0.6 * h_dir, -0.6), 6.4, 7.0, Color(0.98, 0.85, 0.72)) # Світла шкіра
	_draw_oval(head_c + Vector2(-1.8 * h_dir, -1.8), 3.8, 4.2, Color(1.0, 0.94, 0.86)) # Блік
	
	# Пухкі рум'яні яблучні щічки (фірмовий штрих мультфільмів Дахна та Кирича)
	var cheek_pos := head_c + Vector2(2.8 * h_dir, 1.8)
	_draw_oval(cheek_pos, 2.4, 1.6, Color(0.98, 0.45, 0.45, 0.40))
	if absf(head_facing) <= 0.30:
		_draw_oval(head_c + Vector2(-2.8, 1.8), 2.4, 1.6, Color(0.98, 0.45, 0.45, 0.40))
	
	# Козацьке вухо та золота сережка-півмісяць (традиція козаків-одинаків)
	var ear_pos := head_c + Vector2(-4.8 * h_dir, 0.8)
	_draw_oval(ear_pos, 1.8, 2.4, Color(0.88, 0.68, 0.55))
	_draw_oval(ear_pos + Vector2(0.4 * h_dir, 0.0), 1.1, 1.5, Color(0.98, 0.85, 0.72))
	var earring_sway := sin(time_passed * 10.0) * 0.8
	draw_arc(ear_pos + Vector2(0.0, 2.2), 1.6, 0.2 + earring_sway, TAU - 0.2 + earring_sway, 8, Color(1.0, 0.84, 0.18), 1.4)
	draw_circle(ear_pos + Vector2(0.0, 3.8), 0.7, Color(1.0, 0.95, 0.55))
	
	# Кирпатий козацький ніс-ґудзик Дахна/Кирича
	var nose_c := head_c + Vector2(4.8 * h_dir if absf(head_facing) > 0.30 else 0.0, 0.6)
	_draw_oval(nose_c, 2.2, 1.8, Color(0.90, 0.68, 0.56))
	_draw_oval(nose_c + Vector2(-0.4 * h_dir, -0.4), 1.6, 1.2, Color(1.0, 0.88, 0.78))
	draw_circle(nose_c + Vector2(-0.5 * h_dir, -0.5), 0.6, Color(1.0, 0.96, 0.90))
	
	# Очі Київнаукфільм: великі, анімовані, виразні для кожної пози
	var eye_c := head_c + Vector2(2.4 * h_dir if absf(head_facing) > 0.30 else 2.6, -1.8)
	var eye_l_pos := head_c + Vector2(-2.6, -1.8)
	
	if bonk_timer > 0.0:
		# Поза: Стукнувся головою — очі-хрестики «X X» та язичок (Класика Дахна/Черкаського!)
		draw_line(eye_c - Vector2(2.2, 2.2), eye_c + Vector2(2.2, 2.2), Color(0.12, 0.10, 0.10), 1.8)
		draw_line(eye_c - Vector2(-2.2, 2.2), eye_c + Vector2(-2.2, 2.2), Color(0.12, 0.10, 0.10), 1.8)
		if absf(head_facing) <= 0.30:
			draw_line(eye_l_pos - Vector2(2.2, 2.2), eye_l_pos + Vector2(2.2, 2.2), Color(0.12, 0.10, 0.10), 1.8)
			draw_line(eye_l_pos - Vector2(-2.2, 2.2), eye_l_pos + Vector2(-2.2, 2.2), Color(0.12, 0.10, 0.10), 1.8)
		# З ротика висовується кумедний язичок від оглушення
		var mouth_p := head_c + Vector2(1.8 * h_dir, 3.8)
		_draw_oval(mouth_p + Vector2(0.8 * h_dir, 1.2), 1.6, 2.0, Color(0.96, 0.35, 0.45))
		draw_arc(mouth_p, 2.4, 0.2, PI - 0.2, 8, Color(0.20, 0.08, 0.08), 1.4)
	elif is_fast_dropping:
		# Поза: Падіння стрімголов — витріщені очі від швидкості з маленькими зіницями
		_draw_oval(eye_c, 2.6, 2.8, Color.WHITE)
		draw_arc(eye_c, 2.7, 0.0, TAU, 12, Color(0.15, 0.12, 0.10), 1.0)
		draw_circle(eye_c + Vector2(0.0, 0.4), 0.9, Color(0.12, 0.12, 0.18))
		if absf(head_facing) <= 0.30:
			_draw_oval(eye_l_pos, 2.6, 2.8, Color.WHITE)
			draw_arc(eye_l_pos, 2.7, 0.0, TAU, 12, Color(0.15, 0.12, 0.10), 1.0)
			draw_circle(eye_l_pos + Vector2(0.0, 0.4), 0.9, Color(0.12, 0.12, 0.18))
		# Відкритий круглий рот «О!» від вітру
		_draw_oval(head_c + Vector2(1.5 * h_dir, 3.8), 1.5, 2.2, Color(0.25, 0.08, 0.08))
	elif is_rolling:
		# Поза: Акробатичний козацький перекат — зосереджені очі-стрілочки «> <» і рішучий оскал
		draw_line(eye_c - Vector2(2.2 * h_dir, -1.8), eye_c, Color(0.15, 0.12, 0.10), 2.0)
		draw_line(eye_c, eye_c - Vector2(2.2 * h_dir, 1.8), Color(0.15, 0.12, 0.10), 2.0)
		if absf(head_facing) <= 0.30:
			draw_line(eye_l_pos - Vector2(-2.2 * h_dir, -1.8), eye_l_pos, Color(0.15, 0.12, 0.10), 2.0)
			draw_line(eye_l_pos, eye_l_pos - Vector2(-2.2 * h_dir, 1.8), Color(0.15, 0.12, 0.10), 2.0)
		# Зухвалий зціплений бойовий оскал
		draw_line(head_c + Vector2(-1.2 * h_dir, 3.4), head_c + Vector2(2.8 * h_dir, 3.4), Color(0.22, 0.10, 0.10), 1.6)
		draw_line(head_c + Vector2(0.8 * h_dir, 2.8), head_c + Vector2(0.8 * h_dir, 4.0), Color(0.22, 0.10, 0.10), 1.2)
	elif is_gliding:
		# Поза: Ширяння на киреї — щасливі примружені очі-дуги «^_^» та широка посмішка
		draw_arc(eye_c, 2.2, PI + 0.3, TAU - 0.3, 8, Color(0.15, 0.12, 0.10), 1.8)
		if absf(head_facing) <= 0.30:
			draw_arc(eye_l_pos, 2.2, PI + 0.3, TAU - 0.3, 8, Color(0.15, 0.12, 0.10), 1.8)
		draw_arc(head_c + Vector2(1.5 * h_dir, 3.2), 3.2, 0.2, PI - 0.2, 8, Color(0.70, 0.15, 0.18), 1.6)
	elif is_hopak:
		# Пози: 6 фаз Бойового Гопака зі специфічною акторською мімікою Київнаукфільм
		if hopak_time < 0.68:
			# Фаза 1: Бойовий крик! («Гей-я!» на тичку лівою)
			_draw_oval(eye_c, 2.4, 2.0, Color.WHITE)
			draw_circle(eye_c + Vector2(-1.0, 0.0), 1.2, Color(0.12, 0.22, 0.35))
			draw_line(eye_c + Vector2(-2.0, -2.4), eye_c + Vector2(2.0, -1.6), Color(0.18, 0.12, 0.10), 1.8) # Насуплена броhead
			# Широкий відкритий рот бойового крику
			_draw_oval(head_c + Vector2(-1.5, 3.6), 2.2, 2.6, Color(0.30, 0.08, 0.08))
			draw_arc(head_c + Vector2(-1.5, 3.0), 2.0, 0.2, PI - 0.2, 8, Color.WHITE, 1.0)
		elif hopak_time < 1.36:
			# Фаза 2: Силовий хук праворуч — напружений прицільний погляд вправо
			_draw_oval(eye_c, 2.4, 2.0, Color.WHITE)
			draw_circle(eye_c + Vector2(1.2, 0.0), 1.2, Color(0.12, 0.22, 0.35))
			draw_line(eye_c + Vector2(-2.0, -1.6), eye_c + Vector2(2.0, -2.4), Color(0.18, 0.12, 0.10), 1.8)
			draw_line(head_c + Vector2(-1.0, 3.4), head_c + Vector2(3.0, 3.4), Color(0.25, 0.10, 0.10), 1.6)
		elif hopak_time < 2.04:
			# Фаза 3: Високий стрибок «Тинок» — азартний задерикуватий погляд вгору
			_draw_oval(eye_c, 2.4, 2.4, Color.WHITE)
			draw_circle(eye_c + Vector2(0.5, -0.8), 1.3, Color(0.12, 0.22, 0.35))
			draw_circle(eye_c + Vector2(0.8, -1.1), 0.6, Color.WHITE)
			draw_arc(head_c + Vector2(1.8 * h_dir, 3.2), 2.8, 0.2, PI - 0.2, 8, Color(0.72, 0.15, 0.18), 1.8)
		elif hopak_time < 2.76:
			# Фаза 4: «Щупак / Різножка 180°» у польоті — обличчя анфас, сяючі очі та посмішка на все обличчя!
			_draw_oval(eye_c, 2.6, 2.4, Color.WHITE)
			_draw_oval(eye_l_pos, 2.6, 2.4, Color.WHITE)
			draw_circle(eye_c, 1.2, Color(0.12, 0.22, 0.35))
			draw_circle(eye_l_pos, 1.2, Color(0.12, 0.22, 0.35))
			draw_circle(eye_c + Vector2(0.4, -0.4), 0.6, Color.WHITE)
			draw_circle(eye_l_pos + Vector2(0.4, -0.4), 0.6, Color.WHITE)
			# Сяюча широка посмішка переможця
			draw_arc(head_c + Vector2(0.0, 3.2), 3.8, 0.2, PI - 0.2, 10, Color(0.75, 0.12, 0.15), 2.0)
		elif hopak_time < 3.44:
			# Фаза 5: «Низький Повзунець / Пістоль» — хитре козацьке підморгування! (Праве око підморгує, ліве дивиться)
			draw_arc(eye_c, 2.2, 0.2, PI - 0.2, 8, Color(0.15, 0.12, 0.10), 2.0) # Підморгнув!
			_draw_oval(eye_l_pos, 2.4, 2.2, Color.WHITE)
			draw_circle(eye_l_pos + Vector2(0.8, 0.0), 1.2, Color(0.12, 0.22, 0.35))
			draw_circle(eye_l_pos + Vector2(1.1, -0.4), 0.5, Color.WHITE)
			# Хитра посмішка в куточок рота
			draw_arc(head_c + Vector2(2.0, 3.0), 2.4, 0.4, PI - 0.1, 8, Color(0.72, 0.15, 0.18), 1.8)
		else:
			# Фаза 6: «Козак у поли» — горда велична посмішка козака-переможця
			_draw_oval(eye_c, 2.4, 2.2, Color.WHITE)
			_draw_oval(eye_l_pos, 2.4, 2.2, Color.WHITE)
			draw_circle(eye_c + Vector2(0.0, 0.2), 1.2, Color(0.12, 0.22, 0.35))
			draw_circle(eye_l_pos + Vector2(0.0, 0.2), 1.2, Color(0.12, 0.22, 0.35))
			draw_circle(eye_c + Vector2(0.4, -0.3), 0.5, Color.WHITE)
			draw_circle(eye_l_pos + Vector2(0.4, -0.3), 0.5, Color.WHITE)
			draw_arc(head_c + Vector2(0.0, 3.4), 3.2, 0.3, PI - 0.3, 8, Color(0.70, 0.14, 0.16), 1.8)
	elif punch_timer > 0.0:
		# Поза: Удар Чемпіона Боксу (Кличко / Усик) — вогняний зосереджений погляд, зведені брови та бойовий вигук!
		_draw_oval(eye_c, 2.5, 1.9, Color.WHITE)
		draw_circle(eye_c + Vector2(1.0 * h_dir, 0.0), 1.25, Color(0.10, 0.20, 0.35))
		draw_circle(eye_c + Vector2(1.3 * h_dir, -0.3), 0.5, Color.WHITE)
		draw_line(eye_c + Vector2(-2.4 * h_dir, -2.5), eye_c + Vector2(2.4 * h_dir, -1.4), Color(0.16, 0.10, 0.08), 2.1)
		_draw_oval(head_c + Vector2(1.8 * h_dir, 3.6), 2.1, 2.2, Color(0.32, 0.08, 0.08))
		draw_arc(head_c + Vector2(1.8 * h_dir, 3.1), 1.8, 0.2, PI - 0.2, 8, Color.WHITE, 1.1)
	elif squat_timer > 0.0:
		# Поза: Приземлення супергероя — сфокусований погляд вперед-вниз, сувора козацька витримка
		_draw_oval(eye_c, 2.4, 1.8, Color.WHITE)
		draw_circle(eye_c + Vector2(0.8 * h_dir, 0.5), 1.2, Color(0.12, 0.22, 0.35))
		draw_line(eye_c + Vector2(-2.2 * h_dir, -2.0), eye_c + Vector2(2.2 * h_dir, -1.4), Color(0.18, 0.12, 0.10), 1.8)
		if absf(head_facing) <= 0.30:
			_draw_oval(eye_l_pos, 2.4, 1.8, Color.WHITE)
			draw_circle(eye_l_pos + Vector2(0.8 * h_dir, 0.5), 1.2, Color(0.12, 0.22, 0.35))
			draw_line(eye_l_pos + Vector2(-2.2 * h_dir, -2.0), eye_l_pos + Vector2(2.2 * h_dir, -1.4), Color(0.18, 0.12, 0.10), 1.8)
		draw_line(head_c + Vector2(-0.5 * h_dir, 3.2), head_c + Vector2(2.5 * h_dir, 3.2), Color(0.35, 0.12, 0.12), 1.6)
	elif not on_ground:
		# Поза: Стрибок та політ вгору — натхненний погляд догори, розкритий у захваті рот
		_draw_oval(eye_c, 2.5, 2.4, Color.WHITE)
		draw_arc(eye_c, 2.5, 0.0, TAU, 10, Color(0.18, 0.14, 0.12), 1.0)
		var pupil_jump := Vector2(0.8 * h_dir, -0.7)
		draw_circle(eye_c + pupil_jump, 1.3, Color(0.12, 0.22, 0.35))
		draw_circle(eye_c + pupil_jump + Vector2(0.4 * h_dir, -0.4), 0.6, Color.WHITE)
		draw_arc(eye_c + Vector2(0, -2.6), 2.2, PI + 0.3, TAU - 0.1, 6, Color(0.18, 0.12, 0.10), 1.6)
		
		if absf(head_facing) <= 0.30:
			_draw_oval(eye_l_pos, 2.5, 2.4, Color.WHITE)
			draw_arc(eye_l_pos, 2.5, 0.0, TAU, 10, Color(0.18, 0.14, 0.12), 1.0)
			draw_circle(eye_l_pos + pupil_jump, 1.3, Color(0.12, 0.22, 0.35))
			draw_circle(eye_l_pos + pupil_jump + Vector2(0.4 * h_dir, -0.4), 0.6, Color.WHITE)
			draw_arc(eye_l_pos + Vector2(0, -2.6), 2.2, PI + 0.1, TAU - 0.3, 6, Color(0.18, 0.12, 0.10), 1.6)
		
		# Захоплений відкритий рот під час польоту
		_draw_oval(head_c + Vector2(1.8 * h_dir, 3.4), 1.6, 2.0, Color(0.55, 0.14, 0.16))
	else:
		# Поза: Звичайний біг / спокій (Idle / Run) — допитливий живий козацький погляд з природним кліпанням
		if is_blinking:
			draw_arc(eye_c, 2.2, 0.15, PI - 0.15, 8, Color(0.18, 0.12, 0.10), 1.7)
			if absf(head_facing) <= 0.30:
				draw_arc(eye_l_pos, 2.2, 0.15, PI - 0.15, 8, Color(0.18, 0.12, 0.10), 1.7)
		else:
			_draw_oval(eye_c, 2.3, 2.0, Color.WHITE)
			draw_arc(eye_c, 2.4, 0.0, TAU, 10, Color(0.18, 0.14, 0.12), 1.0)
			var pupil_shift := Vector2(0.7 * h_dir, 0.0)
			draw_circle(eye_c + pupil_shift, 1.2, Color(0.12, 0.22, 0.35))
			draw_circle(eye_c + pupil_shift + Vector2(0.4 * h_dir, -0.4), 0.5, Color.WHITE)
			draw_arc(eye_c + Vector2(0, -2.4), 2.2, PI + 0.5, TAU - 0.2, 6, Color(0.18, 0.12, 0.10), 1.5)
			
			if absf(head_facing) <= 0.30:
				_draw_oval(eye_l_pos, 2.3, 2.0, Color.WHITE)
				draw_arc(eye_l_pos, 2.4, 0.0, TAU, 10, Color(0.18, 0.14, 0.12), 1.0)
				draw_circle(eye_l_pos + pupil_shift, 1.2, Color(0.12, 0.22, 0.35))
				draw_circle(eye_l_pos + pupil_shift + Vector2(0.4 * h_dir, -0.4), 0.5, Color.WHITE)
				draw_arc(eye_l_pos + Vector2(0, -2.4), 2.2, PI + 0.2, TAU - 0.5, 6, Color(0.18, 0.12, 0.10), 1.5)
		
		draw_arc(head_c + Vector2(1.8 * h_dir, 3.2), 2.8, 0.3, PI - 0.3, 8, Color(0.68, 0.18, 0.18), 1.5)
	
	# Юне козацьке обличчя Джури (14–16 років — без вусів, із чітким юнацьким підборіддям та золотою сережкою-півмісяцем)
	draw_arc(head_c + Vector2(1.4 * h_dir, 5.2), 1.6, 0.25, PI - 0.25, 6, Color(0.84, 0.65, 0.54), 1.1)
	
	# Старовинний козацький чуб — «Оселедець-Айдар» (ознака воїна-лицаря з поголеного тімені за вухо)
	var chub_base := head_c + Vector2(0.5 * h_dir, -7.2)
	var hair_col := Color(0.10, 0.07, 0.06)
	var hair_hi := Color(0.38, 0.28, 0.24)
	# Виразна коренева пасмо-основа айдара на тімені
	_draw_oval(chub_base + Vector2(-0.8 * h_dir, 0.4), 2.8, 1.5, hair_col)
	
	if bonk_timer > 0.0:
		# Оглушений: чуб скручується у кумедну пружинку-штопор!
		var p0 := chub_base
		for k in range(6):
			var seg_t := float(k)
			var p_next := chub_base + Vector2(-2.0 * h_dir * seg_t + sin(time_passed * 26.0 + seg_t * 2.0) * 3.2, -3.5 - seg_t * 3.2)
			draw_line(p0, p_next, hair_col, maxf(1.4, 3.4 - seg_t * 0.4))
			p0 = p_next
		draw_circle(p0, 1.6, hair_col)
	elif is_fast_dropping:
		# Падіння вниз: чуб стоїть дибки вгору як антена і вібрує від шаленого вітру!
		var flutter := sin(time_passed * 35.0) * 3.2
		var p1 := chub_base + Vector2(-1.0 * h_dir, -9.5)
		var p2 := chub_base + Vector2(-2.0 * h_dir + flutter * 0.5, -18.5)
		var p3 := chub_base + Vector2(-2.5 * h_dir + flutter, -27.5)
		_draw_oseledets_ribbon(chub_base, p1, p2, p3, h_dir, hair_col, hair_hi)
	elif is_rolling:
		# Перекат: чуб закручується навколо голови від відцентрової сили обертання
		var roll_spin := time_passed * 24.0 * roll_dir
		var p1 := chub_base + Vector2(cos(roll_spin) * 6.0, sin(roll_spin) * 6.0)
		var p2 := chub_base + Vector2(cos(roll_spin + 0.8) * 12.0, sin(roll_spin + 0.8) * 12.0)
		var p3 := chub_base + Vector2(cos(roll_spin + 1.4) * 17.5, sin(roll_spin + 1.4) * 17.5)
		_draw_oseledets_ribbon(chub_base, p1, p2, p3, h_dir, hair_col, hair_hi)
	elif is_hopak and hopak_time >= 2.04 and hopak_time < 2.76:
		# Гопак (Різножка щупак у повітрі): пишний чуб злітає вгору короною-дугою від стрибка
		var p1 := chub_base + Vector2(0.0, -8.5)
		var p2 := chub_base + Vector2(-4.5, -15.5)
		var p3 := chub_base + Vector2(-11.0, -18.5)
		_draw_oseledets_ribbon(chub_base, p1, p2, p3, 1.0, hair_col, hair_hi)
	elif is_gliding or flap_timer > 0.0:
		# Ширяння: довга плавна шовкова хвиля позаду
		var wave_chub := sin(time_passed * 16.0) * 3.8
		var p1 := chub_base + Vector2(-5.2 * h_dir, -6.5)
		var p2 := chub_base + Vector2(-12.5 * h_dir, -3.5 + wave_chub * 0.6)
		var p3 := chub_base + Vector2(-21.0 * h_dir, 1.5 + wave_chub)
		_draw_oseledets_ribbon(chub_base, p1, p2, p3, h_dir, hair_col, hair_hi)
	else:
		# Звичайний біг / спокій: грайливий чуб через ліве вухо з пружним кільцем на пружинній фізиці
		var trail := (run_anim * 3.0 + chub_lag * 1.25)
		var p1 := chub_base + Vector2(-5.5 * h_dir, -5.8)
		var p2 := chub_base + Vector2(-12.0 * h_dir, -1.6 + trail * 0.6)
		var p3 := chub_base + Vector2(-18.5 * h_dir, 4.5 + trail)
		_draw_oseledets_ribbon(chub_base, p1, p2, p3, h_dir, hair_col, hair_hi)
	
	# --- 9. FRONT ARM (Articulated 2-Segment Shoulder -> Elbow -> Wrist) ---
	if is_hopak and hopak_time < 0.68:
		# Phase 1: Left arm unleashes straight punch to the left in the foreground
		_draw_articulated_arm(pose["shoulder_l"], pose["elbow_l"], pose["wrist_l"], -1.0, false, pose["fist_l"])
	elif is_hopak and hopak_time < 1.36:
		# Phase 2: Right arm unleashes power cross punch to the right in the foreground
		_draw_articulated_arm(pose["shoulder_r"], pose["elbow_r"], pose["wrist_r"], 1.0, false, pose["fist_r"])
	else:
		_draw_articulated_arm(pose["shoulder_r"], pose["elbow_r"], pose["wrist_r"], 1.0 if (is_hopak and pose["wrist_r"].x > chest.x) else flip, false, pose["fist_r"])
	
	# Martial impact air-shock crescent at peak punch or kick extension
	var streak: Vector2 = pose["punch_streak"]
	if streak != Vector2.ZERO:
		var s_dir := signf(streak.x - chest.x)
		if absf(s_dir) < 0.1:
			s_dir = punch_facing
		var s_rad := 11.5 if punch_timer > 0.0 else 5.5
		var s_col := Color(1.0, 0.88, 0.25, 0.92) if punch_timer > 0.0 else Color(1.0, 0.96, 0.75, 0.80)
		draw_arc(streak, s_rad, -0.80 if s_dir > 0 else PI - 0.80, 0.80 if s_dir > 0 else PI + 0.80, 10, s_col, 2.8)
		if punch_timer > 0.0:
			draw_arc(streak + Vector2(s_dir * 5.5, 0.0), s_rad * 1.38, -0.65 if s_dir > 0 else PI - 0.65, 0.65 if s_dir > 0 else PI + 0.65, 8, Color(1.0, 0.95, 0.40, 0.68), 2.0)
			if punch_active_skill == ChampionSkill.HOPAK_SHCHUPAK_SPLIT:
				# Друга ударна хвиля з лівого чобота під час подвійного удару «Щупак»!
				var left_streak: Vector2 = pose["ankle_l"] + Vector2(-7.0, 0.0)
				draw_arc(left_streak, s_rad, PI - 0.80, PI + 0.80, 10, s_col, 2.8)
				draw_arc(left_streak + Vector2(-5.5, 0.0), s_rad * 1.38, PI - 0.65, PI + 0.65, 8, Color(1.0, 0.95, 0.40, 0.68), 2.0)
	
	# Соковиті візуальні спецефекти ударів руками та ногами (ударні кільця, 8-променеві зірки, іскри та золоті підкови!)
	for fx in strike_effects:
		var fx_t: float = float(fx["time"]) / maxf(float(fx["duration"]), 0.01)
		var fx_alpha: float = clampf(1.0 - fx_t, 0.0, 1.0)
		var fx_pos: Vector2 = fx["pos"]
		var fx_col: Color = fx["color"]
		var fx_dir: float = float(fx["dir"])
		var is_kick_fx: bool = bool(fx["is_kick"])
		var is_hit_fx: bool = bool(fx["is_hit"])
		
		# 1. Подвійне розширюване ударне кільце (Shockwave Ring)
		var ring_r := lerpf(6.0, 32.0 if is_hit_fx else 22.0, fx_t)
		draw_arc(fx_pos, ring_r, 0.0, TAU, 16, Color(fx_col.r, fx_col.g, fx_col.b, fx_alpha * 0.85), 2.6 * fx_alpha + 0.8)
		draw_arc(fx_pos, ring_r * 0.62, 0.0, TAU, 12, Color(1.0, 1.0, 0.88, fx_alpha * 0.75), 1.8 * fx_alpha)
		
		# 2. Якщо це удар ногою — малюємо сяючий слід золотої козацької підкови!
		if is_kick_fx:
			var shoe_c := fx_pos + Vector2(fx_dir * 4.0 * fx_t, 0.0)
			draw_arc(shoe_c, 7.5 + fx_t * 4.0, -1.1 if fx_dir > 0 else PI - 1.1, 1.1 if fx_dir > 0 else PI + 1.1, 8, Color(1.0, 0.88, 0.18, fx_alpha), 3.2)
		
		# 3. Віяло козацьких іскор та 8-променева зірка влучання (Starburst)
		var num_sparks := 8 if is_hit_fx else 5
		for sp_i in range(num_sparks):
			var ang := float(sp_i) / float(num_sparks) * TAU + fx_t * 2.5
			var r_in := ring_r * 0.35
			var r_out := ring_r * (1.35 if (sp_i % 2 == 0) else 0.95)
			var p_start := fx_pos + Vector2(cos(ang), sin(ang)) * r_in
			var p_end := fx_pos + Vector2(cos(ang), sin(ang)) * r_out
			draw_line(p_start, p_end, Color(1.0, 0.96, 0.55, fx_alpha), 2.2 if is_hit_fx else 1.6)
			draw_circle(p_end, 1.6 * fx_alpha, Color(fx_col.r, fx_col.g, fx_col.b, fx_alpha))
		if is_hit_fx:
			draw_circle(fx_pos, 6.5 * (1.0 - fx_t), Color(1.0, 1.0, 0.92, fx_alpha * 0.90))
	
	# Comical cartoon dizzy stars circling around Dzhura's head on ceiling bonk!
	if bonk_timer > 0.0:
		var bonk_center := head_c + Vector2(0.0, -11.0)
		for s in range(3):
			var star_ang := time_passed * 16.0 + float(s) * (TAU / 3.0)
			var star_pos := bonk_center + Vector2(cos(star_ang) * 11.5, sin(star_ang) * 4.5)
			# 4-point golden cartoon star
			draw_line(star_pos - Vector2(3.5, 0), star_pos + Vector2(3.5, 0), Color(1.0, 0.88, 0.20), 1.8)
			draw_line(star_pos - Vector2(0, 3.5), star_pos + Vector2(0, 3.5), Color(1.0, 0.88, 0.20), 1.8)
			draw_circle(star_pos, 1.3, Color.WHITE)
			
	# Динамічні ефекти пилу та швидкості (акробатика, приземлення та бойовий гопак)
	if is_rolling:
		# Вихор швидкості та дуги обертання навколо колеса Джури
		var spin_ang := time_passed * 24.0 * roll_dir
		draw_arc(pelvis, 13.0, spin_ang, spin_ang + 2.2, 10, Color(0.92, 0.88, 0.78, 0.70), 2.0)
		draw_arc(pelvis, 10.5, spin_ang + PI, spin_ang + PI + 1.8, 8, Color(0.95, 0.90, 0.75, 0.55), 1.6)
		# Хмаринки пилу біля землі
		_draw_oval(pelvis + Vector2(-6.0 * roll_dir, 12.0), 3.8, 1.8, Color(0.85, 0.80, 0.70, 0.45))
	elif squat_timer > 0.0:
		# Супергеройське приземлення: клуби пилу розлітаються ліворуч і праворуч
		var impact_t := clampf(squat_timer / 0.14, 0.0, 1.0)
		var spread := (1.0 - impact_t) * 14.0
		_draw_oval(Vector2(-6.0 - spread, 13.5), 4.2 * impact_t + 1.5, 2.0 * impact_t + 0.8, Color(0.88, 0.82, 0.72, 0.50 * impact_t))
		_draw_oval(Vector2(6.0 + spread, 13.5), 4.2 * impact_t + 1.5, 2.0 * impact_t + 0.8, Color(0.88, 0.82, 0.72, 0.50 * impact_t))
	elif is_hopak and hopak_time >= 2.76 and hopak_time < 3.44:
		# Повзунець: шлейф козацького пилу під сап'янцем, що ковзає по підлозі
		var sweep_progress := clampf((hopak_time - 2.76) / 0.68, 0.0, 1.0)
		var dust_x := lerpf(4.0, 22.0, sweep_progress)
		_draw_oval(Vector2(dust_x, 13.0), 4.0, 1.5, Color(0.90, 0.85, 0.75, 0.55))

# Renders an authentic Kyivnaukfilm 2-bone leg wrapped in billowing crimson Sharovary & upturned Sapyanets boot
func _draw_articulated_leg(hip: Vector2, knee: Vector2, ankle: Vector2, foot_angle: float, flip: float, is_back_leg: bool) -> void:
	var red_shadow := Color(0.44, 0.04, 0.08) if is_back_leg else Color(0.52, 0.05, 0.10)
	var red_mid := Color(0.72, 0.08, 0.14) if is_back_leg else Color(0.86, 0.12, 0.18)
	var red_light := Color(0.88, 0.18, 0.22) if is_back_leg else Color(0.98, 0.28, 0.32)
	var cuff_gold := Color(0.94, 0.78, 0.16)
	
	# Пишні козацькі шаровари (Київнаукфільм): об'ємні, роздуваються при ширянні
	var balloon_extra := 2.2 if is_gliding else (0.8 if not is_on_floor() else 0.0)
	
	# 1. Thigh segment (Hip -> Knee)
	var thigh_vec := knee - hip
	var thigh_len := maxf(thigh_vec.length(), 0.01)
	var thigh_dir := thigh_vec / thigh_len
	var thigh_perp := Vector2(-thigh_dir.y, thigh_dir.x)
	
	var t_p1 := hip + thigh_perp * (4.2 + balloon_extra * 0.5)
	var t_p2 := hip + thigh_dir * (thigh_len * 0.52) + thigh_perp * (7.2 + balloon_extra)
	var t_p3 := knee + thigh_perp * 5.2
	var t_p4 := knee - thigh_perp * 5.2
	var t_p5 := hip + thigh_dir * (thigh_len * 0.52) - thigh_perp * (6.6 + balloon_extra)
	var t_p6 := hip - thigh_perp * (4.2 + balloon_extra * 0.5)
	draw_colored_polygon(PackedVector2Array([t_p1, t_p2, t_p3, t_p4, t_p5, t_p6]), red_mid)
	draw_line(hip - thigh_perp * 2.8, knee - thigh_perp * 3.2, red_shadow, 2.6)
	draw_line(hip + thigh_perp * 2.4, knee + thigh_perp * 2.4, red_light, 2.4)
	
	# Об'ємне козацьке коліно
	draw_circle(knee, 5.0, red_mid)
	draw_circle(knee + Vector2(0.8 * flip, -0.8), 2.8, red_light)
	
	# 2. Calf segment (Knee -> Ankle)
	var calf_vec := ankle - knee
	var calf_len := maxf(calf_vec.length(), 0.01)
	var calf_dir := calf_vec / calf_len
	var calf_perp := Vector2(-calf_dir.y, calf_dir.x)
	
	var c_p1 := knee + calf_perp * 4.8
	var c_p2 := knee + calf_dir * (calf_len * 0.55) + calf_perp * (6.8 + balloon_extra)
	var c_p3 := ankle + calf_perp * 2.8
	var c_p4 := ankle - calf_perp * 2.8
	var c_p5 := knee + calf_dir * (calf_len * 0.60) - calf_perp * (6.2 + balloon_extra)
	var c_p6 := knee - calf_perp * 4.8
	draw_colored_polygon(PackedVector2Array([c_p1, c_p2, c_p3, c_p4, c_p5, c_p6]), red_mid)
	draw_line(knee - calf_perp * 3.0, ankle - calf_perp * 2.0, red_shadow, 2.2)
	draw_line(knee + calf_perp * 2.2, ankle + calf_perp * 1.4, red_light, 2.0)
	
	# Золотий шовковий манжет шароварів над чоботом
	draw_line(ankle - calf_perp * 3.0, ankle + calf_perp * 3.0, cuff_gold, 1.8)
	
	# 3. Сап'янці із загнутими носками вгору (Київнаукфільм)
	var boot_base := Color(0.35, 0.06, 0.05)
	var boot_mid := Color(0.66, 0.10, 0.08) if is_back_leg else Color(0.78, 0.14, 0.10)
	var boot_hi := Color(0.85, 0.22, 0.15) if is_back_leg else Color(0.98, 0.32, 0.22)
	var sole_col := Color(0.18, 0.05, 0.04)
	var heel_brass := Color(0.88, 0.72, 0.18)
	
	var f_fwd := Vector2(cos(foot_angle) * flip, sin(foot_angle) * flip)
	var f_down := Vector2(-sin(foot_angle), cos(foot_angle))
	
	var b_top_back := ankle - f_fwd * 2.6
	var b_top_front := ankle + f_fwd * 2.6
	var b_heel := ankle - f_fwd * 2.8 + f_down * 4.6
	var b_arch := ankle + f_fwd * 2.4 + f_down * 4.6
	var b_toe_curve := ankle + f_fwd * 8.6 + f_down * 0.4 # Задертий догори кінчик!
	var b_toe_tip := ankle + f_fwd * 7.4 + f_down * 2.4
	var b_instep := ankle + f_fwd * 4.4 + f_down * 1.8
	
	# Корпус чобітка з характерним козацьким вигином
	draw_colored_polygon(PackedVector2Array([
		b_top_back, b_top_front, b_instep, b_toe_curve, b_toe_tip, b_arch, b_heel
	]), boot_mid)
	draw_line(b_top_front - f_fwd * 0.8, b_instep - f_fwd * 0.8, boot_hi, 1.6)
	draw_line(b_top_back + f_fwd * 0.6, b_heel + f_fwd * 0.6, boot_base, 1.4)
	
	# Підошва, каблук та ковані підківки
	draw_line(b_heel, b_arch, sole_col, 1.8)
	draw_line(b_arch, b_toe_tip, sole_col, 1.5)
	draw_line(b_heel, b_heel + f_fwd * 2.0, heel_brass, 1.8)
	
	if has_vakula_shoes:
		# Чарівні золоті підківки Вакули з іскрами
		draw_line(b_heel, b_toe_tip, Color(1.0, 0.88, 0.20), 2.5)
		draw_line(b_toe_tip, b_toe_curve, Color(1.0, 0.88, 0.20), 2.2)
		draw_circle(b_heel, 2.2, Color(1.0, 1.0, 0.60))
		draw_circle(b_toe_curve, 1.8, Color(1.0, 1.0, 0.60))
		# Золоті іскри при бігу та стрибках
		var spk_ang := time_passed * 16.0 + (float(ankle.x) * 0.05)
		var spk_p := b_toe_curve + Vector2(cos(spk_ang), sin(spk_ang)) * 3.2
		draw_line(spk_p - Vector2(1.8, 0), spk_p + Vector2(1.8, 0), Color(1.0, 0.95, 0.40), 1.2)
		draw_line(spk_p - Vector2(0, 1.8), spk_p + Vector2(0, 1.8), Color(1.0, 0.95, 0.40), 1.2)

# Renders an anatomical 2-bone arm (Shoulder -> Elbow -> Wrist) with embroidered sleeve & hand/fist
func _draw_articulated_arm(shoulder: Vector2, elbow: Vector2, wrist: Vector2, flip: float, is_back_arm: bool, is_fist: bool) -> void:
	var sleeve_shadow := Color(0.72, 0.75, 0.82) if is_back_arm else Color(0.80, 0.83, 0.90)
	var sleeve_mid := Color(0.86, 0.88, 0.94) if is_back_arm else Color(0.95, 0.96, 0.99)
	var sleeve_hi := Color(0.95, 0.96, 1.0) if is_back_arm else Color(1.0, 1.0, 1.0)
	var emb_red := Color(0.82, 0.12, 0.15)
	var skin_shadow := Color(0.80, 0.62, 0.50)
	var skin_light := Color(0.98, 0.85, 0.72)
	
	# 1. Upper Arm (Shoulder -> Elbow)
	draw_line(shoulder, elbow, sleeve_shadow, 4.4)
	draw_line(shoulder + Vector2(0, -0.6), elbow + Vector2(0, -0.6), sleeve_mid, 3.2)
	draw_line(shoulder + Vector2(0, -1.1), elbow + Vector2(0, -1.1), sleeve_hi, 1.4)
	
	# Traditional Ukrainian shoulder embroidery band ("полики") with red & black ornament
	var polyk_pos := shoulder.lerp(elbow, 0.28)
	draw_circle(polyk_pos, 2.3, emb_red)
	draw_circle(polyk_pos, 1.1, Color(0.12, 0.10, 0.10))
	draw_circle(polyk_pos + Vector2(0.3, -0.3), 0.5, Color.WHITE)
	
	# 2. Articulated Elbow Joint
	draw_circle(elbow, 2.2, sleeve_mid)
	
	# 3. Forearm (Elbow -> Wrist) with puffed linen sleeve tapering to embroidered cuff
	var forearm_mid := elbow.lerp(wrist, 0.52)
	draw_circle(forearm_mid, 2.6, sleeve_mid)
	draw_line(elbow, wrist, sleeve_shadow, 4.2)
	draw_line(elbow + Vector2(0, -0.5), wrist + Vector2(0, -0.5), sleeve_mid, 3.0)
	draw_line(elbow + Vector2(0, -1.0), wrist + Vector2(0, -1.0), sleeve_hi, 1.4)
	
	# Embroidered wrist cuff ("манжет") with golden button accent
	var cuff_pos := elbow.lerp(wrist, 0.86)
	draw_circle(cuff_pos, 2.0, emb_red)
	draw_circle(cuff_pos, 0.9, Color(0.95, 0.85, 0.20))
	
	# 4. Anatomical Hand / Martial Fist at Wrist
	var hand_dir := (wrist - elbow).normalized()
	var hand_center := wrist + hand_dir * 1.4
	if is_fist:
		draw_circle(hand_center, 2.7, skin_shadow)
		draw_circle(hand_center + Vector2(0.4 * flip, -0.5), 2.2, skin_light)
		# Knuckle ridge highlight
		draw_line(hand_center + Vector2(-0.8, -1.2), hand_center + Vector2(1.2, -0.6), Color(1.0, 0.94, 0.86), 1.1)
	else:
		_draw_oval(hand_center, 2.6, 2.0, skin_shadow if is_back_arm else skin_light)
		# Thumb detail
		draw_circle(hand_center + Vector2(0.8 * flip, -1.2), 1.1, skin_light)

func _draw_oseledets_ribbon(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, h_dir: float, hair_col: Color, hair_hi: Color) -> void:
	var steps := 10
	var prev_pt := p0
	for i in range(1, steps + 1):
		var t := float(i) / float(steps)
		var omt := 1.0 - t
		var pt := (omt * omt * omt) * p0 + (3.0 * omt * omt * t) * p1 + (3.0 * omt * t * t) * p2 + (t * t * t) * p3
		var width := lerpf(4.0, 1.5, t)
		draw_line(prev_pt, pt, hair_col, width)
		if t < 0.65:
			draw_line(prev_pt + Vector2(0.0, -0.5), pt + Vector2(0.0, -0.5), hair_hi, width * 0.42)
		prev_pt = pt
	draw_arc(p3 + Vector2(-1.8 * h_dir, 1.0), 2.1, 0.4, TAU - 0.2, 8, hair_col, 1.7)

func _draw_oval(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	var num_pts := 20
	for i in range(num_pts):
		var phi := float(i) / float(num_pts) * TAU
		pts.append(center + Vector2(cos(phi) * rx, sin(phi) * ry))
	draw_colored_polygon(pts, color)
