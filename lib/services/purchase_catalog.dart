import 'package:modular_chef/models/module.dart';

/// Превращает «блюда из меню» в «продукты для магазина».
/// Здесь живут: отделы магазина, ингредиенты супов и домашних соусов,
/// и правило «что покупается готовым, а что готовим сами».

/// Ингредиент для покупки: имя, сколько брать (на ~6 порций), отдел.
typedef Ingredient = ({String name, String qty, String section});

/// Отделы магазина — порядок = порядок секций в списке.
const List<String> kShopSections = [
  'Мясо и птица',
  'Рыба и морепродукты',
  'Овощи и зелень',
  'Фрукты и ягоды',
  'Молочное, сыры и яйца',
  'Крупы и гарниры',
  'Орехи и сухофрукты',
  'Соусы и бакалея',
  'Хлеб и выпечка',
  'Прочее',
];

/// Рыба и морепродукты — для отдела магазина и группировки в меню.
const Set<String> kFishIds = {
  'salmon', 'cod', 'trout', 'tuna', 'shrimp', 'squid',
  'pink_salmon', 'mackerel', 'pikeperch', 'pollock', 'hake',
  'seabass', 'dorado', 'herring', 'mussels', 'fish_cutlets',
  'chum_salmon', 'perch', 'halibut', 'wolffish', 'flounder',
  'scallops', 'octopus', 'crab',
};

/// Птица — для группировки белков в меню.
const Set<String> kPoultryIds = {
  'chicken_breast', 'chicken_thighs', 'turkey', 'duck',
  'chicken_cutlets', 'liver', 'chicken_wings', 'whole_chicken',
  'goose', 'quail', 'chicken_mince', 'turkey_mince',
};

/// Растительный белок.
const Set<String> kPlantProteinIds = {
  'tofu', 'tempeh', 'seitan', 'edamame', 'chickpea_cutlets',
  'falafel', 'soy_meat',
};

/// Иконки для ингредиентов супов и домашних соусов (по имени позиции).
/// Часть переиспользует готовые акварели, часть ждёт файлов ing_*.png.
const Map<String, String> kIngredientIcons = {
  'Тыква': 'ing_pumpkin',
  'Лук': 'ing_onion',
  'Лук красный': 'ing_red_onion',
  'Морковь': 'ing_carrot',
  'Чеснок': 'ing_garlic',
  'Сливки 20%': 'ing_cream',
  'Молоко': 'ing_milk',
  'Сливочное масло': 'ing_butter',
  'Мука': 'ing_flour',
  'Сыр плавленый': 'ing_processed_cheese',
  'Пармезан': 'ing_parmesan',
  'Томаты в с/с': 'ing_canned_tomatoes',
  'Томаты': 'ing_tomatoes',
  'Базилик': 'ing_basil',
  'Укроп': 'ing_dill',
  'Петрушка': 'ing_parsley',
  'Кинза': 'ing_cilantro',
  'Огурец': 'ing_cucumber',
  'Лимон': 'ing_lemon',
  'Лайм': 'ing_lime',
  'Горчица': 'ing_mustard',
  'Оливковое масло': 'ing_olive_oil',
  'Лапша': 'ing_noodles',
  'Хлеб для гренок': 'ing_bread',
  'Лавровый лист': 'ing_bay_leaf',
  'Винный уксус': 'ing_vinegar',
  'Кокосовое молоко': 'ing_coconut_milk',
  'Паста карри': 'ing_curry_paste',
  // Ингредиенты новых супов:
  'Свёкла': 'ing_beet',
  'Капуста': 'ing_cabbage',
  'Горох сухой': 'ing_split_peas',
  'Копчёности': 'ing_smoked_meat',
  'Фасоль в банке': 'ing_canned_beans',
  'Паста том-ям': 'ing_tom_yum',
  'Имбирь': 'ing_ginger',
  'Кефир': 'ing_kefir',
  'Редис': 'ing_radish',
  // Переиспользуем существующие акварели:
  'Говядина для бульона': 'beef_stew',
  'Чечевица красная': 'lentils',
  'Кабачок': 'zucchini',
  'Мелкая паста': 'pasta',
  'Рис': 'rice',
  'Грецкие орехи': 'jt_walnuts',
  'Ткемали': 'tkemali',
  'Белая рыба': 'cod',
  'Креветки': 'shrimp',
  'Яйца': 'eggs',
  'Зелёный лук': 'addin_green_onion',
  'Ветчина': 'addin_ham',
  'Брокколи': 'broccoli',
  'Шпинат': 'spinach',
  'Мёд': 'jbar_honey',
  'Тыквенные семечки': 'jt_pumpkin_seeds',
  'Шампиньоны': 'addin_mushrooms',
  'Картофель': 'potato',
  'Греческий йогурт': 'jb_greek_yogurt',
  'Курица (бёдра)': 'chicken_thighs',
  'Говяжий фарш': 'ground_beef',
  'Авокадо': 'addin_avocado',
};

