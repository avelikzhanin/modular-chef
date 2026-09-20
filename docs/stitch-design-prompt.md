# Stitch prompt — Modular Chef · «Лён, песок и молодой лист» / "Linen, Sand & Young Leaf"

> Эволюция «Лён и глины»: воздушные нейтралы (лён, песок, облачно-белый) + свежий зелёный «молодого листа» как главный акцент (кнопки) вместо коралловой глины. Вся графика — **акварель**: рисованные облака на фоне и watercolor-wash иконки продуктов. Глина — лишь тёплая деталь.

> Как пользоваться: в Google Stitch (labs.google/stitch) сначала вставь блок **DESIGN SYSTEM** как контекст проекта, затем генерируй экраны по одному — для каждого вставляй его блок из **SCREENS**. Ассеты (фон, иконки) — блоки **ASSETS**. UI-текст уже на русском. Дизайн-инструкции на английском — так Stitch стабильнее.

---

## DESIGN SYSTEM (paste first / project context)

Design a **premium mobile app** called **Modular Chef** — a warm, grown-up meal-prep app with two roles: **Chef** (cooks ahead in batches) and **Guest** (eats from the prepared stock). The whole UI is in **Russian**.

**Atmosphere:** warm, faded, natural, editorial — like an expensive modern cookbook. Calm and airy (density 4/10), confident but not chaotic (variance 5/10), fluid spring-physics motion (6/10). It must feel hand-crafted and "expensive", never templated or childish.

**Color palette (airy «Linen, Sand & Young Leaf» — exact hex; ONE primary accent: fresh young-leaf green; clay kept only as a tiny warm detail):**
- Linen Canvas `#EDE6DA` — primary screen background
- Warm Sand `#E4D9C6` — secondary surfaces / inset sections
- Cloud Paper `#FBF7F0` — cards, floating containers (airy warm white)
- Sky Mist `#DEE7E5` — cool airy tint inside the atmospheric cloud header
- Young Leaf `#8FB96A` — PRIMARY accent: primary buttons («Собрать»), active state, key highlights (fresh young-leaf green, saturated pastel with a slight cool lean)
- Leaf Deep `#4C6B2F` — text/icons on light-leaf fills, pressed accent
- Light Leaf `#DCE9C8` — soft accent fills, selected state, chips, indicators (the soft tone to lean on)
- Leaf Ink `#23351A` — text on the young-leaf button
- Olive Taupe `#8A7E5E` — secondary accent, gentle highlights
- Clay Terracotta `#AE6A4D` — tiny WARM detail ONLY (e.g. ♥ «в любимое», small marks), NEVER on primary buttons
- Espresso `#2E2620` — primary text and headings (never pure black)
- Muted Stone `#8A7C6C` — secondary text, captions, metadata
- Tag Wash `#EFEAE0` — neutral tag/pill backgrounds (use Light Leaf for active/selected tags)

**Typography (editorial «modern cookbook» scale):**
- Headings / display: **Fraunces** (soft editorial serif; in Stitch — Noto Serif as the closest substitute). Weight **600**, track-tight (-0.02em). Sizes: display 48 / headline 32 (mobile 28) / headline-md 24.
- Title (card titles, dish names): Fraunces or Inter **20 / 600**.
- Body / UI: **Inter** — body-lg 18, body-md 16, weight 400, relaxed leading, secondary text in Muted Stone.
- Labels / metadata (the «надписи» — «СВЕЖЕСТЬ 85%», «2 порции», «ШЕФ рекомендует», «Осталось 2 дня»): Inter, label-md 14/500 (+0.01em), label-sm **12/600 with +0.05em tracking, often UPPERCASE** — this crisp spaced small caps differentiates metadata from narrative text.
- The serif-headline (w600) + sans-body + spaced small-caps labels contrast is the signature "grown-up editorial / cookbook" feel.

**Brand wordmark:** the app name **«Modular Chef»** is set in **Fraunces serif, ITALIC**, paired with the small watercolor leaf-sprig logo (sage/green). Keep the name as-is (no Russian rename).

**Shape & components:**
- Cards: cloud-paper fill `#FBF7F0`, large rounded corners **24px**, soft warm diffused shadow `0 8px 24px rgba(46,38,32,0.06)` (never harsh or black). Optional nested "double-bezel" look (outer warm wash shell + inner paper core, concentric radii).
- Buttons: PRIMARY action («Собрать») = soft watercolor sage-olive green fill `#8FB96A` (gentle painted wash, botanical), label text deep leaf-ink `#23351A`, **14px** rounded corners (soft rectangle, NOT a fat pill), generous padding, gentle press feedback. Secondary = warm ghost/outline.
- Small tags/chips: pill, `#EFEAE0` fill (active/selected = Light Leaf `#DCE9C8` with Leaf Deep `#4C6B2F` text), small.
- Selection: soft Light Leaf `#DCE9C8` fill + 1.5px young-leaf `#8FB96A` outline + tiny scale-down on tap — no hard borders.
- Texture: very subtle paper grain over backgrounds (≈3% opacity). Deliberate, not noisy.

