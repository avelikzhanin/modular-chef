/// Зоны хранения, на которые делятся модули и правила.
enum StorageZone {
  fridge('fridge', '🟩', 'Холодильник'),
  freezer('freezer', '🟦', 'Морозилка'),
  vacuum('vacuum', '🟣', 'Вакуум'),
  pantry('pantry', '🟫', 'Кладовая');

  const StorageZone(this.jsonValue, this.emoji, this.label);

  final String jsonValue;
  final String emoji;
  final String label;

  static StorageZone fromJson(String value) =>
      StorageZone.values.firstWhere((z) => z.jsonValue == value);
}
