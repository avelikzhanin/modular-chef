import 'package:flutter/material.dart';
import 'package:modular_chef/models/module.dart';

/// Акварельные картинки продуктов из дизайна Stitch (assets/art/icons/<id>.png).
/// Для модулей без картинки — фолбэк на скруглённую иконку категории.
const Set<String> _kIconFiles = {
  'addin_avocado', 'addin_bacon', 'addin_cheese',
  'bell_pepper', 'broccoli', 'buckwheat', 'cherry_tomato', 'chicken_breast',
  'egg_boiled', 'egg_omelet', 'egg_poached', 'egg_scrambled', 'eggs', 'jar',
  'jb_chia', 'jb_overnight_oats', 'mushroom_soup', 'pesto', 'porridge',
  'potato', 'pumpkin_soup', 'rice', 'salmon', 'shrimp', 'spaghetti',
  'spinach', 'steak', 'syrniki', 'tahini', 'tomato_sauce', 'tomato_soup',
  'yogurt_sauce',
  // — нарезано из листов Stitch (2-я партия):
  'soy_sesame', 'tzatziki', 'balsamic', 'addin_feta', 'addin_mushrooms',
  'addin_ham', 'addin_green_onion', 'addin_herbs', 'addin_toast',
  'jb_greek_yogurt', 'jb_rice_pudding', 'jb_semolina',
  'jb_quinoa', 'jb_bircher', 'jb_flax', 'jb_coconut', 'jb_millet',
  'jb_choco_oats', 'jb_pumpkin_oats', 'jb_protein_mousse', 'jb_milk_couscous',
  'jbar_peanut', 'jbar_almond', 'jbar_jam', 'jbar_honey', 'jbar_fruit_puree',
  'jbar_coulis', 'jbar_lemon_curd', 'jbar_cream_cheese', 'jbar_coconut_cream',
  'jbar_choco_spread', 'jbar_caramel', 'jbar_condensed', 'jbar_thick_yogurt',
  'jbar_urbech',
  'jm_strawberry', 'jm_raspberry', 'jm_frozen_berries', 'jm_banana',
  'jm_apple_pear', 'jm_peach', 'jm_mango', 'jm_kiwi', 'jm_pomegranate',
  'jm_baked_apple', 'jm_pineapple', 'jm_fig', 'jm_citrus', 'jm_dried_fruit',
  'jt_granola', 'jt_walnuts', 'jt_almonds', 'jt_hazelnuts', 'jt_cashews',
  'jt_pumpkin_seeds', 'jt_sunflower_seeds', 'jt_chia_flax', 'jt_coconut',
  'jt_cacao_nibs', 'jt_dark_choco', 'jt_fruit_chips', 'jt_muesli',
  'jt_sesame_poppy', 'jt_mint_zest',
  // — финальная партия (листы 1–4): полный каталог 141/141.
  'turkey', 'cod', 'meatballs', 'tofu', 'bulgur', 'couscous', 'quinoa',
  'cheese_soup', 'chicken_noodle_soup', 'salad_mix', 'zucchini',
  'sandwiches', 'granola_bowl', 'nuts', 'cottage_cheese', 'fruit',
  'protein_bar', 'energy_balls',
  'bechamel', 'lemon_dressing', 'creamy_mushroom', 'teriyaki',
  'curry_coconut', 'bbq', 'cheese_sauce', 'tkemali',
  'adjika', 'bolognese', 'chimichurri', 'salsa', 'guacamole', 'hummus',
  'caesar', 'honey_mustard',
  // — единый стиль (102 одиночных, 12.07): свои картинки у бывших алиасов.
  'egg_fried', 'egg_shakshuka', 'jm_blueberry',
  // — расширение каталога 15.07: новые белки, гарниры, виды каш.
  'pork_tenderloin', 'chicken_thighs', 'ground_beef', 'trout', 'tuna',
  'squid', 'liver', 'rice_basmati', 'pasta', 'lentils', 'chickpeas',
  'pearl_barley', 'porridge_oat', 'porridge_rice', 'porridge_semolina',
  'porridge_millet',
  // — рыба и мясо 16.07.
  'pink_salmon', 'mackerel', 'pikeperch', 'pollock', 'hake', 'seabass',
  'dorado', 'herring', 'mussels', 'lamb', 'rabbit', 'duck', 'beef_tongue',
  'chicken_cutlets', 'fish_cutlets',
  // — белки-расширение 17.07.
  'chicken_wings', 'whole_chicken', 'goose', 'quail', 'chicken_mince',
  'turkey_mince', 'veal', 'pork_ribs', 'pork_loin', 'beef_stew',
  'beef_liver', 'beef_stroganoff', 'chum_salmon', 'perch', 'halibut',
  'wolffish', 'flounder', 'scallops', 'octopus', 'crab', 'tempeh',
  'seitan', 'edamame', 'chickpea_cutlets', 'falafel', 'soy_meat',
  'addin_salmon',
  // — ингредиенты покупок (ing_*) и категории меню (cat_*).
  'ing_pumpkin', 'ing_onion', 'ing_red_onion', 'ing_carrot', 'ing_garlic',
  'ing_cream', 'ing_milk', 'ing_butter', 'ing_flour',
  'ing_processed_cheese', 'ing_parmesan', 'ing_canned_tomatoes',
  'ing_tomatoes', 'ing_basil', 'ing_dill', 'ing_parsley', 'ing_cilantro',
  'ing_cucumber', 'ing_lemon', 'ing_lime', 'ing_mustard', 'ing_olive_oil',
  'ing_noodles', 'ing_bread', 'ing_bay_leaf', 'ing_vinegar',
  'ing_coconut_milk', 'ing_curry_paste',
  'cat_meat', 'cat_poultry', 'cat_fish', 'cat_plant', 'cat_grains',
  'cat_legumes', 'cat_pasta', 'cat_soups', 'cat_breakfast',
  // — супы-расширение и их ингредиенты 17.07.
  'borscht', 'shchi', 'lentil_soup', 'pea_soup', 'minestrone', 'kharcho',
  'ukha', 'tom_yum', 'ramen_soup', 'beet_cold_soup', 'okroshka',
  'broccoli_cream_soup', 'spinach_cream_soup',
  'ing_beet', 'ing_cabbage', 'ing_split_peas', 'ing_smoked_meat',
  'ing_canned_beans', 'ing_tom_yum', 'ing_ginger', 'ing_kefir', 'ing_radish',
};