**Header (signature element):** an **atmospheric header band** — a **hand-painted watercolor sky** with soft, loose-edged clouds in warm light (gentle peach, blush, oat cream) bleeding softly into the linen background; a large Fraunces title sits on it. Calm, dreamy, tender, expensive. May include a delicate watercolor leaf/sprig (young greens) as a light botanical accent.

**Icons & food visuals (CRITICAL — this replaces the current childish emoji):** every food item uses a **hand-painted WATERCOLOR WASH illustration** — loose watercolor with soft bleeding edges, visible cold-press paper texture, translucent layered pigment, NO hard outlines, light and airy. Fresh natural palette (young-leaf & olive greens, terracotta/clay, soft peach, oat cream, espresso for tiny details). **NOT flat childish emoji, NOT thin generic line icons, NOT cartoon-kiddie.** A cohesive set — identical watercolor technique, lighting and palette across all items. Chrome/UI icons (chevrons, settings, add, back) = clean rounded thin-medium line icons in espresso/sage-green.

**Food visuals (where a full dish/jar is shown):** the same hand-painted watercolor style — loose, tender, appetising, on a soft cream/linen ground; or a top-down watercolor of the dish. Keep it painterly, never a hard photograph.

**Motion:** spring physics (weighty, no linear easing), staggered cascade reveals for lists, gentle fade-up + soft blur on entry, soft micro-interactions. Animate transform/opacity only.

**Anti-patterns (NEVER):** no emoji; no pure black `#000000`; no neon / outer-glow / purple-blue AI gradients; no harsh 1px gray borders; no 3-equal-cards rows; no AI clichés ("Elevate/Seamless/Unleash"); no fake names; no thin sterile fintech look. Saturated natural pastel is welcome (the young-leaf green is meant to be lively) — but keep it earthy and grown-up, never childish candy-bright or neon.

---

## SCREENS (generate one at a time — Russian UI text)

### Guest · «Сегодня» (Today hub)
A guest home screen. Atmospheric cloud header with large Fraunces title **«Сегодня»** and caption **«Собери день из того, что Шеф приготовил заранее»**, a small segmented role switcher **[ Шеф | Гость ]** top-right. Below, a vertical stack of 4 warm-paper meal-slot cards, each with a watercolor food icon, slot label and content:
- **Завтрак** — filled: dish **«Овсянка overnight · черника, гранола»**, small chip **«2 мин»**, watercolor oats-jar icon.
- **Обед** — filled: **«Курица · рис · брокколи · песто»**, green chip **«Проверенное сочетание»**.
- **Ужин** — empty state: muted, with a young-leaf primary button **«Собрать»** and a ghost **«Пропустить»**.
- **Перекус** — empty, smaller.
Bottom nav bar (2 tabs): **Сегодня** (active) and **Запасы**, rounded line icons. Calm spacing, fade-up cards.

### Guest · «Собрать обед» (assemble a plate)
A build screen opened from a slot. Plain warm top bar with back arrow and title **«Собрать: обед»**. Caption **«Собери тарелку из того, что есть»**. Four horizontal scrollable rows of selectable square cards (watercolor food icons + name), labelled **«Белок»**, **«Гарнир» (по желанию)**, **«Овощ» (по желанию)**, **«Соус» (по желанию)**; one card in each row selected (light-leaf fill + young-leaf outline + check). A soft hint card near the bottom: green tick **«✓ Проверенное сочетание (русская кухня)»**. Sticky bottom area: selection summary **«Курица + Рис»** and a full-width young-leaf button **«Готово»**.

### Guest · «Собрать завтрак» (jar constructor)
Top bar back + **«Собрать: завтрак»**. Caption **«Какой завтрак собираем?»**. A row of type cards (watercolor icons): **Яйца**, **Баночка** (selected), **Сырники**, **Каша**. A warm info chip **«Слои снизу вверх — не перемешиваются при хранении»**. Then four layered selectable rows: **«1 · Основа»** (selected «Овсянка overnight»), **«2 · Прокладка»** (selected «Арахисовая паста»), **«3 · Сочный слой»** (selected «Черника»), **«4 · Хруст / декор»** («Гранола»). Hint card with a small leaf-green info dot: **«Гранола — добавь утром, иначе размокнет»** (no emoji). Bottom young-leaf button **«Готово»**.

