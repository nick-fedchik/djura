extends CanvasLayer

class_name StoryCardsOverlay

signal story_finished

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var text_label: Label = $Panel/VBox/TextLabel
@onready var prompt_label: Label = $Panel/VBox/PromptLabel
@onready var visual_node: Control = $Panel/VBox/VisualArea

var current_level: int = 1
var current_slide_idx: int = 0
var slides: Array = []
var time_passed: float = 0.0
var is_active: bool = false
var mentor_texture: Texture2D = null
var qirimli_texture: Texture2D = null
var slide_meeting_texture: Texture2D = null
var slide_pledge_texture: Texture2D = null
var slide_mission_texture: Texture2D = null

# Pre-defined cartoon slide stories for levels
const LEVEL_STORIES: Dictionary = {
	1: [
		{
			"title": "ЗУСТРІЧ З НАСТАВНИКОМ-ХАРАКТЕРНИКОМ",
			"text": "Над сивим Дніпром біля стародавнього дуба сидить мудрий Козак-Характерник. Побачивши юнака з гарячим серцем і палаючим поглядом, старий майстер мовить:\n«Бачу в тобі лицарську душу, хлопче! Нечисть суне на нашу землю, прагнучи знищити Січ і спокій України. Чи маєш відвагу стати козацьким Джурою і пізнати таємниці характерництва?»",
			"visual": "mentor_meeting"
		},
		{
			"title": "ВИБІР СЕРЦЯ: «Я ГОТОВИЙ БУТИ ДЖУРОЮ!»",
			"text": "Хлопчик без вагань схиляє голову, притискає правицю до грудей і дає щиру козацьку обітницю:\n«Я готовий, батьку-наставнику! Моє серце б'ється для рідної землі. Прийми мене за джуру — я вірно служитиму Січі й боронитиму край від темряви!»\nХарактерник благословляє його, оперізує золотим кушаком та нарікає Джурою.",
			"visual": "dzhura_pledge"
		},
		{
			"title": "НАКАЗ НАСТАВНИКА: БОМБИ ТА ЧЕРГА ВОРОГІВ",
			"text": "Характерник наставляє нового Джуру:\n«Темні сили розкидали по високих помостах вибухові ядра-бомби! Твоє завдання — зібрати їх усі, поки не здетонували!\nСтережися Нечисті: спочатку вийде підступний Вогник, що підпалює ґноти. Через два рівні приєднається хитрий Чортик, а ще через два — небезпечна Відьма з чарами. Захисти Січ, Джуро!»",
			"visual": "mission_briefing"
		}
	],
	2: [
		{
			"title": "УРОК РІВНОВАГИ ТА ШВИДКИЙ ВОГНИК",
			"text": "Вогник розлютився і став на 10% швидшим та спритнішим! Він метається по помостах і намагається підпалити порохові ґноти ще хутчіше.",
			"visual": "cossack_scroll"
		},
		{
			"title": "ГАСІННЯ ПІДПАЛЕНИХ ЯДЕР",
			"text": "Якщо підступний Вогник торкнеться бомби — ґніт засичить і почне танути! Встигни дістатися палаючого ядра за 4 секунди, щоб знешкодити його до вибуху!",
			"visual": "chumak_cart"
		},
		{
			"title": "НАСТАВНИК: УРОК 2 — КРИЛАТА КИРЕЯ ТА ВІРА",
			"text": "Біля вечірнього вогнища Характерник наставляє:\n«Не бійся висоти, Джуро! Коли земля йде з-під ніг — розправляй крилату кирею. Відчувай вітер і тримай спокій у серці — тоді жоден вогонь тебе не дістане!»",
			"visual": "mentor_portrait"
		}
	],
	3: [
		{
			"title": "ПОЯВА ХИТРОГО ЧОРТИКА-БЕШКЕТНИКА!",
			"text": "Як і попереджав Наставник, через два рівні до Вогника приєднався хитрий Чортик! Рогатий бешкетник скаче по ярусах, скидає бомби та розкидає липку смолу!",
			"visual": "chort_steal"
		},
		{
			"title": "ПІДСТУПНИЙ ТАНДЕМ НЕЧИСТІ",
			"text": "Чортик відволікає Джуру та перевертає помости, поки Вогник шукає нові бомби. Проти них потрібна козацька кмітливість та бойова виправка!",
			"visual": "fortress_cannon"
		},
		{
			"title": "НАСТАВНИК: УРОК 3 — ПЕРШІ БОЙОВІ УДАРИ",
			"text": "Наставник навчає Джуру козацького бою:\n«Час пустити в хід кулаки! Натискай кнопку удару: прямий сталевий джеб зупиняє Чортика, а високий удар ногою «Тинок» відкидає нечисть геть від бомб!»",
			"visual": "mentor_portrait"
		}
	],
	4: [
		{
			"title": "НАВАЛА НЕЧИСТІ НА ВЕРХНІХ ЯРУСАХ",
			"text": "Чортики зграєю обсіли дзвіницю Січі! Вони стають спритнішими й виставляють засідки на тонких перекладинах.",
			"visual": "baturyn_palace"
		},
		{
			"title": "ПАРКУРНИЙ ПЕРЕКАТ ТА АЕРОБАТИКА",
			"text": "Приземляючись із високих балок на бігу, Джура групується в щільний паркурний перекат, зберігаючи швидкість і не втрачаючи жодної секунди!",
			"visual": "moskal_invaders"
		},
		{
			"title": "НАСТАВНИК: УРОК 4 — ПОВІТРЯНИЙ ЩУПАК ТА ПОВЗУНЕЦЬ",
			"text": "Характерник демонструє верхові прийоми:\n«У повітрі бий подвійною різножкою «Щупак», а внизу підсікай Чортиків косою-«Повзунцем»! Не дай ворогу наблизитися до бочок із порохом!»",
			"visual": "mentor_portrait"
		}
	],
	5: [
		{
			"title": "ФІНАЛ ЕТАПУ 1: ПОЯВА ВІДЬМИ СОЛОХИ!",
			"text": "Ось і головна загроза першого етапу: на мітлі прилетіла підступна Відьма Солоха! Вона затуляє місяць чорними хмарами та огортає нечисть магічними щитами!",
			"visual": "vidma_sky"
		},
		{
			"title": "ВИРІШАЛЬНИЙ БІЙ ЗА ЗАПОРОЗЬКУ СІЧ",
			"text": "Вогник палає на повну, Чортики крутять веремію, а Відьма насилає вихори! Джура має зібрати всі бомби на Січі та здолати ворожу навалу!",
			"visual": "perekop_gate"
		},
		{
			"title": "НАСТАВНИК: ТРІУМФ НА СІЧІ ТА ПОГЛЯД НА ПІВДЕНЬ",
			"text": "Відьму розвіяно ранковим світлом, Січ урятовано! Джура танцює повний Переможний Гопак! Наставник гордо мовить:\n«Ти справжній козак, Джуро! Січ очищено, але розбита нечисть утекла на Південь. Там починається наш Етап 2 — Крим, де на тебе чекає вірний побратим Киримли!»",
			"visual": "mentor_portrait"
		}
	],
	6: [
		{
			"title": "КАЗКА 6: ХАНСЬКИЙ БАХЧИСАРАЙ ТА ПЕЧЕРНИЙ АЖДАХА",
			"text": "Сонце золотить стрункі мінарети Хан-Сараю, Соколину вежу та скелі Чуфут-Кале! У печерах прокинувся добродушний дракончик Аждаха, а із Сиваша підкрадаються Соляні Джинни!",
			"visual": "perekop_gate"
		},
		{
			"title": "ЗОЛОТА ТАРАК-ТАМГА ТА ТУГАЙ-БЕЙ",
			"text": "Перекопський Тугай-Бей та їгіти з бойовими соколами стають пліч-о-пліч із Джурою: «Захистимо Бахчисарай від найманців і покажемо силу степового братства!»",
			"visual": "cossack_crimean_union"
		},
		{
			"title": "ТАНЕЦЬ ХАЙТАРМА ПІД БАХЧИСАРАЄМ",
			"text": "Збери всі 24 ядра над терасами Ханського палацу, і юний Киримли заграє запальну Хайтарму на честь перемоги!",
			"visual": "grand_fireworks"
		}
	],
	7: [
		{
			"title": "КАЗКА 7: КОНОТОПСЬКА ПЕРЕПРАВА ТА КАРПАТСЬКИЙ ЧУГАЙСТЕР",
			"text": "На Соснівських болотах під Конотопом до Козаків та Киримли приєднується карпатський велетень Чугайстер та благородні Побратими-Литвини під стягом «Погоні»!",
			"visual": "kamianets_towers"
		},
		{
			"title": "ПРОТИ ОПРИЧНИКІВ ТА ЦАРСЬКОГО ДЯКА",
			"text": "Царський приказний дяк із безкінечним сувоєм та опричники з мітлами грузнуть у конотопській багнюці під сміх Чугайстра та влучні стріли союзників!",
			"visual": "moskal_retreat"
		},
		{
			"title": "ВПЕРЕД ДО СЛАВИ ЧОТИРЬОХ НАРОДІВ!",
			"text": "Від Конотопа до Стародавнього Полоцька, Чорногори й Тарасової Гори — очистимо рідний край від загарбників та потвор!",
			"visual": "grand_fireworks"
		}
	],
	8: [
		{
			"title": "КАЗКА 8: СТАРОДАВНІЙ ПОЛОЦЬК ТА ЛІСОВИЙ БАГНИК",
			"text": "Полоцькі собори над Двіною та дрімучі пущі Литвинів! Тут у чорних драговинах ховається підступний Багник, а царські карателі намагаються спалити літописні пергаменти!",
			"visual": "kamianets_towers"
		},
		{
			"title": "СТЯГ «ПОГОНІ» ТА ЧАРОДІЙ ВСЕСЛАВ",
			"text": "Шляхетні литвинські лицарі із срібними мечами та лісовий Чародій Всеслав розганяють темряву сяйвом Цвіту Папороті!",
			"visual": "cossack_crimean_union"
		},
		{
			"title": "НАСТАВНИК: УРОК 8 — ПІВНІЧНИЙ СОЮЗ ВОЛІ",
			"text": "Козак-Шабельник надихає воїнів:\n«Полоцьк і Січ стоять на варті спільної свободи! Не дамо багняним потворам затьмарити правду нашої землі!»",
			"visual": "mentor_portrait"
		}
	],
	9: [
		{
			"title": "КАЗКА 9: ЧОРНОГОРА ТА СЕРЦЕ КАРПАТ",
			"text": "Скелі Довбуша та вершина гори Піп-Іван! Тут серед грозових хмар Арідника гупають дикі Песиголовці, а хитрий Щезник намагається викрасти полонинські ядра!",
			"visual": "kamianets_towers"
		},
		{
			"title": "ВАТАЖОК ОЛЕКСА ДОВБУШ ТА ТАНОК «АРКАН»",
			"text": "Олекса Довбуш із золотою барткою та юний Гуцулик грають на трембітах! Чугайстер пускається в танець, скидаючи песиголовців із кам'яних круч!",
			"visual": "cossack_scroll"
		},
		{
			"title": "НАСТАВНИК: УРОК 9 — ЛИЦАРСЬКА СИЛА ГІР",
			"text": "Радник вручає Джурі пояс-черес:\n«Хто подолав карпатські вітри та громовиці Арідника — той готовий до фінального бою за волю всіх народів!»",
			"visual": "mentor_portrait"
		}
	],
	10: [
		{
			"title": "КАЗКА 10: ЗОЛОТІ ВОРОТА КИЄВА — ВЕЛИКИЙ ФІНАЛ",
			"text": "Золоті бані стародавнього Києва! До Золотих Воріт прикотили важку чавунну Цар-Мортиру, яку охороняє Лихо Однооке та заліський воєвода!",
			"visual": "baturyn_palace"
		},
		{
			"title": "БРАТСТВО ЧОТИРЬОХ НАРОДІВ ТРІУМФУЄ",
			"text": "Козаки на чайках, кримськотатарські вершники з соколами, гуцульські опришки з бартками та литвини розбивають мортиру вщент! Загарбники тікають без оглядки!",
			"visual": "moskal_retreat"
		},
		{
			"title": "НАСТАВНИК: УРОК 10 — ВІЧНА СЛАВА ПЕРЕМОГИ",
			"text": "Козак-Шабельник підіймає золотий кубок:\n«Слава вільному братству вільних людей! На оновленій землі врага не буде, а буде син, і буде мати, і будуть люде на землі!»",
			"visual": "mentor_portrait"
		}
	]
}

