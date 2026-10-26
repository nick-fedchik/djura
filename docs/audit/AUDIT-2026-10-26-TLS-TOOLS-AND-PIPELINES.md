# АУДИТ TLS: Інструменти та конвеєри

- **Код аудиту:** `TLS` (`TLS-01..TLS-08`)
- **Дата:** 2026-10-26
- **Аудитор:** Claude Sonnet 5.5 (лише читання; мережа й Blender не запускались)
- **Об'єкт:** `tools/*.py`, `tools/*.sh`, `tools/blender/*.py`, `tools/diagnostics.js`, кореневі `generate_*.py`, `make_*_sfx.py`, `update_audio.py`
- **Коміт:** `92174da`; `git status --short`: 34 записи
- **Інструменти:** python3 (`-I`), grep, bash

---

## 1. Підсумок

В інструментах є цінне: конвеєр 3D→2D (Blender → спрайт-аркуш → `SpriteFrames`), аналізатор телеметрії, валідатор налаштувань. Але більшість скриптів прив'язана до однієї машини жорсткими абсолютними шляхами (25 файлів містять `/home/mfedchyk`), а 10 генераторів звуку пишуть у **старий каталог `~/geek-jack/assets/audio`**, тобто в іншу робочу копію репозиторію, а не в цей проєкт. Тестовано лише два з приблизно 20 скриптів.

## 2. Що в порядку

| Перевірка | Результат | Команда |
|---|---|---|
| Python-тести інструментів | `tools/test_tools.py` OK; `tools/test_sprite_generator.py` PASS у `run_tests.sh` | `python3 -I tools/test_tools.py` |
| Ollama лише дорадчо й поза грою | `ollama_review.py` читає `OLLAMA_HOST` зі змінної середовища (`ollama_review.py:19`) | читання |
| Веб-збірка: Secure Context | `lan_server.py` додає COOP/COEP, MIME для `.wasm`/`.pck`, генерує самопідписаний сертифікат | читання заголовка файлу |
| Збірка перевіряє залежність | `build_web.sh:14` `command -v godot` | читання |
| Мережевий код лише на стандартній бібліотеці | `urllib`, `http.server`, `ssl`, `socket` (без `requests`) | `grep -hE "^(import\|from) " tools/*.py` |

## 3. Реєстр дефектів