### Guest · «Запасы» (inventory)
Header **«Запасы»** + warm subtitle **«Свежесть заготовок под контролем — ешь, пока они в лучшей форме»**. Content (bento of Cloud-Paper cards):
- **Dish cards** — watercolor dish image/icon + Fraunces title with portions **«Тыквенный крем-суп (2 порции)»**; small badges (clay heart **«Шеф рекомендует»**, or **«Пряное»**, **«Высокий белок»**); one-line warm description («Бархатистая текстура с нотками мускатного ореха…»); a **freshness bar** — uppercase label **«СВЕЖЕСТЬ 85%»** + right note **«Осталось 2 дня»** (near-expiry → red **«Употребить до завтра»**), with a young-leaf progress bar at that %.
- **Summary card «Обзор запасов»** — **«Готово 5 порций еды на ближайшие дни»** + chips **«2 супа»**, **«3 основных блюда»**.
- **Refill alert** (clay/tertiary card) — **«Время пополнить запасы?»** + **«Через 2 дня холодильник опустеет. Посмотрите новые модули от шефа, чтобы спланировать следующую неделю.»** + young-leaf button **«Собрать новое меню»**.

### Chef · «Собери меню» (build the menu)
Atmospheric cloud header, Fraunces title **«Собери меню»**, caption **«Искусство готовить заранее — выбери, что любишь, остальное соберём»**, role switcher top-right. A soft light-leaf info card: spoon line icon + **«Соусы и заправки система подберёт сама — под каждое блюдо своё»**. Then sections, each a Fraunces label + small uppercase hint on the right + a horizontal scroll of selectable food-icon cards: **«Белки» · выберите 3–5**, **«Гарниры» · 2–4**, **«Супы» · опционально**, **«Завтраки» · 2–3**, **«Мои блюда»** (with a «+ Своё» add card). Several cards selected. Sticky bottom: full-width young-leaf button with sparkle line icon **«Собрать меню · 5»**.

### Chef · «Меню на 2 недели» (the generated menu)
Top bar back + **«Меню на 2 недели»** + subtitle **«Две недели вкуса, собранные под тебя»**. A pill segmented control **[ Неделя 1 | Неделя 2 ]**. A soft summary badge card: **«18 уникальных блюд»** из **«8 модулей · 42 приёма»**. An **«Обзор меню»** card grouping components into rows of small tappable tag-chips: **Белок: Курица ×6 · Лосось ×4**, **Гарнир: Рис ×8 · Гречка ×5**, **Соус: Йогуртовый ×5 · Песто ×3** with caption **«тап по продукту — выбери, где заменить»**. Then day cards (Fraunces weekday **«ПН»**), each listing 3–4 meals with soft food-icon and component chips, e.g. breakfast **«Овсянка overnight · черника, гранола»**, lunch **«Курица + рис + брокколи + песто»**. Sticky bottom young-leaf button **«Утвердить»**.

### Chef · «Заготовки завтраков» (breakfast preps)
Header **«Заготовки завтраков»**, caption **«Что заготовишь к завтракам — из этого Гость и соберёт»**. Section **«Мои банки»** (with a small watercolor jar icon, not emoji): a list of composed-jar cards (Fraunces title «Овсянка overnight · черника, гранола» + small component chips + delete line icon), and a ghost outline button **«+ Собрать банку»**. Section **«Яйца наготове»**: caption + horizontal selectable cards **«Виды яиц»** (Омлет, Скрэмбл, Пашот, Варёные…) and **«Добавки»** (Сыр, Шпинат, Бекон, Авокадо…), several selected.

### Chef · «Собрать банку» (compose a jar)
Top bar back + **«Собрать банку»**. Warm info chip **«Слои снизу вверх — не перемешиваются при хранении»**. Four horizontal selectable rows of watercolor icons: **«1 · Основа»**, **«2 · Прокладка»**, **«3 · Сочный слой»**, **«4 · Хруст / декор»**. A hint card with a leaf-green info dot. Bottom young-leaf button **«Сохранить банку»**.

### Chef · «Подготовка» (prep day)
Header **«Подготовка»**, caption **«Выбери способ и загляни в детали — как готовить и где хранить»**. Grouped lists (Fraunces group titles **«Белки»**, **«Гарниры»**, **«Овощи»**, **«Супы»**): each row = watercolor food icon, name, method chips (e.g. **«Запечь 40 мин»**, **«Гриль»**), and a small storage line **«холодильник · 3 дня»**. Tapping a row hints a detail sheet.

