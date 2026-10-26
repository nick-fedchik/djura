# Інструменти (`tools/`)

Усі шляхи рахуються від кореня репозиторію, ніяких `/home/<користувач>/` (перевіряє `test_hygiene.py`).
Python-залежності: `pip install -r tools/requirements.txt`. Скрипти з позначкою Blender запускаються як
`blender --background --python <скрипт>` (Blender 5.0.1) і користуються його вбудованими `bpy`/`mathutils`.

| Скрипт | Призначення | Залежності | Тест |
|---|---|---|---|
| `run_tests.sh` | усі перевірки однією командою (GDScript + Python) | godot 4.7, python3 | це і є набір |
| `test_tools.py`, `test_sprite_generator.py`, `test_hygiene.py` | Python-тести інструментів | numpy, Pillow | так |
| `build_web.sh` | експорт у Web (`build/web`) | godot, шаблони експорту | ні |
| `lan_server.py` | HTTPS/HTTP-сервер веб-збірки для LAN (Xbox, телефон) | openssl | ні |
| `analyze_telemetry.py` | калібровка Раша за `user://telemetry/events.jsonl` | stdlib | так |
| `tuning_validator.py` | детермінований валідатор пропозицій налаштувань | stdlib | так |
| `ollama_review.py` | дорадчий огляд телеметрії моделлю (поза грою); `OLLAMA_HOST`, `OLLAMA_MODEL` | мережа до Ollama | частково |
| `vlm_sprite_auditor.py` | дорадчий VLM-аудит спрайтів; `OLLAMA_HOST` | мережа до Ollama | так (офлайн-режим) |
| `render_sprites.gd` | процедурний рендер спрайтів із Godot | godot | ні |
| `render_sprites_3d.py` | Blender: 3D→2D кадри за діями (ADR-003) | Blender | через `test_sprite_generator.py` |
| `bake_meshy_*.py`, `render_turnaround_12.py`, `stitch_turnaround.py` | Blender: спрайти з моделей Meshy | Blender | ні |
| `blender/*.py` | побудова моделей, цел-шейдер, пакувальник аркушів, сцена рендера | Blender | частково |
| `create_npc_meshy_sketches.py`, `create_story_slide_art.py` | ескізи НПС і слайди історії | Pillow | ні |
| `audio/*.py` | процедурний синтез звуку й музики у `assets/audio/` | stdlib | перевірка `OUT_DIR` у `test_hygiene.py` |
| `archive/` | одноразові скрипти, лишені для довідки | | ні |

Мережеві інструменти (`ollama_review.py`, `vlm_sprite_auditor.py`) за замовчуванням звертаються до вузла J501
(`http://192.168.68.68:11434`) і попереджають у stderr, якщо `OLLAMA_HOST` не задано.
