# Modular Chef — акварельные иконки продуктов (полный набор)

> Всего модулей: **141**. Стиль — **Watercolor Wash**. Генерь в Stitch **по группам** (так держится единый стиль). Каждый файл называй **`<id>.png`** (прозрачный фон, квадрат ≈512×512) — тогда я подключу автоматически.

## Единый стиль (вставлять в начало каждой группы)

```text
Hand-painted WATERCOLOR WASH food icon, premium cooking app. Loose watercolor with soft bleeding edges, visible cold-press paper texture, translucent layered pigment, NO hard outlines, light and airy. Single centered subject, generous margin, isolated on transparent background. Identical technique, lighting and palette across the whole set so they form one family. Palette: warm earthy watercolors — terracotta/clay, soft peach, oat cream, with fresh botanical young-leaf & olive greens as accents, espresso for tiny details. Tender, modern, appetising, premium. NOT childish, NOT cartoon, no text, no labels, no frame. Render each item below as its own clean icon:
```

## Чтобы не рисовать всё: переиспользование (alias)
Эти id используют ту же картинку, что и другой продукт — их **отдельно генерить не нужно**, я свяжу в коде:
- `addin_spinach` → `spinach` · `addin_pepper` → `bell_pepper` · `addin_tomatoes` → `cherry_tomato`
- `addin_chicken` → `chicken_breast` · `addin_salmon` → `salmon` · `addin_salad` → `salad_mix`
- `jb_cottage` → `cottage_cheese` · `jbar_tahini` → `tahini` · `jt_granola` → `granola_bowl`

→ остаётся **~132 уникальных**. Если захочешь ещё меньше — фрукты/орехи тоже можно свести к общим (скажи).

## Рекомендованный порядок (тиры)
1. **Тир 1 — самые видимые (~44):** Белки, Гарниры, Овощи, Завтраки-типы, Виды яиц, Перекусы. С них и начни — их видно везде.
2. **Тир 2 (~36):** Соусы/заправки, Основы баночек.
3. **Тир 3 — гранулярное (~45):** Прокладки, Сочные слои, Хруст, Добавки к яйцам (видны только внутри конструктора баночки/яиц).

---

## ГРУППЫ (id — название)

### 1. Белки (protein) — 8
chicken_breast — Курица · salmon — Лосось · steak — Стейк · turkey — Индейка · shrimp — Креветки · cod — Треска · meatballs — Фрикадельки · tofu — Тофу

### 2. Гарниры (side) — 7
rice — Рис · buckwheat — Гречка · bulgur — Булгур · spaghetti — Спагетти · potato — Картофель · couscous — Кускус · quinoa — Киноа

### 3. Супы (soup) — 5
cheese_soup — Сырный крем-суп · chicken_noodle_soup — Куриный с лапшой · tomato_soup — Томатный суп · pumpkin_soup — Тыквенный крем-суп · mushroom_soup — Грибной суп

### 4. Завтраки-типы (breakfast) — 6
eggs — Яйца · jar — Баночка · syrniki — Сырники · porridge — Каша · sandwiches — Бутерброд · granola_bowl — Гранола

### 5. Овощи (vegetable) — 6
broccoli — Брокколи · spinach — Шпинат · bell_pepper — Болгарский перец · cherry_tomato — Черри · salad_mix — Салат микс · zucchini — Цукини

### 6. Соусы и заправки (sauce) — 23
yogurt_sauce — Йогуртовый соус · tomato_sauce — Томатный соус · bechamel — Бешамель · pesto — Песто · lemon_dressing — Лимонная заправка · tahini — Тахини · creamy_mushroom — Сливочно-грибной · teriyaki — Терияки · curry_coconut — Карри-кокосовый · bbq — Барбекю · cheese_sauce — Сырный соус · tkemali — Ткемали · adjika — Аджика · bolognese — Болоньезе · chimichurri — Чимичурри · salsa — Сальса · guacamole — Гуакамоле · hummus — Хумус · caesar — Цезарь · honey_mustard — Медово-горчичная · soy_sesame — Соево-кунжутная · tzatziki — Дзадзики · balsamic — Бальзамик-винегрет

