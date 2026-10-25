extends CanvasLayer

class_name JackHUD

signal profile_changed(age: String, exp_level: String)

@onready var score_label: Label = $Margin/HBox/ScoreBox/ScoreValue
@onready var highscore_label: Label = $Margin/HBox/HighscoreBox/HighscoreValue
@onready var bombs_label: Label = $Margin/HBox/BombsBox/BombsValue
@onready var profile_value_label: Label = get_node_or_null("Margin/HBox/ProfileBox/ProfileValue")
@onready var profile_overlay: Panel = get_node_or_null("ProfileOverlay")
@onready var status_label: Label = get_node_or_null("ProfileOverlay/VBox/StatusLabel")
@onready var btn_age_8_10: Button = get_node_or_null("ProfileOverlay/VBox/AgeHBox/BtnAge8_10")
@onready var btn_age_11_14: Button = get_node_or_null("ProfileOverlay/VBox/AgeHBox/BtnAge11_14")
@onready var btn_age_15_plus: Button = get_node_or_null("ProfileOverlay/VBox/AgeHBox/BtnAge15Plus")
@onready var btn_exp_novice: Button = get_node_or_null("ProfileOverlay/VBox/ExpHBox/BtnExpNovice")
@onready var btn_exp_casual: Button = get_node_or_null("ProfileOverlay/VBox/ExpHBox/BtnExpCasual")
@onready var btn_exp_master: Button = get_node_or_null("ProfileOverlay/VBox/ExpHBox/BtnExpMaster")
@onready var btn_apply: Button = get_node_or_null("ProfileOverlay/VBox/ActionHBox/BtnApply")
@onready var btn_cancel: Button = get_node_or_null("ProfileOverlay/VBox/ActionHBox/BtnCancel")

@onready var combo_label: Label = $ComboLabel
@onready var message_label: Label = $MessageLabel
@onready var combat_hint_label: Label = $CombatHintLabel

var combo_tween: Tween = null
var message_tween: Tween = null
var hint_tween: Tween = null
var hint_pulse_time: float = 0.0
var is_hint_active: bool = false
var is_showing_completion_flash: bool = false

var current_age: String = "11-14"
var current_exp: String = "casual"
var is_profile_dialog_open: bool = false

func _ready() -> void:
	if btn_age_8_10: btn_age_8_10.pressed.connect(func(): _select_age("8-10"))
	if btn_age_11_14: btn_age_11_14.pressed.connect(func(): _select_age("11-14"))
	if btn_age_15_plus: btn_age_15_plus.pressed.connect(func(): _select_age("15+"))
	if btn_exp_novice: btn_exp_novice.pressed.connect(func(): _select_exp("novice"))
	if btn_exp_casual: btn_exp_casual.pressed.connect(func(): _select_exp("casual"))
	if btn_exp_master: btn_exp_master.pressed.connect(func(): _select_exp("experienced"))
	if btn_apply: btn_apply.pressed.connect(_apply_profile)
	if btn_cancel: btn_cancel.pressed.connect(close_profile_dialog)
	_update_dialog_ui()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_P:
			toggle_profile_dialog()
			get_viewport().set_input_as_handled()
			return
		elif is_profile_dialog_open:
			match event.keycode:
				KEY_1:
					_select_age("8-10")
					get_viewport().set_input_as_handled()
				KEY_2:
					_select_age("11-14")
					get_viewport().set_input_as_handled()
				KEY_3:
					_select_age("15+")
					get_viewport().set_input_as_handled()
				KEY_4:
					_select_exp("novice")
					get_viewport().set_input_as_handled()
				KEY_5:
					_select_exp("casual")
					get_viewport().set_input_as_handled()
				KEY_6:
					_select_exp("experienced")
					get_viewport().set_input_as_handled()
				KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
					_apply_profile()
					get_viewport().set_input_as_handled()
				KEY_ESCAPE:
					close_profile_dialog()
					get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed and is_profile_dialog_open:
		if event.button_index == JOY_BUTTON_A:
			_apply_profile()
			get_viewport().set_input_as_handled()
		elif event.button_index == JOY_BUTTON_B:
			close_profile_dialog()
			get_viewport().set_input_as_handled()

func toggle_profile_dialog() -> void:
	if is_profile_dialog_open:
		close_profile_dialog()
	else:
		open_profile_dialog()

func open_profile_dialog() -> void:
	if not profile_overlay:
		return
	is_profile_dialog_open = true
	profile_overlay.visible = true
	get_tree().paused = true
	_update_dialog_ui()

func close_profile_dialog() -> void:
	if not profile_overlay:
		return
	is_profile_dialog_open = false
	profile_overlay.visible = false
	get_tree().paused = false

func _select_age(age: String) -> void:
	current_age = age
	_update_dialog_ui()

func _select_exp(exp_level: String) -> void:
	current_exp = exp_level
	_update_dialog_ui()

func _update_dialog_ui() -> void:
	var exp_ukr := "Звичайний"
	var target_p := "70%"
	match current_exp:
		"novice":
			exp_ukr = "Новачок"
			target_p = "78%"
		"experienced":
			exp_ukr = "Бувалий"
			target_p = "62%"

	if status_label:
		status_label.text = "Обрано: %s років | %s (ціль успіху: %s)" % [current_age, exp_ukr, target_p]
	
	if btn_age_8_10: btn_age_8_10.modulate = Color(1.3, 1.3, 1.0) if current_age == "8-10" else Color(0.7, 0.7, 0.7)
	if btn_age_11_14: btn_age_11_14.modulate = Color(1.3, 1.3, 1.0) if current_age == "11-14" else Color(0.7, 0.7, 0.7)
	if btn_age_15_plus: btn_age_15_plus.modulate = Color(1.3, 1.3, 1.0) if current_age == "15+" else Color(0.7, 0.7, 0.7)

	if btn_exp_novice: btn_exp_novice.modulate = Color(1.3, 1.3, 1.0) if current_exp == "novice" else Color(0.7, 0.7, 0.7)
	if btn_exp_casual: btn_exp_casual.modulate = Color(1.3, 1.3, 1.0) if current_exp == "casual" else Color(0.7, 0.7, 0.7)
	if btn_exp_master: btn_exp_master.modulate = Color(1.3, 1.3, 1.0) if current_exp == "experienced" else Color(0.7, 0.7, 0.7)

func _apply_profile() -> void:
	update_profile_display(current_age, current_exp)
	profile_changed.emit(current_age, current_exp)
	close_profile_dialog()
	show_message("ПРОФІЛЬ ЗБЕРЕЖЕНО: %s | %s" % [current_age, current_exp], 2.2, Color(0.4, 1.0, 0.5))

func update_profile_display(age: String, exp_level: String) -> void:
	current_age = age
	current_exp = exp_level
	var exp_short := "ЗВИЧАЙНИЙ"
	match exp_level:
		"novice": exp_short = "НОВАЧОК"
		"experienced": exp_short = "БУВАЛИЙ"
	if profile_value_label:
		profile_value_label.text = "%s | %s" % [age, exp_short]
	_update_dialog_ui()

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
	combat_hint_label.text = "ОСВОЄНО: %s!" % completed_title
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