func _ready() -> void:
	visible = false
	if ResourceLoader.exists("res://assets/sprites/mentor_portrait.png"):
		mentor_texture = load("res://assets/sprites/mentor_portrait.png")
	if ResourceLoader.exists("res://assets/sprites/qirimli_portrait.png"):
		qirimli_texture = load("res://assets/sprites/qirimli_portrait.png")
	if ResourceLoader.exists("res://assets/sprites/story/slide_level1_1_meeting.png"):
		slide_meeting_texture = load("res://assets/sprites/story/slide_level1_1_meeting.png")
	if ResourceLoader.exists("res://assets/sprites/story/slide_level1_2_pledge.png"):
		slide_pledge_texture = load("res://assets/sprites/story/slide_level1_2_pledge.png")
	if ResourceLoader.exists("res://assets/sprites/story/slide_level1_3_mission.png"):
		slide_mission_texture = load("res://assets/sprites/story/slide_level1_3_mission.png")
	if visual_node:
		visual_node.draw.connect(_on_visual_draw)

func _process(delta: float) -> void:
	if not is_active:
		return
	time_passed += delta
	if visual_node:
		visual_node.queue_redraw()

func _input(event: InputEvent) -> void:
	if not is_active:
		return
	if event.is_action_pressed("jump") or event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE) or (event is InputEventJoypadButton and event.pressed and (event.button_index == JOY_BUTTON_A or event.button_index == JOY_BUTTON_X)):
		_next_slide()
		get_viewport().set_input_as_handled()
	elif (event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.keycode == KEY_F)) or (event is InputEventJoypadButton and event.pressed and (event.button_index == JOY_BUTTON_START or event.button_index == JOY_BUTTON_BACK or event.button_index == JOY_BUTTON_B)):
		# Skip entire story
		_finish_story()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		_next_slide()
		get_viewport().set_input_as_handled()

func has_story_for_level(lvl: int) -> bool:
	return LEVEL_STORIES.has(lvl) and not LEVEL_STORIES[lvl].is_empty()

func show_story_for_level(lvl: int) -> void:
	current_level = lvl
	slides = LEVEL_STORIES.get(lvl, [])
	if slides.is_empty():
		is_active = false
		visible = false
		if get_tree():
			get_tree().paused = false
		call_deferred("emit_signal", "story_finished")
		return
	
	current_slide_idx = 0
	is_active = true
	visible = true
	time_passed = 0.0
	_display_current_slide()
	
	if DisplayServer.get_name() != "headless":
		if get_tree():
			get_tree().paused = true

func _display_current_slide() -> void:
	if current_slide_idx >= slides.size():
		_finish_story()
		return
	
	var data: Dictionary = slides[current_slide_idx]
	title_label.text = data["title"]
	text_label.text = data["text"]
	prompt_label.text = "КРОК %d з %d  |  [ ПРОБІЛ / ENTER / A на геймпаді ] - ДАЛІ  |  [ ESC / START ] - ПРОПУСТИТИ" % [current_slide_idx + 1, slides.size()]
	if visual_node:
		visual_node.queue_redraw()

func _next_slide() -> void:
	current_slide_idx += 1
	if current_slide_idx >= slides.size():
		_finish_story()
	else:
		_display_current_slide()

func _finish_story() -> void:
	is_active = false
	visible = false
	if get_tree():
		get_tree().paused = false
	story_finished.emit()

func _on_visual_draw() -> void:
	if not is_active or current_slide_idx >= slides.size():
		return
	var v_type: String = slides[current_slide_idx].get("visual", "")
	var size := visual_node.size
	var center := size * 0.5
	
	# Background frame
	visual_node.draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.12, 0.22), true)
	visual_node.draw_rect(Rect2(Vector2.ZERO, size), Color(0.85, 0.70, 0.22), false, 2.5) # Gold frame
	
	match v_type:
		"mentor_meeting":
			_draw_mentor_meeting(center)
		"dzhura_pledge":
			_draw_dzhura_pledge(center)
		"mission_briefing":
			_draw_mission_briefing(center)
		"sich_apple":
			_draw_sich_apple(center)
		"chort_steal":
			_draw_chort_steal(center)
		"mamay_gift":
			_draw_mamay_gift(center)
		"cossack_scroll":
			_draw_cossack_scroll(center)
		"chumak_cart":
			_draw_chumak_cart(center)
		"vidma_sky":
			_draw_vidma_sky(center)
		"vakula_anvil":
			_draw_vakula_anvil(center)
		"kamianets_towers":
			_draw_kamianets_towers(center)
		"qirimli_ally":
			_draw_qirimli_ally(center)
		"fortress_cannon":
			_draw_fortress_cannon(center)
		"baturyn_palace":
			_draw_baturyn_palace(center)
		"moskal_invaders":
			_draw_moskal_invaders(center)
		"cossack_crimean_union":
			_draw_cossack_crimean_union(center)
		"perekop_gate":
			_draw_perekop_gate(center)
		"moskal_retreat":
			_draw_moskal_retreat(center)
		"grand_fireworks":
			_draw_grand_fireworks(center)
		"mentor_portrait":
			_draw_mentor_portrait(center)

# --- Cartoon procedural illustrations ---

func _draw_mentor_meeting(c: Vector2) -> void:
	if slide_meeting_texture != null:
		var rect := Rect2(Vector2.ZERO, visual_node.size)
		visual_node.draw_texture_rect(slide_meeting_texture, rect, false)
		return
	# Deep night sky over the Dnipro
	visual_node.draw_rect(Rect2(0, 0, visual_node.size.x, visual_node.size.y), Color(0.06, 0.09, 0.16))
	
	# Twinkling stars
	for i in range(12):
		var sx := fposmod(float(i * 31 + 17), visual_node.size.x)
		var sy := fposmod(float(i * 23 + 11), visual_node.size.y * 0.45)
		var st_pulse := 0.4 + 0.6 * sin(time_passed * 4.0 + float(i))
		visual_node.draw_circle(Vector2(sx, sy), 1.6, Color(1.0, 0.95, 0.7, st_pulse))
	
	# Ancient oak tree silhouette on the left
	var oak_pts := PackedVector2Array([
		Vector2(0, visual_node.size.y), Vector2(35, c.y - 10), Vector2(50, c.y - 45),
		Vector2(20, c.y - 75), Vector2(70, c.y - 55), Vector2(100, c.y - 80),
		Vector2(90, c.y - 40), Vector2(65, c.y), Vector2(70, visual_node.size.y)
	])
	visual_node.draw_colored_polygon(oak_pts, Color(0.03, 0.05, 0.08))
	
	# Warm golden campfire in center
	var glow := 0.28 + 0.08 * sin(time_passed * 6.0)
	visual_node.draw_circle(Vector2(c.x, c.y + 25), 65.0, Color(1.0, 0.50, 0.12, glow))
	visual_node.draw_circle(Vector2(c.x, c.y + 25), 32.0, Color(1.0, 0.85, 0.25, 0.45))
	# Campfire logs
	visual_node.draw_line(Vector2(c.x - 18, c.y + 36), Vector2(c.x + 18, c.y + 28), Color(0.25, 0.14, 0.08), 5.0)
	visual_node.draw_line(Vector2(c.x + 16, c.y + 36), Vector2(c.x - 16, c.y + 28), Color(0.30, 0.16, 0.10), 5.0)
	# Flickering flame
	var fl_h := 18.0 + sin(time_passed * 15.0) * 4.0
	visual_node.draw_colored_polygon(PackedVector2Array([
		Vector2(c.x - 10, c.y + 30), Vector2(c.x, c.y + 30 - fl_h), Vector2(c.x + 10, c.y + 30)
	]), Color(1.0, 0.65, 0.15))
	visual_node.draw_colored_polygon(PackedVector2Array([
		Vector2(c.x - 5, c.y + 30), Vector2(c.x, c.y + 34 - fl_h), Vector2(c.x + 5, c.y + 30)
	]), Color(1.0, 0.92, 0.40))
	
	# Wise Mentor sitting on the left
	var m_pos := c + Vector2(-65, 20)
	# Torso & Blue Zhupan
	visual_node.draw_colored_polygon(PackedVector2Array([
		m_pos + Vector2(-22, -18), m_pos + Vector2(18, -18),
		m_pos + Vector2(12, 16), m_pos + Vector2(-16, 16)
	]), Color(0.14, 0.32, 0.65))
	# Crossed sharovary legs
	visual_node.draw_colored_polygon(PackedVector2Array([
		m_pos + Vector2(-24, 14), m_pos + Vector2(24, 14),
		m_pos + Vector2(18, 26), m_pos + Vector2(-18, 26)
	]), Color(0.78, 0.12, 0.16))
	# Head with silver mustache & оселедець
	var mh := m_pos + Vector2(0, -28)
	visual_node.draw_circle(mh, 9.5, Color(0.92, 0.78, 0.65))
	# Long Cossack mustache
	visual_node.draw_line(mh + Vector2(-1, 2), mh + Vector2(-12, 8), Color(0.92, 0.92, 0.96), 2.5)
	visual_node.draw_line(mh + Vector2(1, 2), mh + Vector2(12, 8), Color(0.92, 0.92, 0.96), 2.5)
	# Silver hair оселедець
	visual_node.draw_line(mh + Vector2(0, -9), mh + Vector2(-12, -14), Color(0.92, 0.92, 0.96), 3.0)
	# Extended welcoming hand pointing to young boy
	visual_node.draw_line(m_pos + Vector2(14, -6), m_pos + Vector2(36, -2), Color(0.14, 0.32, 0.65), 5.0)
	visual_node.draw_circle(m_pos + Vector2(37, -2), 3.5, Color(0.92, 0.78, 0.65))
	
	# Young prospective boy standing attentively on the right
	var b_pos := c + Vector2(62, 14)
	# Simple village shirt & brown trousers
	visual_node.draw_rect(Rect2(b_pos.x - 7, b_pos.y - 12, 14, 22), Color(0.88, 0.90, 0.95)) # shirt
	visual_node.draw_line(b_pos + Vector2(-3, 10), b_pos + Vector2(-4, 28), Color(0.42, 0.28, 0.16), 4.5) # leg L
	visual_node.draw_line(b_pos + Vector2(3, 10), b_pos + Vector2(4, 28), Color(0.42, 0.28, 0.16), 4.5) # leg R
	# Young head with brown forelock, looking up with awe
	var bh := b_pos + Vector2(0, -20)
	visual_node.draw_circle(bh, 8.5, Color(0.94, 0.80, 0.68))
	visual_node.draw_circle(bh + Vector2(-2, -1), 1.8, Color(0.15, 0.12, 0.12)) # eager eye
	visual_node.draw_line(bh + Vector2(-6, -7), bh + Vector2(4, -9), Color(0.35, 0.22, 0.14), 3.0) # hair

