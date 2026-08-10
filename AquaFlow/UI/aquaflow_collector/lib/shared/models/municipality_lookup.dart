/// A municipality as returned by `GET /Municipalities`, trimmed to what the
/// cascading Grad -> Općina -> Naselje address pickers need (see
/// [LocationLookupService]).
class MunicipalityLookup {
  const MunicipalityLookup({
    required this.id,
    required this.name,
    required this.cityId,
  });

  final int id;
  final String name;
  final int cityId;

  factory MunicipalityLookup.fromJson(Map<String, dynamic> json) {
    return MunicipalityLookup(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '') as String,
      cityId: (json['cityId'] as num?)?.toInt() ?? 0,
    );
  }
}
