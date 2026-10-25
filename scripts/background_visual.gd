extends Node2D

class_name BackgroundVisual

@export var current_level: int = 1:
	set(val):
		current_level = val
		queue_redraw()

var time_passed: float = 0.0

func _process(delta: float) -> void:
	time_passed += delta
	queue_redraw()

func _draw() -> void:
	var stage := ((current_level - 1) % 20) + 1
	match stage:
		1: _draw_zaporizhia_sich()
		2: _draw_chumak_stars_and_khutir()
		3: _draw_kamianets_fortress()
		4: _draw_baturyn_hetmanate()
		5: _draw_perekop_bakhchysarai()
		6: _draw_bakhchysarai_palace()
		7: _draw_konotop_crossing()
		8: _draw_polotsk_castle()
		9: _draw_chornohora_dovbush()
		10: _draw_kyiv_golden_gate()
		11: _draw_lutsk_lubart_castle()
		12: _draw_khotyn_fortress()
		13: _draw_ostroh_academy()
		14: _draw_bilovezha_pushcha()
		15: _draw_zadunayska_sich()
		16: _draw_danube_estuary()
		17: _draw_kalinowski_pushcha()
		18: _draw_verkhovyna_pysanyi_kamin()
		19: _draw_kezlev_khan_jami()
		20: _draw_kaniv_taras_hill()
		_: _draw_zaporizhia_sich()

# -------------------------------------------------------------------------
# ДОПОМІЖНІ ХУДОЖНІ ФУНКЦІЇ СТИЛЮ «КИЇВНАУКФІЛЬМ» (Кирич / Дахно)
# -------------------------------------------------------------------------

# Плавна акварельно-гуашева розтяжка неба з каліброваною яскравістю (Value Separation)
func _draw_painterly_sky(top_c: Color, mid_c: Color, bot_c: Color, h: float = 340.0) -> void:
	draw_rect(Rect2(0, 0, 960, 540), top_c)
	var steps := int(h / 6.0)
	for i in range(steps):
		var y := float(i) * 6.0
		var t := y / h
		var c := top_c.lerp(mid_c, t * 1.6) if t < 0.6 else mid_c.lerp(bot_c, (t - 0.6) / 0.4)
		draw_rect(Rect2(0, y, 960, 6.0), c)

# М'яке кругле світлове сяйво вікон, каганців чи сигнальних ватр
func _draw_warm_glow(pos: Vector2, r: float, col: Color) -> void:
	draw_circle(pos, r * 1.8, Color(col.r, col.g, col.b, col.a * 0.14))
	draw_circle(pos, r * 1.2, Color(col.r, col.g, col.b, col.a * 0.32))
	draw_circle(pos, r * 0.6, Color(col.r, col.g, col.b, col.a * 0.85))
	draw_circle(pos, r * 0.25, Color.WHITE)

# Силует хвойної смереки або сосни з характерними ярусами
func _draw_pine_silhouette(base_pos: Vector2, h: float, w: float, col: Color) -> void:
	var trunk_w := maxf(2.0, w * 0.18)
	draw_rect(Rect2(base_pos.x - trunk_w * 0.5, base_pos.y - h * 0.25, trunk_w, h * 0.25), Color(col.r * 0.8, col.g * 0.8, col.b * 0.8))
	for tier in 4:
		var ty := base_pos.y - h * (0.2 + float(tier) * 0.22)
		var tw := w * (1.0 - float(tier) * 0.22)
		var th := h * 0.28
		draw_colored_polygon(PackedVector2Array([
			Vector2(base_pos.x - tw * 0.5, ty),
			Vector2(base_pos.x + tw * 0.5, ty),
			Vector2(base_pos.x, ty - th)
		]), col)

# Козацький місяць (повний або серпик) із м'яким подвійним ореолом
func _draw_cossack_moon(pos: Vector2, r: float = 22.0, crescent: bool = false) -> void:
	draw_circle(pos, r * 1.8, Color(0.98, 0.94, 0.72, 0.12))
	draw_circle(pos, r * 1.3, Color(0.98, 0.94, 0.72, 0.22))
	draw_circle(pos, r, Color(0.98, 0.96, 0.84, 0.95))
	if crescent:
		draw_circle(pos + Vector2(r * 0.45, -r * 0.15), r * 0.82, Color(0.04, 0.07, 0.16)) # Тінь серпика
	else:
		draw_circle(pos + Vector2(-r * 0.25, -r * 0.15), r * 0.22, Color(0.88, 0.85, 0.70, 0.35))
		draw_circle(pos + Vector2(r * 0.30, r * 0.25), r * 0.18, Color(0.88, 0.85, 0.70, 0.35))

# Допоміжна функція для малювання еліпсів/овалів
func _draw_oval(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(20):
		var a := float(i) / 20.0 * TAU
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)

# Допоміжна функція для малювання козацького барокового купола (грушоподібної бані) з хрестом
func _draw_cossack_dome(cx: float, base_y: float, drum_w: float, drum_h: float, dome_col: Color, wall_col: Color) -> void:
	# Підбанник (барабан з вузькими вікнами)
	draw_rect(Rect2(cx - drum_w * 0.5, base_y - drum_h, drum_w, drum_h), wall_col)
	draw_line(Vector2(cx - drum_w * 0.54, base_y - drum_h), Vector2(cx + drum_w * 0.54, base_y - drum_h), Color(0.88, 0.78, 0.55), 2.0)
	var win_count := 3
	for w_i in range(win_count):
		var wx := cx + (float(w_i) - 1.0) * (drum_w * 0.28)
		draw_rect(Rect2(wx - 2.0, base_y - drum_h * 0.75, 4.0, drum_h * 0.50), Color(1.0, 0.85, 0.32, 0.75))
	
	# Грушоподібна барокова баня
	var top_y := base_y - drum_h
	var dome_pts := PackedVector2Array([
		Vector2(cx - drum_w * 0.52, top_y),
		Vector2(cx - drum_w * 0.62, top_y - drum_h * 0.35),
		Vector2(cx - drum_w * 0.28, top_y - drum_h * 0.78),
		Vector2(cx, top_y - drum_h * 1.10),
		Vector2(cx + drum_w * 0.28, top_y - drum_h * 0.78),
		Vector2(cx + drum_w * 0.62, top_y - drum_h * 0.35),
		Vector2(cx + drum_w * 0.52, top_y)
	])
	draw_colored_polygon(dome_pts, dome_col)
	# Світловий блік на бані
	draw_line(Vector2(cx - drum_w * 0.22, top_y - drum_h * 0.15), Vector2(cx - drum_w * 0.08, top_y - drum_h * 0.82), Color(1.0, 0.96, 0.68, 0.45), 2.5)
	
	# Маківка та кований козацький хрест із півмісяцем у підніжжі
	var spire_top := top_y - drum_h * 1.10
	draw_circle(Vector2(cx, spire_top), 3.2, Color(1.0, 0.88, 0.22))
	draw_line(Vector2(cx, spire_top), Vector2(cx, spire_top - 15.0), Color(1.0, 0.90, 0.28), 2.0)
	draw_line(Vector2(cx - 5.5, spire_top - 9.5), Vector2(cx + 5.5, spire_top - 9.5), Color(1.0, 0.90, 0.28), 1.8)
	draw_line(Vector2(cx - 3.5, spire_top - 12.5), Vector2(cx + 3.5, spire_top - 12.5), Color(1.0, 0.90, 0.28), 1.4)
	draw_arc(Vector2(cx, spire_top - 4.0), 4.0, 0.15, PI - 0.15, 8, Color(1.0, 0.90, 0.28), 1.6)