func _draw_dzhura_pledge(c: Vector2) -> void:
	if slide_pledge_texture != null:
		var rect := Rect2(Vector2.ZERO, visual_node.size)
		visual_node.draw_texture_rect(slide_pledge_texture, rect, false)
		return
	# Twilight hill with glowing golden aura
	visual_node.draw_rect(Rect2(0, 0, visual_node.size.x, visual_node.size.y), Color(0.08, 0.06, 0.14))
	
	# Golden celestial blessing glow
	var aura_pulse := 1.0 + sin(time_passed * 5.0) * 0.12
	visual_node.draw_circle(Vector2(c.x, c.y - 10), 80.0 * aura_pulse, Color(1.0, 0.85, 0.25, 0.18))
	visual_node.draw_circle(Vector2(c.x, c.y - 10), 45.0, Color(0.2, 0.75, 1.0, 0.22))
	
	# Floating Cossack Kyreya wing-cape in center
	var k_pos := c + Vector2(0, -18 + sin(time_passed * 4.0) * 4.0)
	var cape_pts := PackedVector2Array([
		k_pos + Vector2(-26, 12), k_pos + Vector2(0, -15), k_pos + Vector2(26, 12),
		k_pos + Vector2(16, 20), k_pos + Vector2(0, 10), k_pos + Vector2(-16, 20)
	])
	visual_node.draw_colored_polygon(cape_pts, Color(0.10, 0.38, 0.85))
	visual_node.draw_polyline(cape_pts, Color(1.0, 0.85, 0.25), 2.2)
	
	# Golden sash ribbon
	visual_node.draw_line(k_pos + Vector2(-14, 18), k_pos + Vector2(14, 18), Color(0.98, 0.84, 0.18), 3.5)
	
	# Mentor on the left raising hand in blessing
	var m_pos := c + Vector2(-70, 18)
	visual_node.draw_colored_polygon(PackedVector2Array([
		m_pos + Vector2(-16, -18), m_pos + Vector2(14, -18),
		m_pos + Vector2(10, 16), m_pos + Vector2(-14, 16)
	]), Color(0.14, 0.32, 0.65))
	var mh := m_pos + Vector2(0, -28)
	visual_node.draw_circle(mh, 9.5, Color(0.92, 0.78, 0.65))
	visual_node.draw_line(mh + Vector2(1, 2), mh + Vector2(12, 8), Color(0.92, 0.92, 0.96), 2.5) # mustache
	# Blessing arm raised
	visual_node.draw_line(m_pos + Vector2(10, -10), m_pos + Vector2(30, -26), Color(0.14, 0.32, 0.65), 4.5)
	visual_node.draw_circle(m_pos + Vector2(31, -27), 3.5, Color(0.92, 0.78, 0.65))
	
	# Young Djura on the right taking oath: hand over heart!
	_draw_story_dzhura(c + Vector2(65, 20), -1.0, "horseshoe")

func _draw_mission_briefing(c: Vector2) -> void:
	if slide_mission_texture != null:
		var rect := Rect2(Vector2.ZERO, visual_node.size)
		visual_node.draw_texture_rect(slide_mission_texture, rect, false)
		return
	# Night fortress silhouette & wooden platforms
	visual_node.draw_rect(Rect2(0, 0, visual_node.size.x, visual_node.size.y), Color(0.07, 0.08, 0.12))
	
	# Defensive platforms of Sich
	visual_node.draw_rect(Rect2(20, c.y + 20, 340, 10), Color(0.38, 0.24, 0.14)) # main beam
	visual_node.draw_line(Vector2(20, c.y + 20), Vector2(360, c.y + 20), Color(0.60, 0.42, 0.22), 2.0)
	visual_node.draw_rect(Rect2(80, c.y - 35, 220, 8), Color(0.38, 0.24, 0.14)) # upper beam
	visual_node.draw_line(Vector2(80, c.y - 35), Vector2(300, c.y - 35), Color(0.60, 0.42, 0.22), 2.0)
	
	# Powder Bombs sitting on platforms
	var b1 := Vector2(c.x - 60, c.y + 11)
	visual_node.draw_circle(b1, 9.0, Color(0.12, 0.12, 0.15))
	visual_node.draw_circle(b1 + Vector2(-2, -3), 2.5, Color(0.4, 0.4, 0.5, 0.6)) # shine
	
	var b2 := Vector2(c.x + 50, c.y - 43)
	visual_node.draw_circle(b2, 9.0, Color(0.12, 0.12, 0.15))
	visual_node.draw_circle(b2 + Vector2(-2, -3), 2.5, Color(0.4, 0.4, 0.5, 0.6))
	
	# Center bomb with burning sparkling fuse!
	var b_center := Vector2(c.x, c.y + 11)
	visual_node.draw_circle(b_center, 10.0, Color(0.15, 0.14, 0.18))
	visual_node.draw_circle(b_center + Vector2(-3, -3), 2.8, Color(0.5, 0.5, 0.6, 0.7))
	# Burning wick
	var wick_end := b_center + Vector2(6, -14)
	visual_node.draw_line(b_center + Vector2(2, -8), wick_end, Color(0.6, 0.4, 0.2), 2.0)
	# Sparking fire
	var spk_pulse := 1.0 + sin(time_passed * 24.0) * 0.3
	visual_node.draw_circle(wick_end, 5.0 * spk_pulse, Color(1.0, 0.85, 0.2))
	visual_node.draw_circle(wick_end, 2.5, Color.WHITE)
	for s in range(4):
		var sa := time_passed * 16.0 + float(s) * (PI * 0.5)
		visual_node.draw_line(wick_end, wick_end + Vector2(cos(sa), sin(sa)) * 8.0, Color(1.0, 0.5, 0.1), 1.5)
	
	# Sneaky Vohnyk flame spirit sneaking up on the left beam!
	var v_pos := Vector2(c.x - 110 + sin(time_passed * 6.0) * 6.0, c.y + 11)
	# Flame body
	visual_node.draw_circle(v_pos, 11.0, Color(1.0, 0.45, 0.10))
	visual_node.draw_circle(v_pos + Vector2(2, -2), 7.0, Color(1.0, 0.82, 0.22))
	# Glowing ember eyes
	visual_node.draw_circle(v_pos + Vector2(4, -3), 2.2, Color(0.12, 0.05, 0.02))
	visual_node.draw_circle(v_pos + Vector2(4, -3), 1.0, Color(1.0, 0.95, 0.4))
	# Flame tail flick
	var tail_x := v_pos.x - 12.0 - sin(time_passed * 18.0) * 4.0
	visual_node.draw_colored_polygon(PackedVector2Array([
		v_pos + Vector2(-6, -4), Vector2(tail_x, v_pos.y - 12), v_pos + Vector2(-4, 6)
	]), Color(1.0, 0.35, 0.05))
	
	# Looming shadows of Chortik and Vidma in background clouds
	var chort_eye := Vector2(c.x + 120, c.y - 65)
	visual_node.draw_circle(chort_eye, 2.2, Color(1.0, 0.2, 0.2, 0.75))
	visual_node.draw_circle(chort_eye + Vector2(8, 0), 2.2, Color(1.0, 0.2, 0.2, 0.75))
	# Little horns
	visual_node.draw_line(chort_eye + Vector2(-1, -3), chort_eye + Vector2(-4, -9), Color(0.2, 0.15, 0.25, 0.8), 2.0)
	visual_node.draw_line(chort_eye + Vector2(9, -3), chort_eye + Vector2(12, -9), Color(0.2, 0.15, 0.25, 0.8), 2.0)


func _draw_mentor_portrait(c: Vector2) -> void:
	# Campfire night atmosphere background
	visual_node.draw_rect(Rect2(0, 0, visual_node.size.x, visual_node.size.y), Color(0.08, 0.05, 0.07))
	
	# Warm campfire glow in background
	var glow_alpha := 0.22 + 0.08 * sin(time_passed * 5.0)
	visual_node.draw_circle(Vector2(c.x, c.y + 40), 120.0, Color(1.0, 0.45, 0.1, glow_alpha))
	
	# Sparks rising from campfire
	for i in range(7):
		var sp_seed := float(i) * 1.618
		var sp_y := fposmod(c.y + 70.0 - (time_passed * 40.0 + sp_seed * 30.0), 160.0)
		var sp_x := c.x + sin(time_passed * 3.0 + sp_seed) * 60.0
		visual_node.draw_circle(Vector2(sp_x, c.y + 80.0 - sp_y), 2.0, Color(1.0, 0.8, 0.2, 0.75))

	if mentor_texture:
		var tex_h := 170.0
		var tex_w := 170.0
		var rect := Rect2(c.x - tex_w * 0.5, c.y - tex_h * 0.5 - 10.0, tex_w, tex_h)
		# Cossack golden ornamental border
		visual_node.draw_rect(rect.grow(5), Color(0.85, 0.70, 0.22), true)
		visual_node.draw_rect(rect.grow(2), Color(0.06, 0.04, 0.10), true)
		visual_node.draw_texture_rect(mentor_texture, rect, false)
	else:
		_draw_mamay_gift(c)

