import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/admin/models/admin_customer_profile.dart';
import 'package:aquaflow_desktop/admin/models/admin_service_location.dart';
import 'package:aquaflow_desktop/admin/models/admin_service_location_draft.dart';
import 'package:aquaflow_desktop/admin/models/admin_service_location_page.dart';
import 'package:aquaflow_desktop/admin/models/admin_settlement_option.dart';
import 'package:aquaflow_desktop/admin/services/admin_service_location_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

class AdminServiceLocationService {
  AdminServiceLocationService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<AdminServiceLocationPage> fetch({
    required int page,
    required int pageSize,
    int? customerId,
    int? settlementId,
    String? locationType,
    bool? isActive,
    String? address,
  }) async {
    final token = await _requireToken();
    final query = <String, String>{
      'Page': '$page',
      'PageSize': '$pageSize',
      'IncludeTotalCount': 'true',
      'SortBy': 'CreatedAt',
      'SortDescending': 'true',
    };

    if (customerId != null) {
      query['CustomerId'] = '$customerId';
    }
    if (settlementId != null) {
      query['SettlementId'] = '$settlementId';
    }
    if (locationType != null && locationType.isNotEmpty) {
      query['LocationType'] = locationType;
    }
    if (isActive != null) {
      query['IsActive'] = '$isActive';
    }
    final addressText = address?.trim();
    if (addressText != null && addressText.isNotEmpty) {
      query['Address'] = addressText;
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/ServiceLocations',
    ).replace(queryParameters: query);

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminServiceLocationException(
        _messageFor(response, 'Lokacije nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminServiceLocationException(
        'Lokacije su u neispravnom formatu.',
      );
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const AdminServiceLocationException(
        'Lista lokacija je neispravna.',
      );
    }

    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AdminServiceLocation.fromJson)
        .toList();

    return AdminServiceLocationPage(
      items: items,
      totalCount: (decoded['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }

  Future<AdminServiceLocation> create(AdminServiceLocationDraft draft) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/ServiceLocations');

    final response = await _send(
      () => _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(draft.toJson()),
      ),
    );

    if (response.statusCode != 201) {
      throw AdminServiceLocationException(
        _messageFor(response, 'Lokaciju nije moguće dodati'),
      );
    }

    return _decodeLocation(response.body);
  }

  Future<AdminServiceLocation> update(
    int id,
    AdminServiceLocationDraft draft,
  ) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/ServiceLocations/$id');

    final response = await _send(
      () => _client.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(draft.toJson()),
      ),
    );

    if (response.statusCode != 200) {
      throw AdminServiceLocationException(
        _messageFor(response, 'Lokaciju nije moguće sačuvati'),
      );
    }

    return _decodeLocation(response.body);
  }

  /// Toggles [isActive] only, via PATCH - the row "Deaktiviraj"/"Aktiviraj"
  /// action never touches the other fields.
  Future<AdminServiceLocation> setActive(int id, bool isActive) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/ServiceLocations/$id');

    final response = await _send(
      () => _client.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'isActive': isActive}),
      ),
    );

    if (response.statusCode != 200) {
      throw AdminServiceLocationException(
        _messageFor(
          response,
          isActive
              ? 'Lokaciju nije moguće aktivirati'
              : 'Lokaciju nije moguće deaktivirati',
        ),
      );
    }

    return _decodeLocation(response.body);
  }

  Future<void> delete(int id) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/ServiceLocations/$id');

    final response = await _send(
      () => _client.delete(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 204) {
      throw AdminServiceLocationException(
        _messageFor(response, 'Lokaciju nije moguće obrisati'),
      );
    }
  }

  Future<List<AdminSettlementOption>> fetchSettlements() async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Settlements').replace(
      queryParameters: {
        'PageSize': '100',
        'IncludeTotalCount': 'true',
        'SortBy': 'Name',
      },
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminServiceLocationException(
        _messageFor(response, 'Naselja nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminServiceLocationException(
        'Naselja su u neispravnom formatu.',
      );
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const AdminServiceLocationException(
        'Lista naselja je neispravna.',
      );
    }

    return itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AdminSettlementOption.fromJson)
        .toList();
  }

  Future<List<AdminCustomerProfile>> fetchCustomers() async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/CustomerProfiles').replace(
      queryParameters: {
        'PageSize': '200',
        'IncludeTotalCount': 'true',
        'SortBy': 'FirstName',
      },
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminServiceLocationException(
        _messageFor(response, 'Kupce nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminServiceLocationException(
        'Kupci su u neispravnom formatu.',
      );
    }

    final itemsJson = decoded['items'];
    if (itemsJson is! List) {
      throw const AdminServiceLocationException(
        'Lista kupaca je neispravna.',
      );
    }

    return itemsJson
        .whereType<Map<String, dynamic>>()
        .map(AdminCustomerProfile.fromJson)
        .toList();
  }

  AdminServiceLocation _decodeLocation(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminServiceLocationException(
        'Lokacija je u neispravnom formatu.',
      );
    }
    return AdminServiceLocation.fromJson(decoded);
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const AdminServiceLocationException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw AdminServiceLocationException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const AdminServiceLocationException(
        'Server nije odgovorio na vrijeme.',
      );
    } on http.ClientException catch (e) {
      throw AdminServiceLocationException('Greška mreže: ${e.message}');
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