# -------------------------------------------------------------------------
# РІВЕНЬ 1 (XVII ст.): ЗАПОРОЗЬКА СІЧ НА ОСТРОВІ ХОРТИЦЯ (960x540 2K 16:9)
# Історична панорама: Січова Покровська церква, зрубні вежі з «Фігурами»,
# курені, гармати на лафетах, тулумбаси, пороги Дніпра та флотилія чайок
# -------------------------------------------------------------------------
func _draw_zaporizhia_sich() -> void:
	# 1. Глибоке нічне небо над Великим Лугом і Дніпром
	draw_rect(Rect2(0, 0, 960, 540), Color(0.03, 0.05, 0.13))
	for y in range(0, 340, 4):
		var t := float(y) / 340.0
		var c := Color(0.03, 0.05, 0.13).lerp(Color(0.09, 0.16, 0.30), t)
		draw_line(Vector2(0, y), Vector2(960, y), c, 4.0)
	
	# Сузір'я та мерехтливі степові зорі
	var star_seed := 10101
	for i in range(85):
		star_seed = (star_seed * 1103515245 + 12345) & 0x7FFFFFFF
		var sx := (star_seed % 940) + 10
		star_seed = (star_seed * 1103515245 + 12345) & 0x7FFFFFFF
		var sy := (star_seed % 230) + 8
		var twinkle := 0.45 + sin(time_passed * 2.8 + float(i)) * 0.35
		draw_circle(Vector2(sx, sy), 1.2 + float(i % 2) * 0.5, Color(0.95, 0.96, 1.0, twinkle))
	
	# Козацький Місяць уповні з м'яким ореолом над Хортицею
	var moon_pos := Vector2(845, 68)
	draw_circle(moon_pos, 38.0, Color(0.95, 0.90, 0.65, 0.10))
	draw_circle(moon_pos, 26.0, Color(0.98, 0.94, 0.72, 0.22))
	draw_circle(moon_pos, 19.0, Color(0.98, 0.96, 0.82, 0.95))
	draw_circle(moon_pos + Vector2(-5, -3), 4.0, Color(0.88, 0.84, 0.68, 0.45))
	draw_circle(moon_pos + Vector2(6, 5), 3.2, Color(0.88, 0.84, 0.68, 0.45))
	
	# 2. Далекі гранітні кручі острова Хортиця та ліси Великого Лугу
	var far_hills := PackedVector2Array([
		Vector2(0, 310), Vector2(110, 275), Vector2(240, 290), Vector2(390, 268),
		Vector2(540, 285), Vector2(700, 265), Vector2(850, 282), Vector2(960, 270),
		Vector2(960, 380), Vector2(0, 380)
	])
	draw_colored_polygon(far_hills, Color(0.06, 0.10, 0.18))
	
	# 3. Дерев'яна Січова Церква Покрови Пресвятої Богородиці в центрі Січі!
	var ch_x := 480.0
	var ch_base := 320.0
	# Зрубні стіни церкви з мореного дуба
	draw_rect(Rect2(ch_x - 62, ch_base - 52, 124, 52), Color(0.24, 0.15, 0.09))
	draw_rect(Rect2(ch_x - 36, ch_base - 76, 72, 26), Color(0.28, 0.18, 0.10))
	# Горизонтальні колоди зрубу
	for ly in range(int(ch_base - 50), int(ch_base), 6):
		draw_line(Vector2(ch_x - 62, ly), Vector2(ch_x + 62, ly), Color(0.18, 0.11, 0.06), 1.0)
	# Три дерев'яні козацькі бані з золотими верхами та хрестами
	_draw_cossack_dome(ch_x - 42, ch_base - 52, 22.0, 20.0, Color(0.72, 0.54, 0.16), Color(0.30, 0.19, 0.11))
	_draw_cossack_dome(ch_x + 42, ch_base - 52, 22.0, 20.0, Color(0.72, 0.54, 0.16), Color(0.30, 0.19, 0.11))
	_draw_cossack_dome(ch_x, ch_base - 76, 28.0, 26.0, Color(0.85, 0.66, 0.18), Color(0.32, 0.20, 0.12))
	# Аркові двері та свічкові вікна Покровської церкви
	draw_rect(Rect2(ch_x - 8, ch_base - 24, 16, 24), Color(0.14, 0.08, 0.04))
	draw_circle(Vector2(ch_x, ch_base - 24), 8.0, Color(0.14, 0.08, 0.04))
	draw_circle(Vector2(ch_x - 38, ch_base - 30), 4.5, Color(1.0, 0.82, 0.25, 0.85))
	draw_circle(Vector2(ch_x + 38, ch_base - 30), 4.5, Color(1.0, 0.82, 0.25, 0.85))
	
	# 4. Січові курені під очеретяними стріхами та димарі
	for kx in [145.0, 310.0, 650.0]:
		draw_rect(Rect2(kx - 42, 292, 84, 30), Color(0.22, 0.15, 0.09))
		draw_colored_polygon(PackedVector2Array([
			Vector2(kx - 48, 292), Vector2(kx + 48, 292),
			Vector2(kx + 32, 264), Vector2(kx - 32, 264)
		]), Color(0.42, 0.32, 0.16))
		draw_rect(Rect2(kx - 6, 298, 12, 10), Color(1.0, 0.80, 0.22, 0.80))
	
	# 5. Дубовий частокіл Запорозької Січі, земляний вал та зрубні башти з сигнальними вогнями («Фігурами»)
	for px in range(12, 952, 12):
		var h_var := float((px * 7) % 5)
		draw_line(Vector2(px, 332), Vector2(px, 294 + h_var), Color(0.19, 0.13, 0.08), 4.5)
		draw_colored_polygon(PackedVector2Array([
			Vector2(px - 2.5, 294 + h_var), Vector2(px + 2.5, 294 + h_var), Vector2(px, 286 + h_var)
		]), Color(0.24, 0.16, 0.10))
	# Поперечні балки частоколу
	draw_line(Vector2(10, 306), Vector2(950, 306), Color(0.14, 0.09, 0.05), 2.5)
	draw_line(Vector2(10, 322), Vector2(950, 322), Color(0.14, 0.09, 0.05), 2.5)
	
	# Дві сторожові вежі-башти (ліворуч і праворуч) із бійницями та вогняними «Фігурами»
	for tx in [72.0, 815.0]:
		draw_rect(Rect2(tx - 20, 195, 40, 130), Color(0.22, 0.14, 0.08))
		for t_log in range(200, 325, 8):
			draw_line(Vector2(tx - 20, t_log), Vector2(tx + 20, t_log), Color(0.15, 0.09, 0.05), 1.2)
		# Широкий верхній ярус-галерея (обланки)
		draw_rect(Rect2(tx - 25, 182, 50, 16), Color(0.26, 0.17, 0.10))
		# Шатровий ґонтовий дах вежі
		draw_colored_polygon(PackedVector2Array([
			Vector2(tx - 28, 182), Vector2(tx + 28, 182), Vector2(tx, 144)
		]), Color(0.32, 0.21, 0.12))
		# Бійниці
		draw_rect(Rect2(tx - 3, 215, 6, 14), Color(0.06, 0.04, 0.02))
		draw_rect(Rect2(tx - 12, 245, 5, 12), Color(0.06, 0.04, 0.02))
		draw_rect(Rect2(tx + 7, 245, 5, 12), Color(0.06, 0.04, 0.02))
		# Сигнальна смоляна бочка «Фігура» з полум'ям на вершині
		var flame_pulse := 1.0 + sin(time_passed * 14.0 + tx) * 0.22
		draw_circle(Vector2(tx, 138), 11.0 * flame_pulse, Color(1.0, 0.42, 0.05, 0.42))
		draw_circle(Vector2(tx, 138), 6.0 * flame_pulse, Color(1.0, 0.82, 0.15, 0.85))
		draw_circle(Vector2(tx, 138), 2.5, Color.WHITE)
	
	# Малинова козацька корогва з хрестом біля церкви та січові литаври (тулумбаси)
	var ban_x := 562.0
	var ban_wave := sin(time_passed * 4.5) * 3.5
	draw_line(Vector2(ban_x, 325), Vector2(ban_x, 238), Color(0.45, 0.30, 0.16), 2.5)
	draw_colored_polygon(PackedVector2Array([
		Vector2(ban_x, 242), Vector2(ban_x + 36, 244 + ban_wave * 0.5),
		Vector2(ban_x + 28, 255 + ban_wave * 0.7), Vector2(ban_x + 36, 266 + ban_wave),
		Vector2(ban_x, 266)
	]), Color(0.78, 0.12, 0.22)) # Малиновий стяг
	draw_line(Vector2(ban_x + 12, 248 + ban_wave * 0.3), Vector2(ban_x + 12, 260 + ban_wave * 0.3), Color(1.0, 0.90, 0.25), 2.0)
	draw_line(Vector2(ban_x + 6, 254 + ban_wave * 0.3), Vector2(ban_x + 18, 254 + ban_wave * 0.3), Color(1.0, 0.90, 0.25), 2.0)
	
	# Січові литаври (тулумбаси) на тринозі та козацька гармата на лафеті
	_draw_oval(Vector2(405, 318), 9.0, 6.5, Color(0.68, 0.42, 0.16)) # Мідний казан литаври
	_draw_oval(Vector2(405, 314), 9.0, 3.0, Color(0.92, 0.88, 0.76)) # Шкіряна мембрана
	# Гармата праворуч
	draw_line(Vector2(695, 316), Vector2(722, 308), Color(0.22, 0.25, 0.30), 5.5)
	draw_circle(Vector2(704, 322), 7.5, Color(0.36, 0.22, 0.12))
	draw_circle(Vector2(704, 322), 2.5, Color(0.20, 0.22, 0.25))
	
	# 6. Гранітні скелі Хортиці, ревучі пороги Дніпра та козацькі Чайки
	var rock_pts := PackedVector2Array([
		Vector2(0, 332), Vector2(140, 326), Vector2(310, 336), Vector2(480, 324),
		Vector2(660, 335), Vector2(830, 325), Vector2(960, 334), Vector2(960, 372), Vector2(0, 372)
	])
	draw_colored_polygon(rock_pts, Color(0.12, 0.14, 0.20))
	
	# Широке плесо Дніпра з місячною доріжкою
	draw_rect(Rect2(0, 365, 960, 175), Color(0.04, 0.11, 0.22))
	for m_i in range(8):
		var my := 374.0 + float(m_i) * 16.0
		var mw := 18.0 + float(m_i) * 4.5 + sin(time_passed * 3.0 + float(m_i)) * 6.0
		draw_line(Vector2(845 - mw, my), Vector2(845 + mw, my), Color(0.98, 0.92, 0.62, 0.22), 2.2)
	
	# Хвилі та гранітні валуни Дніпрових порогів із білою піною
	for w in range(7):
		var wy := 378.0 + float(w) * 20.0
		var w_off := sin(time_passed * 2.0 + float(w)) * 18.0
		draw_line(Vector2(40 + w_off, wy), Vector2(290 + w_off, wy), Color(0.20, 0.42, 0.65, 0.35), 2.0)
		draw_line(Vector2(480 - w_off, wy + 6), Vector2(790 - w_off, wy + 6), Color(0.20, 0.42, 0.65, 0.35), 2.0)
	
	# Два бойові човни — Козацькі Чайки з вітрилами, веслами та очеретяними в'язанками (кошницями)
	var chaikas := [
		{"x": 270.0, "y": 412.0, "scale": 1.0, "phase": 0.0},
		{"x": 640.0, "y": 438.0, "scale": 0.85, "phase": 2.1}
	]
	for ch in chaikas:
		var sc: float = ch["scale"]
		var cx: float = ch["x"] + sin(time_passed * 1.4 + float(ch["phase"])) * 10.0
		var cy: float = ch["y"] + cos(time_passed * 1.9 + float(ch["phase"])) * 3.0
		# Корпус чайки з високо задертими носом і кормою
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 46 * sc, cy - 6 * sc),
			Vector2(cx - 34 * sc, cy + 2 * sc),
			Vector2(cx + 34 * sc, cy + 2 * sc),
			Vector2(cx + 46 * sc, cy - 6 * sc),
			Vector2(cx + 30 * sc, cy + 14 * sc),
			Vector2(cx - 30 * sc, cy + 14 * sc)
		]), Color(0.26, 0.16, 0.09))
		# Очеретяні в'язанки-кошниці вздовж борту (історична деталь козацької чайки!)
		draw_line(Vector2(cx - 32 * sc, cy + 3 * sc), Vector2(cx + 32 * sc, cy + 3 * sc), Color(0.68, 0.56, 0.25), 3.0 * sc)
		# Щогла та напнуте пряме вітрило з малиновою смугою
		draw_line(Vector2(cx, cy + 2 * sc), Vector2(cx, cy - 42 * sc), Color(0.38, 0.25, 0.14), 2.4 * sc)
		var sail_pts := PackedVector2Array([
			Vector2(cx - 18 * sc, cy - 36 * sc),
			Vector2(cx + 18 * sc, cy - 36 * sc),
			Vector2(cx + 22 * sc, cy - 10 * sc),
			Vector2(cx - 14 * sc, cy - 10 * sc)
		])
		draw_colored_polygon(sail_pts, Color(0.92, 0.90, 0.84, 0.88))
		draw_line(Vector2(cx - 15 * sc, cy - 23 * sc), Vector2(cx + 19 * sc, cy - 23 * sc), Color(0.78, 0.14, 0.20, 0.85), 3.5 * sc)
		# Весла у воді
		for oar_i in range(-3, 4):
			var ox := cx + float(oar_i) * 8.0 * sc
			var oar_sway := sin(time_passed * 4.0 + float(oar_i)) * 3.0 * sc
			draw_line(Vector2(ox, cy + 5 * sc), Vector2(ox + oar_sway, cy + 17 * sc), Color(0.48, 0.34, 0.18), 1.5 * sc)