### Chef · «Список покупок» (shopping)
Header **«Список покупок»** + subtitle **«Всё для недели в одном списке — отметь, что уже есть дома»**. Two grouped sections: **«Купить»** (checkable rows with soft food icon + name + qty, empty checkbox circle) and **«Уже есть»** (muted, checked rows). A small leaf-green progress caption **«куплено 4 из 12»**.

### Chef · «Профиль» (profile)
Header **«Профиль»** + subtitle **«Твоя кухня и твои привычки — всё, что делает меню „твоим“»**, with role switcher. A vertical stack of warm-paper nav tiles, each: light-leaf rounded icon tile + title + caption + chevron: **«Мои блюда»** (Личная библиотека рецептов), **«Мои сочетания»** (Любимые тройки для генератора), **«Заготовки завтраков»** (Банки и яйца впрок), **«Предпочтения»** (Аллергии, диета, ограничения), **«Настройки»** (muted/disabled).

---

## ASSETS

### Atmospheric background / underlay (watercolor)
Generate a **vertical (9:16) hand-painted WATERCOLOR sky background**: soft loose-edged clouds in warm light at the very top — gentle peach, blush, oat cream and a faint warm grey — with visible paper grain, fading smoothly into a flat calm linen-cream `#EDE6DA` over the lower ~70%. Airy, dreamy, tender, minimal, lots of empty calm space for UI. No objects, no people, no text.

### Food icon set (WATERCOLOR WASH) — all 141 products
Generate a **cohesive set of hand-painted WATERCOLOR WASH food icons**, identical technique/lighting/palette, isolated on transparent (or warm cream `#EDE6DA`): loose watercolor, soft bleeding edges, cold-press paper texture, translucent pigment, NO hard outlines, light and airy. Palette: young-leaf & olive greens, terracotta/clay, soft peach, oat cream, espresso for tiny details. Premium and tender, **NOT childish, NOT cartoon, no text**.
**The complete list of all 141 products (grouped, with `id` for file naming) is in `docs/watercolor-icons.md`.** Generate group by group so the style stays consistent; name each file `<id>.png`.

### Meal-slot icons (soft watercolor) — 4
Generate a WATERCOLOR ICON SHEET illustration (NOT a UI screen). 4 soft hand-painted watercolor icons on a flat warm cream `#EDE6DA` background, even grid, each centered with generous margin, same size and technique, NO text, NO frames. Palette: peach, oat cream, soft sage-olive green, espresso. Tender, calm, premium.
Items (meal times): 1) breakfast — a soft sunrise over the horizon; 2) lunch — a warm midday sun; 3) dinner — a calm crescent moon with a tiny star; 4) snack — a small apple with one bite.
Files: `slot_breakfast.png, slot_lunch.png, slot_dinner.png, slot_snack.png` → `assets/art/ui/`.

### UI / nav / role / action icons (one-color line) — 20
Generate an ICON SHEET of MINIMAL UI ICONS (NOT a UI screen). Clean, rounded, hand-drawn line icons with a light watercolor-tinted stroke, on a flat warm cream `#EDE6DA` background, even grid, each centered, same stroke weight and size, **ONE single color = deep leaf green `#436823`** (not grey, not multi-color), no fills, NO text, NO frames. Simple and legible at small size, tender and warm. (Active state in the app is shown by a Light Leaf `#DCE9C8` pill behind the icon, not by recolouring.)
Items: 1) chef hat (Chef mode); 2) crossed fork & spoon (Guest mode); 3) sun (Today); 4) glass jars on a shelf (Pantry/Stock); 5) open recipe book (Build menu); 6) shopping basket; 7) chef knife & board (Prep); 8) fridge with containers (Storage); 9) person bust (Profile); 10) back arrow; 11) plus (add); 12) sliders (adjust/swap); 13) two swap arrows (replace); 14) heart outline (favourite); 15) check mark; 16) chevron right; 17) trash bin (delete); 18) sparkle (generate); 19) spoon (sauce hint); 20) small leaf sprig (fresh hint).
Files: `ui_chef, ui_guest, ui_today, ui_stock, ui_menu, ui_shopping, ui_prep, ui_storage, ui_profile, ui_back, ui_add, ui_adjust, ui_swap, ui_heart, ui_check, ui_chevron, ui_delete, ui_sparkle, ui_spoon, ui_leaf` (`.png`) → `assets/art/ui/`.

---

## Notes
- Stitch generates **screens**; standalone icon/background export may be limited — if so, generate a dedicated **«style sheet»** screen showing the icon set, and a **«splash / background»** screen, then export those.
- Keep ALL on-screen copy in Russian as specified above.
- One primary accent — young-leaf green; clay only as a tiny warm detail. Keep it airy, natural and faded — restraint is the point.
