@tool
extends StaticBody2D

class_name BombJackPlatform

@export var width: float = 90.0:
	set(val):
		width = val
		_update_shape()
		queue_redraw()

@export var height: float = 12.0:
	set(val):
		height = val
		_update_shape()
		queue_redraw()

@export var is_one_way: bool = false:
	set(val):
		is_one_way = val
		_update_one_way()
		queue_redraw()

@export var platform_style: int = 0: # 0: Oak Beam (Січ), 1: Chiseled Timber (Хутір), 2: Fortress Stone (Кам'янець), 3: Hetman Walnut
	set(val):
		platform_style = val
		queue_redraw()

@onready var col_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	if col_shape and col_shape.shape:
		col_shape.shape = col_shape.shape.duplicate()
	_update_shape()

func _update_shape() -> void:
	if not col_shape:
		col_shape = get_node_or_null("CollisionShape2D")
	if col_shape:
		if not (col_shape.shape is RectangleShape2D):
			col_shape.shape = RectangleShape2D.new()
		(col_shape.shape as RectangleShape2D).size = Vector2(width, height)
		_update_one_way()

func _update_one_way() -> void:
	if not col_shape:
		col_shape = get_node_or_null("CollisionShape2D")
	if col_shape:
		col_shape.one_way_collision = is_one_way
		col_shape.one_way_collision_margin = 8.0

func _draw() -> void:
	var h_w := width * 0.5
	var h_h := height * 0.5
	var rect := Rect2(-h_w, -h_h, width, height)
	
	match platform_style % 4:
		0:
			# СІЧ (XVII ст.): Морений тесаний дубовий брус із кованими залізними окуттями
			draw_rect(rect, Color(0.36, 0.22, 0.11)) # Глибокий морений дуб
			# Деревні волокна
			draw_line(Vector2(-h_w + 14, -h_h + 3), Vector2(h_w - 14, -h_h + 3), Color(0.28, 0.16, 0.08), 1.2)
			draw_line(Vector2(-h_w + 18, -h_h + 7), Vector2(h_w - 18, -h_h + 7), Color(0.28, 0.16, 0.08), 1.0)
			# Верхня витесана фаска
			draw_line(Vector2(-h_w, -h_h), Vector2(h_w, -h_h), Color(0.58, 0.40, 0.22), 2.0)
			# Нижня монолітна стеля
			draw_line(Vector2(-h_w, h_h), Vector2(h_w, h_h), Color(0.14, 0.08, 0.04), 2.5)
			# Ковані залізні скоби/окуття по краях бруса
			draw_rect(Rect2(-h_w, -h_h, 8.0, height), Color(0.22, 0.24, 0.28))
			draw_rect(Rect2(h_w - 8.0, -h_h, 8.0, height), Color(0.22, 0.24, 0.28))
			draw_circle(Vector2(-h_w + 4.0, 0), 1.5, Color(0.65, 0.70, 0.75)) # Залізна заклепка
			draw_circle(Vector2(h_w - 4.0, 0), 1.5, Color(0.65, 0.70, 0.75))
		
		1:
			# ХУТІР ТА ЧУМАКИ (XVIII-XIX ст.): Світлий наддніпрянський тесаний брус із кілками
			draw_rect(rect, Color(0.48, 0.34, 0.18))
			draw_line(Vector2(-h_w + 6, -h_h + 3), Vector2(h_w - 6, -h_h + 3), Color(0.38, 0.25, 0.12), 1.2)
			draw_line(Vector2(-h_w, -h_h), Vector2(h_w, -h_h), Color(0.72, 0.54, 0.32), 2.0)
			draw_line(Vector2(-h_w, h_h), Vector2(h_w, h_h), Color(0.22, 0.14, 0.06), 2.5)
			# Дерев'яні кілки на торцях
			draw_circle(Vector2(-h_w + 5.0, 0), 2.0, Color(0.32, 0.20, 0.10))
			draw_circle(Vector2(h_w - 5.0, 0), 2.0, Color(0.32, 0.20, 0.10))
		
		2:
			# КАМ'ЯНЕЦЬКА ТВЕРДИНЯ (XVII-XVIII ст.): Кам'яні блоки фортечного муру
			draw_rect(rect, Color(0.32, 0.30, 0.35)) # Сірий подільський вапняк
			# Шви між тесаними блоками
			var block_w := 24.0
			for bx in range(int(-h_w) + 12, int(h_w) - 6, int(block_w)):
				draw_line(Vector2(bx, -h_h), Vector2(bx, h_h), Color(0.18, 0.16, 0.20), 1.5)
			# Верхня кам'яна плита
			draw_line(Vector2(-h_w, -h_h), Vector2(h_w, -h_h), Color(0.52, 0.50, 0.56), 2.0)
			draw_line(Vector2(-h_w, h_h), Vector2(h_w, h_h), Color(0.14, 0.12, 0.16), 2.5)
			draw_line(Vector2(-h_w, -h_h), Vector2(-h_w, h_h), Color(0.22, 0.20, 0.25), 1.5)
			draw_line(Vector2(h_w, -h_h), Vector2(h_w, h_h), Color(0.22, 0.20, 0.25), 1.5)
			
		3:
			# БАТУРИН (XVIII ст.): Гетьманський темний горіх із золотим кантом
			draw_rect(rect, Color(0.28, 0.16, 0.12))
			# Золотий різьблений кант
			draw_line(Vector2(-h_w, -h_h), Vector2(h_w, -h_h), Color(0.92, 0.78, 0.25), 2.0)
			draw_line(Vector2(-h_w, h_h), Vector2(h_w, h_h), Color(0.12, 0.06, 0.04), 2.5)
			draw_rect(Rect2(-h_w, -h_h, 6.0, height), Color(0.85, 0.70, 0.20))
			draw_rect(Rect2(h_w - 6.0, -h_h, 6.0, height), Color(0.85, 0.70, 0.20))
	
	# Золоте сяйво суперскіла Вакули: платформа стає проникною знизу вгору!
	if is_one_way:
		draw_line(Vector2(-h_w, h_h), Vector2(h_w, h_h), Color(1.0, 0.88, 0.20, 0.90), 2.2)
		draw_line(Vector2(-h_w, h_h + 2.0), Vector2(h_w, h_h + 2.0), Color(1.0, 0.88, 0.20, 0.35), 4.0)
