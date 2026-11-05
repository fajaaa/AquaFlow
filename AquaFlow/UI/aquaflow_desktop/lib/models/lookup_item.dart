class LookupItem {
  const LookupItem({
    required this.id,
    required this.code,
    required this.name,
    required this.nameEn,
    required this.nameDe,
    required this.sortOrder,
    required this.isSystem,
    required this.isActive,
  });

  final int id;
  final String code;
  final String name;
  final String? nameEn;
  final String? nameDe;
  final int sortOrder;
  final bool isSystem;
  final bool isActive;

  factory LookupItem.fromJson(Map<String, dynamic> json) {
    String? text(String key) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty ? value : null;
    }

    return LookupItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: (json['code'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      nameEn: text('nameEn'),
      nameDe: text('nameDe'),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isSystem: json['isSystem'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  String localizedName(String languageCode) {
    switch (languageCode) {
      case 'de':
        return nameDe ?? name;
      case 'en':
        return nameEn ?? name;
      default:
        return name;
    }
  }
}

class LookupItemPage {
  const LookupItemPage({required this.items, required this.totalCount});

  final List<LookupItem> items;
  final int totalCount;
}

class LookupItemDraft {
  const LookupItemDraft({
    required this.code,
    required this.name,
    required this.nameEn,
    required this.nameDe,
    required this.sortOrder,
    required this.isActive,
  });

  final String code;
  final String name;
  final String nameEn;
  final String nameDe;
  final int sortOrder;
  final bool isActive;

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'nameEn': nameEn.isEmpty ? null : nameEn,
    'nameDe': nameDe.isEmpty ? null : nameDe,
    'sortOrder': sortOrder,
    'isActive': isActive,
  };
}