# -------------------------------------------------------------------------
# РІВЕНЬ 2 (XVIII-XIX ст.): ЧУМАЦЬКИЙ ШЛЯХ ТА СТЕПОВИЙ ХУТІР (960x540)
# Історична панорама: Мальовнича хата-мазанка з мальвами й соняшниками,
# Кузня Коваля Вакули з іскрами, криниця-журавель, вітряк та Чумацька валка з волами
# -------------------------------------------------------------------------
func _draw_chumak_stars_and_khutir() -> void:
	# 1. Оксамитове українське нічне небо («Ніч перед Різдвом» / Купальська ніч)
	draw_rect(Rect2(0, 0, 960, 540), Color(0.02, 0.04, 0.11))
	for y in range(0, 360, 4):
		var t := float(y) / 360.0
		var c := Color(0.02, 0.04, 0.11).lerp(Color(0.06, 0.13, 0.26), t)
		draw_line(Vector2(0, y), Vector2(960, y), c, 4.0)
	
	# Сяюча зоряна ріка Чумацького Шляху через усе склепіння неба
	for i in range(220):
		var px := float(i) / 220.0 * 960.0
		var py := 38.0 + sin(px * 0.0036) * 76.0 + float(i % 7) * 4.2
		var c_alpha := 0.16 + sin(time_passed * 2.0 + float(i) * 0.2) * 0.07
		draw_circle(Vector2(px, py), 15.0, Color(0.68, 0.82, 1.0, c_alpha * 0.34))
		draw_circle(Vector2(px + float(i % 5) * 3.0, py + float(i % 3) * 2.0), 1.3, Color(1.0, 0.98, 0.90, 0.80))
	
	# Срібний місяць-молодик над хутором
	draw_circle(Vector2(115, 62), 20.0, Color(0.98, 0.96, 0.82, 0.94))
	draw_circle(Vector2(107, 58), 16.5, Color(0.03, 0.05, 0.13))
	
	# 2. Далекий степовий курган-могила та Чумацька валка круторогих волів із мажами!
	var far_ridge := PackedVector2Array([
		Vector2(0, 338), Vector2(180, 315), Vector2(360, 302), Vector2(540, 294),
		Vector2(720, 312), Vector2(960, 305), Vector2(960, 385), Vector2(0, 385)
	])
	draw_colored_polygon(far_ridge, Color(0.05, 0.09, 0.15))
	
	# Силует чумацької валки (круторогі воли та вози-мажі з кримською сіллю на гребені пагорба)
	for w_idx in range(2):
		var wx := 430.0 + float(w_idx) * 105.0 + fmod(time_passed * 4.0, 40.0)
		var wy := 296.0 + float(w_idx) * 4.0
		# Віз-мажа з мішками солі
		draw_colored_polygon(PackedVector2Array([
			Vector2(wx - 16, wy - 4), Vector2(wx + 16, wy - 4),
			Vector2(wx + 20, wy - 15), Vector2(wx - 20, wy - 15)
		]), Color(0.14, 0.10, 0.08))
		draw_circle(Vector2(wx - 11, wy - 3), 5.0, Color(0.20, 0.14, 0.10))
		draw_circle(Vector2(wx + 11, wy - 3), 5.0, Color(0.20, 0.14, 0.10))
		# Круторогий віл попереду мажі
		var ox_x := wx + 30.0
		_draw_oval(Vector2(ox_x, wy - 9), 9.0, 5.5, Color(0.16, 0.13, 0.12))
		draw_line(Vector2(ox_x - 6, wy - 4), Vector2(ox_x - 6, wy), Color(0.16, 0.13, 0.12), 2.0)
		draw_line(Vector2(ox_x + 5, wy - 4), Vector2(ox_x + 5, wy), Color(0.16, 0.13, 0.12), 2.0)
		# Круті чумацькі роги вола (півмісяцем вгору)
		draw_arc(Vector2(ox_x + 9, wy - 15), 5.0, 0.2, PI - 0.2, 6, Color(0.85, 0.82, 0.72), 1.5)
	
	# 3. Ближні м'які пагорби Степового Хутора
	var near_hill := PackedVector2Array([
		Vector2(0, 365), Vector2(230, 332), Vector2(540, 355), Vector2(820, 326),
		Vector2(960, 342), Vector2(960, 540), Vector2(0, 540)
	])
	draw_colored_polygon(near_hill, Color(0.06, 0.13, 0.09))
	
	# 4. Мальовнича Українська Біла Хата-Мазанка ліворуч (з призьбою, віконницями, димарем, мальвами й соняшниками!)
	var hut_x := 68.0
	var hut_y := 326.0
	# Руда глиняна призьба знизу
	draw_rect(Rect2(hut_x - 4, hut_y + 38, 122, 10), Color(0.52, 0.28, 0.14))
	# Білені стіни мазанки
	draw_rect(Rect2(hut_x, hut_y, 114, 40), Color(0.92, 0.93, 0.96))
	# Народний квітковий розпис під стріхою
	draw_line(Vector2(hut_x + 4, hut_y + 4), Vector2(hut_x + 110, hut_y + 4), Color(0.82, 0.18, 0.20), 1.6)
	# Висока ступінчаста солом'яна стріха та димар із півником
	draw_rect(Rect2(hut_x + 74, hut_y - 42, 12, 18), Color(0.88, 0.88, 0.92))
	draw_colored_polygon(PackedVector2Array([
		Vector2(hut_x - 14, hut_y + 2), Vector2(hut_x + 128, hut_y + 2),
		Vector2(hut_x + 98, hut_y - 32), Vector2(hut_x + 16, hut_y - 32)
	]), Color(0.58, 0.44, 0.18))
	draw_line(Vector2(hut_x - 12, hut_y), Vector2(hut_x + 126, hut_y), Color(0.42, 0.30, 0.12), 2.5)
	# Дерев'яні двері та два теплі свічкові віконця з блакитними віконницями
	draw_rect(Rect2(hut_x + 14, hut_y + 14, 16, 26), Color(0.42, 0.24, 0.12))
	for win_x in [hut_x + 48.0, hut_x + 82.0]:
		draw_rect(Rect2(win_x - 5, hut_y + 11, 5, 16), Color(0.22, 0.52, 0.82)) # Ліва віконниця
		draw_rect(Rect2(win_x + 16, hut_y + 11, 5, 16), Color(0.22, 0.52, 0.82)) # Права віконниця
		draw_rect(Rect2(win_x, hut_y + 11, 16, 16), Color(1.0, 0.86, 0.26, 0.94))
		draw_line(Vector2(win_x + 8, hut_y + 11), Vector2(win_x + 8, hut_y + 27), Color(0.32, 0.20, 0.10), 1.3)
		draw_line(Vector2(win_x, hut_y + 19), Vector2(win_x + 16, hut_y + 19), Color(0.32, 0.20, 0.10), 1.3)
	
	# Високі квітучі мальви та золоті соняшники біля хати і тину
	for mx_fl in [52.0, 192.0, 206.0]:
		draw_line(Vector2(mx_fl, hut_y + 46), Vector2(mx_fl, hut_y + 14), Color(0.16, 0.48, 0.22), 2.2)
		draw_circle(Vector2(mx_fl, hut_y + 18), 3.6, Color(0.92, 0.22, 0.45))
		draw_circle(Vector2(mx_fl, hut_y + 26), 3.8, Color(0.96, 0.35, 0.55))
		draw_circle(Vector2(mx_fl, hut_y + 34), 4.0, Color(0.85, 0.15, 0.38))
	for sx_fl in [222.0, 238.0]:
		draw_line(Vector2(sx_fl, hut_y + 46), Vector2(sx_fl, hut_y + 20), Color(0.18, 0.52, 0.22), 2.4)
		draw_circle(Vector2(sx_fl, hut_y + 18), 6.2, Color(1.0, 0.84, 0.14))
		draw_circle(Vector2(sx_fl, hut_y + 18), 3.2, Color(0.28, 0.16, 0.08))
	
	# Плетений вербовий тин із глиняними глечиками та Криниця-Журавель
	var fence_y := 368.0
	for fx in range(195, 345, 9):
		draw_line(Vector2(fx, fence_y - 14), Vector2(fx, fence_y + 12), Color(0.36, 0.24, 0.12), 2.0)
	for row_y in [-7.0, 0.0, 7.0]:
		draw_line(Vector2(195, fence_y + row_y), Vector2(345, fence_y + row_y), Color(0.46, 0.32, 0.16), 2.2)
	draw_circle(Vector2(230, fence_y - 16), 4.0, Color(0.74, 0.34, 0.16))
	draw_circle(Vector2(297, fence_y - 16), 4.0, Color(0.68, 0.30, 0.14))
	
	# Криниця-журавель посеред подвір'я
	var well_x := 385.0
	var well_y := 358.0
	draw_rect(Rect2(well_x - 12, well_y, 24, 16), Color(0.38, 0.26, 0.14)) # Цямрина криниці
	draw_line(Vector2(well_x + 28, well_y + 14), Vector2(well_x + 28, well_y - 34), Color(0.32, 0.22, 0.12), 3.2) # Стовп-соха
	draw_line(Vector2(well_x - 8, well_y - 48), Vector2(well_x + 56, well_y - 16), Color(0.42, 0.28, 0.15), 2.8) # Стріла журавля
	draw_line(Vector2(well_x - 8, well_y - 48), Vector2(well_x - 8, well_y - 6), Color(0.65, 0.58, 0.48), 1.4) # Жердина з цебром
	draw_rect(Rect2(well_x - 12, well_y - 6, 8, 9), Color(0.45, 0.30, 0.16))
	
	# 5. Кузня Коваля Вакули з палаючим горном та Вітряк праворуч!
	var forge_x := 640.0
	var forge_y := 334.0
	draw_rect(Rect2(forge_x, forge_y, 76, 36), Color(0.28, 0.22, 0.20)) # Кам'яно-дерев'яна кузня
	draw_colored_polygon(PackedVector2Array([
		Vector2(forge_x - 8, forge_y), Vector2(forge_x + 84, forge_y),
		Vector2(forge_x + 68, forge_y - 24), Vector2(forge_x + 8, forge_y - 24)
	]), Color(0.22, 0.15, 0.10))
	# Відкритий ковальський горн із багряним полум'ям та снопом іскор з димаря!
	var forge_glow := 0.8 + sin(time_passed * 12.0) * 0.2
	draw_circle(Vector2(forge_x + 26, forge_y + 22), 14.0 * forge_glow, Color(1.0, 0.42, 0.08, 0.45))
	draw_circle(Vector2(forge_x + 26, forge_y + 22), 7.5, Color(1.0, 0.78, 0.18, 0.92))
	draw_rect(Rect2(forge_x + 52, forge_y - 38, 12, 16), Color(0.24, 0.18, 0.16))
	for sp_i in range(4):
		var sp_y := fmod(time_passed * 28.0 + float(sp_i) * 9.0, 26.0)
		var sp_x := forge_x + 58.0 + sin(time_passed * 6.0 + float(sp_i)) * 5.0
		draw_circle(Vector2(sp_x, forge_y - 40.0 - sp_y), 1.6, Color(1.0, 0.85, 0.20, 1.0 - sp_y / 26.0))
	
	# Традиційний дерев'яний степовий вітряк з ажурними крилами
	var mill_x := 825.0
	var mill_y := 292.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(mill_x - 20, mill_y + 48), Vector2(mill_x + 20, mill_y + 48),
		Vector2(mill_x + 13, mill_y - 4), Vector2(mill_x - 13, mill_y - 4)
	]), Color(0.32, 0.22, 0.12))
	draw_colored_polygon(PackedVector2Array([
		Vector2(mill_x - 17, mill_y - 4), Vector2(mill_x + 17, mill_y - 4), Vector2(mill_x, mill_y - 22)
	]), Color(0.24, 0.16, 0.09))
	var mill_rot := time_passed * 0.75
	for k in range(4):
		var ang := mill_rot + float(k) * (PI / 2.0)
		var dir := Vector2(cos(ang), sin(ang))
		var perp := Vector2(-dir.y, dir.x)
		var wing_end := Vector2(mill_x, mill_y) + dir * 44.0
		draw_line(Vector2(mill_x, mill_y), wing_end, Color(0.45, 0.32, 0.18), 2.6)
		# Решітка крила вітряка
		var blade_pts := PackedVector2Array([
			Vector2(mill_x, mill_y) + dir * 10.0 + perp * 2.0,
			wing_end + perp * 2.0,
			wing_end + perp * 9.0,
			Vector2(mill_x, mill_y) + dir * 10.0 + perp * 7.0
		])
		draw_colored_polygon(blade_pts, Color(0.78, 0.68, 0.48, 0.55))

