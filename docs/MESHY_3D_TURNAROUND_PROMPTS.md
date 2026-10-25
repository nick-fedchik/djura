# Ескізи з 12 кутів огляду та промпти для Meshy AI (Рівні 1 та 2)

Цей документ містить повну художню та технічну специфікацію для створення 3D-моделей та 2D-спрайтових поворотів (turnaround) усіх персонажів та ключових артефактів **Рівня 1 (Запорозька Січ)** та **Рівня 2 (Диканський / Степовий Хутір)** гри **«Джура: початок шляху козака»**.

> [!IMPORTANT]
> **Віковий інваріант побратимів (T-035 / GDD §2.1 & §4):**
> **Джура, Киримли та Гуцулик — ровесники (14–15 років)**. Вони є юними юнаками-підлітками, кандидатами у лицарі свого краю, сповненими енергії, спритності та взаємної поваги. Заборонено малювати Киримли чи Гуцула старими бородатими дідами.

---

## 1. Геометрична матриця 12 кутів огляду (Turnaround Matrix $\Delta\theta = 30^\circ$)

Для створення повноцінних 3D-асетів та спрайтових аркушів кожен персонаж моделюється або рендериться у нейтральній **A-позі (A-Pose)** навколо вертикальної осі $Y$ (обертання камери або платформи з кроком $30^\circ$):

| Ракурс | Кут $\theta$ | Назва ракурсу | Анатомічний та силуетний фокус |
| :--- | :---: | :--- | :--- |
| **A-01** | $0^\circ$ | **Front View (Фас)** | Повна фронтальна симетрія, вираз юного обличчя, вишивка коміра, пояс, посадка взуття. |
| **A-02** | $30^\circ$ | **Front 3/4 Left (Фас 3/4 зліва)** | Об'єм грудей, вигин шапки, ліве плече, китиця пояса на лівому боці. |
| **A-03** | $60^\circ$ | **Oblique Front-Left (Косий лівий)** | Контур носа, профіль капелюха (крисані/бьоріка), видимість зброї (бартки/лука). |
| **A-04** | $90^\circ$ | **Left Profile (Лівий профіль)** | Чистий профіль силуету, товщина торсу, форма чуба/пера, кріплення сагайдака/піхов. |
| **A-05** | $120^\circ$ | **Oblique Back-Left (Косий задній лівий)** | Ліва лопатка, задній схил шапки, спадання киреї/кептаря, ліва штанина. |
| **A-06** | $150^\circ$ | **Back 3/4 Left (Тил 3/4 зліва)** | Задні складки шароварів/гачів, поясний вузол, сагайдак за спиною. |
| **A-07** | $180^\circ$ | **Back View (Тил / Спина)** | Повна задня симетрія, орнамент спинки кептаря, спадання пояса, хвіст чортика. |
| **A-08** | $210^\circ$ | **Back 3/4 Right (Тил 3/4 справа)** | Права сторона спини, кріплення бартки, стріли в сагайдаку. |
| **A-09** | $240^\circ$ | **Oblique Back-Right (Косий задній правий)** | Контур правого плеча, вигин лука з правого боку. |
| **A-10** | $270^\circ$ | **Right Profile (Правий профіль)** | Чистий правий профіль, рух руки, вигин постолів/чобітків. |
| **A-11** | $300^\circ$ | **Oblique Front-Right (Косий передній правий)** | Праве плече, права щока, сокіл на руці/плечі (у Киримли). |
| **A-12** | $330^\circ$ | **Front 3/4 Right (Фас 3/4 справа)** | Динамічний тричетвертний ракурс, підготовка до фронтальної симетрії. |

---

## 2. Специфікація персонажів та промпти для Meshy AI (`https://www.meshy.ai/`)

---

### 2.1. Юний Джура (Djura Hero) — Головний герой (15 років)

* **Роль:** Кандидат у козаки, учень характерника, володар крилатої киреї.
* **Вік та анатомія:** 15 років, гнучкий, стрункий, спритний атлет без рослинності на обличчі, відкритий щирий погляд, хвацький чорний оселедець (чуб-айдар).
* **Одяг та спорядження:** Біла лляна вишиванка зі стійкою та червоно-чорним геометричним орнаментом, широкий шовковий червоний пояс із золотими китицями, вільні кобальтово-сині шаровари, м'які червоні сап'янці-чоботи, легка шовкова кирея за плечима.