func _draw_sich_apple(c: Vector2) -> void:
	# Blue sky & wooden palisade of Zaporozhian Sich
	visual_node.draw_rect(Rect2(0, c.y + 42, 380, 78), Color(0.18, 0.12, 0.08))
	for p in range(10, 380, 22):
		var h_top := c.y - 12.0 - float((p / 22) % 2) * 6.0
		visual_node.draw_rect(Rect2(p - 6, h_top, 12, c.y + 42 - h_top), Color(0.35, 0.22, 0.12))
		visual_node.draw_colored_polygon(PackedVector2Array([
			Vector2(p - 6, h_top), Vector2(p + 6, h_top), Vector2(p, h_top - 10)
		]), Color(0.45, 0.28, 0.15))
	
	# Юний 15-річний козак-Джура (без вусів, зі справжнім оселедцем-айдаром, у вишиванці, шароварах і сап'янцях)
	var d_pos := c + Vector2(-25, 22)
	_draw_story_dzhura(d_pos, 1.0, "apple")

func _draw_chort_steal(c: Vector2) -> void:
	# Night ground
	visual_node.draw_rect(Rect2(0, c.y + 40, 380, 80), Color(0.06, 0.08, 0.14))
	
	# Chort tiptoeing with burning cannonball
	var ch_pos := c + Vector2(sin(time_passed * 5.0) * 8.0, 10)
	var bob := sin(time_passed * 12.0) * 4.0
	
	# Chort body & legs in tiptoe sneak
	visual_node.draw_circle(ch_pos + Vector2(0, bob), 15.0, Color(0.18, 0.15, 0.22))
	# Tiptoe legs
	visual_node.draw_line(ch_pos + Vector2(-6, 12 + bob), ch_pos + Vector2(-12, 26 + bob), Color(0.18, 0.15, 0.22), 3.0)
	visual_node.draw_line(ch_pos + Vector2(6, 12 + bob), ch_pos + Vector2(14, 28 + bob), Color(0.18, 0.15, 0.22), 3.0)
	# Hooves
	visual_node.draw_circle(ch_pos + Vector2(-12, 26 + bob), 2.5, Color(0.4, 0.2, 0.1))
	visual_node.draw_circle(ch_pos + Vector2(14, 28 + bob), 2.5, Color(0.4, 0.2, 0.1))
	
	# Snout & sticking out tongue!
	visual_node.draw_circle(ch_pos + Vector2(8, 2 + bob), 5.0, Color(0.9, 0.5, 0.6))
	# Red sticking out tongue (comic tease)
	visual_node.draw_line(ch_pos + Vector2(12, 4 + bob), ch_pos + Vector2(18, 8 + bob), Color(1.0, 0.2, 0.3), 3.0)
	
	# Sly Eyes & Horns
	visual_node.draw_circle(ch_pos + Vector2(5, -4 + bob), 3.5, Color(1.0, 0.85, 0.1))
	visual_node.draw_circle(ch_pos + Vector2(6, -4 + bob), 1.5, Color.BLACK)
	visual_node.draw_line(ch_pos + Vector2(-6, -10 + bob), ch_pos + Vector2(-12, -22 + bob), Color(0.7, 0.2, 0.2), 3.0)
	visual_node.draw_line(ch_pos + Vector2(6, -10 + bob), ch_pos + Vector2(12, -22 + bob), Color(0.7, 0.2, 0.2), 3.0)
	
	# Burning Cannonball held in claws!
	var bomb_pos := ch_pos + Vector2(30, -6 + bob)
	visual_node.draw_circle(bomb_pos, 13.0, Color(0.15, 0.15, 0.18))
	visual_node.draw_circle(bomb_pos + Vector2(-3, -3), 4.0, Color(0.4, 0.4, 0.45))
	# Sparking burning fuse
	var spark_pulse := 1.0 + sin(time_passed * 20.0) * 0.3
	visual_node.draw_circle(bomb_pos + Vector2(8, -12), 6.0 * spark_pulse, Color(1.0, 0.5, 0.1, 0.6))
	visual_node.draw_circle(bomb_pos + Vector2(8, -12), 3.5 * spark_pulse, Color(1.0, 0.9, 0.2))

func _draw_mamay_gift(c: Vector2) -> void:
	# Земля кургану та вечірнє небо
	visual_node.draw_rect(Rect2(0, c.y + 42, 380, 78), Color(0.16, 0.24, 0.14))
	
	# Козак Мамай сидить по-турецьки з кобзою (анатомічна фігура Київнаукфільм, а не кола!)
	var m_pos := c + Vector2(-72, 24)
	# Схрещені ноги у широких червоних шароварах та сап'янцях
	visual_node.draw_colored_polygon(PackedVector2Array([
		m_pos + Vector2(-26, 8), m_pos + Vector2(26, 8),
		m_pos + Vector2(20, 20), m_pos + Vector2(-20, 20)
	]), Color(0.82, 0.12, 0.16))
	visual_node.draw_circle(m_pos + Vector2(-22, 14), 6.0, Color(0.74, 0.10, 0.14))
	visual_node.draw_circle(m_pos + Vector2(22, 14), 6.0, Color(0.74, 0.10, 0.14))
	# Широкоплечий торс Мамая у синьому козацькому жупані з золотими застібками
	visual_node.draw_colored_polygon(PackedVector2Array([
		m_pos + Vector2(-18, -24), m_pos + Vector2(18, -24),
		m_pos + Vector2(13, 8), m_pos + Vector2(-13, 8)
	]), Color(0.16, 0.34, 0.68))
	visual_node.draw_rect(Rect2(m_pos.x - 13, m_pos.y + 2, 26, 6), Color(0.95, 0.78, 0.18))
	# Голова старого характерника Мамая з сивими вусами та оселедцем
	var mh := m_pos + Vector2(0, -35)
	visual_node.draw_circle(mh, 10.5, Color(0.94, 0.80, 0.68))
	visual_node.draw_line(mh + Vector2(-2, -1), mh + Vector2(-14, 4), Color(0.88, 0.90, 0.95), 3.0)
	visual_node.draw_line(mh + Vector2(2, -1), mh + Vector2(14, 4), Color(0.88, 0.90, 0.95), 3.0)
	visual_node.draw_line(mh + Vector2(0, -10), mh + Vector2(-15, -16), Color(0.88, 0.90, 0.95), 3.5)
	visual_node.draw_line(mh + Vector2(-15, -16), mh + Vector2(-18, -5), Color(0.88, 0.90, 0.95), 2.8)
	# Кобза в руках Мамая
	var b_pos := m_pos + Vector2(15, -4)
	visual_node.draw_circle(b_pos, 11.0, Color(0.72, 0.48, 0.22))
	visual_node.draw_line(b_pos, b_pos + Vector2(8, -22), Color(0.45, 0.28, 0.12), 3.6)
	
	# Сяюча Крилата Кирея в центрі
	var k_pos := c + Vector2(2, -12 + sin(time_passed * 4.0) * 4.0)
	var k_pulse := 1.0 + sin(time_passed * 8.0) * 0.12
	visual_node.draw_circle(k_pos, 24.0 * k_pulse, Color(0.2, 0.8, 1.0, 0.25))
	var cape_pts := PackedVector2Array([
		k_pos + Vector2(-24, 12), k_pos + Vector2(0, -14), k_pos + Vector2(24, 12),
		k_pos + Vector2(14, 19), k_pos + Vector2(0, 10), k_pos + Vector2(-14, 19)
	])
	visual_node.draw_colored_polygon(cape_pts, Color(0.12, 0.45, 0.88))
	visual_node.draw_polyline(cape_pts, Color(1.0, 0.85, 0.25), 2.0)
	
	# Юний Джура праворуч приймає крилату кирею від Мамая
	_draw_story_dzhura(c + Vector2(76, 22), -1.0, "cheer")

func _draw_cossack_scroll(c: Vector2) -> void:
	# Ancient Parchment Scroll of the Zaporozhian Host
	var s_rect := Rect2(c.x - 110, c.y - 70, 220, 140)
	# Parchment shadow & sheet
	visual_node.draw_rect(Rect2(s_rect.position + Vector2(4, 4), s_rect.size), Color(0.04, 0.06, 0.12, 0.70))
	visual_node.draw_rect(s_rect, Color(0.92, 0.85, 0.70))
	# Rolled parchment edges
	visual_node.draw_rect(Rect2(s_rect.position.x - 8, s_rect.position.y - 4, 12, s_rect.size.y + 8), Color(0.78, 0.68, 0.52))
	visual_node.draw_rect(Rect2(s_rect.end.x - 4, s_rect.position.y - 4, 12, s_rect.size.y + 8), Color(0.78, 0.68, 0.52))
	
	# Handwriting lines on parchment
	for line_i in range(5):
		var ly := s_rect.position.y + 22.0 + line_i * 16.0
		visual_node.draw_line(Vector2(s_rect.position.x + 20, ly), Vector2(s_rect.end.x - 20, ly), Color(0.35, 0.28, 0.20, 0.65), 2.0)
	
	# Red Wax Seal of the Zaporozhian Host with yellow ribbons
	var seal_pos := Vector2(s_rect.position.x + 40, s_rect.end.y - 25)
	# Yellow ribbons
	visual_node.draw_line(seal_pos, seal_pos + Vector2(-12, 22), Color(0.95, 0.82, 0.20), 4.0)
	visual_node.draw_line(seal_pos, seal_pos + Vector2(10, 22), Color(0.95, 0.82, 0.20), 4.0)
	# Red wax stamp
	var seal_pulse := 1.0 + sin(time_passed * 6.0) * 0.08
	visual_node.draw_circle(seal_pos, 16.0 * seal_pulse, Color(0.75, 0.12, 0.14))
	visual_node.draw_circle(seal_pos, 12.0 * seal_pulse, Color(0.90, 0.18, 0.20))
	# Cossack cross / coat on wax
	visual_node.draw_line(seal_pos - Vector2(6, 0), seal_pos + Vector2(6, 0), Color(1.0, 0.9, 0.4), 2.0)
	visual_node.draw_line(seal_pos - Vector2(0, 6), seal_pos + Vector2(0, 6), Color(1.0, 0.9, 0.4), 2.0)
	
	# Curved steel Cossack sabre laying across the bottom
	var sabre_pts = PackedVector2Array([
		c + Vector2(-90, 65), c + Vector2(-20, 68), c + Vector2(50, 62), c + Vector2(110, 48)
	])
	visual_node.draw_polyline(sabre_pts, Color(0.85, 0.88, 0.95), 3.0)
	# Brass hilt
	visual_node.draw_circle(c + Vector2(-90, 65), 5.0, Color(0.95, 0.80, 0.22))