# -------------------------------------------------------------------------
# РІВЕНЬ 3 (XVII-XVIII ст.): КАМ'ЯНЕЦЬКА ТВЕРДИНЯ (Старий Замок, 960x540)
# Історична панорама: Папська (Кармелюкова), Тенчинська, Ляська, Денна і Чорна вежі,
# Замковий арковий міст над Смотрицьким каньйоном, водоспад та смолоскипи
# -------------------------------------------------------------------------
func _draw_kamianets_fortress() -> void:
	# 1. Драматичне вечірнє небо Поділля
	draw_rect(Rect2(0, 0, 960, 540), Color(0.05, 0.04, 0.12))
	for y in range(0, 340, 4):
		var t := float(y) / 340.0
		var c := Color(0.05, 0.04, 0.12).lerp(Color(0.22, 0.11, 0.24), t)
		draw_line(Vector2(0, y), Vector2(960, y), c, 4.0)
	
	# Багряно-золотий місяць над вежами Кам'янця
	draw_circle(Vector2(640, 66), 34.0, Color(1.0, 0.65, 0.30, 0.14))
	draw_circle(Vector2(640, 66), 21.0, Color(1.0, 0.86, 0.55, 0.90))
	
	# 2. Замковий арковий міст у глибині та водоспад річки Смотрич у каньйоні
	draw_rect(Rect2(0, 415, 960, 125), Color(0.04, 0.08, 0.16))
	# Арковий Замковий міст через каньйон
	draw_rect(Rect2(240, 342, 480, 68), Color(0.22, 0.20, 0.25))
	for arch_x in range(275, 700, 64):
		draw_rect(Rect2(arch_x - 18, 362, 36, 50), Color(0.06, 0.05, 0.12))
		draw_circle(Vector2(arch_x, 362), 18.0, Color(0.06, 0.05, 0.12))
	
	# 3. Головний ансамбль Старого Замку Кам'янця-Подільського (5 історичних веж та мури з машикулями!)
	# Кам'яний фортечний мур із бійницями та зубцями-мерлонами
	draw_rect(Rect2(110, 238, 740, 112), Color(0.28, 0.26, 0.31))
	for row_st in range(248, 345, 14):
		draw_line(Vector2(110, row_st), Vector2(850, row_st), Color(0.20, 0.18, 0.23), 1.2)
	for mx in range(125, 835, 28):
		draw_rect(Rect2(mx, 224, 16, 14), Color(0.32, 0.30, 0.35))
		draw_rect(Rect2(mx + 5, 255, 5, 14), Color(0.09, 0.07, 0.11)) # Бійниця муру
	
	# 5 знаменитих веж Кам'янецької фортеці (Папська, Ковпак, Тенчинська, Ляська, Нова Західна)
	var towers := [
		{"x": 125.0, "w": 56.0, "top": 158.0, "roof_h": 54.0, "col": Color(0.32, 0.30, 0.35)}, # Папська (Кармелюкова)
		{"x": 285.0, "w": 48.0, "top": 172.0, "roof_h": 48.0, "col": Color(0.30, 0.28, 0.33)}, # Вежа Ковпак
		{"x": 480.0, "w": 66.0, "top": 145.0, "roof_h": 58.0, "col": Color(0.35, 0.32, 0.38)}, # Головна Тенчинська / Рожанка
		{"x": 675.0, "w": 48.0, "top": 172.0, "roof_h": 48.0, "col": Color(0.30, 0.28, 0.33)}, # Ляська вежа
		{"x": 835.0, "w": 56.0, "top": 158.0, "roof_h": 54.0, "col": Color(0.32, 0.30, 0.35)}  # Чорна / Західна вежа
	]
	for tw in towers:
		var tx: float = tw["x"]
		var tw_w: float = tw["w"]
		var t_top: float = tw["top"]
		var r_h: float = tw["roof_h"]
		var t_col: Color = tw["col"]
		
		# Корпус вежі
		draw_rect(Rect2(tx - tw_w * 0.5, t_top, tw_w, 350.0 - t_top), t_col)
		# Світла грань вежі
		draw_rect(Rect2(tx - tw_w * 0.5, t_top, tw_w * 0.28, 350.0 - t_top), t_col.lightened(0.10))
		# Аркатурний пояс (машикулі) під дахом вежі
		draw_rect(Rect2(tx - tw_w * 0.56, t_top - 8.0, tw_w * 1.12, 10.0), t_col.lightened(0.08))
		for m_i in range(-2, 3):
			draw_rect(Rect2(tx + float(m_i) * (tw_w * 0.20) - 2.0, t_top + 2.0, 4.0, 6.0), Color(0.16, 0.14, 0.18))
		# Гостроверхий черепичний дах вежі (червона подільська черепиця)
		draw_colored_polygon(PackedVector2Array([
			Vector2(tx - tw_w * 0.62, t_top - 8.0),
			Vector2(tx + tw_w * 0.62, t_top - 8.0),
			Vector2(tx, t_top - 8.0 - r_h)
		]), Color(0.68, 0.22, 0.16))
		draw_colored_polygon(PackedVector2Array([
			Vector2(tx - tw_w * 0.62, t_top - 8.0),
			Vector2(tx, t_top - 8.0),
			Vector2(tx, t_top - 8.0 - r_h)
		]), Color(0.78, 0.28, 0.20))
		# Золотий флюгер на шпилі
		var spire_y := t_top - 8.0 - r_h
		draw_line(Vector2(tx, spire_y), Vector2(tx, spire_y - 14.0), Color(1.0, 0.88, 0.25), 2.0)
		draw_circle(Vector2(tx, spire_y - 4.0), 2.4, Color(1.0, 0.88, 0.25))
		# Бійниці та освітлені вартові вікна вежі
		draw_rect(Rect2(tx - 3.5, t_top + 22.0, 7.0, 16.0), Color(1.0, 0.80, 0.22, 0.85))
		draw_rect(Rect2(tx - tw_w * 0.25, t_top + 52.0, 5.0, 14.0), Color(0.10, 0.08, 0.12))
		draw_rect(Rect2(tx + tw_w * 0.25 - 5.0, t_top + 52.0, 5.0, 14.0), Color(0.10, 0.08, 0.12))
	
	# Палаючі смолоскипи вздовж бастіонів
	for torch_x in [205.0, 385.0, 575.0, 755.0]:
		var fl := 1.0 + sin(time_passed * 13.0 + torch_x) * 0.20
		draw_line(Vector2(torch_x, 278), Vector2(torch_x, 264), Color(0.35, 0.22, 0.12), 2.5)
		draw_circle(Vector2(torch_x, 261), 7.5 * fl, Color(1.0, 0.45, 0.08, 0.45))
		draw_circle(Vector2(torch_x, 261), 3.8 * fl, Color(1.0, 0.86, 0.20, 0.90))
	
	# 4. Прямовисні вапнякові скелі Смотрицького каньйону на передньому плані
	var canyon_l := PackedVector2Array([
		Vector2(0, 342), Vector2(235, 350), Vector2(315, 420), Vector2(265, 540), Vector2(0, 540)
	])
	draw_colored_polygon(canyon_l, Color(0.13, 0.11, 0.17))
	var canyon_r := PackedVector2Array([
		Vector2(960, 342), Vector2(725, 350), Vector2(645, 420), Vector2(695, 540), Vector2(960, 540)
	])
	draw_colored_polygon(canyon_r, Color(0.13, 0.11, 0.17))