#### Промпт для Meshy AI (Text-to-3D):
```text
3D character model of a young 15-year-old Ukrainian Cossack apprentice named Djura. Youthful athletic teenage boy, clean-shaven friendly face, lively brown eyes, authentic traditional Cossack shaved head with a single long black forelock hair strand (oseledets/chub) draped gracefully over one ear. Wearing an authentic white linen vyshyvanka shirt with red and black geometric embroidery on the standing collar and chest, a wide vibrant scarlet silk sash belt (koyas) tied at the waist with golden tassels hanging on the hip, loose flowing deep cobalt-blue Cossack sharovary trousers gathered into soft red leather Cossack boots (sap'yantsi). Light sky-blue silk capelet fluttering on the shoulders. 

Stylized 3D character, clean Pixar and classic Kyivnaukfilm cartoon animation aesthetic, warm vibrant colors, PBR stylized hand-painted textures, symmetrical relaxed A-pose, standing firmly on ground plane Z=0, full body visible from head to toe, clean quad topology, game-ready asset.
```

#### Negative Prompt:
```text
old man, mustache, beard, wrinkles, adult warrior, grotesque, horror, uncanny valley, photorealistic human skin pores, gritty, dark, low poly triangles, distorted limbs, modern clothing, jeans, sneakers, asymmetrical pose, floating, clipping through ground.
```

---

### 2.2. Киримли-Побратим (Qırımlı Yigit) — Лучник зі Степовим Соколом (14–15 років)

* **Роль:** Юний кримськотатарський батир, побратим Джури, неперевершений степовий стрілець.
* **Вік та анатомія:** **14–15 років (ровесник Джури)**, стрункий, засмаглий степовий юнак, проникливі мигдалеподібні карі очі, благородна постава, спритні пальці лучника.
* **Одяг та спорядження:** Традиційна кримськотатарська шапка з чорного каракулю (бьорк/бьорік) із темно-синім оксамитовим шликом та золотою вишивкою кримського родинного герба (Золота Тарак-Тамга). Бірюзово-синій шовковий чекмень/бішмет із срібними застібками, підперезаний тонким шкіряним ременем із карбуванням. Зручні східні штани-шальвари, заправлені в м'які шкіряні чобітки (ічіги). За спиною — шкіряний сагайдак зі стрілами та витончений кримськотатарський рекурсивний композитний лук. На лівому зап'ясті або плечі сидить маленький відважний степовий сокіл-сапсан (Şahin).

#### Промпт для Meshy AI (Text-to-3D):
```text
3D character model of a 15-year-old Crimean Tatar youth warrior and archer (Qırımlı Yigit), teenage sworn brother of the young Cossack. Slender agile teenage boy with healthy sun-tanned skin, expressive dark almond eyes, confident and kind youthful face, no beard, no mustache. Wearing an authentic traditional Crimean Tatar karakul fur hat (börk) with a navy-blue velvet crown finely embroidered with the golden Crimean Tarak-Tamga crest. Dressed in a tailored turquoise-blue silk cherkesska/bechmet coat with delicate silver braided clasps on the chest, a fine leather belt adorned with engraved silver plates. Flowing dark silk shalwar trousers neatly tucked into soft black leather archer riding boots (ichigi).

Carrying a beautifully crafted ornate horn-and-wood composite recurve steppe bow slung across his shoulder and a leather quiver with feathery fletched arrows on his back. A sleek alert young steppe falcon (saker falcon) perches comfortably on his leather-braced left forearm. 

Stylized 3D character, warm Crimean steppe folklore aesthetic, Pixar and Kyivnaukfilm animation art style, clean hand-painted PBR textures, neutral symmetrical A-pose, feet grounded at Z=0, full-length complete character, clean topology, game-ready asset.
```

#### Negative Prompt:
```text
elderly, thick beard, mustache, angry barbarian, menacing orc, modern camo, helmet with spikes, grotesque, horror, dark gritty realism, uncanny, lowpoly mesh distortion, extra fingers, asymmetric legs, detached bird.
```

---

