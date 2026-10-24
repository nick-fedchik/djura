extends Area2D

class_name BombItem

signal collected(bomb: BombItem, is_lit: bool)

@export var is_lit: bool = false:
	set(val):
		is_lit = val
		queue_redraw()

var time_passed: float = 0.0
var hover_offset: float = 0.0
var hover_speed: float = 2.5
var hover_phase: float = 0.0
var glint_timer: float = 0.0

# 3D Embers array for lit bomb
var embers: Array[Dictionary] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Randomize hover phase so bombs don't all bob synchronously
	hover_phase = randf_range(0.0, TAU)
	hover_speed = randf_range(2.2, 2.8)

func _process(delta: float) -> void:
	time_passed += delta
	hover_offset = sin(time_passed * hover_speed + hover_phase) * 2.2
	
	glint_timer += delta * 1.5
	
	if is_lit:
		# Update and spawn floating 3D embers
		if randf() < 0.35:
			embers.append({
				"pos": Vector2(4.0 + randf_range(-2.0, 2.0), -14.0),
				"vel": Vector2(randf_range(-15.0, 15.0), randf_range(-25.0, -55.0)),
				"life": randf_range(0.2, 0.45),
				"max_life": 0.45,
				"size": randf_range(1.0, 2.5)
			})
		
		var kept_embers: Array[Dictionary] = []
		for emb in embers:
			emb["life"] -= delta
			emb["pos"] += emb["vel"] * delta
			if emb["life"] > 0:
				kept_embers.append(emb)
		embers = kept_embers
	
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body is JackPlayer:
		if body.is_hopak:
			return
		collected.emit(self, is_lit)
		queue_free()

func _draw() -> void:
	var sphere_center := Vector2(0.0, 2.0 + hover_offset)
	var radius := 11.5
	
	# 1. PSEUDO-3D DROP SHADOW ON THE WALL/FLOOR (Depth Cue)
	# Shadow stays at ground level, expanding/contracting as the bomb hovers
	var shadow_scale := 1.0 - (hover_offset / 18.0)
	_draw_oval(Vector2(0, 16.5), 10.0 * shadow_scale, 3.8 * shadow_scale, Color(0.0, 0.0, 0.05, 0.38))
	_draw_oval(Vector2(0, 16.5), 6.5 * shadow_scale, 2.2 * shadow_scale, Color(0.0, 0.0, 0.05, 0.55))
	
	# 2. AMBIENT GLOW IF LIT
	if is_lit:
		var aura_pulse := 1.0 + sin(time_passed * 12.0) * 0.15
		draw_circle(sphere_center, 24.0 * aura_pulse, Color(1.0, 0.35, 0.05, 0.12))
		draw_circle(sphere_center, 17.0 * aura_pulse, Color(1.0, 0.60, 0.10, 0.20))
	
	# 3. SPHERICAL PSEUDO-3D RAYTRACED SHADING (Concentric Iso-Luminance Bands)
	# Light vector comes from top-left (-0.45, -0.45)
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
		
		# If lit, top sphere surface reflects warm firelight
		if is_lit and t > 0.2:
			var fire_warmth := sin(time_passed * 16.0) * 0.1 + 0.9
			col = col.lerp(Color(1.0, 0.65, 0.25), 0.32 * fire_warmth * (1.0 - t * 0.5))
		
		draw_circle(center, r, col)
	
	# Specular Hotspot Glint (Shining 3D Specular Highlight)
	var spec_center := light_target
	draw_circle(spec_center, 1.8, Color(1.0, 1.0, 1.0, 0.95))
	
	# Occasional dynamic 4-point star glint twinkle
	var glint_phase := fmod(glint_timer, 3.5)
	if glint_phase < 0.35:
		var glint_size := sin(glint_phase / 0.35 * PI) * 4.5
		draw_line(spec_center - Vector2(glint_size, 0), spec_center + Vector2(glint_size, 0), Color.WHITE, 1.2)
		draw_line(spec_center - Vector2(0, glint_size), spec_center + Vector2(0, glint_size), Color.WHITE, 1.2)
	
	# 4. 3D BRASS COLLAR / NECK
	var collar_y := sphere_center.y - 10.5
	# Dark base shadow
	draw_rect(Rect2(-4.0, collar_y, 8.0, 3.5), Color(0.35, 0.25, 0.05))
	# Brass body with 3D metallic bevel
	draw_rect(Rect2(-3.5, collar_y, 7.0, 3.0), Color(0.75, 0.55, 0.10))
	# Left highlight
	draw_line(Vector2(-2.5, collar_y), Vector2(-2.5, collar_y + 3.0), Color(0.98, 0.85, 0.35), 1.5)
	# Right shadow
	draw_line(Vector2(2.5, collar_y), Vector2(2.5, collar_y + 3.0), Color(0.40, 0.28, 0.05), 1.5)
	# Top rim
	_draw_oval(Vector2(0, collar_y), 3.5, 1.2, Color(0.95, 0.80, 0.30))
	
	# 5. 3D BRAIDED FUSE
	var fuse_start := Vector2(0, collar_y)
	var fuse_mid := Vector2(2.5, collar_y - 4.0)
	var fuse_tip := Vector2(4.5, collar_y - 8.0)
	# Twisted cord segments
	draw_line(fuse_start, fuse_mid, Color(0.75, 0.65, 0.40), 2.4)
	draw_line(fuse_mid, fuse_tip, Color(0.65, 0.55, 0.32), 2.2)
	draw_line(fuse_start + Vector2(0.5, 0), fuse_mid + Vector2(0.5, 0), Color(0.90, 0.82, 0.60), 1.0)
	
	# 6. DYNAMIC 3D LIT SPARK & VOLUMETRIC CORONA
	if is_lit:
		var spark_pulse := 1.0 + sin(time_passed * 24.0) * 0.25
		# Outer fiery halo
		draw_circle(fuse_tip, 8.0 * spark_pulse, Color(1.0, 0.25, 0.0, 0.45))
		# Mid bright orange
		draw_circle(fuse_tip, 5.0 * spark_pulse, Color(1.0, 0.65, 0.05, 0.85))
		# Inner incandescent yellow/white core
		draw_circle(fuse_tip, 2.5 * spark_pulse, Color(1.0, 0.98, 0.65))
		draw_circle(fuse_tip, 1.2, Color.WHITE)
		
		# 4-point rotating spark corona rays
		var angle := time_passed * 14.0
		for k in range(4):
			var a := angle + k * (PI / 2.0)
			var ray_len := 7.0 * spark_pulse
			var ray_dir := Vector2(cos(a), sin(a)) * ray_len
			draw_line(fuse_tip, fuse_tip + ray_dir, Color(1.0, 0.9, 0.4, 0.75), 1.2)
		
		# Render rising floating 3D embers
		for emb in embers:
			var alpha: float = emb["life"] / emb["max_life"]
			var col := Color(1.0, 0.75 * alpha, 0.1, alpha * 0.9)
			draw_circle(emb["pos"], emb["size"] * alpha, col)

func _draw_oval(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	var num_pts := 20
	for i in range(num_pts):
		var phi := float(i) / float(num_pts) * TAU
		pts.append(center + Vector2(cos(phi) * rx, sin(phi) * ry))
	draw_colored_polygon(pts, color)