# -------------------------------------------------------------------------
# РІВЕНЬ 4 (XVIII ст.): ГЕТЬМАНСЬКИЙ БАТУРИН (Козацьке Бароко, 960x540)
# Історична панорама: Палац Гетьмана Івана Мазепи на Гончарівці з бароковими
# фронтонами й пілястрами, п'ятибанний собор Мазепинського бароко, Сейм і балюстрада
# -------------------------------------------------------------------------
func _draw_baturyn_hetmanate() -> void:
	# 1. Королівське темно-синє небо над Гетьманською столицею
	draw_rect(Rect2(0, 0, 960, 540), Color(0.03, 0.05, 0.14))
	for y in range(0, 340, 4):
		var t := float(y) / 340.0
		var c := Color(0.03, 0.05, 0.14).lerp(Color(0.11, 0.16, 0.34), t)
		draw_line(Vector2(0, y), Vector2(960, y), c, 4.0)
	
	# Золотий місяць над Батурином
	draw_circle(Vector2(150, 64), 32.0, Color(1.0, 0.90, 0.50, 0.16))
	draw_circle(Vector2(150, 64), 20.0, Color(1.0, 0.94, 0.65, 0.92))
	
	# 2. Величний п'ятибанний Собор Українського (Мазепинського) Бароко в центрі!
	var cath_x := 480.0
	var cath_base := 268.0
	draw_rect(Rect2(cath_x - 105, cath_base - 56, 210, 56), Color(0.86, 0.84, 0.80))
	# Бароковий хвилястий фронтон із золотою ліпниною
	draw_colored_polygon(PackedVector2Array([
		Vector2(cath_x - 65, cath_base - 56),
		Vector2(cath_x - 35, cath_base - 82),
		Vector2(cath_x, cath_base - 96),
		Vector2(cath_x + 35, cath_base - 82),
		Vector2(cath_x + 65, cath_base - 56)
	]), Color(0.90, 0.88, 0.84))
	draw_line(Vector2(cath_x - 65, cath_base - 56), Vector2(cath_x, cath_base - 96), Color(0.96, 0.80, 0.22), 2.2)
	draw_line(Vector2(cath_x + 65, cath_base - 56), Vector2(cath_x, cath_base - 96), Color(0.96, 0.80, 0.22), 2.2)
	
	# 5 грушоподібних золотих бань Мазепинського бароко
	_draw_cossack_dome(cath_x - 82, cath_base - 56, 22.0, 22.0, Color(0.82, 0.64, 0.14), Color(0.84, 0.82, 0.78))
	_draw_cossack_dome(cath_x + 82, cath_base - 56, 22.0, 22.0, Color(0.82, 0.64, 0.14), Color(0.84, 0.82, 0.78))
	_draw_cossack_dome(cath_x - 42, cath_base - 72, 26.0, 26.0, Color(0.88, 0.70, 0.16), Color(0.88, 0.86, 0.82))
	_draw_cossack_dome(cath_x + 42, cath_base - 72, 26.0, 26.0, Color(0.88, 0.70, 0.16), Color(0.88, 0.86, 0.82))
	_draw_cossack_dome(cath_x, cath_base - 90, 32.0, 32.0, Color(0.96, 0.78, 0.20), Color(0.92, 0.90, 0.86))
	
	# 3. Палац Гетьмана Івана Мазепи (білокам'яні пілястри, червоно-теракотові стіни, аркові вікна та герб!)
	var pal_top := 258.0
	var pal_h := 108.0
	draw_rect(Rect2(60, pal_top, 840, pal_h), Color(0.54, 0.20, 0.18)) # Благородна барокова теракота
	# Верхній та міжповерховий білокам'яний карниз із золотим фризом
	draw_rect(Rect2(54, pal_top - 6, 852, 8), Color(0.92, 0.90, 0.85))
	draw_line(Vector2(54, pal_top + 2), Vector2(906, pal_top + 2), Color(0.96, 0.80, 0.22), 2.0)
	draw_line(Vector2(60, pal_top + 52), Vector2(900, pal_top + 52), Color(0.88, 0.86, 0.80), 2.5)
	
	# Білокам'яні колони-пілястри та осяяні свічками аркові вікна палацу
	for col_i in range(13):
		var col_x := 80.0 + float(col_i) * 66.0
		# Колона-пілястра з золотою капітеллю
		draw_rect(Rect2(col_x - 4, pal_top + 2, 8, pal_h - 2), Color(0.90, 0.88, 0.84))
		draw_rect(Rect2(col_x - 6, pal_top + 2, 12, 5), Color(0.96, 0.80, 0.22))
		if col_i < 12:
			var win_cx := col_x + 33.0
			# Верхнє барокове вікно з трикутною чи лучковою сандрикою
			draw_rect(Rect2(win_cx - 10, pal_top + 16, 20, 28), Color(1.0, 0.86, 0.28, 0.88))
			draw_circle(Vector2(win_cx, pal_top + 16), 10.0, Color(1.0, 0.86, 0.28, 0.88))
			draw_line(Vector2(win_cx, pal_top + 6), Vector2(win_cx, pal_top + 44), Color(0.35, 0.20, 0.12), 1.4)
			draw_line(Vector2(win_cx - 10, pal_top + 26), Vector2(win_cx + 10, pal_top + 26), Color(0.35, 0.20, 0.12), 1.4)
			# Нижня аркова галерея
			draw_rect(Rect2(win_cx - 13, pal_top + 68, 26, 38), Color(0.14, 0.10, 0.16))
			draw_circle(Vector2(win_cx, pal_top + 68), 13.0, Color(0.14, 0.10, 0.16))
	
	# Парадний центральний портал із Гетьманським Гербом
	draw_colored_polygon(PackedVector2Array([
		Vector2(cath_x - 52, pal_top - 6),
		Vector2(cath_x + 52, pal_top - 6),
		Vector2(cath_x, pal_top - 34)
	]), Color(0.92, 0.90, 0.85))
	draw_circle(Vector2(cath_x, pal_top - 18), 8.5, Color(0.85, 0.16, 0.20))
	draw_line(Vector2(cath_x, pal_top - 24), Vector2(cath_x, pal_top - 12), Color(1.0, 0.88, 0.22), 2.0)
	draw_line(Vector2(cath_x - 5, pal_top - 18), Vector2(cath_x + 5, pal_top - 18), Color(1.0, 0.88, 0.22), 2.0)
	
	# 4. Набережна річки Сейм з білокам'яною балюстрадою та кованими ліхтарями
	draw_rect(Rect2(0, 366, 960, 174), Color(0.05, 0.10, 0.22))
	draw_rect(Rect2(0, 358, 960, 10), Color(0.78, 0.76, 0.72))
	for l_x in range(90, 910, 160):
		draw_line(Vector2(l_x, 358), Vector2(l_x, 336), Color(0.18, 0.18, 0.22), 2.5)
		draw_circle(Vector2(l_x, 334), 8.0, Color(1.0, 0.85, 0.28, 0.38))
		draw_circle(Vector2(l_x, 334), 4.0, Color(1.0, 0.94, 0.55, 0.95))
	# Золоті відблиски палацу у воді Сейму
	for r_i in range(6):
		var ry := 382.0 + float(r_i) * 18.0
		var r_off := sin(time_passed * 2.4 + float(r_i)) * 12.0
		draw_line(Vector2(220 + r_off, ry), Vector2(740 + r_off, ry), Color(0.96, 0.78, 0.22, 0.18), 2.2)