const _fishIds = kFishIds;

/// Точечные назначения отделов — там, где префикс/категория не угадывает.
const Map<String, String> _sectionOverrides = {
  // Молочное и сыры
  'jb_greek_yogurt': 'Молочное, сыры и яйца',
  'jbar_cream_cheese': 'Молочное, сыры и яйца',
  'jbar_thick_yogurt': 'Молочное, сыры и яйца',
  'addin_cheese': 'Молочное, сыры и яйца',
  'addin_feta': 'Молочное, сыры и яйца',
  'cottage_cheese': 'Молочное, сыры и яйца',
  'syrniki': 'Молочное, сыры и яйца',
  // Крупяные основы баночек и каш — покупается крупа/хлопья
  'jb_overnight_oats': 'Крупы и гарниры',
  'jb_choco_oats': 'Крупы и гарниры',
  'jb_pumpkin_oats': 'Крупы и гарниры',
  'jb_bircher': 'Крупы и гарниры',
  'jb_flax': 'Крупы и гарниры',
  'jb_millet': 'Крупы и гарниры',
  'jb_rice_pudding': 'Крупы и гарниры',
  'jb_semolina': 'Крупы и гарниры',
  'jb_quinoa': 'Крупы и гарниры',
  'jb_milk_couscous': 'Крупы и гарниры',
  'jt_muesli': 'Крупы и гарниры',
  'jt_granola': 'Крупы и гарниры',
  'granola_bowl': 'Крупы и гарниры',
  // Орехи, семечки, сухофрукты
  'nuts': 'Орехи и сухофрукты',
  'jt_walnuts': 'Орехи и сухофрукты',
  'jt_almonds': 'Орехи и сухофрукты',
  'jt_hazelnuts': 'Орехи и сухофрукты',
  'jt_cashews': 'Орехи и сухофрукты',
  'jt_coconut': 'Орехи и сухофрукты',
  'jt_pumpkin_seeds': 'Орехи и сухофрукты',
  'jt_sunflower_seeds': 'Орехи и сухофрукты',
  'jt_chia_flax': 'Орехи и сухофрукты',
  'jt_sesame_poppy': 'Орехи и сухофрукты',
  'jt_fruit_chips': 'Орехи и сухофрукты',
  'jm_dried_fruit': 'Орехи и сухофрукты',
  'jbar_peanut': 'Орехи и сухофрукты',
  'jbar_almond': 'Орехи и сухофрукты',
  'jbar_urbech': 'Орехи и сухофрукты',
  'jb_chia': 'Орехи и сухофрукты',
  // Бакалея
  'jbar_jam': 'Соусы и бакалея',
  'jbar_honey': 'Соусы и бакалея',
  'jbar_fruit_puree': 'Соусы и бакалея',
  'jbar_coulis': 'Соусы и бакалея',
  'jbar_lemon_curd': 'Соусы и бакалея',
  'jbar_choco_spread': 'Соусы и бакалея',
  'jbar_caramel': 'Соусы и бакалея',
  'jbar_condensed': 'Соусы и бакалея',
  'jt_cacao_nibs': 'Соусы и бакалея',
  'jt_dark_choco': 'Соусы и бакалея',
  'jb_coconut': 'Соусы и бакалея',
  'jb_protein_mousse': 'Соусы и бакалея',
  'protein_bar': 'Соусы и бакалея',
  'energy_balls': 'Соусы и бакалея',
  // Овощи, зелень и добавки-овощи
  'addin_tomatoes': 'Овощи и зелень',
  'addin_pepper': 'Овощи и зелень',
  'addin_spinach': 'Овощи и зелень',
  'addin_mushrooms': 'Овощи и зелень',
  'addin_green_onion': 'Овощи и зелень',
  'addin_herbs': 'Овощи и зелень',
  'addin_salad': 'Овощи и зелень',
  'addin_avocado': 'Овощи и зелень',
  'jt_mint_zest': 'Овощи и зелень',
  // Мясные и рыбные добавки
  'addin_ham': 'Мясо и птица',
  'addin_bacon': 'Мясо и птица',
  'addin_chicken': 'Мясо и птица',
  'addin_salmon': 'Рыба и морепродукты',
  // Хлеб
  'addin_toast': 'Хлеб и выпечка',
  'sandwiches': 'Хлеб и выпечка',
  // Фрукты
  'fruit': 'Фрукты и ягоды',
};