### 2.3. Гуцулик-Легінь (Hutsul Yigit) — Карпатський Опришок з Барткою (14–15 років)

* **Роль:** Юний карпатський легінь із Чорногори, гірський акробат, майстер володіння барткою.
* **Вік та анатомія:** **14–15 років (ровесник Джури)**, міцний, спритний, рум'яний хлопець із карпатських полонин, кучеряве русяве волосся, що вибивається з-під капелюха, весела усмішка.
* **Одяг та спорядження:** Традиційний чорний повстяний гуцульський капелюх (крисаня), прикрашений яскравою червоною вовняною стрічкою-галункою, золотими червінцями та грайливим пір'ям. Біла лляна сорочка навипуск із багатим геометричним карпатським орнаментом на грудях та манжетах. Автентичний хутряний кептар (овчинна безрукавка), оздоблений сап'яновими аплікаціями, вовняними китицями та кольоровими шнурами. Традиційні червоні сукняні штани (гачі), широкий шкіряний пояс (черес) із мідними пряжками, на ногах — шкіряні постоли з вовняними капцями. У правій руці або на плечі — автентична гуцульська мосяжна бартка (топірець із гравійованим латунним обухом та візерунковим дерев'яним руків'ям).

#### Промпт для Meshy AI (Text-to-3D):
```text
3D character model of a vibrant 15-year-old Hutsul Carpathian mountain boy (young opryshok / legin), teenage sworn brother of the young Cossack. Energetic athletic teenage boy with rosy cheeks, cheerful bright green eyes, slightly curly light-brown hair peeking from under his hat, clean-shaven youthful face. Wearing an iconic black felt Hutsul hat (krysanya) with a brim decorated with a bright red braided woolen cord, peacock feather, and golden trinkets. Dressed in a traditional white embroidered linen tunic shirt worn loose, layered with a lavishly decorated shearling sheepskin vest (keptar) featuring ornate colorful leather appliqué, brass studs, and red wool pompoms.

Bright red woolen mountain trousers (hachi), cinched with a wide stamped brown leather belt (cheres) with multiple polished brass buckles. Traditional carved leather moccasin shoes (postoly) with braided woolen socks. Confidently resting a traditional Hutsul brass-headed walking axe (bartka) with a carved wooden haft against his shoulder.

Stylized 3D character, colorful Ukrainian Carpathian folk tale aesthetic, Disney/Pixar cartoon stylization, vibrant warm color palette, clean hand-painted PBR materials, balanced standing A-pose, ground contact Z=0, clean quad mesh, game engine ready.
```

#### Negative Prompt:
```text
old hussar, old mountain man, huge grey beard, mustache, violent berserker, medieval knight, modern hiking clothes, plastic axe, grotesque, horror, asymmetrical arms, bad proportions, missing boots.
```

---

### 2.4. Козак-Шабельник (Радник / Наставник Джури) (50+ років)

* **Роль:** Мудрий січовий характерник, ветеран походів, батько-наставник куреня.
* **Вік та анатомія:** 50–55 років, статна лицарська постава, широкий торс, сиві козацькі вуса, густі сивуваті брови, добрі й проникливі очі, загартоване степовим вітром обличчя з благородними зморшками посмішки.
* **Одяг та спорядження:** Синій козацький сукняний жупан із золотими петлицями та вишитими манжетами, підперезаний шкіряним військовим паском із латунною пряжкою. Сива каракулева смушева шапка з червоним оксамитовим верхом, кобальтові шаровари, темні юхтові чоботи. При лівому боці — козацька шабля у срібних ошатних піхвах із темляком.

#### Промпт для Meshy AI (Text-to-3D):
```text
3D character model of a wise senior Zaporozhian Cossack mentor and swordsman advisor (Kozak-Shabelnyk), 52 years old. Dignified broad-shouldered veteran knight, noble weather-beaten face with warm kind eyes, iconic long flowing silver-grey Cossack mustaches reaching down, shaved head with a silver forelock tucked under a traditional grey astrakhan fur hat (smushka) with an embroidered crimson velvet crown. 

Dressed in a rich royal-blue wool Cossack zhupan coat fastened with golden embroidered frog buttons (brandenbourgs), a sturdy brown leather broad belt with an embossed brass Cossack cross buckle. Deep blue sharovary trousers tucked into classic polished brown leather riding boots. A sheathed curved silver-mounted Cossack sabre hangs gracefully from his left hip belt.

Stylized 3D character, warm patriotic Ukrainian folklore legend aesthetic, heroic Pixar/Kyivnaukfilm stylized proportions, rich PBR cloth and metal textures, calm authoritative A-pose, grounded at Z=0, clean quad topology, game-ready model.
```