| ID | Серйозність | Суть | Доказ | Статус |
|---|---|---|---|---|
| `TLS-01` | HIGH | Генератори звуку в корені (`generate_audio.py:8`, `generate_cossack_bgm.py:7`, `generate_fantasy_sfx.py:7`, `generate_hopak.py:7`, `generate_jarre.py:8`, `generate_comic_sfx.py:7`, `make_bonk_sfx.py:7`, `make_hopak_sfx.py`, `make_roll_sfx.py:7`, `update_audio.py:7`; усього 10 файлів) мають `OUT_DIR = "/home/mfedchyk/geek-jack/assets/audio"`. Каталог `~/geek-jack` існує як окрема стара робоча копія (коміт `77f5206`, 59 МБ), тож запуск скрипта оновить звуки **не в цьому проєкті**. Відновлення звуків у `djura-1` потребує ручного копіювання | `grep -rn "geek-jack/assets" *.py`; `git -C ~/geek-jack log --oneline -1` | fixed 2026-10-26 (не закомічено) |
| `TLS-02` | HIGH | 25 файлів містять абсолютний шлях `/home/mfedchyk`, зокрема `bake_meshy_djura_animated.py:18, 177, 416–421`, `bake_meshy_qirimli_sprites.py:21, 69`, `blender/create_djura_hero_model.py:462`. Конвеєр не запуститься на іншому комп'ютері чи в CI, а при перейменуванні каталогу мовчки писатиме не туди | `grep -rlE "/home/mfedchyk" --include=*.py --include=*.sh . \| wc -l` → 25 | fixed 2026-10-26 (не закомічено) |
| `TLS-03` | MEDIUM | Жорстко прописана LAN-адреса Jetson `192.168.68.68:11434` як значення за замовчуванням у `vlm_sprite_auditor.py:18` і `ollama_review.py:19`. Інший користувач чи мережа отримає тайм-аут 45 с (`vlm_sprite_auditor.py:82`) замість зрозумілої помилки | `grep -n "192.168" tools/*.py` | partially fixed 2026-10-26 (попередження; значення за замовчуванням збережено) |
| `TLS-04` | MEDIUM | `parse_meshy.py` витягує дані зі сторінки `meshy.ai` за жорстким URL конкретної моделі без перевірки статусу й тайм-ауту (`urlopen(req)` без `timeout`, рядок 6); це розбір HTML, який зламається зі зміною сайту. Файл не описаний у `docs/` | `sed -n 1,10p tools/parse_meshy.py` | fixed 2026-10-26 (не закомічено) |
| `TLS-05` | MEDIUM | Два конкуруючі конвеєри спрайтів без пояснення, який основний: процедурний `tools/render_sprites.gd` і Blender `tools/render_sprites_3d.py` + чотири скрипти `bake_meshy_*`. Лише `test_sprite_generator.py` покриває один із них. Розбіжність із «100% процедурна графіка» (див. DOC-01) | `ls tools` | fixed 2026-10-26 (не закомічено) |
| `TLS-06` | LOW | `lan_server.py` за замовчуванням слухає `0.0.0.0` (`lan_server.py:185`) і віддає `build/web` усім у мережі з самопідписаним сертифікатом. Для домашньої розробки прийнятно, але немає попередження про публічні Wi-Fi і немає обмеження на підмережу | `grep -n "0.0.0.0" tools/lan_server.py` | fixed 2026-10-26 (не закомічено) |
| `TLS-07` | MEDIUM | Залежності Python не зафіксовані: скрипти імпортують `numpy` і `PIL` (Pillow), Blender-скрипти `bpy`/`mathutils`, але немає `requirements.txt`, `pyproject.toml` чи розділу в `INSTALL.md` з версіями. `tools/test_sprite_generator.py` тому залежить від того, що Pillow випадково встановлений | `ls requirements*.txt pyproject.toml` → не знайдено; `grep -hE "^(import\|from) " tools/*.py *.py` | fixed 2026-10-26 (не закомічено) |
| `TLS-08` | MEDIUM | `vlm_sprite_auditor.py` при недосяжному вузлі повертає `"approved": True` з `offline_fallback` (рядки ~88–95): відмова інфраструктури виглядає як схвалення спрайта (fail-open). Звіт `reports/sprite_audit_test_cossack.json` має `approved`, і відрізнити реальну оцінку від заглушки можна лише за прапорцем. Поведінку закріплює тест `tools/test_sprite_generator.py:68-76` (`assertTrue(res.get("approved"))`), тому змінювати її без рішення власника не можна | `sed -n 84,97p tools/vlm_sprite_auditor.py`; `sed -n 68,76p tools/test_sprite_generator.py` | open (потрібне рішення власника) |

## 4. Пропозиції

1. **Шляхи від кореня проєкту (TLS-01, TLS-02).** Спільний модуль `tools/paths.py`: `ROOT = Path(__file__).resolve().parents[1]`, `ASSETS = ROOT / "assets"`; скрипти беруть `OUT_DIR` звідти, Blender-скрипти отримують корінь через аргумент `-- --root <шлях>`.
   *EARS:* No script in the repository SHALL contain an absolute path to a user home directory. *Приймання:* `grep -rE "/home/[a-z]+" --include=*.py --include=*.sh . ` порожньо; скрипти запускаються з клону в довільному каталозі.
2. **Один перелік звукових генераторів (TLS-01).** Перенести в `tools/audio/` разом із `README`, що пояснює, який файл що генерує; у `test_tools.py` додати перевірку, що `OUT_DIR` лежить усередині репозиторію.
3. **Конфігурація через змінні (TLS-03).** `OLLAMA_HOST` обов'язкова змінна, без значення за замовчуванням; зрозуміла помилка: «Задайте OLLAMA_HOST».
   *EARS:* WHEN `OLLAMA_HOST` is not set, the tool SHALL exit with code 2 and a message naming the variable. *Приймання:* запуск без змінної завершується за < 1 с.
