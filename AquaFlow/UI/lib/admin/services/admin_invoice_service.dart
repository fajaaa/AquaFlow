import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/admin/models/admin_invoice.dart';
import 'package:aquaflow_desktop/admin/models/admin_invoice_billing_cycle_option.dart';
import 'package:aquaflow_desktop/admin/models/admin_invoice_page.dart';
import 'package:aquaflow_desktop/admin/services/admin_invoice_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

class AdminInvoiceService {
  AdminInvoiceService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<AdminInvoicePage> fetch({
    required int page,
    required int pageSize,
    String? invoiceNumber,
    String? status,
    int? billingCycleId,
  }) async {
    final token = await _requireToken();
    final query = <String, String>{
      'Page': '$page',
      'PageSize': '$pageSize',
      'IncludeTotalCount': 'true',
      'SortBy': 'CreatedAt',
      'SortDescending': 'true',
    };

    final invoiceNumberText = invoiceNumber?.trim();
    if (invoiceNumberText != null && invoiceNumberText.isNotEmpty) {
      query['InvoiceNumber'] = invoiceNumberText;
    }
    if (status != null && status.isNotEmpty) {
      query['Status'] = status;
    }
    if (billingCycleId != null) {
      query['BillingCycleId'] = '$billingCycleId';
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/Invoices',
    ).replace(queryParameters: query);

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminInvoiceException(
        _messageFor(response, 'Račune nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminInvoiceException('Računi su u neispravnom formatu.');
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const AdminInvoiceException('Lista računa je neispravna.');
    }

    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AdminInvoice.fromJson)
        .toList();

    return AdminInvoicePage(
      items: items,
      totalCount: (decoded['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }

  Future<List<AdminInvoiceBillingCycleOption>> fetchBillingCycles() async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/BillingCycles').replace(
      queryParameters: {
        'PageSize': '200',
        'SortBy': 'PeriodFrom',
        'SortDescending': 'true',
      },
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminInvoiceException(
        _messageFor(response, 'Ciklusi obračuna nisu dostupni'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['items'] is! List) {
      throw const AdminInvoiceException(
        'Lista ciklusa obračuna je neispravna.',
      );
    }

    return (decoded['items'] as List)
        .whereType<Map<String, dynamic>>()
        .map(AdminInvoiceBillingCycleOption.fromJson)
        .toList();
  }

  Future<AdminInvoice> issue(int id) => _postAction(id, 'issue');

  Future<AdminInvoice> recordPayment(int id, double amount) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Invoices/$id/payments');

    final response = await _send(
      () => _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'amount': amount}),
      ),
    );

    if (response.statusCode != 200) {
      throw AdminInvoiceException(
        _messageFor(response, 'Uplatu nije moguće evidentirati'),
      );
    }

    return _decodeInvoice(response.body);
  }

  Future<AdminInvoice> cancel(int id) => _postAction(id, 'cancel');

  Future<AdminInvoice> markOverdue(int id) => _postAction(id, 'mark-overdue');

  Future<AdminInvoice> _postAction(int id, String action) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Invoices/$id/$action');

    final response = await _send(
      () => _client.post(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminInvoiceException(
        _messageFor(response, 'Radnju nije moguće izvršiti'),
      );
    }

    return _decodeInvoice(response.body);
  }

  AdminInvoice _decodeInvoice(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminInvoiceException('Račun je u neispravnom formatu.');
    }
    return AdminInvoice.fromJson(decoded);
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const AdminInvoiceException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw AdminInvoiceException('Server nije dostupan na ${ApiConfig.baseUrl}.');
    } on TimeoutException {
      throw const AdminInvoiceException('Server nije odgovorio na vrijeme.');
    } on http.ClientException catch (e) {
      throw AdminInvoiceException('Greška mreže: ${e.message}');
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