#### Negative Prompt:
```text
young boy, anime elf, demonic wizard, dark fantasy grimdark, blood, torn clothes, grotesque, evil expression, modern military, guns, low resolution texture, malformed sabre, clipping geometry.
```

---

### 2.5. Вогник-Стрибунець (Vohnyk) — Січовий вогняний дух (Рівень 1)

* **Роль:** Пустотливий магічний дух порохового полум'я на Січі, стрибучий нейтрально-ворожий NPC, що перестрибує з балки на балку.
* **Зріст та силует:** Маленька краплеподібна жива вогняна істота (зріст Джурі до колін, $\approx 0.45\times$ від зросту Джури). Верхня частина витягується у динамічні язики полум'я, що звиваються при стрибку.
* **Анатомія та обличчя:** Округле палаюче тільце золотисто-бурштинового кольору з гарячим біло-жовтим ядром у центрі. Великі виразні мультяшні бурштинові очі з грайливими вугликами-зіницями, пустотлива усмішка. З боків тіла — маленькі крилаті язички вогню замість рук, якими він балансує у повітрі. Навколо тіла постійно кружляють дрібні золоті та багряні іскри (ембери).
* **Ракурси Turnaround:**
  - *Front ($0^\circ$):* Краплеподібна симетрія полум'я, сяючі очі, грайлива посмішка, центральне золоте ядро.
  - *3/4 Left/Right ($30^\circ / 330^\circ$):* Вигин язиків вогню назад по інерції руху, видимість бічних вогняних крилець.
  - *Profile ($90^\circ / 270^\circ$):* Аеродинамічний нахил полум'я вперед із шлейфом іскор позаду.
  - *Back ($180^\circ$):* Насичене багряно-помаранчеве градієнтне сяйво зі шлейфом тліючих іскорок.

#### Промпт для Meshy AI (Text-to-3D):
```text
3D character model of a lively stylized fire spirit creature named Vohnyk, inspired by Slavic Cossack folklore and classic animation. Adorable teardrop-shaped living flame elemental with a bright glowing golden-yellow inner core and warm scarlet-orange outer flame licks swirling upward into a pointed crest. Expressive round cartoon amber eyes with glowing charcoal pupils and a cheerful cheeky cartoon grin.

Sprouting tiny dynamic flame-wing wisps at its sides and trailing dancing embers and sparkles around its silhouette. No realistic horror, strictly cute fairy-tale cartoon style like Calcifer from Ghibli or Pixar elemental characters. 

Stylized 3D character, clean hand-painted PBR emissive materials with soft gradient glow, centered at origin Z=0, symmetrical floating or hovering stance, game-ready asset.
```

#### Negative Prompt:
```text
terrifying demon, scary hellfire monster, horror skull, dark sinister lava monster, realistic burnt skin, human torso, legs, shoes, gritty realism, uncanny, low poly distortion.
```

---

### 2.6. Чортик-крутько (Chortik-Besketnyk) — Гоголівський степовий бісик

* **Роль:** Спритний мультяшний злодійчук ядер, комічний слуга відьми.
* **Вік та анатомія:** Мультяшний маленький бісик (зріст Джурі до пояса), пухнасте графітово-чорне тільце, смішний рожевий свинячий п'ятачок, два маленьких закручених червоних ріжки на маківці, великі круглі жовті очі з чорними зіницями, довгий тонкий хвостик із пухнастим пензликом.
* **Одяг та спорядження:** Тоненькі ніжки з маленькими копитцями, у лапах тримає димляче вогневе ядро або полотняний мішечок із латками.

