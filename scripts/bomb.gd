extends Area2D

class_name BombItem

signal collected(bomb: BombItem, is_lit: bool)
signal exploded(bomb: BombItem)
signal fizzled(bomb: BombItem)

const FUSE_DURATION: float = 7.0
const CRITICAL_FUSE_THRESHOLD: float = 2.2
const EXPLOSION_DURATION: float = 0.45
const FIZZLE_DURATION: float = 0.65
const FIZZLE_CHANCE: float = 0.20
const CHAIN_CHANCE: float = 0.50
const CHAIN_CHANCE_EARLY: float = 0.20  # рівні 1–2: м'якша ланцюгова реакція для дітей 8–10


# Шанс ланцюгового підпалу сусідніх ядер залежно від рівня
static func chain_chance_for_level(level: int) -> float:
	return CHAIN_CHANCE_EARLY if level <= 2 else CHAIN_CHANCE


var fuse_timer: float = 7.0
var chain_chance: float = CHAIN_CHANCE
var is_exploding: bool = false
var explosion_anim_time: float = 0.0
var is_fizzling: bool = false
var fizzle_anim_time: float = 0.0

@export var is_lit: bool = false:
	set(val):
		var was := is_lit
		is_lit = val
		if val and not was:
			fuse_timer = FUSE_DURATION
		queue_redraw()

var time_passed: float = 0.0
var hover_offset: float = 0.0
var hover_speed: float = 2.5
var hover_phase: float = 0.0
var glint_timer: float = 0.0

# 3D Embers array for lit bomb
var embers: Array[Dictionary] = []


func _ready() -> void:
	add_to_group("bombs")
	body_entered.connect(_on_body_entered)
	# Randomize hover phase so bombs don't all bob synchronously
	hover_phase = randf_range(0.0, TAU)
	hover_speed = randf_range(2.2, 2.8)
	if is_lit:
		fuse_timer = FUSE_DURATION


func ignite() -> void:
	if not is_lit and not is_exploding and not is_queued_for_deletion():
		is_lit = true
		fuse_timer = FUSE_DURATION
		queue_redraw()


func fizzle() -> void:
	if is_fizzling or is_exploding or is_queued_for_deletion():
		return
	is_lit = false
	is_fizzling = true
	fizzle_anim_time = 0.0
	fuse_timer = FUSE_DURATION
	embers.clear()
	fizzled.emit(self)
	queue_redraw()


func explode() -> void:
	if is_exploding or is_queued_for_deletion():
		return
	is_exploding = true
	explosion_anim_time = 0.0
	exploded.emit(self)

	# Ланцюгова реакція: підпал сусідніх холодних бомб із шансом 50% (на рівнях 1–2 — 20%, щоб не було лавини для дітей 8–10)
	var tree := get_tree()
	if tree != null:
		for other in tree.get_nodes_in_group("bombs"):
			if other is BombItem and other != self and not other.is_lit and not other.is_exploding and not other.is_queued_for_deletion():
				if global_position.distance_to(other.global_position) <= 72.0:
					if randf() < chain_chance:
						other.ignite()


func _process(delta: float) -> void:
	time_passed += delta
	hover_offset = sin(time_passed * hover_speed + hover_phase) * 2.2
	glint_timer += delta * 1.5

	if is_exploding:
		explosion_anim_time += delta
		queue_redraw()
		if explosion_anim_time >= EXPLOSION_DURATION:
			queue_free()
		return

	if is_fizzling:
		fizzle_anim_time += delta
		queue_redraw()
		if fizzle_anim_time >= FIZZLE_DURATION:
			is_fizzling = false

	if is_lit:
		fuse_timer -= delta
		if fuse_timer <= 0.0:
			# 20% шанс, що ґніт просто пшикне й згасне без вибуху!
			if randf() < FIZZLE_CHANCE:
				fizzle()
			else:
				explode()
			return

		# Інтенсивність іскор зростає, коли ґніт догорає (критична фаза)
		var ember_chance := 0.35 if fuse_timer > CRITICAL_FUSE_THRESHOLD else 0.85
		if randf() < ember_chance:
			embers.append(
				{
					"pos": Vector2(4.0 + randf_range(-2.0, 2.0), -14.0),
					"vel": Vector2(randf_range(-20.0, 20.0), randf_range(-30.0, -70.0)),
					"life": randf_range(0.2, 0.45),
					"max_life": 0.45,
					"size": randf_range(1.5, 3.2) if fuse_timer <= CRITICAL_FUSE_THRESHOLD else randf_range(1.0, 2.5)
				}
			)

		var kept_embers: Array[Dictionary] = []
		for emb in embers:
			emb["life"] -= delta
			emb["pos"] += emb["vel"] * delta
			if emb["life"] > 0:
				kept_embers.append(emb)
		embers = kept_embers

	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if is_exploding:
		return
	if body is JackPlayer:
		if body.is_hopak:
			return
		collected.emit(self, is_lit)
		queue_free()


