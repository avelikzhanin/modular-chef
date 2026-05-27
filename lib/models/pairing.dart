/// Готовая тройка «белок + гарнир + соус» из матрицы сочетаемости.
/// Подаётся в Claude как hints для построения меню — гарантирует, что
/// генератор не предложит несовместимые сочетания.
class Pairing {
  const Pairing({
    required this.proteinId,
    required this.sideId,
    required this.tags,
    this.sauceId,
    this.name,
  });

  final String proteinId;
  final String sideId;
  final String? sauceId;
  final List<String> tags;
  final String? name;

  factory Pairing.fromJson(Map<String, dynamic> json) => Pairing(
        proteinId: json['protein'] as String,
        sideId: json['side'] as String,
        sauceId: json['sauce'] as String?,
        tags: ((json['tags'] as List?) ?? const []).cast<String>(),
        name: json['name'] as String?,
      );
}