/// Отдел магазина для модуля каталога.
String shopSection(Module m) {
  final id = m.id;
  final override = _sectionOverrides[id];
  if (override != null) return override;
  if (id == 'eggs' || id.startsWith('egg_')) return 'Молочное, сыры и яйца';
  if (id.startsWith('jm_')) return 'Фрукты и ягоды';
  switch (m.category) {
    case ModuleCategory.protein:
      return _fishIds.contains(id) ? 'Рыба и морепродукты' : 'Мясо и птица';
    case ModuleCategory.side:
      return 'Крупы и гарниры';
    case ModuleCategory.vegetable:
      return 'Овощи и зелень';
    case ModuleCategory.sauce:
      return 'Соусы и бакалея';
    case ModuleCategory.snack:
      return 'Прочее';
    case ModuleCategory.breakfast:
      return 'Молочное, сыры и яйца';
    default:
      return 'Прочее';
  }
}

/// Супы не покупаются — покупаются их ингредиенты (основу варим сами).
const Map<String, List<Ingredient>> kSoupIngredients = {
  'pumpkin_soup': [
    (name: 'Тыква', qty: '~1 кг', section: 'Овощи и зелень'),
    (name: 'Лук', qty: '1 шт', section: 'Овощи и зелень'),
    (name: 'Морковь', qty: '1 шт', section: 'Овощи и зелень'),
    (name: 'Сливки 20%', qty: '200 мл', section: 'Молочное, сыры и яйца'),
    (name: 'Тыквенные семечки', qty: 'горсть', section: 'Соусы и бакалея'),
  ],
  'tomato_soup': [
    (name: 'Томаты в с/с', qty: '2 банки', section: 'Соусы и бакалея'),
    (name: 'Лук', qty: '1 шт', section: 'Овощи и зелень'),
    (name: 'Чеснок', qty: '3 зуб.', section: 'Овощи и зелень'),
    (name: 'Сливки 20%', qty: '150 мл', section: 'Молочное, сыры и яйца'),
    (name: 'Базилик', qty: 'пучок', section: 'Овощи и зелень'),
  ],
  'mushroom_soup': [
    (name: 'Шампиньоны', qty: '500 г', section: 'Овощи и зелень'),
    (name: 'Картофель', qty: '3 шт', section: 'Овощи и зелень'),
    (name: 'Лук', qty: '1 шт', section: 'Овощи и зелень'),
    (name: 'Сливки 20%', qty: '200 мл', section: 'Молочное, сыры и яйца'),
    (name: 'Укроп', qty: 'пучок', section: 'Овощи и зелень'),
  ],
  'cheese_soup': [
    (name: 'Сыр плавленый', qty: '200 г', section: 'Молочное, сыры и яйца'),
    (name: 'Картофель', qty: '3 шт', section: 'Овощи и зелень'),
    (name: 'Лук', qty: '1 шт', section: 'Овощи и зелень'),
    (name: 'Морковь', qty: '1 шт', section: 'Овощи и зелень'),
    (name: 'Хлеб для гренок', qty: '½ багета', section: 'Прочее'),
  ],
  'chicken_noodle_soup': [
    (name: 'Курица (бёдра)', qty: '500 г', section: 'Мясо и птица'),
    (name: 'Лапша', qty: '1 упак.', section: 'Крупы и гарниры'),
    (name: 'Морковь', qty: '1 шт', section: 'Овощи и зелень'),
    (name: 'Лук', qty: '1 шт', section: 'Овощи и зелень'),
    (name: 'Лавровый лист', qty: '2 шт', section: 'Соусы и бакалея'),
  ],
  'chicken_broth': [
    (name: 'Суповой набор куриный', qty: '1 кг', section: 'Мясо и птица'),
    (name: 'Лук', qty: '1 шт', section: 'Овощи и зелень'),
    (name: 'Морковь', qty: '1 шт', section: 'Овощи и зелень'),
    (name: 'Лавровый лист', qty: '2 шт', section: 'Соусы и бакалея'),
  ],
  'beef_broth': [
    (name: 'Говяжьи кости с мясом', qty: '1 кг', section: 'Мясо и птица'),
    (name: 'Лук', qty: '1 шт', section: 'Овощи и зелень'),
    (name: 'Морковь', qty: '1 шт', section: 'Овощи и зелень'),
  ],
  'fish_broth': [
    (name: 'Рыбные головы и хребты', qty: '700 г', section: 'Рыба и морепродукты'),
    (name: 'Лук', qty: '1 шт', section: 'Овощи и зелень'),
    (name: 'Лавровый лист', qty: '2 шт', section: 'Соусы и бакалея'),
  ],
  'vegetable_broth': [
    (name: 'Морковь', qty: '2 шт', section: 'Овощи и зелень'),
    (name: 'Лук', qty: '2 шт', section: 'Овощи и зелень'),
    (name: 'Сельдерей', qty: '2 стебля', section: 'Овощи и зелень'),
  ],
  'borscht': [
    (name: 'Говядина для бульона', qty: '500 г', section: 'Мясо и птица'),
    (name: 'Свёкла', qty: '2 шт', section: 'Овощи и зелень'),
    (name: 'Капуста', qty: '½ кочана', section: 'Овощи и зелень'),
    (name: 'Картофель', qty: '3 шт', section: 'Овощи и зелень'),
    (name: 'Морковь', qty: '1 шт', section: 'Овощи и зелень'),
    (name: 'Лук', qty: '1 шт', section: 'Овощи и зелень'),
  ],
  'shchi': [
    (name: 'Говядина для бульона', qty: '400 г', section: 'Мясо и птица'),
    (name: 'Капуста', qty: '½ кочана', section: 'Овощи и зелень'),
    (name: 'Картофель', qty: '3 шт', section: 'Овощи и зелень'),
    (name: 'Морковь', qty: '1 шт', section: 'Овощи и зелень'),
    (name: 'Лук', qty: '1 шт', section: 'Овощи и зелень'),
  ],
  'lentil_soup': [
    (name: 'Чечевица красная', qty: '300 г', section: 'Крупы и гарниры'),
    (name: 'Морковь', qty: '1 шт', section: 'Овощи и зелень'),
    (name: 'Лук', qty: '1 шт', section: 'Овощи и зелень'),
    (name: 'Томаты в с/с', qty: '1 банка', section: 'Соусы и бакалея'),
  ],
  'pea_soup': [
    (name: 'Горох сухой', qty: '300 г', section: 'Крупы и гарниры'),
    (name: 'Копчёности', qty: '300 г', section: 'Мясо и птица'),
    (name: 'Картофель', qty: '2 шт', section: 'Овощи и зелень'),
    (name: 'Лук', qty: '1 шт', section: 'Овощи и зелень'),
  ],
  'minestrone': [
    (name: 'Кабачок', qty: '1 шт', section: 'Овощи и зелень'),
    (name: 'Морковь', qty: '1 шт', section: 'Овощи и зелень'),
    (name: 'Томаты в с/с', qty: '1 банка', section: 'Соусы и бакалея'),
    (name: 'Фасоль в банке', qty: '1 банка', section: 'Соусы и бакалея'),
    (name: 'Мелкая паста', qty: '150 г', section: 'Крупы и гарниры'),
  ],
  'kharcho': [
    (name: 'Говядина для бульона', qty: '500 г', section: 'Мясо и птица'),
    (name: 'Рис', qty: '100 г', section: 'Крупы и гарниры'),
    (name: 'Грецкие орехи', qty: 'горсть', section: 'Орехи и сухофрукты'),
    (name: 'Ткемали', qty: '2 ст.л.', section: 'Соусы и бакалея'),
    (name: 'Кинза', qty: 'пучок', section: 'Овощи и зелень'),
  ],
  'ukha': [
    (name: 'Белая рыба', qty: '600 г', section: 'Рыба и морепродукты'),
    (name: 'Картофель', qty: '3 шт', section: 'Овощи и зелень'),
    (name: 'Морковь', qty: '1 шт', section: 'Овощи и зелень'),
    (name: 'Лук', qty: '1 шт', section: 'Овощи и зелень'),
    (name: 'Лавровый лист', qty: '2 шт', section: 'Соусы и бакалея'),
  ],
  'tom_yum': [
    (name: 'Креветки', qty: '300 г', section: 'Рыба и морепродукты'),
    (name: 'Паста том-ям', qty: '1 банка', section: 'Соусы и бакалея'),
    (name: 'Кокосовое молоко', qty: '1 банка', section: 'Соусы и бакалея'),
    (name: 'Шампиньоны', qty: '200 г', section: 'Овощи и зелень'),
    (name: 'Лайм', qty: '1 шт', section: 'Фрукты и ягоды'),
  ],
  'ramen_soup': [
    (name: 'Курица (бёдра)', qty: '500 г', section: 'Мясо и птица'),
    (name: 'Лапша', qty: '2 порции', section: 'Крупы и гарниры'),
    (name: 'Яйца', qty: '2 шт', section: 'Молочное, сыры и яйца'),
    (name: 'Имбирь', qty: 'кусочек', section: 'Овощи и зелень'),
    (name: 'Зелёный лук', qty: 'пучок', section: 'Овощи и зелень'),
  ],
  'beet_cold_soup': [
    (name: 'Свёкла', qty: '2 шт', section: 'Овощи и зелень'),
    (name: 'Огурец', qty: '2 шт', section: 'Овощи и зелень'),
    (name: 'Кефир', qty: '1 л', section: 'Молочное, сыры и яйца'),
    (name: 'Яйца', qty: '2 шт', section: 'Молочное, сыры и яйца'),
    (name: 'Укроп', qty: 'пучок', section: 'Овощи и зелень'),
  ],
  'okroshka': [
    (name: 'Кефир', qty: '1 л', section: 'Молочное, сыры и яйца'),
    (name: 'Огурец', qty: '2 шт', section: 'Овощи и зелень'),
    (name: 'Редис', qty: 'пучок', section: 'Овощи и зелень'),
    (name: 'Яйца', qty: '3 шт', section: 'Молочное, сыры и яйца'),
    (name: 'Ветчина', qty: '200 г', section: 'Мясо и птица'),
    (name: 'Укроп', qty: 'пучок', section: 'Овощи и зелень'),
  ],
  'broccoli_cream_soup': [
    (name: 'Брокколи', qty: '500 г', section: 'Овощи и зелень'),
    (name: 'Картофель', qty: '2 шт', section: 'Овощи и зелень'),
    (name: 'Лук', qty: '1 шт', section: 'Овощи и зелень'),
    (name: 'Сливки 20%', qty: '150 мл', section: 'Молочное, сыры и яйца'),
  ],
  'spinach_cream_soup': [
    (name: 'Шпинат', qty: '400 г', section: 'Овощи и зелень'),
    (name: 'Картофель', qty: '2 шт', section: 'Овощи и зелень'),
    (name: 'Лук', qty: '1 шт', section: 'Овощи и зелень'),
    (name: 'Сливки 20%', qty: '150 мл', section: 'Молочное, сыры и яйца'),
  ],
};

