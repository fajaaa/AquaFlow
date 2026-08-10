/// A settlement as returned by `GET /Settlements`, trimmed to what the
/// cascading Grad -> Općina -> Naselje address pickers need (see
/// [LocationLookupService]).
class SettlementLookup {
  const SettlementLookup({
    required this.id,
    required this.name,
    required this.municipalityId,
  });

  final int id;
  final String name;
  final int municipalityId;

  factory SettlementLookup.fromJson(Map<String, dynamic> json) {
    return SettlementLookup(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '') as String,
      municipalityId: (json['municipalityId'] as num?)?.toInt() ?? 0,
    );
  }
}
