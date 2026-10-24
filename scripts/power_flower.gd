extends Area2D

class_name FernFlowerItem

signal collected(flower: FernFlowerItem)
signal stolen_by_enemy(flower: FernFlowerItem, enemy: Node2D)

var velocity: Vector2 = Vector2(85.0, 70.0)
var time_passed: float = 0.0
var pulse_speed: float = 6.0
var rot_angle: float = 0.0
var enemy_grab_grace_timer: float = 2.0

@onready var col_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	body_entered.connect(_on_body_entered, CONNECT_DEFERRED)
	area_entered.connect(_on_area_entered, CONNECT_DEFERRED)
	# Randomize initial drift direction
	var ang := randf_range(0.0, TAU)
	velocity = Vector2(cos(ang), sin(ang)) * 95.0

func _process(delta: float) -> void:
	time_passed += delta
	if enemy_grab_grace_timer > 0.0:
		enemy_grab_grace_timer -= delta
	rot_angle += delta * 2.2
	position += velocity * delta
	
	# Bounce off arena walls (960x540 2K 16:9 widescreen)
	if position.x < 30.0:
		position.x = 30.0
		velocity.x = abs(velocity.x)
	elif position.x > 930.0:
		position.x = 930.0
		velocity.x = -abs(velocity.x)
	
	if position.y < 45.0:
		position.y = 45.0
		velocity.y = abs(velocity.y)
	elif position.y > 495.0:
		position.y = 495.0
		velocity.y = -abs(velocity.y)
	
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body is JackPlayer:
		collected.emit(self)
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if enemy_grab_grace_timer > 0.0:
		return
	if area is FolkloreEnemy and not area.is_scared and not area.has_stolen_artifact:
		area.apply_stolen_artifact_buff(6.5)
		stolen_by_enemy.emit(self, area)
		queue_free()

func _draw() -> void:
	# 1. Містична купальська аура (сяйво золота та смарагду)
	var pulse := 1.0 + sin(time_passed * pulse_speed) * 0.22
	draw_circle(Vector2.ZERO, 22.0 * pulse, Color(0.15, 0.95, 0.45, 0.18)) # Смарагдове сяйво
	draw_circle(Vector2.ZERO, 15.0 * pulse, Color(1.0, 0.85, 0.15, 0.28)) # Золоте сяйво
	draw_circle(Vector2.ZERO, 8.0 * pulse, Color(1.0, 0.25, 0.35, 0.40)) # Багряне серце
	
	# 2. 8 Магічних пелюсток Цвіту Папороті
	var num_petals := 8
	for i in range(num_petals):
		var a := rot_angle + float(i) / float(num_petals) * TAU
		var p_dir := Vector2(cos(a), sin(a))
		var p_perp := Vector2(-p_dir.y, p_dir.x)
		var p_tip := p_dir * (14.0 * pulse)
		var p_mid := p_dir * 7.0
		
		# Пелюстка: перелив від золотого до полум'яно-червоного
		var petal_pts = PackedVector2Array([
			Vector2.ZERO,
			p_mid + p_perp * 3.5,
			p_tip,
			p_mid - p_perp * 3.5
		])
		var col := Color(1.0, 0.82, 0.18) if (i % 2 == 0) else Color(1.0, 0.28, 0.32)
		draw_colored_polygon(petal_pts, col)
		draw_line(Vector2.ZERO, p_tip, Color(1.0, 1.0, 0.85), 1.2)
	
	# 3. Палаюче серце квітки
	draw_circle(Vector2.ZERO, 3.5, Color(1.0, 1.0, 0.95))
	
	# 4. Чарівні іскри навколо квітки
	for s in range(4):
		var sa := time_passed * 4.0 + s * (PI / 2.0)
		var s_pos := Vector2(cos(sa), sin(sa)) * (18.0 * pulse)
		draw_circle(s_pos, 1.2, Color(1.0, 0.95, 0.65, 0.85))
