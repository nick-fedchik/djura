extends CanvasLayer

class_name JackHUD

@onready var score_label: Label = $Margin/HBox/ScoreBox/ScoreValue
@onready var highscore_label: Label = $Margin/HBox/HighscoreBox/HighscoreValue
@onready var bombs_label: Label = $Margin/HBox/BombsBox/BombsValue
@onready var combo_label: Label = $ComboLabel
@onready var message_label: Label = $MessageLabel
@onready var combat_hint_label: Label = $CombatHintLabel

var combo_tween: Tween = null
var message_tween: Tween = null
var hint_tween: Tween = null
var hint_pulse_time: float = 0.0
var is_hint_active: bool = false
var is_showing_completion_flash: bool = false

func _process(delta: float) -> void:
	if is_hint_active and not is_showing_completion_flash and combat_hint_label and combat_hint_label.visible:
		hint_pulse_time += delta * 4.5
		var pulse_alpha := 0.86 + sin(hint_pulse_time) * 0.14
		combat_hint_label.modulate = Color(1.0, 1.0, 1.0, pulse_alpha)

func show_persistent_combat_hint(text: String) -> void:
	if not combat_hint_label:
		combat_hint_label = get_node_or_null("CombatHintLabel")
	if not combat_hint_label:
		return
	if hint_tween and hint_tween.is_valid():
		hint_tween.kill()
	is_showing_completion_flash = false
	if text.is_empty():
		is_hint_active = false
		combat_hint_label.visible = false
		return
	is_hint_active = true
	combat_hint_label.text = text
	combat_hint_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.30, 1.0))
	combat_hint_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	combat_hint_label.visible = true

func complete_combat_hint(completed_title: String, next_hint_text: String = "") -> void:
	if not combat_hint_label:
		combat_hint_label = get_node_or_null("CombatHintLabel")
	if not combat_hint_label:
		return
	if hint_tween and hint_tween.is_valid():
		hint_tween.kill()
	is_showing_completion_flash = true
	combat_hint_label.visible = true
	combat_hint_label.text = "✅ ОСВОЄНО: %s!" % completed_title
	combat_hint_label.add_theme_color_override("font_color", Color(0.30, 1.0, 0.55, 1.0))
	combat_hint_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	hint_tween = create_tween()
	hint_tween.tween_interval(1.25)
	hint_tween.tween_callback(func():
		show_persistent_combat_hint(next_hint_text)
	)

func update_score(score: int) -> void:
	score_label.text = "%06d" % score

func update_highscore(highscore: int) -> void:
	highscore_label.text = "%06d" % highscore

func update_bombs(count: int, total: int = 24) -> void:
	bombs_label.text = "%d / %d" % [count, total]

const HISTORICAL_STAGES: Array[Dictionary] = [
	{"epoch": "XVII ст.", "loc": "ЗАПОРОЗЬКА СІЧ НА ХОРТИЦІ", "lore": "ОСНОВИ ПАРКУРУ ТА МАЛІ ЧОРТИКИ"},
	{"epoch": "XVIII-XIX ст.", "loc": "СТЕПОВИЙ ХУТІР ТА ЧУМАЦЬКИЙ ШЛЯХ", "lore": "НІЧНА КАЗКА: ВІДЬМА ТА ВАКУЛА"},
	{"epoch": "XVII-XVIII ст.", "loc": "КАМ'ЯНЕЦЬКА ТВЕРДИНЯ", "lore": "СТЕПОВЕ ПОБРАТИМСТВО ТА МОСКАЛІ"},
	{"epoch": "XVIII ст.", "loc": "ГЕТЬМАНСЬКИЙ БАТУРИН", "lore": "ЗАХИСТ СКАРБНИЦІ ТА КЛЕЙНОДІВ"}
]

func show_combo(multiplier: int, bonus: int) -> void:
	if combo_tween and combo_tween.is_valid():
		combo_tween.kill()
	combo_label.text = "ВОГНЕВЕ ЯДРО x%d! +%d" % [multiplier, bonus]
	combo_label.modulate = Color(1.0, 0.95, 0.2, 1.0)
	combo_label.visible = true
	combo_tween = create_tween()
	combo_tween.tween_property(combo_label, "modulate:a", 0.0, 1.2)
	combo_tween.tween_callback(func(): combo_label.visible = false)

func show_message(text: String, duration: float = 2.0, color: Color = Color(0.25, 1.0, 0.45, 1.0)) -> void:
	if message_tween and message_tween.is_valid():
		message_tween.kill()
	
	message_label.text = text
	message_label.add_theme_color_override("font_color", color)
	message_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	message_label.scale = Vector2(0.85, 0.85)
	message_label.visible = true
	
	var fade_time: float = clamp(duration * 0.35, 0.35, 1.1)
	var hold_time: float = max(0.1, duration - fade_time - 0.18)
	
	message_tween = create_tween()
	message_tween.tween_property(message_label, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	message_tween.tween_interval(hold_time)
	message_tween.tween_property(message_label, "modulate:a", 0.0, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	message_tween.tween_callback(func(): message_label.visible = false)

func announce_level(level_num: int, duration: float = 2.7) -> void:
	if message_tween and message_tween.is_valid():
		message_tween.kill()
	
	var stage_idx := (level_num - 1) % HISTORICAL_STAGES.size()
	var stage_info: Dictionary = HISTORICAL_STAGES[stage_idx]
	message_label.text = "РІВЕНЬ %d: %s\n%s • (%s)" % [level_num, stage_info["loc"], stage_info.get("lore", "ГОТУЙСЯ, ДЖУРО!"), stage_info["epoch"]]
	message_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.22, 1.0))
	message_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	message_label.scale = Vector2(0.70, 0.70)
	message_label.visible = true
	
	var pop_time: float = 0.25
	var hold_time: float = max(0.4, duration * 0.45)
	var fade_time: float = max(0.65, duration - pop_time - hold_time)
	
	message_tween = create_tween()
	message_tween.tween_property(message_label, "scale", Vector2(1.0, 1.0), pop_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	message_tween.tween_interval(hold_time)
	# Smooth classic arcade fade-out in the center of the screen
	message_tween.tween_property(message_label, "modulate:a", 0.0, fade_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	message_tween.tween_callback(func(): message_label.visible = false)