4. **Видалити або задокументувати `parse_meshy.py` (TLS-04).** Якщо він одноразовий, перенести в `tools/archive/`, інакше додати тайм-аут і обробку помилок.
5. **`tools/README.md` (TLS-05).** Таблиця: скрипт, вхід, вихід, залежності (Blender/Ollama/мережа), чи покритий тестом, чи основний.
6. **Залежності (TLS-07).** `tools/requirements.txt` (`numpy`, `Pillow` із версіями) і рядок у `INSTALL.md` про Blender 5.0.1 для `bpy`-скриптів.
   *EARS:* The repository SHALL list every third-party Python dependency with a version. *Приймання:* `pip install -r tools/requirements.txt` у чистому venv дозволяє пройти `python3 tools/test_sprite_generator.py`.
7. **`lan_server.py` (TLS-06).** За замовчуванням `--bind` на першу приватну LAN-адресу; повідомлення про ризик при виборі `0.0.0.0`.

## 5. План хвилями

| Хвиля | Строк | Зміст | Приймання |
|---|---|---|---|
| 1 | день | TLS-01 (виправити `OUT_DIR` у 10 скриптах), TLS-03 | grep по `geek-jack` порожній |
| 2 | тиждень | TLS-02 (`paths.py`), TLS-05 (`tools/README.md`) | grep по `/home/` порожній |
| 3 | місяць | TLS-04, TLS-06; тест, який на чистому клоні проганяє детермінований підмножину інструментів | тест у `run_tests.sh` |

## 6. Межі валідності

- Після виправлень Blender-скрипти не запускались: `_PROJECT_ROOT` будується з `__file__`, що Blender задає при `--python`, але під `exec()` або інтерактивною консоллю змінна була б не визначена.

- Жоден Blender-скрипт не запускався, тож їхню працездатність я не оцінював.
- Мережеві скрипти (`vlm_sprite_auditor.py`, `ollama_review.py`, `parse_meshy.py`) не запускалися; висновки про тайм-аути й відсутність обробки помилок зроблено з читання.
- 25 файлів з `/home/mfedchyk` підраховано грепом за розширеннями `.py`/`.sh`; у цей перелік входять і коментарі.
- Чи потрібен ще `~/geek-jack` власнику (архів чи робоча копія), я не знаю; TLS-01 стверджує лише, що скрипти пишуть туди.

## 7. Журнал виправлень (2026-10-26)

| Дефект | Що зроблено | Перевірка |
|---|---|---|
| TLS-01, ORG-03 | 11 генераторів звуку перенесено `git mv` у `tools/audio/`; `OUT_DIR` рахується від розташування файлу (`../../assets/audio`); `generate_vakula_sfx.py` більше не залежить від cwd; порожній кореневий `main.tscn` видалено (на нього немає посилань) | `tools/test_hygiene.py::test_audio_generators_write_inside_repo` |
| TLS-02 | У 15 файлах `tools/**` абсолютні шляхи замінено на `_PROJECT_ROOT` (від `__file__`) | `tools/test_hygiene.py::test_no_absolute_home_paths`; негативна перевірка: тимчасовий файл із `/home/someone/` валить тест |
| TLS-03 | `OLLAMA_HOST` читають обидва мережеві інструменти; без змінної друкується попередження в stderr. **Відхилення від пропозиції:** значення J501 лишено за замовчуванням, а не помилку з кодом 2, бо воно задокументоване в T-025/T-030 і ламало б існуючий процес | читання |
| TLS-04 | `parse_meshy.py` (одноразовий, ніхто не посилається) перенесено в `tools/archive/` | `grep -rn parse_meshy` |
| TLS-05 | `tools/README.md`: таблиця скриптів, залежностей і тестів | читання |
| TLS-06 | `lan_server.py` попереджає в stderr при `--bind 0.0.0.0`; поведінку за замовчуванням не змінено, бо Xbox і телефон мають бачити сервер | читання |
| TLS-07 | `tools/requirements.txt` (`numpy>=2.0`, `Pillow>=11.0`) | `tools/test_hygiene.py::test_third_party_imports_are_declared` |
| TLS-08 | знайдено під час виправлень; не виправлено, див. реєстр | |

Тести: `tools/run_tests.sh` → «Усі перевірки пройшли» (16 перевірок). Blender-скрипти після зміни шляхів **не запускались**; перевірено лише `py_compile` (див. межі валідності).
