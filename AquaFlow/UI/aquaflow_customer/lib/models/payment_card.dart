/// A saved Stripe card as returned by `GET /PaymentCards` (`items[]`).
class PaymentCard {
  const PaymentCard({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
  });

  final String id;
  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;

  /// A card is valid through the last day of its expiry month.
  bool get isExpired {
    final now = DateTime.now();
    return expYear < now.year || (expYear == now.year && expMonth < now.month);
  }

  String get expiryLabel =>
      '${expMonth.toString().padLeft(2, '0')}/${(expYear % 100).toString().padLeft(2, '0')}';

  factory PaymentCard.fromJson(Map<String, dynamic> json) {
    return PaymentCard(
      id: (json['id'] ?? '').toString(),
      brand: (json['brand'] ?? '') as String,
      last4: (json['last4'] ?? '') as String,
      expMonth: (json['expMonth'] as num?)?.toInt() ?? 0,
      expYear: (json['expYear'] as num?)?.toInt() ?? 0,
    );
  }
}

/// `GET /PaymentCards` response. [isSupported] is false when the active
/// payment provider has no saved-card support.
class PaymentCardList {
  const PaymentCardList({required this.isSupported, required this.items});

  final bool isSupported;
  final List<PaymentCard> items;

  factory PaymentCardList.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return PaymentCardList(
      isSupported: json['isSupported'] != false,
      items: raw is List
          ? raw.whereType<Map<String, dynamic>>().map(PaymentCard.fromJson).toList()
          : const [],
    );
  }
}

/// `POST /PaymentCards/setup` response - drives a Stripe PaymentSheet in
/// setup-intent mode.
class PaymentCardSetup {
  const PaymentCardSetup({
    required this.setupIntentClientSecret,
    required this.stripeCustomerId,
    required this.ephemeralKeySecret,
  });

  final String setupIntentClientSecret;
  final String stripeCustomerId;
  final String ephemeralKeySecret;

  factory PaymentCardSetup.fromJson(Map<String, dynamic> json) {
    return PaymentCardSetup(
      setupIntentClientSecret: (json['setupIntentClientSecret'] ?? '') as String,
      stripeCustomerId: (json['stripeCustomerId'] ?? '') as String,
      ephemeralKeySecret: (json['ephemeralKeySecret'] ?? '') as String,
    );
  }
}
