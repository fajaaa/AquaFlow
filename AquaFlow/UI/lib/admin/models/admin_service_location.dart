class AdminServiceLocation {
  const AdminServiceLocation({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.settlementId,
    required this.settlementName,
    required this.address,
    required this.locationType,
    required this.latitude,
    required this.longitude,
    required this.isActive,
    required this.createdAt,
  });

  final int id;
  final int customerId;
  final String customerName;
  final int settlementId;
  final String settlementName;
  final String address;
  final String locationType;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final DateTime? createdAt;

  factory AdminServiceLocation.fromJson(Map<String, dynamic> json) {
    return AdminServiceLocation(
      id: (json['id'] as num?)?.toInt() ?? 0,
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      customerName: (json['customerName'] ?? '') as String,
      settlementId: (json['settlementId'] as num?)?.toInt() ?? 0,
      settlementName: (json['settlementName'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      locationType: (json['locationType'] ?? '') as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isActive: (json['isActive'] as bool?) ?? true,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String),
    );
  }
}