/// Домашние соусы: покупаем ингредиенты, а не банку.
const Map<String, List<Ingredient>> kHomemadeSauceIngredients = {
  'yogurt_sauce': [
    (name: 'Греческий йогурт', qty: '250 г', section: 'Молочное, сыры и яйца'),
    (name: 'Укроп', qty: 'пучок', section: 'Овощи и зелень'),
  ],
  'tomato_sauce': [
    (name: 'Томаты в с/с', qty: '1 банка', section: 'Соусы и бакалея'),
    (name: 'Чеснок', qty: '2 зуб.', section: 'Овощи и зелень'),
  ],
  'bechamel': [
    (name: 'Молоко', qty: '500 мл', section: 'Молочное, сыры и яйца'),
    (name: 'Мука', qty: '50 г', section: 'Соусы и бакалея'),
    (name: 'Сливочное масло', qty: '50 г', section: 'Молочное, сыры и яйца'),
  ],
  'creamy_mushroom': [
    (name: 'Шампиньоны', qty: '300 г', section: 'Овощи и зелень'),
    (name: 'Сливки 20%', qty: '200 мл', section: 'Молочное, сыры и яйца'),
  ],
  'cheese_sauce': [
    (name: 'Сыр', qty: '150 г', section: 'Молочное, сыры и яйца'),
    (name: 'Сливки 20%', qty: '150 мл', section: 'Молочное, сыры и яйца'),
  ],
  'lemon_dressing': [
    (name: 'Лимон', qty: '2 шт', section: 'Фрукты и ягоды'),
    (name: 'Оливковое масло', qty: 'есть дома?', section: 'Соусы и бакалея'),
  ],
  'caesar': [
    (name: 'Греческий йогурт', qty: '150 г', section: 'Молочное, сыры и яйца'),
    (name: 'Пармезан', qty: '50 г', section: 'Молочное, сыры и яйца'),
    (name: 'Чеснок', qty: '2 зуб.', section: 'Овощи и зелень'),
  ],
  'honey_mustard': [
    (name: 'Мёд', qty: '2 ст.л.', section: 'Соусы и бакалея'),
    (name: 'Горчица', qty: '2 ст.л.', section: 'Соусы и бакалея'),
  ],
  'tzatziki': [
    (name: 'Греческий йогурт', qty: '250 г', section: 'Молочное, сыры и яйца'),
    (name: 'Огурец', qty: '1 шт', section: 'Овощи и зелень'),
    (name: 'Чеснок', qty: '2 зуб.', section: 'Овощи и зелень'),
  ],
  'guacamole': [
    (name: 'Авокадо', qty: '2 шт', section: 'Фрукты и ягоды'),
    (name: 'Лайм', qty: '1 шт', section: 'Фрукты и ягоды'),
  ],
  'salsa': [
    (name: 'Томаты', qty: '3 шт', section: 'Овощи и зелень'),
    (name: 'Лук красный', qty: '1 шт', section: 'Овощи и зелень'),
    (name: 'Кинза', qty: 'пучок', section: 'Овощи и зелень'),
  ],
  'chimichurri': [
    (name: 'Петрушка', qty: '2 пучка', section: 'Овощи и зелень'),
    (name: 'Чеснок', qty: '3 зуб.', section: 'Овощи и зелень'),
    (name: 'Винный уксус', qty: '2 ст.л.', section: 'Соусы и бакалея'),
  ],
  'bolognese': [
    (name: 'Говяжий фарш', qty: '400 г', section: 'Мясо и птица'),
    (name: 'Томаты в с/с', qty: '1 банка', section: 'Соусы и бакалея'),
    (name: 'Лук', qty: '1 шт', section: 'Овощи и зелень'),
  ],
  'curry_coconut': [
    (name: 'Кокосовое молоко', qty: '1 банка', section: 'Соусы и бакалея'),
    (name: 'Паста карри', qty: '1 банка', section: 'Соусы и бакалея'),
  ],
};

/// Готовые соусы — покупаются банкой/бутылкой как есть.
bool isStoreBoughtSauce(String id) =>
    !kHomemadeSauceIngredients.containsKey(id) && !kSoupIngredients.containsKey(id);