#### Промпт для Meshy AI (Text-to-3D):
```text
3D character model of a mischievous Ukrainian folklore imp chort (Chortik-Besketnyk) inspired by Nikolai Gogol's comedic tales and classic Kyivnaukfilm animations. Small cuddly dark charcoal-grey furry imp creature with a round silhouette, short stubby cute curved reddish-brown horns on top of its head, a funny round pink piggy snout, oversized playful round yellow cartoon eyes with expressive black pupils, and a sticking-out comic pink tongue.

Thin sprightly legs ending in tiny shiny cloven hooves, and a long flexible animated devil tail with a tufted brush tip curled into a spring. In its cute clawed cartoon paws, it holds a glowing round cannonball with a sparking fuse. 

Stylized 3D cartoon mascot, zero-horror policy, purely comedic and adorable villain like Looney Tunes or classic animated fairy tales, vibrant hand-painted PBR textures, cheerful sneaking pose or A-pose, grounded at Z=0, clean quad topology.
```

#### Negative Prompt:
```text
scary demon, terrifying hellhound, gore, blood, skulls, fangs, realistic devil, horrifying monster, dark sinister horror, naked humanoid, sharp scary spikes, grotesque anatomy, photorealistic skin.
```

---

### 2.6. Нічна Відьма Солоха (Vidma-Inzhener) — Диканська господиня

* **Роль:** Чарівниця-винахідниця хутора, викрадачка зір та місяця, володарка мітли.
* **Вік та анатомія:** Пишна, вродлива й хитра українська молодиця 30–35 років, білолиця, чорноброва, з лукавою посмішкою та ямочками на щоках.
* **Одяг та спорядження:** Велика яскрава червона квітчаста хустка з довгими тороками, зав'язана ззаду. Біла полотняна сорочка з пишними вишитими рукавами («пухликами»), темно-зелена оксамитова корсетка-безрукавка з золотою тасьмою, картата червоно-жовта плахта із запаскою. Багаторядне червоне коралове намисто з дукачами на шиї. Витончені червоні чобітки на підборах. Сидить верхи або тримає чарівну березову мітлу, що світиться золотими іскорками.

#### Промпт для Meshy AI (Text-to-3D):
```text
3D character model of the charming Ukrainian night witch Solokha (Vidma), inspired by Nikolai Gogol's folk comedy. Full-figured attractive smiling Ukrainian village woman in her early 30s with rosy cheeks, sparkling brown eyes, arched dark eyebrows, and a playful sly smile. Wearing a voluminous crimson floral headscarf (khustka) with long fringed tassels framing her dark hair. 

Dressed in an authentic richly embroidered white linen blouse with puffy sleeves, a fitted dark-emerald velvet bodice vest (korsetka) trimmed with golden braid, and a traditional checkered woven wrap skirt (plakhta) with a bright apron. Wearing layered lustrous red coral bead necklaces (namysto) with golden coin pendants (dukachi). Neat red morocco leather heeled boots. Holding a stylized magical birch flying broomstick with subtle glowing sparks at the brush tip.

Stylized 3D character, warm joyful Gogolian Ukrainian folk comedy aesthetic, Disney/Pixar animation style, colorful hand-painted PBR materials, balanced standing A-pose next to broom, grounded at Z=0, clean quad topology.
```

#### Negative Prompt:
```text
ugly hag, rotten teeth, green skin, wart on nose, scary zombie witch, dark gothic horror, occult symbols, naked, blood, torn rags, realistic human pores, grotesque.
```

---

### 2.7. Коваль Вакула (Vakula the Blacksmith) — Диканський богатир

* **Роль:** Майстер-коваль, чародійний ремісник, творець золотих підківок для Джури.
* **Вік та анатомія:** 22–25 років, дужий широкоплечий парубок-красень, міцні рельєфні мультяшні м'язи, густе хвилясте чорне волосся, добродушний сміливий погляд.
* **Одяг та спорядження:** Закочені до ліктів рукави білої сорочки, цупкий темно-коричневий шкіряний фартух коваля з кишенею для інструментів поверх темно-сірих парусинових штанів. Міцні робочі шкіряні чоботи. У правій руці тримає важкий кований ковальський молот (ручницю), а на долоні лівої руки — сяючу золоту чарівну підківку, від якої летять іскри.

