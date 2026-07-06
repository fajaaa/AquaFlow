/// One of the signed-in customer's own service locations, as returned by
/// `GET /ServiceLocations` (the backend pins the listing to the caller for the
/// Customer role). Used as the pick-list when requesting a new water meter.
class CustomerServiceLocation {
  const CustomerServiceLocation({
    required this.id,
    required this.address,
    required this.locationType,
  });

  final int id;
  final String address;
  final String locationType;

  factory CustomerServiceLocation.fromJson(Map<String, dynamic> json) {
    return CustomerServiceLocation(
      id: (json['id'] as num?)?.toInt() ?? 0,
      address: (json['address'] ?? '') as String,
      locationType: (json['locationType'] ?? '') as String,
    );
  }
}
