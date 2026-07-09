import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/customer/models/customer_invoice.dart';
import 'package:aquaflow_desktop/customer/models/customer_invoice_page.dart';
import 'package:aquaflow_desktop/customer/models/customer_payment.dart';
import 'package:aquaflow_desktop/customer/services/customer_invoice_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

/// Invoices of the signed-in customer, and the completed payments recorded
/// against one of them. No CustomerId is ever sent - the backend resolves and
/// pins it from the JWT (see the Invoice ownership-pinning rule in
/// AGENTS.md), so this service can never touch another customer's invoices.
/// Follows the `CustomerWaterMeterRequestService` template.
class CustomerInvoiceService {
  CustomerInvoiceService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  /// One page of the caller's invoices, newest first. The backend pins
  /// `CustomerId` to the caller from the JWT, so this only ever returns the
  /// signed-in customer's own invoices (every status).
  Future<CustomerInvoicePage> fetchPage({
    required int page,
    int pageSize = 20,
  }) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Invoices').replace(
      queryParameters: {
        'Page': '$page',
        'PageSize': '$pageSize',
        'IncludeTotalCount': 'true',
        'SortBy': 'CreatedAt',
        'SortDescending': 'true',
      },
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw CustomerInvoiceException(
        _messageFor(response, 'Račune nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CustomerInvoiceException(
        'Odgovor servera je u neispravnom formatu.',
      );
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const CustomerInvoiceException(
        'Lista je u neispravnom formatu.',
      );
    }

    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(CustomerInvoice.fromJson)
        .toList();

    return CustomerInvoicePage(
      items: items,
      totalCount: (decoded['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }

  /// The Completed payments recorded against one of the caller's invoices.
  /// The backend pins `CustomerId` to the caller from the JWT, same as
  /// [fetchPage].
  Future<List<CustomerPayment>> fetchPayments(int invoiceId) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Payments').replace(
      queryParameters: {
        'InvoiceId': '$invoiceId',
        'Status': 'Completed',
        'PageSize': '100',
      },
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw CustomerInvoiceException(
        _messageFor(response, 'Uplate nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CustomerInvoiceException(
        'Odgovor servera je u neispravnom formatu.',
      );
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const CustomerInvoiceException(
        'Lista je u neispravnom formatu.',
      );
    }

    return itemsJson
        .whereType<Map<String, dynamic>>()
        .map(CustomerPayment.fromJson)
        .toList();
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const CustomerInvoiceException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw CustomerInvoiceException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const CustomerInvoiceException(
        'Server nije odgovorio na vrijeme.',
      );
    } on http.ClientException catch (e) {
      throw CustomerInvoiceException('Greška mreže: ${e.message}');
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
