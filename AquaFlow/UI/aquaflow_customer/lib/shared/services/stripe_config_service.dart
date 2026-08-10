import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/stripe_config.dart';

/// Fetches the publishable Stripe config (`GET /Payments/stripe-config`,
/// `[AllowAnonymous]` server-side - a publishable key is not a secret by
/// design, so this needs no bearer token and can run before login). Called
/// once at startup, before any customer payment screen, to set
/// `Stripe.publishableKey`.
///
/// [fetch] returns null on any failure (network error, non-200, empty key)
/// rather than throwing - the rest of the app (including login) must keep
/// working even when Stripe isn't configured (e.g. the default Manual
/// provider is active) or the backend is briefly unreachable at cold start.
/// `CustomerInvoiceDetailScreen._payInvoice` falls back to its pre-Stripe
/// SnackBar flow whenever a checkout session comes back with no
/// `clientSecret`, so a null config here degrades gracefully rather than
/// breaking payment.
class StripeConfigService {
  StripeConfigService({http.Client? client, Duration? timeout})
    : _client = client ?? http.Client(),
      _timeout = timeout ?? const Duration(seconds: 10);

  final http.Client _client;
  final Duration _timeout;

  Future<StripeConfig?> fetch() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/Payments/stripe-config');
      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      final config = StripeConfig.fromJson(decoded);
      if (config.publishableKey.isEmpty) return null;
      return config;
    } catch (_) {
      return null;
    }
  }

  void dispose() => _client.close();
}
