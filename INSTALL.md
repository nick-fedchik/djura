# 🛠️ Інструкція зі встановлення та налаштування робочого середовища розробника (INSTALL.md)

**Проєкт:** «Джура: початок шляху козака» (*Djura: Path of the Cossack*)  
**Рушій:** Godot Engine 4.x (рекомендовано 4.3+ або 4.7 Standard, 64-bit, без .NET)  
**Мова скриптів:** GDScript 2.0 + Python 3.13 / 3.14+ (проєкт верифіковано на Python 3.14)  
**Репозиторій:** [https://github.com/nick-fedchik/djura.git](https://github.com/nick-fedchik/djura.git)

Цей посібник допоможе новим розробникам, художникам і тестувальникам швидко налаштувати оточення, запустити проєкт локально та доєднатися до розробки гри під **Ubuntu Linux** або **Windows 10 / 11**.

---

## 📋 Системні вимоги

| Компонент | Мінімальні | Рекомендовані |
| :--- | :--- | :--- |
| **ОС** | Ubuntu 22.04 LTS / Windows 10 (64-bit) | Ubuntu 24.04 LTS / Windows 11 |
| **Процесор** | 2 ядра, 2.0 GHz (x86_64) | 4+ ядра (Intel i5/i7, AMD Ryzen) |
| **ОЗП** | 4 ГБ | 8–16 ГБ |
| **Відеокарта** | Підтримка OpenGL 3.3 / Vulkan 1.0 | NVIDIA GeForce GTX 1060 / RTX або еквівалент |
| **Вільне місце** | 1 ГБ (проєкт) + 500 МБ (Godot) | 5 ГБ (з урахуванням Blender та інструментів) |

---

## 🐧 Встановлення та запуск на Ubuntu Linux (22.04 / 24.04 LTS)

### Крок 1. Встановлення базових залежностей
Відкрийте термінал (`Ctrl + Alt + T`) та оновіть пакети:
```bash
sudo apt update && sudo apt install -y git python3 python3-pip curl unzip
```

### Крок 2. Встановлення Godot Engine 4.x
Оберіть один із двох найзручніших способів:

* **Варіант А (Швидке завантаження офіційного бінарника — Рекомендовано):**
  ```bash
  # Створюємо папку для користувацьких бінарників у PATH
  mkdir -p ~/.local/bin

  # Завантажуємо офіційний реліз Godot 4 (наприклад, 4.3-stable або 4.7)
  curl -L -o /tmp/godot.zip https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip
  unzip -q /tmp/godot.zip -d ~/.local/bin/
  mv ~/.local/bin/Godot_v4.3-stable_linux.x86_64 ~/.local/bin/godot
  chmod +x ~/.local/bin/godot

  # Перевіряємо версію
  godot --version
  ```

* **Варіант Б (Через Snap):**
  ```bash
  sudo snap install godot-4 --classic
  ```

### Крок 3. Клонування репозиторію
```bash
git clone https://github.com/nick-fedchik/djura.git
cd djura
```

### Крок 4. Запуск автоматизованих тестів
Перед початком роботи переконайтеся, що всі 14 тестів проходять:
```bash
bash tools/run_tests.sh
```
Очікуваний вивід: `Усі перевірки пройшли` (14/14 PASS).

### Крок 5. Запуск гри та редактора
* **Запуск гри безпосередньо:**
  ```bash
  godot --path .
  ```
* **Запуск редактора Godot:**
  ```bash
  godot -e --path .
  ```

---

## 🪟 Встановлення та запуск на Windows 10 / 11

### Крок 1. Швидке встановлення компонентів через Winget (в один клік)
Відкрийте **PowerShell** або **Термінал Windows** від імені адміністратора та виконайте команду встановлення Git, Python і Godot:
```powershell
winget install --id Git.Git -e --source winget
winget install --id Python.Python.3.14 -e --source winget
winget install --id GodotEngine.GodotEngine -e --source winget
```
*(Якщо `Python.Python.3.14` ще не синхронізовано у вашому регіоні Winget, команда `winget install --id Python.Python.3.13 -e --source winget` або `winget install Python.Python.3` встановить найсвіжіший офіційний реліз. Після встановлення перезапустіть вікно PowerShell, щоб оновилися змінні середовища PATH).*

> **Альтернативний ручний спосіб:**
> 1. Завантажте **Git for Windows**: [git-scm.com/download/win](https://git-scm.com/download/win).
> 2. Завантажте **Godot Engine 4.x (Standard version)**: [godotengine.org/download/windows](https://godotengine.org/download/windows) (розпакуйте архів `Godot_v4.*.exe` у зручну папку, наприклад `C:\Tools\Godot\`, і додайте в PATH або створіть ярлик).
> 3. Завантажте актуальний **Python 3.14 / 3.13+**: [python.org/downloads](https://www.python.org/downloads) (обов'язково поставте прапорець **«Add python.exe to PATH»** під час інсталяції).

### Крок 2. Клонування проєкту
Відкрийте **Git Bash** або **PowerShell**:
```bash
git clone https://github.com/nick-fedchik/djura.git
cd djura
```

### Крок 3. Запуск проєкту через графічний інтерфейс Godot
1. Запустіть **Godot Engine** через ярлик або меню «Пуск».
2. У вікні менеджера проєктів натисніть кнопку **«Import» (Імпортувати)** праворуч угорі.
3. Натисніть **«Browse» (Огляд)**, знайдіть папку, куди ви клонували репозиторій (`djura`), і виберіть файл **`project.godot`**.
4. Натисніть **«Import & Edit» (Імпортувати й редагувати)**.
5. У редакторі Godot натисніть клавішу **F5** (або кнопку запуску ▶ у правому верхньому куті) для запуску гри.

### Крок 4. Запуск тестів у Windows (через Git Bash або WSL)
У терміналі **Git Bash** виконайте:
```bash
./tools/run_tests.sh
```

---

## 🎨 Додатково: Інструменти для 3D-моделлерів (Blender)

Якщо ви плануєте працювати над 3D-моделями (`assets/models/*.glb`, `*.blend`) або запікати спрайт-листи:
* **Ubuntu:**
  ```bash
  sudo apt install -y blender
  ```
* **Windows:**
  ```powershell
  winget install --id BlenderFoundation.Blender -e --source winget
  ```

Для перегляду сцен і референсів персонажів у папці `assets/models/`:
```bash
# Відкрити модель Джури (15 років):
blender assets/models/djura_meshy.blend

# Відкрити модель Козака-Наставника:
blender assets/models/mentor_cossack.blend

# Відкрити студію ортографічних референсів:
blender assets/models/djura_reference_studio.blend
```

---

## 🎮 Керування у грі та гарячі клавіші розробника

| Дія | Клавіатура | Геймпад (XInput / Logitech F310) |
| :--- | :--- | :--- |
| **Рух ліворуч / праворуч** | `A / D` або `← / →` | Лівий аналоговий стік / D-Pad |
| **Стрибок** | `Пробіл` / `W` / `↑` | Кнопка `A` (Хрестик) |
| **Ширяння на киреї** | Утримувати `Пробіл` у повітрі | Утримувати `A` у повітрі |
| **Бойовий Гопак («Пістоль»)** | `C`, `K` або `Z` | Кнопка `B` або `Y` |
| **Ухил / швидкий крок** | `Shift` | Бампери `LB / RB` |
| **Гаряче перемикання графіки (Hot-Toggle)** | **`F6`** (перемикає 3D-спрайти $\leftrightarrow$ 2D вектор) | — |
| **Пауза / Меню** | `Esc` | Кнопка `Start` |

---

## 📁 Структура кодової бази

```text
djura/
├── assets/
│   ├── audio/           # Звукові ефекти та народні інструменти (.wav)
│   ├── models/          # 3D-моделі (.glb, .blend) Джури та Наставника
│   └── sprites/         # Спрайт-листи, текстури та референси (.png, .tres)
├── docs/
│   ├── GDD.md           # Головний Game Design Document та ЛОР гри
│   ├── SHR-*.md         # Вимоги зацікавлених сторін (Stakeholder Requirements)
│   ├── SWR-*.md         # Програмні вимоги (Software Requirements)
│   └── ADR-*.md         # Архітектурні рішення (Architectural Decisions)
├── scenes/              # Сцени Godot (.tscn: гравець, вороги, рівні, HUD, історія)
├── scripts/             # Вихідний код на GDScript (.gd)
│   ├── player.gd        # Фізика козацького паркуру, кирея, Гопак, IK
│   ├── telemetry.gd     # Збір ігрових метрик для адаптивного потоку
│   └── story_cards.gd   # Сцени наставництва біля вогнища між рівнями
├── shaders/             # GLSL шейдери (чорнильний контур, сел-шейдинг)
├── test/                # Автоматизовані headless-тести для перевірки інваріантів
└── tools/               # Утиліти Python/Bash для збірки, тестів та рендерингу
```

---

## 📜 Правила та інваріанти для контриб'юторів

Перед відправленням Pull Request або пропозицій змін ознайомтеся з [**`docs/GDD.md`**](docs/GDD.md):

1. **Інваріант Нульового Жаху (Zero-Horror Invariant $I-3$):**  
   Категорично заборонено криваві сцени, насилля чи жахи. Вороги — казкові персонажі, які смішно лякаються й тікають від народного гумору.
2. **Інваріант Анти-Кліпінгу (Anti-Clipping Invariant $I-4$):**  
   Підошви персонажів завжди прив'язані до нульової лінії контакту ($Z = 0$, `y = 16`). Ноги ніколи не провалюються крізь платформи.
3. **100% успішність тестів:**  
   Жоден Pull Request не приймається без проходження перевірки `bash tools/run_tests.sh`.

---

## 🤝 Контакти та спільнота

- **Автор і лід проєкту:** Nick Fedchik ([@nick-fedchik](https://github.com/nick-fedchik))
- **Баг-трекер та пропозиції:** [GitHub Issues](https://github.com/nick-fedchik/djura/issues)
- **Ліцензія:** Відкритий вихідний код згідно з файлом `LICENSE` у корені репозиторію.