func _draw() -> void:
	if is_exploding:
		var progress := explosion_anim_time / EXPLOSION_DURATION
		var r_cloud := 14.0 + progress * 26.0
		var c_smoke := Color(0.12, 0.12, 0.15, (1.0 - progress) * 0.9)
		var c_fire := Color(1.0, 0.45, 0.08, (1.0 - progress) * 0.95)
		draw_circle(Vector2(0, 2), r_cloud * 1.1, c_smoke)
		draw_circle(Vector2(-6, -4), r_cloud * 0.7, c_smoke)
		draw_circle(Vector2(6, -2), r_cloud * 0.75, c_smoke)
		draw_circle(Vector2(0, 0), r_cloud * 0.6, c_fire)
		draw_circle(Vector2(0, 0), r_cloud * 0.35, Color(1.0, 0.95, 0.35, 1.0 - progress))
		var fnt := ThemeDB.fallback_font
		if fnt:
			draw_string(
				fnt, Vector2(-20.0, -r_cloud - 2.0), "БАХ!", HORIZONTAL_ALIGNMENT_CENTER, 40.0, 15, Color(1.0, 0.92, 0.25, 1.0 - progress)
			)
		return

	var fuse_progress := clampf(fuse_timer / FUSE_DURATION, 0.0, 1.0) if is_lit else 1.0
	var is_critical := is_lit and (fuse_timer <= CRITICAL_FUSE_THRESHOLD)
	var panic_shake := Vector2(randf_range(-1.4, 1.4), randf_range(-1.4, 1.4)) if is_critical else Vector2.ZERO
	var sphere_center := Vector2(0.0, 2.0 + hover_offset) + panic_shake
	var radius := 11.5

	# 1. PSEUDO-3D DROP SHADOW ON THE WALL/FLOOR (Depth Cue)
	var shadow_scale := 1.0 - (hover_offset / 18.0)
	_draw_oval(Vector2(0, 16.5), 10.0 * shadow_scale, 3.8 * shadow_scale, Color(0.0, 0.0, 0.05, 0.38))
	_draw_oval(Vector2(0, 16.5), 6.5 * shadow_scale, 2.2 * shadow_scale, Color(0.0, 0.0, 0.05, 0.55))

	# 2. AMBIENT GLOW IF LIT
	if is_lit:
		var aura_pulse := (1.0 + sin(time_passed * (24.0 if is_critical else 12.0)) * 0.18) * (1.2 if is_critical else 1.0)
		draw_circle(sphere_center, 24.0 * aura_pulse, Color(1.0, 0.35, 0.05, 0.14))
		draw_circle(sphere_center, 17.0 * aura_pulse, Color(1.0, 0.60, 0.10, 0.24))

	# 3. SPHERICAL PSEUDO-3D RAYTRACED SHADING (Concentric Iso-Luminance Bands)
	var light_target := sphere_center + Vector2(-4.2, -4.2)

	# Base dark sphere
	draw_circle(sphere_center, radius, Color(0.06, 0.07, 0.10))

	# Rim / Fresnel light on bottom-right edge
	draw_arc(sphere_center, radius - 0.8, 0.2, 2.1, 16, Color(0.30, 0.35, 0.50, 0.45), 1.5)

	# 10 Spherical Depth Steps
	var steps := 10
	for i in range(steps):
		var t := float(i) / float(steps)
		var center := sphere_center.lerp(light_target, t * 0.88)
		var r := radius * (1.0 - t * 0.72)

		# Smooth metallic gradient from deep charcoal to shining highlight
		var col: Color
		if t < 0.3:
			col = Color(0.06, 0.07, 0.10).lerp(Color(0.16, 0.18, 0.24), t / 0.3)
		elif t < 0.7:
			col = Color(0.16, 0.18, 0.24).lerp(Color(0.42, 0.46, 0.58), (t - 0.3) / 0.4)
		elif t < 0.9:
			col = Color(0.42, 0.46, 0.58).lerp(Color(0.78, 0.84, 0.96), (t - 0.7) / 0.2)
		else:
			col = Color(0.78, 0.84, 0.96).lerp(Color(1.0, 1.0, 1.0), (t - 0.9) / 0.1)

		# If lit, top sphere surface reflects warm firelight; in critical phase the core glows red-hot!
		if is_lit and t > 0.1:
			var fire_warmth := sin(time_passed * 16.0) * 0.1 + 0.9
			var heat_tint := Color(1.0, 0.65, 0.25)
			if is_critical:
				var panic_pulse := 0.6 + sin(time_passed * 28.0) * 0.4
				heat_tint = heat_tint.lerp(Color(1.0, 0.15, 0.05), (1.0 - fuse_progress) * panic_pulse)
			col = col.lerp(heat_tint, 0.45 * fire_warmth * (1.0 - t * 0.4))

		draw_circle(center, r, col)

	# Specular Hotspot Glint
	var spec_center := light_target
	draw_circle(spec_center, 1.8, Color(1.0, 1.0, 1.0, 0.95))

	# Occasional dynamic 4-point star glint twinkle
	var glint_phase := fmod(glint_timer, 3.5)
	if glint_phase < 0.35 and not is_critical:
		var glint_size := sin(glint_phase / 0.35 * PI) * 4.5
		draw_line(spec_center - Vector2(glint_size, 0), spec_center + Vector2(glint_size, 0), Color.WHITE, 1.2)
		draw_line(spec_center - Vector2(0, glint_size), spec_center + Vector2(0, glint_size), Color.WHITE, 1.2)

	# 4. 3D BRASS COLLAR / NECK
	var collar_y := sphere_center.y - 10.5
	draw_rect(Rect2(-4.0, collar_y, 8.0, 3.5), Color(0.35, 0.25, 0.05))
	draw_rect(Rect2(-3.5, collar_y, 7.0, 3.0), Color(0.75, 0.55, 0.10))
	draw_line(Vector2(-2.5, collar_y), Vector2(-2.5, collar_y + 3.0), Color(0.98, 0.85, 0.35), 1.5)
	draw_line(Vector2(2.5, collar_y), Vector2(2.5, collar_y + 3.0), Color(0.40, 0.28, 0.05), 1.5)
	_draw_oval(Vector2(0, collar_y), 3.5, 1.2, Color(0.95, 0.80, 0.30))

	# 5. 3D BRAIDED FUSE (динамічно згорає)
	var fuse_start := Vector2(0, collar_y)
	var fuse_mid := Vector2(2.5, collar_y - 4.0)
	var fuse_full_tip := Vector2(4.5, collar_y - 8.0)

	var fuse_tip: Vector2
	if fuse_progress > 0.5:
		var p := (fuse_progress - 0.5) / 0.5
		fuse_tip = fuse_mid.lerp(fuse_full_tip, p)
		draw_line(fuse_start, fuse_mid, Color(0.75, 0.65, 0.40), 2.4)
		draw_line(fuse_mid, fuse_tip, Color(0.65, 0.55, 0.32), 2.2)
		draw_line(fuse_start + Vector2(0.5, 0), fuse_mid + Vector2(0.5, 0), Color(0.90, 0.82, 0.60), 1.0)
	else:
		var p := fuse_progress / 0.5
		fuse_tip = fuse_start.lerp(fuse_mid, p)
		draw_line(fuse_start, fuse_tip, Color(0.75, 0.65, 0.40), 2.4)
		draw_line(fuse_start + Vector2(0.5, 0), fuse_tip + Vector2(0.5, 0), Color(0.90, 0.82, 0.60), 1.0)

	# 6. DYNAMIC 3D LIT SPARK & VOLUMETRIC CORONA
	if is_lit and fuse_progress > 0.01:
		var spark_pulse := (1.0 + sin(time_passed * 24.0) * 0.25) * (1.3 if is_critical else 1.0)
		draw_circle(fuse_tip, 8.0 * spark_pulse, Color(1.0, 0.25, 0.0, 0.45))
		draw_circle(fuse_tip, 5.0 * spark_pulse, Color(1.0, 0.65, 0.05, 0.85))
		draw_circle(fuse_tip, 2.5 * spark_pulse, Color(1.0, 0.98, 0.65))
		draw_circle(fuse_tip, 1.2, Color.WHITE)

		var angle := time_passed * (22.0 if is_critical else 14.0)
		for k in range(4):
			var a := angle + k * (PI / 2.0)
			var ray_len := (9.0 if is_critical else 7.0) * spark_pulse
			var ray_dir := Vector2(cos(a), sin(a)) * ray_len
			draw_line(fuse_tip, fuse_tip + ray_dir, Color(1.0, 0.9, 0.4, 0.75), 1.2)

		# Render rising floating 3D embers
		for emb in embers:
			var alpha: float = emb["life"] / emb["max_life"]
			var col := Color(1.0, 0.75 * alpha, 0.1, alpha * 0.9)
			draw_circle(emb["pos"], emb["size"] * alpha, col)

	# 7. КОМІЧНИЙ ПШИК ТА ДИМОК ПРИ ЗГАСАННІ
	if is_fizzling:
		var f_progress := fizzle_anim_time / FIZZLE_DURATION
		var smoke_y := collar_y - 4.0 - f_progress * 14.0
		var r_fizzle := 3.5 + f_progress * 8.0
		draw_circle(Vector2(2.0, smoke_y), r_fizzle, Color(0.65, 0.70, 0.75, (1.0 - f_progress) * 0.75))
		draw_circle(Vector2(-2.0, smoke_y - 2.0), r_fizzle * 0.75, Color(0.80, 0.85, 0.90, (1.0 - f_progress) * 0.65))
		draw_circle(Vector2(1.0, smoke_y + 2.0), r_fizzle * 0.6, Color(0.95, 0.95, 1.0, (1.0 - f_progress) * 0.8))
		var fnt := ThemeDB.fallback_font
		if fnt:
			draw_string(
				fnt, Vector2(-24.0, smoke_y - 7.0), "ПШИК!", HORIZONTAL_ALIGNMENT_CENTER, 48.0, 11, Color(0.70, 0.88, 1.0, 1.0 - f_progress)
			)


func _draw_oval(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	var num_pts := 20
	for i in range(num_pts):
		var phi := float(i) / float(num_pts) * TAU
		pts.append(center + Vector2(cos(phi) * rx, sin(phi) * ry))
	draw_colored_polygon(pts, color)