# -------------------------------------------------------------------------
# РІВЕНЬ 5 (XVII-XVIII ст.): ПЕРЕКОПСЬКИЙ ВАЛ ОР-КАПУ ТА ХАНСАРАЙ (960x540)
# Історична панорама: Ханський палац у Бахчисараї (Велика Ханська мечеть із 2 мінаретами,
# Соколина вежа з вітражами-шебеке), фортеця Ор-Капу, кипариси, Чатир-Даг та прапори Тарак-Тамги
# -------------------------------------------------------------------------
func _draw_perekop_bakhchysarai() -> void:
	# 1. Золото-багряне кримське небо заходу сонця над горами та степом
	draw_rect(Rect2(0, 0, 960, 540), Color(0.11, 0.06, 0.20))
	for y in range(0, 330, 4):
		var t := float(y) / 330.0
		var c := Color(0.12, 0.07, 0.24).lerp(Color(0.92, 0.46, 0.18), t * t)
		draw_line(Vector2(0, y), Vector2(960, y), c, 4.0)
	
	# Велике південне сонце над плато Чатир-Даг
	draw_circle(Vector2(480, 155), 52.0, Color(1.0, 0.78, 0.24, 0.32))
	draw_circle(Vector2(480, 155), 35.0, Color(1.0, 0.90, 0.42, 0.82))
	draw_circle(Vector2(480, 155), 22.0, Color(1.0, 0.98, 0.78))
	
	# 2. Величне столове плато Чатир-Даг та білі вапнякові скелі Ак-Кая і Чуфут-Кале
	var chatyr_dag := PackedVector2Array([
		Vector2(0, 325), Vector2(110, 265), Vector2(240, 275),
		Vector2(350, 212), Vector2(590, 208), Vector2(690, 260),
		Vector2(820, 225), Vector2(960, 245), Vector2(960, 390), Vector2(0, 390)
	])
	draw_colored_polygon(chatyr_dag, Color(0.24, 0.13, 0.28))
	# Світлі вапнякові уступи скель Бахчисарая
	draw_line(Vector2(352, 214), Vector2(588, 210), Color(0.85, 0.62, 0.45, 0.45), 3.0)
	
	# 3. Архітектурний ансамбль Хансараю (Бахчисарайський Ханський Палац) та мурів Ор-Капу!
	# Дві стрункі вежі Великої Ханської мечеті (Büyük Han Cami) — दस-гранні мінарети з шерефе та півмісяцями!
	for mx in [235.0, 725.0]:
		# Стовбур мінарету з тесаного вапняку
		draw_rect(Rect2(mx - 9, 122, 18, 155), Color(0.90, 0.86, 0.78))
		draw_rect(Rect2(mx - 9, 122, 6, 155), Color(0.96, 0.93, 0.86))
		# Різьблений балкончик азанчі — шерефе (Şerefe) з кам'яними зубцями
		draw_colored_polygon(PackedVector2Array([
			Vector2(mx - 9, 172), Vector2(mx + 9, 172),
			Vector2(mx + 14, 164), Vector2(mx - 14, 164)
		]), Color(0.78, 0.72, 0.64))
		draw_rect(Rect2(mx - 14, 158, 28, 6), Color(0.92, 0.88, 0.80))
		# Гостроверхий свинцево-смарагдовий конічний дах (кюлях)
		draw_colored_polygon(PackedVector2Array([
			Vector2(mx - 10, 122), Vector2(mx + 10, 122), Vector2(mx, 78)
		]), Color(0.18, 0.42, 0.34))
		# Золотий алем із півмісяцем (Alem)
		draw_line(Vector2(mx, 78), Vector2(mx, 66), Color(1.0, 0.88, 0.22), 2.0)
		draw_arc(Vector2(mx, 62), 5.0, -0.8, PI + 0.8, 8, Color(1.0, 0.88, 0.22), 2.0)
	
	# Корпус Ханського палацу з традиційним черепичним дахом «татарка» та вітражами-шебеке
	var pal_y := 248.0
	draw_rect(Rect2(255, pal_y, 450, 55), Color(0.92, 0.89, 0.82))
	# Багатоярусний черепичний дах із широкими дерев'яними піддашшями
	draw_colored_polygon(PackedVector2Array([
		Vector2(242, pal_y), Vector2(718, pal_y),
		Vector2(690, pal_y - 26), Vector2(270, pal_y - 26)
	]), Color(0.68, 0.26, 0.16))
	for tile_x in range(255, 705, 14):
		draw_line(Vector2(tile_x, pal_y), Vector2(tile_x + 6, pal_y - 24), Color(0.54, 0.18, 0.10), 1.2)
	
	# Стрілчасті східні вікна з кольоровими вітражами-шебеке (Şebeke)
	for w_i in range(7):
		var wx := 290.0 + float(w_i) * 62.0
		draw_rect(Rect2(wx - 9, pal_y + 12, 18, 24), Color(0.98, 0.78, 0.22, 0.88))
		draw_colored_polygon(PackedVector2Array([
			Vector2(wx - 9, pal_y + 12), Vector2(wx + 9, pal_y + 12), Vector2(wx, pal_y + 4)
		]), Color(0.22, 0.65, 0.88, 0.90))
		draw_line(Vector2(wx, pal_y + 4), Vector2(wx, pal_y + 36), Color(0.28, 0.18, 0.10), 1.4)
	
	# Соколина вежа (Şahin Kulesi) Хансараю в центрі
	draw_rect(Rect2(454, 188, 52, 62), Color(0.94, 0.90, 0.84))
	draw_rect(Rect2(448, 168, 64, 22), Color(0.52, 0.32, 0.18)) # Дерев'яна різьблена галерея Соколиної вежі
	for g_i in range(-2, 3):
		draw_rect(Rect2(480 + g_i * 11 - 4, 172, 8, 14), Color(1.0, 0.85, 0.28, 0.85))
	draw_colored_polygon(PackedVector2Array([
		Vector2(442, 168), Vector2(518, 168), Vector2(480, 142)
	]), Color(0.72, 0.28, 0.16))
	
	# 4. Стрункі темно-смарагдові кримські кипариси вздовж палацового саду
	for cx in [75.0, 155.0, 335.0, 625.0, 805.0, 885.0]:
		draw_line(Vector2(cx, 320), Vector2(cx, 355), Color(0.22, 0.14, 0.08), 3.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 9, 325), Vector2(cx + 9, 325), Vector2(cx, 228)
		]), Color(0.10, 0.28, 0.20))
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 9, 325), Vector2(cx, 325), Vector2(cx, 228)
		]), Color(0.15, 0.36, 0.25))
	
	# 5. Могутній Перекопський фортечний вал та білокам'яний мур Ор-Капу на передньому плані!
	draw_rect(Rect2(80, 290, 800, 82), Color(0.82, 0.78, 0.70)) # Інкерманський вапняк
	for st_y in range(302, 368, 14):
		draw_line(Vector2(80, st_y), Vector2(880, st_y), Color(0.70, 0.65, 0.58), 1.3)
	for bx in range(95, 865, 32):
		draw_rect(Rect2(bx, 274, 18, 16), Color(0.86, 0.82, 0.74))
	# Центральна аркова брама Ор-Капу
	draw_rect(Rect2(452, 315, 56, 55), Color(0.18, 0.14, 0.12))
	draw_colored_polygon(PackedVector2Array([
		Vector2(452, 315), Vector2(508, 315), Vector2(480, 294)
	]), Color(0.18, 0.14, 0.12))
	
	# Небесно-блакитний кримськотатарський стяг (Kök Bayraq) із золотою Тарак-Тамгою та козацький малиновий стяг поруч!
	var wave := sin(time_passed * 4.2) * 4.0
	# Блакитний стяг Тарак-Тамга
	var fp1 := 415.0
	draw_line(Vector2(fp1, 276), Vector2(fp1, 212), Color(0.35, 0.25, 0.15), 2.6)
	draw_colored_polygon(PackedVector2Array([
		Vector2(fp1, 215), Vector2(fp1 + 44, 215 + wave * 0.4),
		Vector2(fp1 + 44, 242 + wave), Vector2(fp1, 242)
	]), Color(0.18, 0.54, 0.86))
	var t_c := Vector2(fp1 + 18, 228 + wave * 0.5)
	draw_line(t_c + Vector2(0, 5), t_c + Vector2(0, -4), Color(1.0, 0.88, 0.22), 2.0)
	draw_line(t_c + Vector2(-5, 0), t_c + Vector2(5, 0), Color(1.0, 0.88, 0.22), 1.8)
	draw_line(t_c + Vector2(-5, 0), t_c + Vector2(-5, -4), Color(1.0, 0.88, 0.22), 1.8)
	draw_line(t_c + Vector2(5, 0), t_c + Vector2(5, -4), Color(1.0, 0.88, 0.22), 1.8)
	
	# Малиновий козацький стяг побратимства праворуч від брами
	var fp2 := 545.0
	draw_line(Vector2(fp2, 276), Vector2(fp2, 212), Color(0.35, 0.25, 0.15), 2.6)
	draw_colored_polygon(PackedVector2Array([
		Vector2(fp2, 215), Vector2(fp2 + 44, 215 - wave * 0.4),
		Vector2(fp2 + 34, 228 - wave * 0.6), Vector2(fp2 + 44, 242 - wave), Vector2(fp2, 242)
	]), Color(0.80, 0.14, 0.22))
	draw_line(Vector2(fp2 + 15, 222 - wave * 0.3), Vector2(fp2 + 15, 234 - wave * 0.3), Color(1.0, 0.90, 0.25), 2.0)
	draw_line(Vector2(fp2 + 9, 228 - wave * 0.3), Vector2(fp2 + 21, 228 - wave * 0.3), Color(1.0, 0.90, 0.25), 2.0)
	
	# Глибокий Перекопський рів із водою Сиваша внизу
	draw_rect(Rect2(0, 370, 960, 170), Color(0.08, 0.14, 0.24))

# -------------------------------------------------------------------------
# АКТ 2: РІВНІ 6–10 (СІВЕРЩИНА, ВОЛЯ ВКЛ ТА КАРПАТИ)
# -------------------------------------------------------------------------

# Рівень 6: Ханський Бахчисарай та скелі Чуфут-Кале
func _draw_bakhchysarai_palace() -> void:
	_draw_painterly_sky(Color(0.04, 0.06, 0.16), Color(0.12, 0.16, 0.32), Color(0.24, 0.20, 0.35))
	_draw_cossack_moon(Vector2(830, 75), 20.0, true)
	# Скелі Чуфут-Кале на дальньому плані
	var rocks := PackedVector2Array([
		Vector2(0, 290), Vector2(160, 240), Vector2(340, 255), Vector2(510, 225),
		Vector2(680, 245), Vector2(850, 220), Vector2(960, 250), Vector2(960, 370), Vector2(0, 370)
	])
	draw_colored_polygon(rocks, Color(0.18, 0.17, 0.25))
	# Хан-Сарай: Велика Ханська мечеть (Бююк Хан Джамі) та 2 стрункі мінарети
	var pal_x := 480.0
	draw_rect(Rect2(pal_x - 90, 275, 180, 55), Color(0.78, 0.74, 0.65)) # Вапнякові стіни
	for m_off: float in [-82.0, 82.0]:
		var mx: float = pal_x + m_off
		draw_rect(Rect2(mx - 4.5, 175, 9.0, 100), Color(0.88, 0.85, 0.78))
		draw_colored_polygon(PackedVector2Array([Vector2(mx - 6, 175), Vector2(mx + 6, 175), Vector2(mx, 142)]), Color(0.24, 0.35, 0.38)) # Шпиль
		_draw_warm_glow(Vector2(mx, 195), 4.0, Color(1.0, 0.88, 0.35))
	# Фонтанний дворик і стрункі кипариси
	for c_x: float in [320.0, 360.0, 600.0, 640.0]:
		_draw_pine_silhouette(Vector2(c_x, 330), 65.0, 14.0, Color(0.10, 0.22, 0.18))
	draw_rect(Rect2(0, 330, 960, 210), Color(0.12, 0.11, 0.16))

