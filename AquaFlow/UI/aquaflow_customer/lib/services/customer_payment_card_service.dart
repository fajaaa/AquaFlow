import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_customer/models/payment_card.dart';
import 'package:aquaflow_customer/services/customer_payment_card_exception.dart';
import 'package:aquaflow_customer/shared/config/api_config.dart';
import 'package:aquaflow_customer/shared/services/authenticated_client.dart';

/// Saved payment cards of the signed-in customer. The backend resolves the
/// customer from the JWT; no customer id is ever sent.
class CustomerPaymentCardService {
  CustomerPaymentCardService({http.Client? client, Duration? timeout})
    : _client = client ?? AuthenticatedClient.instance,
      _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final Duration _timeout;

  Future<PaymentCardList> fetchCards() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/PaymentCards');
    final response = await _send(() => _client.get(uri));
    if (response.statusCode != 200) {
      throw CustomerPaymentCardException(
        _messageFor(response, 'Kartice nije moguće učitati'),
      );
    }
    return PaymentCardList.fromJson(_decodeMap(response));
  }

  Future<PaymentCardSetup> createSetup() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/PaymentCards/setup');
    final response = await _send(
      () => _client.post(uri, headers: {'Content-Type': 'application/json'}),
    );
    if (response.statusCode != 200) {
      throw CustomerPaymentCardException(
        _messageFor(response, 'Dodavanje kartice nije moguće pokrenuti'),
      );
    }
    return PaymentCardSetup.fromJson(_decodeMap(response));
  }

  Future<void> deleteCard(String id) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/PaymentCards/${Uri.encodeComponent(id)}',
    );
    final response = await _send(() => _client.delete(uri));
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw CustomerPaymentCardException(
        _messageFor(response, 'Karticu nije moguće obrisati'),
      );
    }
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CustomerPaymentCardException(
        'Odgovor servera je u neispravnom formatu.',
      );
    }
    return decoded;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw CustomerPaymentCardException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
        isNetworkError: true,
      );
    } on TimeoutException {
      throw const CustomerPaymentCardException(
        'Server nije odgovorio na vrijeme.',
        isNetworkError: true,
      );
    } on http.ClientException catch (e) {
      throw CustomerPaymentCardException(
        'Greška mreže: ${e.message}',
        isNetworkError: true,
      );
    }
  }

  String _messageFor(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } catch (_) {
      // Body was not JSON; fall through to the status-based message.
    }
    return '$fallback (HTTP ${response.statusCode}).';
  }

  void dispose() => _client.close();
}