### 7. Перекусы (snack) — 5
nuts — Орехи · cottage_cheese — Творог · fruit — Фрукты · protein_bar — Протеин-бар · energy_balls — Энергошарики

### 8. Виды яиц (egg_style) — 6
egg_omelet — Омлет · egg_scrambled — Скрэмбл · egg_fried — Глазунья · egg_shakshuka — Шакшука · egg_poached — Пашот · egg_boiled — Варёные

### 9. Добавки к яйцам (egg_addin) — 15
addin_cheese — Сыр · addin_feta — Фета · addin_tomatoes — Помидоры · addin_spinach — Шпинат · addin_pepper — Перец · addin_mushrooms — Грибы · addin_bacon — Бекон · addin_ham — Ветчина · addin_chicken — Курица (остатки) · addin_green_onion — Зелёный лук · addin_herbs — Зелень · addin_salmon — Лосось с/с · addin_avocado — Авокадо · addin_toast — Тост · addin_salad — Салат-микс

### 10. Основы баночек (jar_base) — 15
jb_overnight_oats — Овсянка overnight · jb_chia — Чиа-пудинг · jb_greek_yogurt — Греческий йогурт · jb_cottage — Творог взбитый · jb_rice_pudding — Рисовый пудинг · jb_semolina — Манный пудинг · jb_quinoa — Киноа-пудинг · jb_bircher — Бирхер-мюсли · jb_flax — Льняная каша · jb_coconut — Кокосовый пудинг · jb_millet — Пшённая каша · jb_choco_oats — Шоколадная овсянка · jb_pumpkin_oats — Тыквенная овсянка · jb_protein_mousse — Протеиновый мусс · jb_milk_couscous — Молочный кускус

### 11. Прокладки баночек (jar_barrier) — 15
jbar_peanut — Арахисовая паста · jbar_almond — Миндальная паста · jbar_jam — Джем · jbar_honey — Мёд · jbar_fruit_puree — Фруктовое пюре · jbar_coulis — Ягодный кули · jbar_tahini — Тахини · jbar_lemon_curd — Лимонный курд · jbar_cream_cheese — Крем-чиз · jbar_coconut_cream — Кокосовый крем · jbar_choco_spread — Шоколадная паста · jbar_caramel — Солёная карамель · jbar_condensed — Варёная сгущёнка · jbar_thick_yogurt — Густой йогурт · jbar_urbech — Урбеч

### 12. Сочные слои баночек (jar_middle) — 15
jm_strawberry — Клубника · jm_raspberry — Малина · jm_blueberry — Черника · jm_frozen_berries — Заморож. ягоды · jm_banana — Банан · jm_apple_pear — Яблоко/груша · jm_peach — Персик · jm_mango — Манго · jm_kiwi — Киви · jm_pomegranate — Гранат · jm_baked_apple — Печёное яблоко · jm_pineapple — Ананас · jm_fig — Инжир · jm_citrus — Цитрус · jm_dried_fruit — Сухофрукты

### 13. Хруст/декор баночек (jar_top) — 15
jt_granola — Гранола · jt_walnuts — Грецкий орех · jt_almonds — Миндаль · jt_hazelnuts — Фундук · jt_cashews — Кешью · jt_pumpkin_seeds — Тыквенные семечки · jt_sunflower_seeds — Семечки · jt_chia_flax — Чиа/лён · jt_coconut — Кокос. стружка · jt_cacao_nibs — Какао-крупка · jt_dark_choco — Тёмный шоколад · jt_fruit_chips — Фруктовые чипсы · jt_muesli — Мюсли · jt_sesame_poppy — Кунжут/мак · jt_mint_zest — Мята/цедра

---

## Куда класть готовые файлы
- Иконки: `assets/art/icons/<id>.png` (прозрачный фон).
- Фон-облака: `assets/art/bg_clouds.png`.
Назвала по id — подключу автоматически (alias-id свяжу в коде).
