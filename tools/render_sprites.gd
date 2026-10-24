extends SceneTree
# Рендер процедурних персонажів у PNG: спокій, силует (перевірка «чорної заливки») і полохливий/танцювальний стан.
# Запуск (потрібен екран): godot --path ~/geek-jack --script res://tools/render_sprites.gd -- <каталог виводу>

const ZOOM := 5.0
const CELL := Vector2i(440, 440)
const ORIGIN := Vector2(220.0, 250.0)

var out_dir := "res://assets/sprites"
var viewport: SubViewport
var stage: Node2D

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	viewport = SubViewport.new()
	viewport.size = CELL
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var outer := Node2D.new()
	outer.position = ORIGIN
	outer.scale = Vector2(ZOOM, ZOOM)
	viewport.add_child(outer)
	# Як у грі (Enemies = CanvasGroup із шейдером «Київнаукфільм»): контур + підсвітка
	var group := CanvasGroup.new()
	group.fit_margin = 16.0
	group.clear_margin = 16.0
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/kyivnaukfilm_ink.gdshader")
	mat.set_shader_parameter("ink_width", 1.4 * ZOOM)
	mat.set_shader_parameter("rim_width", 1.6 * ZOOM)
	group.material = mat
	outer.add_child(group)
	stage = group
	await _run()
	quit()

func _enemy(kind: FolkloreEnemy.EnemyType, scared: bool) -> Node2D:
	var e := FolkloreEnemy.new()
	e.enemy_type = kind
	e.velocity = Vector2(110.0, 0.0)
	e.time_passed = 0.7
	e.is_scared = scared
	e.process_mode = Node.PROCESS_MODE_DISABLED
	return e

func _ally(scene_path: String, dance: bool) -> Node2D:
	var a: Node2D = load(scene_path).instantiate()
	a.process_mode = Node.PROCESS_MODE_DISABLED
	a.time_passed = 0.7
	a.facing_dir = 1.0
	a.is_celebrating_victory = dance
	a.dance_time = 0.6
	return a

func _mavka(cast: bool) -> Node2D:
	var m: Node2D = load("res://scripts/mavka_ally.gd").new()
	m.process_mode = Node.PROCESS_MODE_DISABLED
	m.time_passed = 0.7
	m.cast_flash = 0.4 if cast else 0.0
	return m

func _shot(node: Node2D, file: String) -> Image:
	stage.add_child(node)
	if node.get_script().resource_path == "res://scripts/enemy.gd":
		node.velocity = Vector2(110.0, 0.0) # _ready задає випадковий напрям; для знімка потрібен вправо
	for i in 4:
		node.queue_redraw()
		await process_frame
	await RenderingServer.frame_post_draw
	var img := viewport.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	img.save_png("%s/%s.png" % [out_dir, file])
	stage.remove_child(node)
	node.free()
	return img

func _silhouette(src: Image) -> Image:
	var s := src.duplicate()
	for y in s.get_height():
		for x in s.get_width():
			if s.get_pixel(x, y).a > 0.15:
				s.set_pixel(x, y, Color.BLACK)
			else:
				s.set_pixel(x, y, Color(1, 1, 1, 1))
	return s

func _run() -> void:
	var rows: Array = [
		["chort", "Чортик", func(p): return _enemy(FolkloreEnemy.EnemyType.CHORT, p == 1), 2],
		["vidma", "Відьма (Солоха)", func(p): return _enemy(FolkloreEnemy.EnemyType.VIDMA, p == 1), 2],
		["vognyk", "Блукаючий вогник", func(p): return _enemy(FolkloreEnemy.EnemyType.VOGNYK, p == 1), 2],
		["moskal", "Москаль (вертепний)", func(p): return _enemy(FolkloreEnemy.EnemyType.MOSKAL, p == 1), 2],
		["hutsul", "Гуцул-опришок", func(p): return _ally("res://scenes/hutsul_ally.tscn", p == 1), 2],
		["qirimli", "Киримли-побратим", func(p): return _ally("res://scenes/qirimli_ally.tscn", p == 1), 2],
		["mavka", "Мавка", func(p): return _mavka(p == 1), 2],
	]
	var sheet := Image.create_empty(CELL.x * 3, CELL.y * rows.size(), false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.93, 0.89, 0.78, 1.0))
	var r := 0
	for row in rows:
		var calm: Image = await _shot(row[2].call(0), "%s_calm" % row[0])
		var alt: Image = await _shot(row[2].call(1), "%s_alt" % row[0])
		var sil := _silhouette(calm)
		sil.save_png("%s/%s_silhouette.png" % [out_dir, row[0]])
		for c in 3:
			var img: Image = [calm, sil, alt][c]
			sheet.blend_rect(img, Rect2i(Vector2i.ZERO, CELL), Vector2i(c * CELL.x, r * CELL.y))
		r += 1
	sheet.save_png("%s/contact_sheet.png" % out_dir)
	print("sprites written to ", out_dir)
