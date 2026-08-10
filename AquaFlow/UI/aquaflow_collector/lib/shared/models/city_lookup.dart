/// A city as returned by `GET /Cities`, trimmed to what the cascading
/// Grad -> Općina -> Naselje address pickers need (see [LocationLookupService]).
class CityLookup {
  const CityLookup({required this.id, required this.name});

  final int id;
  final String name;

  factory CityLookup.fromJson(Map<String, dynamic> json) {
    return CityLookup(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '') as String,
    );
  }
}