#### Промпт для Meshy AI (Text-to-3D):
```text
3D character model of Vakula the Blacksmith, legendary young Ukrainian folk hero and master artisan from Dykanka. Tall broad-shouldered muscular young man, 24 years old, handsome courageous face with a warm friendly expression, wavy thick black hair tied back with a leather band, clean-shaven or with faint youthful mustache. Rolled-up white linen sleeves showing strong heroic cartoon forearms, wearing a heavy dark-brown oiled leather blacksmith apron over sturdy charcoal trousers.

Durable dark leather workshop boots. In his right hand, he holds a solid engraved iron forging hammer resting lightly on an iron anvil prop or at his side; on his open left palm, he holds a brightly glowing enchanted Golden Horseshoe emitting magical sunlit sparks.

Stylized 3D heroic cartoon character, epic warm Ukrainian folklore aesthetic, stylized Pixar/Overwatch proportions, rich metallic and leather PBR textures, heroic confident A-pose, grounded at Z=0, clean topology.
```

#### Negative Prompt:
```text
feeble, skinny, old grandpa, grotesque ogre, dark fantasy torture blacksmith, modern welder mask, jeans, horror, deformed anatomy, untextured mesh.
```

---

### 2.8. Магічний артефакт 1: Чарівне Вогневе Ядро (Fire Core)

* **Роль:** Основний колекційний предмет гри (24 ядра на рівень), що заряджає січові гармати та відкриває енергію зір.
* **Опис:** Кулясте чавунне ядро темно-сталевого кольору із золотавим козацьким рельєфом тризуба, палаючим плетеним конопляним гнотом та ореолом яскравих сонячних іскор.

#### Промпт для Meshy AI (Text-to-3D):
```text
3D game prop of an ancient magical Cossack Fire Core cannonball (Vohneve Yadro). Perfectly spherical smooth dark-cast-iron cannonball with subtle embossed golden trident (Tryzub) engravings around its circumference. At the top, a thick braided hemp fuse rope is vigorously burning with a stylized bright golden-orange flame and tiny dancing magical Kupala sparks.

Stylized cartoon prop, clean hand-painted PBR metal and glow textures, emissive flame material, centered at origin, game-ready pick-up item.
```

---

### 2.9. Магічний артефакт 2: Золоті Підківки Вакули (Golden Horseshoes)

* **Роль:** Чарівне спорядження Рівня 2, що дозволяє Джурі прострибувати крізь дощаті балки знизу вгору.
* **Опис:** Пара сяючих викуваних золотих підківок із солярним орнаментом карбування, сонячним ореолом та смарагдовими іскрами.

#### Промпт для Meshy AI (Text-to-3D):
```text
3D game prop of a pair of enchanted Golden Horseshoes (Pidkivky Vakuly) forged by the magical blacksmith. Masterfully crafted gleaming polished solid gold horseshoes with delicate filigree folk scroll engravings and sunburst star motifs along the curves. Hovering with a soft warm golden and emerald magical aura, emitting tiny starlight particles.

Stylized 3D treasure prop, clean PBR gold shader with specular sheen and subtle emissive runes, centered at origin, game asset ready for pickup or icon use.
```

---

## 3. Практичні кроки для генерації на Meshy AI (`https://www.meshy.ai/`)

1. Відкрийте **[Meshy.ai Studio](https://www.meshy.ai/)** $\to$ вкладка **Text to 3D**.
2. Вставте англомовний текст промпта у поле `Prompt`.
3. У полі `Negative Prompt` обов'язково вкажіть запропонований список заборонених тегів (це гарантує захист від дорослих борідок у Джури, Киримли й Гуцулика та виключає зайвий горор).
4. Оберіть стиль: **Stylized / Cartoon**.
5. Натисніть **Generate** $\to$ після створення чернетки оберіть варіант та запустіть **Refine** для отримання деталізованої PBR-текстури.
6. Завантажте результат у форматі **`.glb`** або **`.fbx`** у каталог проєкту:
   `assets/models/<character_name>.glb`
7. Для автоматичного рендерингу 12 ракурсів скористайтеся CLI-скриптом:
   ```bash
   python3 tools/render_turnaround_12.py --model assets/models/<character_name>.glb --name <character_name> --resolution 512
   ```
   Згенеровані кадри (`angle_000.png` ... `angle_330.png`) будуть збережені у `reports/turnarounds/<character_name>/`.
