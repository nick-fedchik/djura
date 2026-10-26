# АУДИТ BLD: Ресурси, експорт і збірка

- **Код аудиту:** `BLD` (`BLD-01..BLD-06`)
- **Дата:** 2026-10-26
- **Аудитор:** Claude Sonnet 5.5 (лише читання)
- **Об'єкт:** `assets/`, `reports/`, `export_presets.cfg`, `tools/build_web.sh`, `build/`, `.gitignore`
- **Коміт:** `92174da`; `git status --short`: 34 записи
- **Інструменти:** Godot 4.7.2.stable, `du`, `git count-objects`

---

## 1. Підсумок

Веб-збірка гри важить **422 МБ** (`build/web/index.pck` = 401 927 704 байт) для аркади, графіка якої за заявою README процедурна. Причина: пресет експорту `export_filter="all_resources"` пакує весь каталог `assets/`, зокрема 3D-моделі `.glb`/`.blend` (269 МБ), які не використовуються у виконанні (жоден скрипт чи сцена не посилається на `assets/models`). Ті самі файли додано до git без LFS: `git count-objects -vH` показує ~253 МБ невпакованих об'єктів. Це головний практичний ризик проєкту: гру для дітей не завантажити по мобільній мережі, а клонування репозиторію важчає з кожним новим рендером.

## 2. Що в порядку

| Перевірка | Результат |
|---|---|
| `build/` не відстежується git | `git ls-files build` порожньо; `build/` у `.gitignore` |
| `.godot/` (529 МБ кешу) не відстежується | `git ls-files \| grep ^\.godot/` порожньо |
| Аудіо легке | `du -sh assets/audio` → 3,8 МБ |
| Екранний вивід | `index.wasm` 39,5 МБ це стандартний рушій, не провина проєкту |
| Скрипт `tools/build_web.sh` перевіряє наявність `godot` у PATH | рядок 14 |

## 3. Реєстр дефектів

| ID | Серйозність | Суть | Доказ | Статус |
|---|---|---|---|---|
| `BLD-01` | HIGH | Експорт пакує невикористані ресурси: `export_presets.cfg:9` `export_filter="all_resources"`, `exclude_filter=""` (рядок 11). `index.pck` = 401,9 МБ. Моделі `assets/models/*.glb` (269 МБ) у виконанні не завантажуються: `grep -rn "assets/models" scripts scenes` порожньо | `ls -l build/web/index.pck`; `du -sh assets/models` | fixed 2026-10-26 (e4f1ccb; index.pck 402 МБ → 26 МБ, перевірено експортом) |
| `BLD-02` | HIGH | Великі бінарні файли у звичайному git без LFS: `mentor_cossack.blend` 54,8 МБ, `mentor_cossack.glb` 50,3 МБ, `qirimli.glb` 31,3 МБ, `vohnyk.glb` 28,9 МБ, `djura_meshy.blend` 24,5 МБ. Запис в історії необоротний без переписування. Окремо `reports/sketches/` = 100 МБ (JPEG від Meshy) | `git ls-files \| xargs -d '\n' du -k \| sort -rn \| head`; `git count-objects -vH` | open |
| `BLD-03` | HIGH | `.blend` і `.glb` в `assets/` Godot автоматично імпортує (створює `.import` і копії в `.godot/imported/`) навіть якщо вони не використовуються: Імпортовані `.scn` із `.glb`/`.blend` займають 198 МБ із 525 МБ у `.godot/imported`, ще частину дають `.ctex` з JPEG-текстур моделей. Кожен новий клон і CI платять цей час і диск | `du -ch .godot/imported/*glb* .godot/imported/*blend*`; `git ls-files \| grep -c "\.import$"` → 141 | fixed 2026-10-26 (e4f1ccb: `sources/` + `.gdignore`) |
| `BLD-04` | MEDIUM | Untracked: 14 `.jpg` текстур у `assets/models/`, каталог `assets/models/textures/` та 20+ `*.import` для `assets/sprites/`. Частина `.import` відстежується (141), частина ні, тож стан залежить від того, хто останнім відкривав редактор | `git status --short \| grep '^??'` | fixed 2026-10-26 (`.import` для `assets/sprites` закомічено; `assets/models` більше немає) |
| `BLD-05` | MEDIUM | `reports/` (102 МБ) містить вхідні ескізи (`reports/sketches/`), а не звіти; є прев'ю `reports/*_preview.png`, на які посилаються `.import`. Назва каталогу вводить в оману, а `reports/` не виключено з експорту | `du -sh reports/*` | fixed 2026-10-26 (e4f1ccb: ескізи в `sources/sketches`) |
| `BLD-06` | LOW | `build/render_tmp` (4,6 МБ) тимчасовий вивід рендера лежить у `build/` разом із релізною веб-збіркою; очищення `build/` для релізу знищить і його | `ls build` | fixed 2026-10-26 (`.tmp/render_tmp`, ігнорується) |