/// id-псевдонимы: продукт использует картинку другого id.
const Map<String, String> _kAliases = {
  'addin_tomatoes': 'cherry_tomato',
  'addin_chicken': 'chicken_breast',
  'addin_pepper': 'bell_pepper',
  'addin_salad': 'salad_mix',
  'addin_spinach': 'spinach',
  'jbar_tahini': 'tahini',
  'jb_cottage': 'cottage_cheese',
};

/// Путь к акварельной картинке модуля или null, если её ещё нет.
String? moduleImage(String id) {
  final key = _kAliases[id] ?? id;
  return _kIconFiles.contains(key) ? 'assets/art/icons/$key.png' : null;
}

/// Промежуточные скруглённые иконки модулей — по категории (фолбэк).
IconData moduleIcon(ModuleCategory category) => switch (category) {
      ModuleCategory.protein => Icons.set_meal_rounded,
      ModuleCategory.side => Icons.rice_bowl_rounded,
      ModuleCategory.soup => Icons.soup_kitchen_rounded,
      ModuleCategory.breakfast => Icons.bakery_dining_rounded,
      ModuleCategory.snack => Icons.cookie_rounded,
      ModuleCategory.vegetable => Icons.eco_rounded,
      ModuleCategory.sauce => Icons.water_drop_rounded,
      ModuleCategory.eggStyle => Icons.egg_rounded,
      ModuleCategory.eggAddin => Icons.local_dining_rounded,
      ModuleCategory.jarBase => Icons.breakfast_dining_rounded,
      ModuleCategory.jarBarrier => Icons.opacity_rounded,
      ModuleCategory.jarMiddle => Icons.spa_rounded,
      ModuleCategory.jarTop => Icons.grain_rounded,
    };