# Рівень 7: Конотопська переправа
func _draw_konotop_crossing() -> void:
	_draw_painterly_sky(Color(0.03, 0.05, 0.14), Color(0.08, 0.14, 0.26), Color(0.15, 0.22, 0.25))
	_draw_cossack_moon(Vector2(140, 70), 18.0, false)
	# Туманні заплавні ліси річки Соснівки
	for fx: float in [100.0, 260.0, 700.0, 860.0]:
		_draw_pine_silhouette(Vector2(fx, 305), 55.0, 32.0, Color(0.08, 0.14, 0.15))
	# Козацькі мостові настили та земляні редути Виговського
	draw_rect(Rect2(0, 305, 960, 45), Color(0.18, 0.14, 0.10))
	for bx in range(20, 940, 30):
		draw_rect(Rect2(bx, 300, 20, 10), Color(0.28, 0.19, 0.12))
	# Плесо річки Соснівки з очеретами й зоряними бліками
	draw_rect(Rect2(0, 350, 960, 190), Color(0.05, 0.10, 0.18))
	for w_i in 6:
		var wy := 365.0 + float(w_i) * 22.0
		draw_line(Vector2(80 + float(w_i * 40), wy), Vector2(880 - float(w_i * 30), wy), Color(0.20, 0.40, 0.55, 0.35), 2.0)

# Рівень 8: Стародавній Полоцьк і Пуща ВКЛ
func _draw_polotsk_castle() -> void:
	_draw_painterly_sky(Color(0.02, 0.04, 0.12), Color(0.07, 0.12, 0.24), Color(0.12, 0.18, 0.28))
	_draw_cossack_moon(Vector2(810, 68), 21.0, false)
	# Кручі Західної Двіни та соснова пуща
	for px: float in [60.0, 150.0, 800.0, 890.0]:
		_draw_pine_silhouette(Vector2(px, 300), 75.0, 24.0, Color(0.06, 0.12, 0.14))
	# Білокам'яний Софійський собор із бароковими шпилями
	var sof_x := 480.0
	draw_rect(Rect2(sof_x - 55, 240, 110, 70), Color(0.85, 0.86, 0.90))
	for sp_off: float in [-42.0, 42.0]:
		var sx: float = sof_x + sp_off
		draw_rect(Rect2(sx - 8, 190, 16, 50), Color(0.90, 0.92, 0.95))
		_draw_cossack_dome(sx, 190, 18.0, 24.0, Color(0.78, 0.65, 0.22), Color(0.85, 0.86, 0.90))
		_draw_warm_glow(Vector2(sx, 215), 4.0, Color(1.0, 0.85, 0.30))
	draw_rect(Rect2(0, 310, 960, 230), Color(0.10, 0.13, 0.18))

# Рівень 9: Чорногора — Скелі Довбуша
func _draw_chornohora_dovbush() -> void:
	_draw_painterly_sky(Color(0.01, 0.03, 0.10), Color(0.05, 0.10, 0.22), Color(0.10, 0.18, 0.25))
	_draw_cossack_moon(Vector2(160, 65), 22.0, false)
	# Величні гранітні скелі Довбуша та карпатські урвища
	var dov_rocks := PackedVector2Array([
		Vector2(0, 310), Vector2(120, 220), Vector2(250, 245), Vector2(380, 185),
		Vector2(500, 235), Vector2(640, 175), Vector2(780, 230), Vector2(960, 205),
		Vector2(960, 360), Vector2(0, 360)
	])
	draw_colored_polygon(dov_rocks, Color(0.14, 0.16, 0.22))
	# Смерековий карпатський бір
	for tx: float in [80.0, 210.0, 340.0, 580.0, 720.0, 880.0]:
		_draw_pine_silhouette(Vector2(tx, 325), 65.0, 26.0, Color(0.05, 0.12, 0.10))
	# Вогнище опришків біля скелі
	_draw_warm_glow(Vector2(480, 315), 9.0, Color(1.0, 0.45, 0.10))
	draw_rect(Rect2(0, 330, 960, 210), Color(0.08, 0.10, 0.14))

# Рівень 10: Золоті Ворота Києва
func _draw_kyiv_golden_gate() -> void:
	_draw_painterly_sky(Color(0.03, 0.05, 0.15), Color(0.09, 0.15, 0.30), Color(0.18, 0.22, 0.38))
	_draw_cossack_moon(Vector2(820, 65), 22.0, false)
	# Могутня кам'яна брама з золоченим надбрамним храмом Благовіщення
	var gate_x := 480.0
	draw_rect(Rect2(gate_x - 75, 230, 150, 85), Color(0.72, 0.58, 0.42)) # Плінфа
	# Арка воріт
	draw_rect(Rect2(gate_x - 22, 265, 44, 50), Color(0.12, 0.08, 0.06))
	draw_circle(Vector2(gate_x, 265), 22.0, Color(0.12, 0.08, 0.06))
	# Надбрамна церква та золотий купол
	draw_rect(Rect2(gate_x - 42, 190, 84, 40), Color(0.78, 0.65, 0.48))
	_draw_cossack_dome(gate_x, 190, 32.0, 30.0, Color(1.0, 0.86, 0.22), Color(0.78, 0.65, 0.48))
	_draw_warm_glow(Vector2(gate_x, 205), 6.0, Color(1.0, 0.90, 0.45))
	draw_rect(Rect2(0, 315, 960, 225), Color(0.12, 0.10, 0.08))

# -------------------------------------------------------------------------
# АКТ 3: РІВНІ 11–15 (ВОЛИНЬ, ПОДІЛЛЯ ТА ЗАДУНАЙСЬКА СІЧ)
# -------------------------------------------------------------------------

# Рівень 11: Луцький замок Любарта
func _draw_lutsk_lubart_castle() -> void:
	_draw_painterly_sky(Color(0.02, 0.04, 0.12), Color(0.06, 0.12, 0.25), Color(0.14, 0.18, 0.28))
	_draw_cossack_moon(Vector2(150, 70), 20.0, true)
	# В'їзна вежа з червоної цегли із зубцями-мерлонами
	var v_x := 480.0
	draw_rect(Rect2(v_x - 45, 175, 90, 140), Color(0.58, 0.22, 0.18))
	for bx in range(int(v_x - 45), int(v_x + 45), 18):
		draw_rect(Rect2(bx, 162, 10, 13), Color(0.64, 0.25, 0.20))
	_draw_warm_glow(Vector2(v_x, 220), 5.0, Color(1.0, 0.85, 0.35))
	# Зубчасті стіни замку ліворуч і праворуч
	draw_rect(Rect2(80, 255, 355, 60), Color(0.50, 0.18, 0.15))
	draw_rect(Rect2(525, 255, 355, 60), Color(0.50, 0.18, 0.15))
	draw_rect(Rect2(0, 315, 960, 225), Color(0.08, 0.12, 0.18))

# Рівень 12: Хотинська фортеця над Дністром
func _draw_khotyn_fortress() -> void:
	_draw_painterly_sky(Color(0.03, 0.05, 0.14), Color(0.08, 0.16, 0.30), Color(0.15, 0.24, 0.36))
	_draw_cossack_moon(Vector2(840, 68), 22.0, false)
	# 40-метрові кам'яні мури Хотина з червоними цегляними візерунками
	var h_x := 480.0
	draw_rect(Rect2(h_x - 120, 185, 240, 130), Color(0.72, 0.68, 0.62))
	for wy in range(200, 300, 20):
		draw_line(Vector2(h_x - 110, wy), Vector2(h_x + 110, wy), Color(0.68, 0.22, 0.20), 2.5) # Червоний орнамент
	# Башти фортеці
	for bx: float in [h_x - 130.0, h_x + 110.0]:
		draw_rect(Rect2(bx, 155, 35, 160), Color(0.76, 0.72, 0.66))
		draw_colored_polygon(PackedVector2Array([Vector2(bx - 3, 155), Vector2(bx + 38, 155), Vector2(bx + 17, 120)]), Color(0.35, 0.15, 0.12))
	draw_rect(Rect2(0, 315, 960, 225), Color(0.06, 0.14, 0.24)) # Дністер

# Рівень 13: Острозька академія та кругла вежа
func _draw_ostroh_academy() -> void:
	_draw_painterly_sky(Color(0.02, 0.04, 0.13), Color(0.07, 0.13, 0.26), Color(0.16, 0.20, 0.32))
	_draw_cossack_moon(Vector2(140, 72), 19.0, false)
	# Мурована ренесансна Кругла вежа Острога
	_draw_oval(Vector2(480, 270), 75.0, 50.0, Color(0.55, 0.42, 0.32))
	draw_rect(Rect2(405, 220, 150, 55), Color(0.62, 0.48, 0.36))
	# Аттик із ренесансними зубцями
	for ax in range(410, 550, 16):
		draw_rect(Rect2(ax, 208, 10, 12), Color(0.68, 0.54, 0.42))
	_draw_warm_glow(Vector2(480, 245), 6.0, Color(1.0, 0.88, 0.40)) # Вікно друкарні Федорова
	draw_rect(Rect2(0, 315, 960, 225), Color(0.10, 0.12, 0.16))

