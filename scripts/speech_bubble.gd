extends Control

class_name SpeechBubble

@onready var panel: PanelContainer = $PanelContainer
@onready var label: Label = $PanelContainer/Label

var current_tween: Tween = null


func _ready() -> void:
	visible = false
	pivot_offset = Vector2(0, 0)  # Pop from bottom center


func say(text: String, duration: float = 1.8) -> void:
	if not label:
		label = get_node_or_null("PanelContainer/Label")
	if not panel:
		panel = get_node_or_null("PanelContainer")
	if not label or not panel:
		return

	if current_tween and current_tween.is_valid():
		current_tween.kill()

	label.text = text
	# Center bubble horizontally over player (offset x based on size)
	panel.reset_size()
	await get_tree().process_frame

	var p_size := panel.size
	panel.position = Vector2(-p_size.x * 0.5, -p_size.y - 10.0)
	pivot_offset = Vector2(0, 0)

	modulate = Color(1, 1, 1, 1)
	scale = Vector2(0.2, 0.2)
	visible = true

	current_tween = create_tween()
	# Pop in with comic bounce
	current_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	current_tween.tween_interval(maxf(0.4, duration - 0.5))
	# Float slightly up and fade out
	current_tween.tween_property(self, "position:y", position.y - 12.0, 0.3).set_trans(Tween.TRANS_SINE)
	current_tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	current_tween.tween_callback(
		func():
			visible = false
			position.y += 12.0
	)


func _draw() -> void:
	if not visible:
		return
	# Small cartoon tail pointer from bubble bottom pointing towards Dzhura's head (0, -2)
	var tail_pts = PackedVector2Array([Vector2(-4.0, -10.0), Vector2(4.0, -10.0), Vector2(0.0, -2.0)])
	draw_colored_polygon(tail_pts, Color.WHITE)
	draw_line(Vector2(-4.0, -10.0), Vector2(0.0, -2.0), Color(0.08, 0.12, 0.22), 1.6)
	draw_line(Vector2(4.0, -10.0), Vector2(0.0, -2.0), Color(0.08, 0.12, 0.22), 1.6)