func _draw_chumak_cart(c: Vector2) -> void:
	# Pitch-black night sky (lost stars)
	visual_node.draw_rect(Rect2(0, 0, visual_node.size.x, visual_node.size.y), Color(0.02, 0.03, 0.08))
	
	# Faint silhouette of windmill and dark steppe hills
	var hill_pts = PackedVector2Array([
		Vector2(0, c.y + 35), Vector2(140, c.y + 10), Vector2(280, c.y + 25), Vector2(390, c.y + 15),
		Vector2(390, visual_node.size.y), Vector2(0, visual_node.size.y)
	])
	visual_node.draw_colored_polygon(hill_pts, Color(0.05, 0.08, 0.14))
	
	# Chumak Wagon (Мажа) in the darkness
	var cart_pos := c + Vector2(-15, 20)
	# Wooden cart body
	var body_pts = PackedVector2Array([
		cart_pos + Vector2(-65, 0), cart_pos + Vector2(55, 0),
		cart_pos + Vector2(45, 20), cart_pos + Vector2(-55, 20)
	])
	visual_node.draw_colored_polygon(body_pts, Color(0.35, 0.24, 0.14))
	visual_node.draw_polyline(body_pts, Color(0.20, 0.12, 0.08), 2.0)
	
	# Big white salt sacks piled high on the cart!
	for sack_i in range(4):
		var sx := cart_pos.x - 45 + sack_i * 26
		var sy := cart_pos.y - 10 - (sack_i % 2) * 8
		visual_node.draw_circle(Vector2(sx, sy), 13.0, Color(0.92, 0.92, 0.96))
		visual_node.draw_circle(Vector2(sx + 2, sy - 2), 11.0, Color(1.0, 1.0, 1.0))
		visual_node.draw_line(Vector2(sx - 5, sy + 6), Vector2(sx + 5, sy + 6), Color(0.65, 0.68, 0.75), 1.6)
	
	# Wooden spoked wagon wheels
	for wx in [cart_pos.x - 42, cart_pos.x + 36]:
		visual_node.draw_circle(Vector2(wx, cart_pos.y + 22), 16.0, Color(0.25, 0.16, 0.09))
		visual_node.draw_circle(Vector2(wx, cart_pos.y + 22), 12.0, Color(0.04, 0.06, 0.10))
		visual_node.draw_circle(Vector2(wx, cart_pos.y + 22), 3.5, Color(0.65, 0.68, 0.72)) # Iron hub
		for spk in range(4):
			var sa := float(spk) * (PI * 0.25)
			var s_dir := Vector2(cos(sa), sin(sa)) * 14.0
			visual_node.draw_line(Vector2(wx, cart_pos.y + 22) - s_dir, Vector2(wx, cart_pos.y + 22) + s_dir, Color(0.45, 0.30, 0.18), 1.8)
	
	# Horned Chumak Steppe Oxen resting in the dark
	var ox_pos := cart_pos + Vector2(95, 22)
	visual_node.draw_circle(ox_pos, 16.0, Color(0.35, 0.36, 0.40)) # Grey ox body
	visual_node.draw_circle(ox_pos + Vector2(14, -8), 10.0, Color(0.38, 0.40, 0.45)) # Head
	# Majestic long white horns!
	visual_node.draw_line(ox_pos + Vector2(14, -14), ox_pos + Vector2(6, -26), Color(0.92, 0.92, 0.95), 2.5)
	visual_node.draw_line(ox_pos + Vector2(16, -14), ox_pos + Vector2(26, -26), Color(0.92, 0.92, 0.95), 2.5)
	
	# Faint lantern flickering on the cart
	var lamp_pos := cart_pos + Vector2(-60, -18)
	var lamp_flicker := 1.0 + sin(time_passed * 15.0) * 0.25
	visual_node.draw_circle(lamp_pos, 10.0 * lamp_flicker, Color(1.0, 0.65, 0.15, 0.25))
	visual_node.draw_circle(lamp_pos, 3.5, Color(1.0, 0.85, 0.25))

func _draw_vidma_sky(c: Vector2) -> void:
	# Night sky with golden crescent moon
	visual_node.draw_circle(c + Vector2(-90, -40), 22.0, Color(1.0, 0.92, 0.65))
	visual_node.draw_circle(c + Vector2(-98, -43), 18.0, Color(0.08, 0.12, 0.22))
	
	# Witch Solokha flying on broom across the moon!
	var w_pos := c + Vector2(30 + sin(time_passed * 3.5) * 20.0, -20 + cos(time_passed * 3.0) * 8.0)
	# Broom
	visual_node.draw_line(w_pos - Vector2(40, -8), w_pos + Vector2(35, 6), Color(0.5, 0.35, 0.18), 4.0)
	# Twigs
	visual_node.draw_colored_polygon(PackedVector2Array([
		w_pos - Vector2(35, -8), w_pos - Vector2(55, -16), w_pos - Vector2(52, 2)
	]), Color(0.65, 0.45, 0.22))
	# Witch body & dress
	visual_node.draw_circle(w_pos + Vector2(4, -14), 10.0, Color(0.25, 0.18, 0.30)) # Head
	visual_node.draw_circle(w_pos + Vector2(0, 0), 14.0, Color(0.55, 0.15, 0.35)) # Dress
	# Sputtering puff clouds
	var puff_t := fmod(time_passed * 4.0, 1.0)
	visual_node.draw_circle(w_pos - Vector2(55 + puff_t * 20.0, -8), 4.0 + puff_t * 6.0, Color(0.85, 0.85, 0.95, 0.6 - puff_t * 0.5))

func _draw_vakula_anvil(c: Vector2) -> void:
	# Blacksmith shop / Forge glow
	visual_node.draw_rect(Rect2(0, c.y + 42, 380, 78), Color(0.14, 0.10, 0.08))
	visual_node.draw_circle(c + Vector2(0, 18), 80.0, Color(1.0, 0.45, 0.10, 0.22))
	
	# Коваль Вакула з могутніми плечима у вишиванці та шкіряному фартусі (анатомічний силует)
	var v_pos := c + Vector2(-65, 22)
	visual_node.draw_line(v_pos + Vector2(-7, 6), v_pos + Vector2(-9, 20), Color(0.22, 0.26, 0.38), 6.0)
	visual_node.draw_line(v_pos + Vector2(7, 6), v_pos + Vector2(9, 20), Color(0.22, 0.26, 0.38), 6.0)
	visual_node.draw_colored_polygon(PackedVector2Array([
		v_pos + Vector2(-18, -22), v_pos + Vector2(18, -22),
		v_pos + Vector2(14, 10), v_pos + Vector2(-14, 10)
	]), Color(0.95, 0.94, 0.90))
	visual_node.draw_colored_polygon(PackedVector2Array([
		v_pos + Vector2(-13, -18), v_pos + Vector2(13, -18),
		v_pos + Vector2(14, 12), v_pos + Vector2(-14, 12)
	]), Color(0.36, 0.22, 0.14)) # Шкіряний ковальський фартух
	var vh := v_pos + Vector2(0, -33)
	visual_node.draw_circle(vh, 10.5, Color(0.95, 0.82, 0.70))
	visual_node.draw_line(vh + Vector2(-8, -8), vh + Vector2(8, -8), Color(0.14, 0.10, 0.08), 5.0) # Густа чуприна Вакули
	visual_node.draw_line(vh + Vector2(-7, 2), vh + Vector2(7, 2), Color(0.14, 0.10, 0.08), 2.5) # Вуса коваля
	# Важкий ковальський молот у руці
	var h_hand := v_pos + Vector2(22, -24 + sin(time_passed * 6.0) * 8.0)
	visual_node.draw_line(v_pos + Vector2(14, -16), h_hand, Color(0.95, 0.94, 0.90), 5.0)
	visual_node.draw_line(h_hand, h_hand + Vector2(12, 20), Color(0.45, 0.30, 0.15), 3.6)
	visual_node.draw_rect(Rect2(h_hand.x + 5, h_hand.y + 15, 18, 11), Color(0.38, 0.42, 0.48))
	
	# Ковадло з сяючою Золотою Підківкою посередині
	var a_pos := c + Vector2(5, 26)
	visual_node.draw_rect(Rect2(a_pos.x - 22, a_pos.y, 44, 18), Color(0.25, 0.28, 0.32))
	var shoe_pulse := 1.0 + sin(time_passed * 12.0) * 0.22
	visual_node.draw_circle(a_pos + Vector2(0, -6), 16.0 * shoe_pulse, Color(1.0, 0.85, 0.15, 0.35))
	visual_node.draw_arc(a_pos + Vector2(0, -6), 9.0, 0.5, TAU - 0.5, 12, Color(1.0, 0.92, 0.25), 4.0)
	
	# Юний Джура праворуч захоплено дивиться на золоту підківку
	_draw_story_dzhura(c + Vector2(78, 22), -1.0, "cheer")

func _draw_kamianets_towers(c: Vector2) -> void:
	# Deep canyon and river Smotrych
	visual_node.draw_rect(Rect2(0, c.y + 35, 380, 85), Color(0.08, 0.14, 0.22))
	# Ancient Stone Fortress Walls with battlements
	var wall_y := c.y + 10.0
	visual_node.draw_rect(Rect2(40, wall_y, 300, 50), Color(0.45, 0.42, 0.40))
	for bx in range(45, 335, 20):
		visual_node.draw_rect(Rect2(bx, wall_y - 12, 12, 12), Color(0.48, 0.45, 0.42))
	# Round Stone Towers (Left & Right)
	visual_node.draw_rect(Rect2(30, wall_y - 45, 45, 95), Color(0.52, 0.50, 0.46))
	visual_node.draw_colored_polygon(PackedVector2Array([
		Vector2(25, wall_y - 45), Vector2(78, wall_y - 45), Vector2(52, wall_y - 75)
	]), Color(0.68, 0.22, 0.18)) # Red conical roof
	
	visual_node.draw_rect(Rect2(295, wall_y - 45, 45, 95), Color(0.52, 0.50, 0.46))
	visual_node.draw_colored_polygon(PackedVector2Array([
		Vector2(290, wall_y - 45), Vector2(343, wall_y - 45), Vector2(317, wall_y - 75)
	]), Color(0.68, 0.22, 0.18))
	
	# Cossack Yellow-Blue Flag on top tower
	visual_node.draw_line(Vector2(52, wall_y - 75), Vector2(52, wall_y - 95), Color(0.3, 0.2, 0.1), 2.0)
	visual_node.draw_rect(Rect2(52, wall_y - 95, 22, 7), Color(0.15, 0.45, 0.85))
	visual_node.draw_rect(Rect2(52, wall_y - 88, 22, 7), Color(0.95, 0.85, 0.15))

