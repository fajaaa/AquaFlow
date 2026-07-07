/// Read-only naselje lookup entry for area/address pickers (e.g. the admin
/// Collectors screen's area dropdown, and the cascading location picker in
/// the Users editor dialog). Carries the flattened `municipalityName` for
/// display only - it has no `municipalityId`, so it cannot be used to filter
/// a cascading dropdown; use [AdminSettlement] for that instead.
class AdminSettlementOption {
  const AdminSettlementOption({
    required this.id,
    required this.name,
    required this.municipalityName,
  });

  final int id;
  final String name;
  final String municipalityName;

  /// "Naselje (Općina)" for dropdown display.
  String get label {
    final name = this.name.trim();
    final municipality = municipalityName.trim();
    if (name.isEmpty) return 'Naselje #$id';
    return municipality.isEmpty ? name : '$name ($municipality)';
  }

  factory AdminSettlementOption.fromJson(Map<String, dynamic> json) {
    return AdminSettlementOption(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '') as String,
      municipalityName: (json['municipalityName'] ?? '') as String,
    );
  }
}
