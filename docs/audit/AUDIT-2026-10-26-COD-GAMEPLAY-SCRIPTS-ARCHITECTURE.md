# АУДИТ COD: Архітектура ігрових скриптів

- **Код аудиту:** `COD` (`COD-01..COD-07`)
- **Дата:** 2026-10-26
- **Аудитор:** Claude Sonnet 5.5 (лише читання)
- **Об'єкт:** `scripts/*.gd` (23 файли, 11 066 рядків), `scenes/*.tscn` (15), `shaders/`
- **Коміт:** `92174da`; `git status --short`: 34 записи
- **Інструменти:** gdtoolkit 4.5.0 (`gdlint`, `gdformat --check`), grep, awk

---

## 1. Підсумок

Код послідовно типізований і підтримує інваріант «усе малюється в `_draw()`», але зосереджений у чотирьох файлах-гігантах, а найбільші функції мають 300–544 рядки. Правило T-009 (не шукати корінь рівня через `get_parent()`) порушується в `enemy.gd` у 12 місцях. Лінтер знаходить 1 640 зауважень, переважно дрібних (довжина рядка, пробіли). Критичних помилок немає: 15 перевірок проходять.

## 2. Що в порядку

| Перевірка | Результат | Команда |
|---|---|---|
| Типізація функцій | усі функції 15 перевірених файлів мають `-> тип` (28/28 у `player.gd`, 36/36 у `enemy.gd`, 45/45 у `game_manager.gd`) | `grep -cE "^\s*func .*\) *->"` проти `grep -c "^\s*func "` |
| Типізація локальних змінних | 1 302 типізованих проти 53 нетипізованих (96%) | `grep -hE "^\s+var [a-z_0-9]+ *(:=\|: )"` |
| Мережа з гри | жодного `HTTPRequest`, `TCPServer`, `OS.execute`, URL у `scripts/` | `grep -nE "HTTPRequest\|StreamPeerTCP\|TCPServer\|WebSocket\|OS\.execute\|https?://" scripts/*.gd` порожньо |
| Автозавантаження | не використовуються (`project.godot` без `[autoload]`), глобальний стан не прихований | `grep -A8 "^\[autoload\]" project.godot` порожньо |
| Геометрія в чистих функціях | 15 функцій `*_points`/`*_geom*` у `enemy.gd` (за T-002) | `grep -c "func .*geom\|_points(" scripts/enemy.gd` |

## 3. Реєстр дефектів

| ID | Серйозність | Суть | Доказ | Статус |
|---|---|---|---|---|
| `COD-01` | HIGH | Функції-велетні в `player.gd` (2 105 рядків): `_draw()` 544 рядки (1403–1946), `_compute_skeletal_pose()` 443 (960–1402), `_physics_process()` 311 (549–859). Такі функції не тестуються по частинах, а будь-яка правка ризикує зламати сусідню поведінку. T-002 («геометрію персонажів у чисті функції») для Джури не виконано | `awk` по `^func`; `grep -n "func _draw\|func _compute_skeletal_pose\|func _physics_process" scripts/player.gd` | open |
| `COD-02` | HIGH | Порушення правила T-009: `enemy.gd` має 12 рядків з `get_parent()`; корінь рівня шукається через ланцюжки `get_parent().get_parent()` (рядки 133–135, 275–277, 361–363, 425–426). Це ламається, коли вузол вставляють в іншу групу (`Cast`, `Enemies` — обидва `CanvasGroup`). Для цього створено `scripts/level_root.gd`, але ворог ним не користується. Ще 9 викликів у `hutsul_ally.gd` (2), `qirimli_ally.gd` (3), `qirimli_arrow.gd`, `qirimli_falcon.gd`, `vakula_horseshoe.gd`, `hutsul_bartka.gd` | `grep -c "get_parent()" scripts/*.gd`; `sed -n 130,136p scripts/enemy.gd` | open |
| `COD-03` | MEDIUM | `game_manager.gd` (1 544 рядки) змішує логіку з ~400 рядками даних: `LEVEL_PLATFORMS` (рядок 209) і `LEVEL_BOMBS` (рядок 404) — константні таблиці для 20 рівнів прямо між функціями. Перегляд diff і злиття між агентами ускладнені | `sed -n 203,215p scripts/game_manager.gd` | fixed 2026-10-26 (`scripts/level_data.gd`; `game_manager.gd` 1544 → 1339 рядків, `LEVEL_PLATFORMS`/`LEVEL_BOMBS` лишилися сумісними аліасами) |
| `COD-04` | MEDIUM | `gdlint` повідомляє 1 640 проблем: 751 `max-line-length`, 678 `trailing-whitespace`, 175 `class-definitions-order`, 11 `load-constant-name`, 8 `max-returns`, 5 `max-file-lines` (файли понад 1 000 рядків: `player.gd`, `enemy.gd`, `game_manager.gd`, `story_cards.gd`, `background_visual.gd`). `gdformat --check`: усі 36 файлів змінилися б. Hook у `.claude/settings.json` лише перевіряє синтаксис | `gdlint scripts test`; `gdformat --check scripts test` | open |
| `COD-05` | MEDIUM | Нетипізовані змінні при отриманні вузлів: `var parent = get_parent()` (`enemy.gd:133`), `var p_mgr = get_parent()` (275, 361). Саме там, де потрібна статична перевірка, її немає; це пов'язано з COD-02 | `grep -nE "var [a-z_]+ = get_parent" scripts/enemy.gd` | open |
| `COD-06` | LOW | Скрипти без прямого посилання в `test/` (пошук за іменем файлу та `class_name`): `background_visual.gd` (1 030 рядків), `hutsul_bartka.gd`, `level_root.gd`, `power_flower.gd`, `qirimli_arrow.gd`, `qirimli_falcon.gd`, `vakula_horseshoe.gd`. Вони можуть покриватися опосередковано через `test_levels.gd` | цикл `grep -l` по `test/*.gd` | open |
| `COD-07` | LOW | Схожа структура `hutsul_ally.gd` (612 рядків) і `qirimli_ally.gd` (615) та `mavka_ally.gd` (228) натякає на спільний базовий клас союзника. Дублювання **не виміряно** (спроба порівняти унікальні рядки через `comm` невдала, бо я не відсортував вхід) | див. «Межі» | not confirmed |