func _draw_qirimli_ally(c: Vector2) -> void:
	# Fortress wall top with battlements
	visual_node.draw_rect(Rect2(0, c.y + 42, 380, 78), Color(0.45, 0.42, 0.40))
	for bx in range(15, 375, 28):
		visual_node.draw_rect(Rect2(bx, c.y + 32, 14, 10), Color(0.52, 0.49, 0.46))
	
	# Відважний побратим Киримли зліва (анатомічна фігура з луком та Тарак-Тамгою)
	_draw_story_qirimli(c + Vector2(-62, 22), 1.0, "bow")
	
	# Золотий щит побратимства посередині з Тарак-Тамгою
	var shield_p := c + Vector2(0, 6 + sin(time_passed * 4.0) * 2.0)
	visual_node.draw_circle(shield_p, 16.0, Color(0.85, 0.70, 0.15))
	visual_node.draw_circle(shield_p, 13.0, Color(0.20, 0.45, 0.75))
	visual_node.draw_line(shield_p + Vector2(0, 7), shield_p + Vector2(0, -6), Color(0.98, 0.88, 0.22), 2.2)
	visual_node.draw_line(shield_p + Vector2(-6, 0), shield_p + Vector2(6, 0), Color(0.98, 0.88, 0.22), 2.0)
	visual_node.draw_line(shield_p + Vector2(-6, 0), shield_p + Vector2(-6, -6), Color(0.98, 0.88, 0.22), 2.0)
	visual_node.draw_line(shield_p + Vector2(6, 0), shield_p + Vector2(6, -6), Color(0.98, 0.88, 0.22), 2.0)
	
	# Юний 15-річний козак-Джура праворуч вітає побратима Киримли!
	_draw_story_dzhura(c + Vector2(62, 22), -1.0, "cheer")

func _draw_fortress_cannon(c: Vector2) -> void:
	# Heavy stone battlements
	visual_node.draw_rect(Rect2(0, c.y + 35, 380, 85), Color(0.40, 0.38, 0.36))
	visual_node.draw_line(Vector2(0, c.y + 35), Vector2(380, c.y + 35), Color(0.60, 0.58, 0.55), 3.0)
	
	# Massive Cossack Bronze Cannon on wooden carriage
	var can_pos := c + Vector2(-20, 20)
	# Wheels
	visual_node.draw_circle(can_pos + Vector2(-25, 12), 16.0, Color(0.35, 0.24, 0.14))
	visual_node.draw_circle(can_pos + Vector2(-25, 12), 11.0, Color(0.20, 0.14, 0.08))
	visual_node.draw_circle(can_pos + Vector2(25, 12), 16.0, Color(0.35, 0.24, 0.14))
	visual_node.draw_circle(can_pos + Vector2(25, 12), 11.0, Color(0.20, 0.14, 0.08))
	# Bronze Cannon Barrel pointing up-right
	visual_node.draw_colored_polygon(PackedVector2Array([
		can_pos + Vector2(-45, 2), can_pos + Vector2(50, -20),
		can_pos + Vector2(52, -34), can_pos + Vector2(-42, -12)
	]), Color(0.80, 0.55, 0.18))
	visual_node.draw_line(can_pos + Vector2(-45, -5), can_pos + Vector2(50, -27), Color(0.98, 0.78, 0.28), 2.5) # Specular sheen
	
	# Pyramid of 6 glowing cannonballs with burning fuses
	var b_base := c + Vector2(110, 30)
	for row in range(3):
		for col in range(3 - row):
			var bp := b_base + Vector2(col * 18 + row * 9, -row * 16)
			visual_node.draw_circle(bp, 8.0, Color(0.18, 0.20, 0.24))
			visual_node.draw_circle(bp + Vector2(2, -2), 3.0, Color(0.4, 0.45, 0.5))
			if row == 2 or (row == 1 and col == 0):
				# Burning spark on top bombs
				var spk_flicker := 1.0 + sin(time_passed * 20.0) * 0.3
				visual_node.draw_circle(bp + Vector2(0, -9), 4.5 * spk_flicker, Color(1.0, 0.85, 0.2, 0.8))
				visual_node.draw_circle(bp + Vector2(0, -9), 2.2, Color(1.0, 0.25, 0.15))

func _draw_baturyn_palace(c: Vector2) -> void:
	# Барокові палаци Батурина та золоті бані
	visual_node.draw_rect(Rect2(0, c.y + 35, 380, 85), Color(0.18, 0.18, 0.28))
	# Колонада
	for col in range(20, 360, 40):
		visual_node.draw_rect(Rect2(col, c.y - 15, 14, 50), Color(0.85, 0.85, 0.90))
	# Золота баня
	visual_node.draw_circle(c + Vector2(0, -35), 32.0, Color(0.95, 0.80, 0.20))
	visual_node.draw_circle(c + Vector2(0, -35), 18.0, Color(1.0, 0.92, 0.45))
	# Козацька скарбниця: кована скриня з золотими дукатами
	var chest_p := c + Vector2(0, 45)
	visual_node.draw_rect(Rect2(chest_p.x - 30, chest_p.y - 18, 60, 34), Color(0.45, 0.28, 0.14))
	visual_node.draw_rect(Rect2(chest_p.x - 26, chest_p.y - 14, 52, 6), Color(0.96, 0.82, 0.18))
	visual_node.draw_circle(chest_p + Vector2(0, 4), 4.0, Color(0.96, 0.82, 0.18))

func _draw_moskal_invaders(c: Vector2) -> void:
	# Земля та похмурий ліс на півночі
	visual_node.draw_rect(Rect2(0, c.y + 45, 380, 75), Color(0.25, 0.22, 0.20))
	
	# Два царські стрільці-москалі у сатиричному стилі Київнаукфільм
	for m in range(2):
		var mx := c.x + (-70.0 if m == 0 else 50.0)
		var my := c.y + 15.0
		var bob := sin(time_passed * 6.0 + float(m) * PI) * 2.5
		
		# Червоний довгий каптан із золотими петлицями
		var body_pts = PackedVector2Array([
			Vector2(mx - 14, my - 8 + bob), Vector2(mx + 14, my - 8 + bob),
			Vector2(mx + 18, my + 26 + bob), Vector2(mx - 18, my + 26 + bob)
		])
		visual_node.draw_colored_polygon(body_pts, Color(0.85, 0.15, 0.18))
		for b in range(3):
			visual_node.draw_line(Vector2(mx - 10, my - 2 + b * 6 + bob), Vector2(mx + 10, my - 2 + b * 6 + bob), Color(0.96, 0.82, 0.18), 2.0)
		
		# Ноги у плетених лаптях
		visual_node.draw_circle(Vector2(mx - 8, my + 30 + bob), 4.5, Color(0.68, 0.52, 0.28))
		visual_node.draw_circle(Vector2(mx + 8, my + 30 + bob), 4.5, Color(0.68, 0.52, 0.28))
		
		# Величезний незграбний бердиш у руках
		visual_node.draw_line(Vector2(mx + 12, my + 26 + bob), Vector2(mx + 28, my - 34 + bob), Color(0.40, 0.25, 0.14), 3.0)
		visual_node.draw_arc(Vector2(mx + 28, my - 34 + bob), 12.0, -1.2, 1.2, 8, Color(0.78, 0.82, 0.88), 3.5)
		
		# Голова, борода лопатою, червоний ніс і високий ковпак
		visual_node.draw_circle(Vector2(mx, my - 16 + bob), 10.0, Color(0.96, 0.82, 0.70))
		# Борода лопатою
		visual_node.draw_rect(Rect2(mx - 9, my - 10 + bob, 18, 16), Color(0.44, 0.28, 0.16))
		visual_node.draw_circle(Vector2(mx + 4, my - 16 + bob), 3.5, Color(0.92, 0.36, 0.36)) # Ніс-буряк
		# Опушка і ковпак
		visual_node.draw_rect(Rect2(mx - 11, my - 24 + bob, 22, 6), Color(0.35, 0.24, 0.15))
		visual_node.draw_colored_polygon(PackedVector2Array([
			Vector2(mx - 9, my - 24 + bob), Vector2(mx + 9, my - 24 + bob), Vector2(mx - 4, my - 44 + bob)
		]), Color(0.85, 0.15, 0.18))

func _draw_cossack_crimean_union(c: Vector2) -> void:
	# Фортечний бастіон під зорями
	visual_node.draw_rect(Rect2(0, c.y + 42, 380, 78), Color(0.20, 0.22, 0.26))
	
	# Юний 15-річний Джура зліва тримає сяючі золоті підківки Вакули
	_draw_story_dzhura(c + Vector2(-58, 22), 1.0, "horseshoe")
	
	# Побратим Киримли справа натягує композитний лук зі стрілою
	_draw_story_qirimli(c + Vector2(58, 22), -1.0, "bow")

func _draw_perekop_gate(c: Vector2) -> void:
	# Білокам'яна арка Перекопу та мінарет
	visual_node.draw_rect(Rect2(0, c.y + 30, 380, 90), Color(0.82, 0.78, 0.72))
	# Брама Ор-Капу
	visual_node.draw_arc(c + Vector2(0, 45), 45.0, PI, TAU, 16, Color(0.22, 0.18, 0.15), 12.0)
	# Мінарет ліворуч з півмісяцем
	var min_x := c.x - 120.0
	visual_node.draw_rect(Rect2(min_x - 8, c.y - 45, 16, 75), Color(0.90, 0.88, 0.82))
	visual_node.draw_colored_polygon(PackedVector2Array([
		Vector2(min_x - 9, c.y - 45), Vector2(min_x + 9, c.y - 45), Vector2(min_x, c.y - 75)
	]), Color(0.20, 0.45, 0.35))
	visual_node.draw_arc(Vector2(min_x, c.y - 80), 5.0, -1.0, 1.0, 8, Color(1.0, 0.88, 0.22), 2.0)
	# Блакитний прапор з Тарақ-Тамгою праворуч
	var fl_x := c.x + 110.0
	visual_node.draw_line(Vector2(fl_x, c.y + 30), Vector2(fl_x, c.y - 40), Color(0.35, 0.25, 0.15), 3.0)
	visual_node.draw_rect(Rect2(fl_x, c.y - 40, 40, 26), Color(0.18, 0.52, 0.82))
	visual_node.draw_line(Vector2(fl_x + 20, c.y - 36), Vector2(fl_x + 20, c.y - 20), Color(1.0, 0.88, 0.22), 2.0)
	visual_node.draw_line(Vector2(fl_x + 14, c.y - 28), Vector2(fl_x + 26, c.y - 28), Color(1.0, 0.88, 0.22), 1.8)

