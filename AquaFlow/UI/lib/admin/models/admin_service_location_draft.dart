class AdminServiceLocationDraft {
  const AdminServiceLocationDraft({
    required this.customerId,
    required this.settlementId,
    required this.address,
    required this.locationType,
    this.latitude,
    this.longitude,
    required this.isActive,
  });

  final int customerId;
  final int settlementId;
  final String address;
  final String locationType;
  final double? latitude;
  final double? longitude;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'settlementId': settlementId,
      'address': address,
      'locationType': locationType,
      'latitude': latitude,
      'longitude': longitude,
      'isActive': isActive,
    };
  }
}
