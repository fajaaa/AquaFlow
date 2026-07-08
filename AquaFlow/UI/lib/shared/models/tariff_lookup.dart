/// An active tariff as returned by `GET /Tariffs?IsActive=true`, trimmed to
/// what the collector's reading-entry tariff picker needs (see
/// [TariffLookupService]).
class TariffLookup {
  const TariffLookup({
    required this.id,
    required this.name,
    required this.pricePerM3,
  });

  final int id;
  final String name;
  final double pricePerM3;

  factory TariffLookup.fromJson(Map<String, dynamic> json) {
    return TariffLookup(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '') as String,
      pricePerM3: (json['pricePerM3'] as num?)?.toDouble() ?? 0,
    );
  }
}