func _draw_moskal_retreat(c: Vector2) -> void:
	# Земля та клуби куряви від панічної втечі
	visual_node.draw_rect(Rect2(0, c.y + 40, 380, 80), Color(0.30, 0.26, 0.22))
	
	# Переляканий стрілець тікає праворуч у паніці!
	var mx := c.x + 30.0 + sin(time_passed * 16.0) * 8.0
	var my := c.y + 10.0
	
	# Тіло у нахилі
	visual_node.draw_colored_polygon(PackedVector2Array([
		Vector2(mx - 15, my - 6), Vector2(mx + 12, my - 6),
		Vector2(mx + 22, my + 24), Vector2(mx - 8, my + 24)
	]), Color(0.85, 0.15, 0.18))
	# Руки задерті вгору у крику "Рятуйте!"
	var arm_flail := sin(time_passed * 24.0) * 8.0
	visual_node.draw_line(Vector2(mx - 6, my - 2), Vector2(mx - 18, my - 22 + arm_flail), Color(0.85, 0.15, 0.18), 3.2)
	visual_node.draw_line(Vector2(mx + 8, my - 2), Vector2(mx + 24, my - 22 - arm_flail), Color(0.85, 0.15, 0.18), 3.2)
	
	# Очі-блюдця навикоті O_O
	visual_node.draw_circle(Vector2(mx + 4, my - 16), 5.0, Color.WHITE)
	visual_node.draw_circle(Vector2(mx + 14, my - 16), 5.0, Color.WHITE)
	visual_node.draw_circle(Vector2(mx + 5, my - 16), 1.5, Color.BLACK)
	visual_node.draw_circle(Vector2(mx + 15, my - 16), 1.5, Color.BLACK)
	# Відкритий кричущий рот
	visual_node.draw_circle(Vector2(mx + 10, my - 6), 4.0, Color(0.2, 0.05, 0.05))
	
	# Шапка злетіла в повітря високо над головою!
	var cap_y := my - 45.0 + sin(time_passed * 20.0) * 4.0
	visual_node.draw_colored_polygon(PackedVector2Array([
		Vector2(mx - 8, cap_y), Vector2(mx + 12, cap_y), Vector2(mx + 2, cap_y - 20)
	]), Color(0.85, 0.15, 0.18))
	
	# Загублені лапті та бердиш летять шкереберть
	visual_node.draw_circle(Vector2(mx - 40, my + 15), 4.5, Color(0.68, 0.52, 0.28))
	visual_node.draw_circle(Vector2(mx - 60, my + 5), 4.5, Color(0.68, 0.52, 0.28))
	visual_node.draw_line(Vector2(mx - 70, my + 25), Vector2(mx - 45, my - 10), Color(0.40, 0.25, 0.14), 2.8)

func _draw_grand_fireworks(c: Vector2) -> void:
	# Святкове нічне небо
	visual_node.draw_rect(Rect2(0, 0, 380, 240), Color(0.04, 0.06, 0.16))
	
	# Спалахи святкового феєрверку Перемоги
	for fw in range(4):
		var fx := c.x + cos(float(fw) * 1.6 + time_passed) * 110.0
		var fy := c.y - 45.0 + sin(float(fw) * 1.3) * 35.0
		var cols = [Color(0.25, 0.95, 0.50), Color(1.0, 0.88, 0.22), Color(0.25, 0.65, 1.0), Color(1.0, 0.35, 0.45)]
		var c_fw: Color = cols[fw % cols.size()]
		for p in range(8):
			var a := float(p) * (TAU / 8.0) + time_passed * 2.0
			var r := 16.0 + sin(time_passed * 12.0) * 6.0
			visual_node.draw_line(Vector2(fx, fy), Vector2(fx + cos(a) * r, fy + sin(a) * r), c_fw, 2.0)
			visual_node.draw_circle(Vector2(fx + cos(a) * (r + 4), fy + sin(a) * (r + 4)), 1.8, Color.WHITE)
	
	# Юний Джура у переможному стрибку «Щупак» ліворуч
	_draw_story_dzhura(c + Vector2(-46, 22), 1.0, "shchupak")
	
	# Побратим Киримли у переможному танці Хоран / Хайтарма праворуч
	_draw_story_qirimli(c + Vector2(46, 22), -1.0, "dance")

# -------------------------------------------------------------------------
# АНАТОМІЧНИЙ ПОРТРЕТ ЮНОГО ДЖУРИ (14-16 РОКІВ) ДЛЯ СЮЖЕТНИХ СЛАЙДІВ
# Без вусів, зі справжнім козацьким чубом «Оселедцем-Айдаром», у вишиванці,
# широких червоних шароварах, сап'янцях та крилатій киреї (стиль Київнаукфільм)
# -------------------------------------------------------------------------
func _draw_story_dzhura(origin: Vector2, dir: float, action: String) -> void:
	var bob := sin(time_passed * 4.5) * 2.5
	var p := origin + Vector2(0.0, bob)
	if action == "shchupak":
		p.y -= 10.0 + absf(sin(time_passed * 6.0)) * 5.0
	
	# 1. Крилата блакитна козацька кирея із золотою облямівкою за плечима
	var cape_pts := PackedVector2Array([
		p + Vector2(-10.0 * dir, -20.0),
		p + Vector2(8.0 * dir, -20.0),
		p + Vector2(18.0 * dir, 6.0),
		p + Vector2(0.0, 2.0),
		p + Vector2(-20.0 * dir, 8.0)
	])
	visual_node.draw_colored_polygon(cape_pts, Color(0.14, 0.44, 0.86))
	visual_node.draw_polyline(cape_pts, Color(0.98, 0.84, 0.20), 1.6)
	
	# 2. Дві анатомічні ноги у пишних червоних шароварах та червоних чоботях-сап'янцях із загнутими носками
	var c_shar := Color(0.86, 0.12, 0.18)
	var c_shar_sh := Color(0.62, 0.07, 0.12)
	var c_boot := Color(0.76, 0.14, 0.10)
	var c_gold := Color(0.96, 0.82, 0.18)
	
	if action == "shchupak":
		# Повітряний шпагат «Щупак» у стрибку!
		var leg_l := p + Vector2(-24.0, 2.0)
		var leg_r := p + Vector2(24.0, 2.0)
		visual_node.draw_line(p + Vector2(-4.0, -2.0), leg_l, c_shar, 8.5)
		visual_node.draw_line(p + Vector2(4.0, -2.0), leg_r, c_shar, 8.5)
		visual_node.draw_colored_polygon(PackedVector2Array([
			leg_l, leg_l + Vector2(-8.0, -4.0), leg_l + Vector2(-6.0, 3.0)
		]), c_boot)
		visual_node.draw_colored_polygon(PackedVector2Array([
			leg_r, leg_r + Vector2(8.0, -4.0), leg_r + Vector2(6.0, 3.0)
		]), c_boot)
	else:
		# Ліва і права штанини шароварів (від пояса до колін і халяв сап'янців)
		var hip_l := p + Vector2(-5.5 * dir, -2.0)
		var ankle_l := p + Vector2(-7.0 * dir, 16.0)
		var hip_r := p + Vector2(5.5 * dir, -2.0)
		var ankle_r := p + Vector2(7.0 * dir, 16.0)
		
		# Об'ємні буфи шароварів
		visual_node.draw_colored_polygon(PackedVector2Array([
			hip_l + Vector2(-5.0, 0.0), hip_l + Vector2(4.0, 0.0),
			ankle_l + Vector2(3.5, -2.0), ankle_l + Vector2(-4.5, -2.0),
			hip_l + Vector2(-8.0, 8.0)
		]), c_shar_sh)
		visual_node.draw_colored_polygon(PackedVector2Array([
			hip_r + Vector2(-4.0, 0.0), hip_r + Vector2(5.0, 0.0),
			hip_r + Vector2(8.0, 8.0),
			ankle_r + Vector2(4.5, -2.0), ankle_r + Vector2(-3.5, -2.0)
		]), c_shar)
		
		# Сап'янці із загнутими носками та золотими підківками
		for ak in [ankle_l, ankle_r]:
			visual_node.draw_rect(Rect2(ak.x - 3.2, ak.y - 3.0, 6.4, 6.0), c_boot)
			visual_node.draw_colored_polygon(PackedVector2Array([
				ak + Vector2(-3.0 * dir, 3.0),
				ak + Vector2(7.5 * dir, 3.0),
				ak + Vector2(9.2 * dir, -0.5),
				ak + Vector2(3.0 * dir, 0.0)
			]), c_boot)
			visual_node.draw_line(ak + Vector2(-3.0 * dir, 3.2), ak + Vector2(7.5 * dir, 3.2), c_gold, 1.5)
	
	# 3. Стрункий юнацький торс (14-16 років) у білій вишиванці та широкому поясі-очкурі
	var torso_pts := PackedVector2Array([
		p + Vector2(-10.5 * dir, -22.0),
		p + Vector2(10.5 * dir, -22.0),
		p + Vector2(7.5 * dir, -2.0),
		p + Vector2(-7.5 * dir, -2.0)
	])
	visual_node.draw_colored_polygon(torso_pts, Color(0.96, 0.96, 0.99))
	# Червоно-чорна вишивана маніжка на грудях та комір-стійка
	visual_node.draw_line(p + Vector2(1.5 * dir, -21.5), p + Vector2(1.5 * dir, -7.5), Color(0.84, 0.14, 0.16), 3.4)
	visual_node.draw_line(p + Vector2(1.5 * dir, -21.5), p + Vector2(1.5 * dir, -7.5), Color(0.14, 0.10, 0.10), 1.2)
	# Зелено-золотий козацький пояс-очкур
	visual_node.draw_rect(Rect2(p.x - 8.0, p.y - 5.5, 16.0, 4.5), Color(0.16, 0.58, 0.30))
	visual_node.draw_line(p + Vector2(-8.0, -3.2), p + Vector2(8.0, -3.2), c_gold, 1.6)
	
	# 4. Двосегментні руки у вишитих рукавах (плече -> лікоть -> кисть)
	var sh_l := p + Vector2(-9.5 * dir, -19.5)
	var sh_r := p + Vector2(9.5 * dir, -19.5)
	var hand_l := sh_l + Vector2(-7.0 * dir, 11.0)
	var hand_r := sh_r + Vector2(13.0 * dir, 3.0)
	if action == "cheer" or action == "shchupak":
		hand_r = sh_r + Vector2(12.0 * dir, -12.0 + sin(time_passed * 8.0) * 3.0)
		if action == "shchupak":
			hand_l = sh_l + Vector2(-12.0 * dir, -12.0)
	
	visual_node.draw_line(sh_l, hand_l, Color(0.90, 0.92, 0.96), 4.5)
	visual_node.draw_circle(hand_l, 2.8, Color(0.98, 0.85, 0.72))
	visual_node.draw_line(sh_r, hand_r, Color(0.96, 0.97, 1.0), 4.8)
	visual_node.draw_circle(sh_r.lerp(hand_r, 0.3), 2.2, Color(0.84, 0.14, 0.16)) # Вишитий полик на плечі
	visual_node.draw_circle(hand_r, 3.0, Color(0.98, 0.85, 0.72))
	
	# Предмет у руці Джури залежно від сюжету слайду
	if action == "apple":
		var apple_pos := hand_r + Vector2(5.0 * dir, -3.0)
		visual_node.draw_circle(apple_pos, 6.5, Color(0.92, 0.15, 0.16))
		visual_node.draw_circle(apple_pos + Vector2(1.5 * dir, -1.5), 2.2, Color(1.0, 0.45, 0.40))
		visual_node.draw_line(apple_pos + Vector2(0, -6), apple_pos + Vector2(1.5, -10), Color(0.35, 0.22, 0.12), 1.8)
		visual_node.draw_circle(apple_pos + Vector2(3.5, -8.5), 2.4, Color(0.22, 0.78, 0.28))
	elif action == "horseshoe":
		var hs_pos := hand_r + Vector2(7.0 * dir, -2.0)
		visual_node.draw_circle(hs_pos, 9.5, Color(1.0, 0.88, 0.20, 0.38))
		visual_node.draw_arc(hs_pos, 6.0, 0.45, TAU - 0.45, 10, Color(1.0, 0.94, 0.30), 3.0)
	
	# 5. Юнацька голова Джури (14-16 років: БЕЗ вусів, чисте молоде обличчя, сережка та довгий Оселедець-Айдар!)
	var h_pos := p + Vector2(0.0, -31.5)
	visual_node.draw_circle(h_pos, 9.2, Color(0.98, 0.85, 0.72))
	# Рум'янець на юній щоці
	visual_node.draw_circle(h_pos + Vector2(3.2 * dir, 2.2), 2.4, Color(0.98, 0.45, 0.45, 0.42))
	# Золота козацька сережка-півмісяць у вусі
	visual_node.draw_arc(h_pos + Vector2(-8.2 * dir, 1.2), 2.0, 0.0, TAU, 8, Color(1.0, 0.86, 0.18), 1.5)
	# Кирпатий юнацький ніс
	visual_node.draw_colored_polygon(PackedVector2Array([
		h_pos + Vector2(6.5 * dir, -1.5),
		h_pos + Vector2(10.2 * dir, 0.8),
		h_pos + Vector2(6.2 * dir, 1.8)
	]), Color(0.94, 0.76, 0.64))
	# Живі козацькі очі та брова
	var eye_p := h_pos + Vector2(3.4 * dir, -2.0)
	visual_node.draw_circle(eye_p, 2.5, Color.WHITE)
	visual_node.draw_circle(eye_p + Vector2(0.7 * dir, 0.0), 1.4, Color(0.12, 0.24, 0.38))
	visual_node.draw_circle(eye_p + Vector2(1.0 * dir, -0.5), 0.55, Color.WHITE)
	visual_node.draw_line(eye_p + Vector2(-2.2 * dir, -2.6), eye_p + Vector2(2.4 * dir, -1.9), Color(0.14, 0.10, 0.08), 1.7)
	# Відкрита щира юнацька посмішка (БЕЗ вусів!)
	visual_node.draw_arc(h_pos + Vector2(2.6 * dir, 2.8), 3.4, 0.2, PI - 0.2, 8, Color(0.72, 0.16, 0.18), 1.9)
	
	# 6. Старовинний козацький чуб — «Оселедець-Айдар» (від тімені пишною хвилею за вухо!)
	var chub_root := h_pos + Vector2(1.0 * dir, -8.6)
	var wave := sin(time_passed * 6.5) * 2.2
	var c1 := chub_root + Vector2(-4.0 * dir, -6.5)
	var c2 := chub_root + Vector2(-13.5 * dir, -4.5 + wave * 0.5)
	var c3 := chub_root + Vector2(-18.5 * dir, 3.5 + wave)
	var c4 := chub_root + Vector2(-14.5 * dir, 8.5 + wave)
	visual_node.draw_circle(chub_root, 2.8, Color(0.10, 0.07, 0.06))
	visual_node.draw_line(chub_root, c1, Color(0.10, 0.07, 0.06), 4.6)
	visual_node.draw_line(c1, c2, Color(0.10, 0.07, 0.06), 4.0)
	visual_node.draw_line(c2, c3, Color(0.12, 0.08, 0.07), 3.0)
	visual_node.draw_line(c3, c4, Color(0.12, 0.08, 0.07), 2.0)
	visual_node.draw_line(chub_root + Vector2(0, -1), c2 + Vector2(0, -1), Color(0.36, 0.26, 0.22), 1.3) # Полиск на айдарі