## 4. Пропозиції

1. **Розбити `player.gd` (COD-01).** Винести малювання у `scripts/player_draw.gd` (чисті функції від позиції та пози), `_compute_skeletal_pose` у `scripts/player_pose.gd`. Тест Anti-Clipping для Джури за зразком чортика.
   *EARS:* No function in `scripts/` SHALL exceed 150 lines. *Приймання:* `tools/check_func_length.py` (awk-перевірка) повертає 0; `tools/run_tests.sh` зелений.
2. **Замінити `get_parent().get_parent()` (COD-02, COD-05).** Метод `LevelRoot.of(node) -> LevelRoot` (статичний, піднімається по дереву до першого вузла з групою `level_root`). Усі 21 викликів замінити.
   *EARS:* Scripts SHALL obtain the level root only through `LevelRoot.of()`. *Приймання:* `grep -nE "get_parent\(\)\.get_parent\(\)|p_mgr" scripts/` порожньо; `test_levels.gd` і `test_jump_to_top_beam.gd` зелені.
3. **Дані рівнів у ресурс (COD-03).** `scripts/level_data.gd` (`class_name LevelData`) або `data/levels.json` із завантаженням у `_ready`; `test_level_reachability.gd` читає той самий джерело.
4. **Лінт поетапно (COD-04).** Спершу `trailing-whitespace` і `max-line-length` автоматично `gdformat` одним комітом, що не змішується з іншою роботою. Потім `.gdlintrc` з вимкненими `class-definitions-order` і `max-line-length` до 140, щоб CI мав нульовий базис.
   *EARS:* WHEN CI runs, `gdlint scripts` SHALL report 0 problems under the project `.gdlintrc`. *Приймання:* код виходу 0.
5. **Покриття (COD-06).** Дим-тест `test/test_scenes_load.gd`: інстанціює кожну сцену з `scenes/` і викликає один кадр.

## 5. План хвилями

| Хвиля | Строк | Зміст | Приймання |
|---|---|---|---|
| 1 | день | `.gdlintrc` + одноразовий `gdformat` (COD-04) окремим комітом | `gdlint scripts` 0 |
| 2 | тиждень | `LevelRoot.of()` (COD-02, COD-05); дим-тест сцен (COD-06) | grep порожній, нові тести PASS |
| 3 | місяць | Розбиття `player.gd` і дані рівнів (COD-01, COD-03) | жодна функція > 150 рядків; тести зелені |

## 6. Межі валідності

- Довжини функцій рахувалися awk-скриптом по рядках `^func`; вкладені класи та `static func` у кінці файлу могли спотворити результат для останньої функції (для `game_manager.gd` я перевірив вручну: рядки 203–609 це `_toggle_fullscreen` плюс дві константи).
- COD-06 за іменем файлу; непряме покриття через інші тести не оцінювалося кількісно (покриття рядків недоступне в GDScript без додаткових інструментів).
- COD-07 не підтверджено й не спростовано.
- Поведінку в запущеній грі (кадрова частота, пам'ять) я не вимірював.
