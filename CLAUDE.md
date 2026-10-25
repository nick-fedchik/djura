# Козак Джура: Вогняні Ядра Січі (Geek-Jack)

Фольклорно-історична аркада у стилі «Київнаукфільму» і Bomb Jack. Godot 4.7 (GL Compatibility), GDScript. Основна мова документації та коментарів: українська.

## Команди
- Усі перевірки: `tools/run_tests.sh` (запускає `test/test_*.gd` через `godot --headless --path . -s res://test/<файл>`, потім Python-тести з `tools/`). Код 0 лише якщо все пройшло.
- Один тест: `godot --headless --path . -s res://test/test_levels.gd`
- Синтаксис GDScript: `gdparse файл.gd` (після кожного Edit/Write `.gd` це запускає hook із `.claude/settings.json`). `gdlint` на наявному коді шумить (сотні зауважень), тому не форматувати файли масово.
- Запуск гри: `godot --path .` (головна сцена `scenes/main.tscn`).
- Python-інструменти (`tools/`): `python3 tools/test_tools.py`, `python3 tools/test_sprite_generator.py`. Blender-конвеєр спрайтів описано в `docs/ADR-003` і `docs/SHR-004`.

## Інваріанти (деталі: `docs/SHR-001-game-rules-as-verifiable-invariants.md`, `CONTRIBUTING.md`)
- Уся графіка процедурна: персонажі, фони й ефекти малюються у `_draw()` векторними примітивами. Геометрію виносити в чисті функції (напр. `chort_horn_points`), щоб її можна було тестувати (Anti-Clipping, `test/test_anti_clipping.gd`).
- Стиль «Київнаукфільм»: чорний контур тушшю, мультиплікаційна пластика, жодного кривавого хорору (Zero-Horror, I-3), вік 8+.
- Клавіатура й геймпад (XInput) мають працювати для кожної нової дії.
- I-1: не більше одного нового типу ворога на рівень. `Difficulty.NPC_INTRO` задає, який NPC вводиться на якому рівні.
- Нова поведінка або правило означає новий або оновлений тест у `test/`. Падіння тесту не «лагодити» зміною тесту без пояснення.

## Структура
- `scripts/`: логіка. `game_manager.gd` (рівні, `LEVEL_COMPOSITIONS`, `LEVEL_PLATFORMS`, `LEVEL_BOMBS`), `enemy.gd`, `player.gd`, `*_ally.gd`, `difficulty.gd` (коефіцієнт K), `player_model.gd` (байєсівська адаптація), `telemetry*.gd`.
- `scenes/`, `shaders/` (контур `kyivnaukfilm_ink.gdshader`), `assets/`, `templates/`.
- `test/`: headless-тести. Кожен друкує `PASSED` або `[OK]` і не містить `[FAIL]`/`SCRIPT ERROR`; `run_tests.sh` покладається на це.
- `docs/`: SHR (вимоги), SWR (специфікації), ADR (рішення), `TASKS.md` (облік задач). Змінюючи поведінку, оновлюйте відповідну задачу в `TASKS.md`.
- `Cast` (CanvasGroup) у `scenes/main.tscn` дає контур Джурі й союзникам; не змінювати ієрархію без перегляду T-009.

## Обережно
- Не редагувати `*.import` і `*.uid` вручну. Їх генерує Godot.
- Файли `.tscn` правити мінімально й точково.
- Телеметрія пишеться в `user://`, у репозиторій не потрапляє. Ollama/VLM-інструменти лише дорадчі, поза циклом гри.