# -------------------------------------------------------------------------
# АНАТОМІЧНИЙ ПОРТРЕТ ПОБРАТИМА КИРИМЛИ ДЛЯ СЮЖЕТНИХ СЛАЙДІВ
# -------------------------------------------------------------------------
func _draw_story_qirimli(origin: Vector2, dir: float, action: String) -> void:
	var bob := sin(time_passed * 4.5 + 1.2) * 2.2
	var p := origin + Vector2(0.0, bob)
	
	if qirimli_texture:
		var rect := Rect2(p.x - 26, p.y - 48, 52, 68)
		visual_node.draw_texture_rect(qirimli_texture, rect, false)
		return

	var c_coat := Color(0.12, 0.44, 0.33)
	var c_gold := Color(0.96, 0.82, 0.18)
	
	# 1. Ноги у темно-синіх шароварах та шкіряних чоботях-ічігах
	visual_node.draw_line(p + Vector2(-4.5, 4.0), p + Vector2(-5.5, 18.0), Color(0.14, 0.18, 0.28), 4.2)
	visual_node.draw_line(p + Vector2(4.5, 4.0), p + Vector2(5.5, 18.0), Color(0.14, 0.18, 0.28), 4.2)
	visual_node.draw_circle(p + Vector2(-5.5 + 1.5 * dir, 18.5), 3.0, Color(0.45, 0.28, 0.16))
	visual_node.draw_circle(p + Vector2(5.5 + 1.5 * dir, 18.5), 3.0, Color(0.45, 0.28, 0.16))
	
	# 2. Смарагдовий бешмет із золотими чапразами та червоним поясом-кушаком
	visual_node.draw_colored_polygon(PackedVector2Array([
		p + Vector2(-9.5, -20.0), p + Vector2(9.5, -20.0),
		p + Vector2(11.5, 8.0), p + Vector2(-11.5, 8.0)
	]), c_coat)
	visual_node.draw_rect(Rect2(p.x - 9.0, p.y - 4.5, 18.0, 4.0), Color(0.78, 0.14, 0.18))
	visual_node.draw_line(p + Vector2(-9.0, -2.5), p + Vector2(9.0, -2.5), c_gold, 1.5)
	
	# 3. Руки та композитний лук (або руки в танці Хайтарма)
	if action == "dance":
		visual_node.draw_line(p + Vector2(-8.5, -17.0), p + Vector2(-18.0, -28.0 + sin(time_passed * 8.0) * 4.0), c_coat, 4.0)
		visual_node.draw_line(p + Vector2(8.5, -17.0), p + Vector2(18.0, -28.0 - sin(time_passed * 8.0) * 4.0), c_coat, 4.0)
	else:
		var bow_h := p + Vector2(15.0 * dir, -12.0)
		visual_node.draw_line(p + Vector2(7.0 * dir, -17.0), bow_h, c_coat, 4.2)
		visual_node.draw_arc(bow_h - Vector2(3.0 * dir, 0.0), 16.0, -1.15 if dir > 0 else PI - 1.15, 1.15 if dir > 0 else PI + 1.15, 10, Color(0.58, 0.38, 0.16), 3.0)
		visual_node.draw_line(bow_h + Vector2(0.0, -14.0), bow_h + Vector2(0.0, 14.0), Color(0.92, 0.94, 0.98), 1.2)
	
	# 4. Голова та кримськотатарський калпак із блакитним верхом, золотою Тарак-Тамгою і білим соколиним пером
	var h_pos := p + Vector2(0.0, -29.5)
	visual_node.draw_circle(h_pos, 8.8, Color(0.96, 0.84, 0.72))
	visual_node.draw_circle(h_pos + Vector2(3.0 * dir, -1.8), 2.2, Color.WHITE)
	visual_node.draw_circle(h_pos + Vector2(3.6 * dir, -1.8), 1.2, Color(0.15, 0.25, 0.35))
	visual_node.draw_arc(h_pos + Vector2(2.2 * dir, 2.6), 3.0, 0.2, PI - 0.2, 6, Color(0.68, 0.18, 0.18), 1.6)
	
	visual_node.draw_rect(Rect2(h_pos.x - 9.5, h_pos.y - 10.5, 19.0, 4.5), Color(0.14, 0.12, 0.14))
	visual_node.draw_colored_polygon(PackedVector2Array([
		h_pos + Vector2(-7.5, -10.5), h_pos + Vector2(7.5, -10.5),
		h_pos + Vector2(5.0, -19.5), h_pos + Vector2(-5.0, -19.5)
	]), Color(0.20, 0.56, 0.86))
	visual_node.draw_line(h_pos + Vector2(-5.5 * dir, -13.0), h_pos + Vector2(-11.5 * dir, -23.0), Color.WHITE, 2.2)
	visual_node.draw_line(h_pos + Vector2(0, -12.5), h_pos + Vector2(0, -17.5), c_gold, 1.5)
	visual_node.draw_line(h_pos + Vector2(-3.0, -15.0), h_pos + Vector2(3.0, -15.0), c_gold, 1.5)