## 4. Пропозиції

1. **Виключити з експорту (BLD-01).** `exclude_filter="assets/models/*,reports/*,docs/*,test/*,templates/*,*.blend,*.glb"` у пресеті Web.
   *EARS:* The Web export SHALL NOT contain files that no scene or script references. *Приймання:* `index.pck` ≤ 40 МБ; `godot --headless --export-release Web` проходить, `test/test_levels.gd` на збірці зелений.
2. **Git LFS (BLD-02).** Налаштувати `*.glb`, `*.blend`, `*.psd` у `.gitattributes` (`filter=lfs`). Існуючу історію мігрувати (`git lfs migrate import`) лише за згодою власника, бо це переписування історії.
3. **Не імпортувати вихідні моделі (BLD-03).** Покласти їх у каталог із порожнім файлом `.gdignore` (напр. `sources/models/`), тоді Godot їх не скануватиме.
   *EARS:* Source 3D models SHALL reside in a directory ignored by the Godot importer. *Приймання:* `.godot/imported` ≤ 100 МБ після чистого відкриття.
4. **Єдина політика `.import` (BLD-04).** Або відстежувати всі `.import`, або жодного; вписати у `.gitignore`/`CONTRIBUTING.md`.
5. **Перейменувати (BLD-05, BLD-06).** `reports/sketches` → `sources/sketches`; `build/render_tmp` → `.cache/render_tmp`.

## 5. План хвилями

| Хвиля | Строк | Зміст | Приймання |
|---|---|---|---|
| 1 | день | BLD-01 (виключення), BLD-06 | `index.pck` ≤ 40 МБ |
| 2 | тиждень | BLD-03, BLD-05 (`sources/` + `.gdignore`) | відкриття редактора не створює імпортів моделей |
| 3 | місяць | BLD-02 (LFS, міграція історії за згодою) | `git count-objects -vH` size-pack ≤ 50 МБ у новому клоні |

## 6. Межі валідності

- Збірку не перезапускав (потрібен web-шаблон експорту і час); розмір `index.pck` береться з наявного `build/web` від 2026-10-25 21:22. Прогноз ≤ 40 МБ це оцінка за сумою `assets/sprites` (26 МБ) + `assets/audio` (3,8 МБ), не вимір.
- Чи використовуються моделі у виконанні, перевірено пошуком шляху `assets/models` у `scripts/` і `scenes/`; динамічне завантаження за складеним шляхом (`"res://assets/" + name`) цей пошук не виявив би. Таких конкатенацій я не шукав.
- Розмір `.git` після клону з нуля не вимірювався.

## 7. Журнал виправлень (2026-10-26)

- BLD-01/03/05: зроблено в `e4f1ccb`; я лише перевірив пробним експортом (`godot --headless --export-release Web`): `index.pck` 26 МБ замість 402 МБ.
- BLD-04: закомічено `.import` для `assets/sprites/*`. BLD-06: тимчасовий рендер переїхав у `.tmp/`.
- **BLD-02 лишається open:** 369 МБ у `sources/` усе ще звичайний git, а старі бінарники лишаються в історії. Потрібне рішення власника (LFS і/або переписування історії).
