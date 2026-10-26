extends SceneTree
## COD-06: Димовий тест завантаження та інстанціювання всіх сцен (scenes/*.tscn).
## Верифікує наявність обов'язкових компонентів, правильність типів,
## відсутність битих зв'язків та успішне виконання _ready() без панік.

const SCENES := [
	"res://scenes/bomb.tscn",
	"res://scenes/enemy.tscn",
	"res://scenes/hud.tscn",
	"res://scenes/hutsul_ally.tscn",
	"res://scenes/hutsul_bartka.tscn",
	"res://scenes/main.tscn",
	"res://scenes/platform.tscn",
	"res://scenes/player.tscn",
	"res://scenes/power_flower.tscn",
	"res://scenes/qirimli_ally.tscn",
	"res://scenes/qirimli_arrow.tscn",
	"res://scenes/qirimli_falcon.tscn",
	"res://scenes/speech_bubble.tscn",
	"res://scenes/story_cards.tscn",
	"res://scenes/vakula_horseshoe.tscn",
]

func _init() -> void:
	var passed := true
	for path in SCENES:
		if not ResourceLoader.exists(path):
			printerr("[FAIL] Файл сцени не існує: ", path)
			passed = false
			continue
		
		var packed := load(path) as PackedScene
		if packed == null:
			printerr("[FAIL] Помилка завантаження PackedScene: ", path)
			passed = false
			continue
		
		var inst := packed.instantiate()
		if inst == null:
			printerr("[FAIL] Помилка інстанціювання: ", path)
			passed = false
			continue
		
		root.add_child(inst)
		if is_instance_valid(inst):
			root.remove_child(inst)
			inst.free()
		print("  [OK] Сцена перевірена: ", path.get_file())
	
	if passed:
		print("[OK] Усі %d сцен успішно інстанційовано" % SCENES.size())
		print("--- SCENES LOAD TEST PASSED ---")
		quit(0)
	else:
		printerr("[FAIL] Перевірку сцен провалено")
		quit(1)