# Рівень 14: Біловезька пуща
func _draw_bilovezha_pushcha() -> void:
	_draw_painterly_sky(Color(0.01, 0.03, 0.10), Color(0.04, 0.08, 0.18), Color(0.09, 0.15, 0.20))
	_draw_cossack_moon(Vector2(800, 70), 20.0, true)
	# Вікові дуби-велетні та силует зубра
	for ox: float in [120.0, 280.0, 680.0, 840.0]:
		_draw_oval(Vector2(ox, 250), 45.0, 55.0, Color(0.06, 0.12, 0.08))
		draw_rect(Rect2(ox - 8, 250, 16, 65), Color(0.16, 0.10, 0.06))
	# Силует зубра біля пущі
	_draw_oval(Vector2(480, 290), 22.0, 15.0, Color(0.08, 0.07, 0.08))
	_draw_oval(Vector2(462, 282), 12.0, 14.0, Color(0.08, 0.07, 0.08)) # Голова з рогами
	draw_rect(Rect2(0, 315, 960, 225), Color(0.06, 0.09, 0.10))

# Рівень 15: Задунайська Січ
func _draw_zadunayska_sich() -> void:
	_draw_painterly_sky(Color(0.03, 0.06, 0.16), Color(0.09, 0.16, 0.32), Color(0.18, 0.26, 0.36))
	_draw_cossack_moon(Vector2(160, 68), 21.0, false)
	# Козацькі курені під очеретом на дунайських косах
	for kx: float in [240.0, 480.0, 720.0]:
		draw_rect(Rect2(kx - 35, 275, 70, 35), Color(0.32, 0.22, 0.14))
		draw_colored_polygon(PackedVector2Array([Vector2(kx - 42, 275), Vector2(kx + 42, 275), Vector2(kx, 245)]), Color(0.48, 0.38, 0.20))
		_draw_warm_glow(Vector2(kx, 285), 4.0, Color(1.0, 0.85, 0.30))
	# Дунайські очерети та причали козацьких чайок
	draw_rect(Rect2(0, 310, 960, 230), Color(0.06, 0.13, 0.22))
	for ox in range(20, 940, 18):
		draw_line(Vector2(ox, 320), Vector2(ox + 4, 292), Color(0.24, 0.36, 0.22), 2.0)

# -------------------------------------------------------------------------
# АКТ 4: РІВНІ 16–20 (ДУНАЙ, ВЕРХОВИНА, КРИМ ТА ВЕЛИКИЙ СОБОР)
# -------------------------------------------------------------------------

# Рівень 16: Дунайські гирла
func _draw_danube_estuary() -> void:
	_draw_painterly_sky(Color(0.02, 0.05, 0.14), Color(0.07, 0.14, 0.28), Color(0.14, 0.22, 0.34))
	_draw_cossack_moon(Vector2(820, 65), 22.0, false)
	# Сторожові каланчі козаків-пластунів на палях
	for cx: float in [220.0, 740.0]:
		draw_line(Vector2(cx - 10, 315), Vector2(cx - 5, 235), Color(0.30, 0.20, 0.12), 3.0)
		draw_line(Vector2(cx + 10, 315), Vector2(cx + 5, 235), Color(0.30, 0.20, 0.12), 3.0)
		draw_rect(Rect2(cx - 18, 220, 36, 16), Color(0.40, 0.28, 0.16))
		_draw_warm_glow(Vector2(cx, 212), 6.0, Color(1.0, 0.55, 0.15)) # Сигнальний каганець
	draw_rect(Rect2(0, 315, 960, 225), Color(0.04, 0.10, 0.20)) # Морське гирло

# Рівень 17: Білоруська пуща Кастуся Калиновського
func _draw_kalinowski_pushcha() -> void:
	_draw_painterly_sky(Color(0.01, 0.03, 0.11), Color(0.05, 0.10, 0.22), Color(0.11, 0.16, 0.25))
	_draw_cossack_moon(Vector2(150, 70), 20.0, true)
	# Партизанські лісові вежі та соснові засеки
	for px: float in [100.0, 250.0, 710.0, 860.0]:
		_draw_pine_silhouette(Vector2(px, 305), 70.0, 28.0, Color(0.06, 0.11, 0.12))
	# Біло-червоно-білий прапор свободи Калиновського біля лісової ватри
	var fx := 480.0
	draw_line(Vector2(fx, 310), Vector2(fx, 240), Color(0.42, 0.28, 0.16), 2.5)
	draw_rect(Rect2(fx, 245, 32, 7), Color.WHITE)
	draw_rect(Rect2(fx, 252, 32, 7), Color(0.85, 0.15, 0.18))
	draw_rect(Rect2(fx, 259, 32, 7), Color.WHITE)
	_draw_warm_glow(Vector2(fx - 15, 305), 8.0, Color(1.0, 0.50, 0.12))
	draw_rect(Rect2(0, 310, 960, 230), Color(0.08, 0.10, 0.12))

# Рівень 18: Верховина й Писаний Камінь
func _draw_verkhovyna_pysanyi_kamin() -> void:
	_draw_painterly_sky(Color(0.02, 0.04, 0.14), Color(0.06, 0.12, 0.28), Color(0.13, 0.20, 0.32))
	_draw_cossack_moon(Vector2(830, 68), 22.0, false)
	# Священний Писаний Камінь мольфарів із петрогліфами
	var kamin := PackedVector2Array([
		Vector2(380, 310), Vector2(420, 230), Vector2(540, 220), Vector2(580, 310)
	])
	draw_colored_polygon(kamin, Color(0.28, 0.26, 0.32))
	# Золоті солярні знаки (петрогліфи) на камені
	draw_arc(Vector2(480, 255), 12.0, 0.0, TAU, 16, Color(1.0, 0.88, 0.30, 0.85), 1.8)
	draw_line(Vector2(480, 240), Vector2(480, 270), Color(1.0, 0.88, 0.30, 0.85), 1.8)
	draw_line(Vector2(465, 255), Vector2(495, 255), Color(1.0, 0.88, 0.30, 0.85), 1.8)
	# Гуцульські смереки обабіч полонини
	for tx: float in [80.0, 200.0, 760.0, 880.0]:
		_draw_pine_silhouette(Vector2(tx, 320), 75.0, 30.0, Color(0.05, 0.13, 0.10))
	draw_rect(Rect2(0, 310, 960, 230), Color(0.09, 0.11, 0.14))

# Рівень 19: Гезльов (Євпаторія) та Хан-Джамі
func _draw_kezlev_khan_jami() -> void:
	_draw_painterly_sky(Color(0.04, 0.06, 0.18), Color(0.12, 0.18, 0.35), Color(0.22, 0.25, 0.42))
	_draw_cossack_moon(Vector2(150, 70), 20.0, true)
	# Величні куполи мечеті Джума-Джамі (архітектор Мімар Сінан) та приморська гавань
	var j_x := 480.0
	draw_rect(Rect2(j_x - 70, 245, 140, 65), Color(0.82, 0.80, 0.74))
	_draw_oval(Vector2(j_x, 245), 45.0, 30.0, Color(0.35, 0.48, 0.52)) # Головний купол
	for mx: float in [j_x - 68.0, j_x + 68.0]:
		draw_rect(Rect2(mx - 4, 180, 8, 90), Color(0.88, 0.86, 0.80))
		draw_colored_polygon(PackedVector2Array([Vector2(mx - 5, 180), Vector2(mx + 5, 180), Vector2(mx, 150)]), Color(0.28, 0.42, 0.45))
		_draw_warm_glow(Vector2(mx, 195), 3.5, Color(1.0, 0.88, 0.35))
	draw_rect(Rect2(0, 310, 960, 230), Color(0.06, 0.14, 0.26)) # Чорне море

# Рівень 20: Тарасова Гора у Каневі — Великий Собор Народів
func _draw_kaniv_taras_hill() -> void:
	# Урочисте золотисто-волошкове небо свободи
	_draw_painterly_sky(Color(0.03, 0.05, 0.18), Color(0.10, 0.18, 0.36), Color(0.22, 0.26, 0.45))
	_draw_cossack_moon(Vector2(820, 65), 24.0, false)
	# Дніпровські кручі та пагорби Канева
	var hills := PackedVector2Array([
		Vector2(0, 300), Vector2(160, 250), Vector2(340, 265), Vector2(480, 215),
		Vector2(620, 255), Vector2(800, 240), Vector2(960, 275), Vector2(960, 360), Vector2(0, 360)
	])
	draw_colored_polygon(hills, Color(0.12, 0.16, 0.25))
	# Віковічний дуб єднання на верхівці Чернечої Гори
	var tree_x := 480.0
	_draw_oval(Vector2(tree_x, 195), 45.0, 38.0, Color(0.15, 0.32, 0.20))
	draw_rect(Rect2(tree_x - 6, 195, 12, 40), Color(0.32, 0.20, 0.12))
	# Три стяги братерства на вершині (Козацький малиновий, Кримський блакитний, Литвинський біло-червоний)
	var flag_y := 170.0
	draw_line(Vector2(tree_x - 30, flag_y + 35), Vector2(tree_x - 30, flag_y), Color(0.50, 0.40, 0.25), 2.0)
	draw_rect(Rect2(tree_x - 30, flag_y, 22, 14), Color(0.82, 0.12, 0.22)) # Козацький
	draw_line(Vector2(tree_x, flag_y + 30), Vector2(tree_x, flag_y - 8), Color(0.50, 0.40, 0.25), 2.0)
	draw_rect(Rect2(tree_x, flag_y - 8, 22, 14), Color(0.18, 0.54, 0.88)) # Кримськотатарський
	draw_line(Vector2(tree_x + 30, flag_y + 35), Vector2(tree_x + 30, flag_y), Color(0.50, 0.40, 0.25), 2.0)
	draw_rect(Rect2(tree_x + 30, flag_y, 22, 14), Color(0.92, 0.92, 0.95)) # Литвинський
	draw_line(Vector2(tree_x + 30, flag_y + 7), Vector2(tree_x + 52, flag_y + 7), Color(0.85, 0.15, 0.18), 4.5)
	# Широкий величний Дніпро-Славутич унизу з місячною стежкою
	draw_rect(Rect2(0, 325, 960, 215), Color(0.04, 0.12, 0.24))
	for mi in 8:
		var my := 340.0 + float(mi) * 18.0
		draw_line(Vector2(320 - float(mi * 15), my), Vector2(640 + float(mi * 25), my), Color(0.40, 0.65, 0.85, 0.35), 2.2)
