import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:aquaflow_desktop/models/dashboard_stats.dart';
import 'package:aquaflow_desktop/models/dashboard_status_breakdown.dart';
import 'package:aquaflow_desktop/models/dashboard_trend_point.dart';
import 'package:aquaflow_desktop/services/admin_dashboard_exception.dart';
import 'package:aquaflow_desktop/shared/config/api_config.dart';
import 'package:aquaflow_desktop/shared/services/token_storage.dart';

/// Feeds the admin dashboard's 6 chart cards from `GET /Dashboard/*`. All 6
/// requests share the same (from, to, cityId) filter and are fired in
/// parallel via [fetchStats] rather than one at a time, since the dashboard
/// always needs every chart at once.
class AdminDashboardService {
  AdminDashboardService({
    http.Client? client,
    TokenStorage? tokenStorage,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final Duration _timeout;

  Future<DashboardStats> fetchStats({
    DateTime? from,
    DateTime? to,
    int? cityId,
  }) async {
    final results = await Future.wait([
      _fetchTrend('revenue-trend', from, to, cityId),
      _fetchBreakdown('invoice-status', from, to, cityId),
      _fetchTrend('consumption-trend', from, to, cityId),
      _fetchBreakdown('fault-report-status', from, to, cityId),
      _fetchTrend('user-growth-trend', from, to, cityId),
      _fetchBreakdown('water-meter-request-status', from, to, cityId),
    ]);

    return DashboardStats(
      revenueTrend: results[0] as List<DashboardTrendPoint>,
      invoiceStatus: results[1] as List<DashboardStatusBreakdown>,
      consumptionTrend: results[2] as List<DashboardTrendPoint>,
      faultReportStatus: results[3] as List<DashboardStatusBreakdown>,
      userGrowthTrend: results[4] as List<DashboardTrendPoint>,
      waterMeterRequestStatus: results[5] as List<DashboardStatusBreakdown>,
    );
  }

  Future<List<DashboardTrendPoint>> _fetchTrend(
    String action,
    DateTime? from,
    DateTime? to,
    int? cityId,
  ) async {
    final items = await _fetchList(action, from, to, cityId);
    return items.map(DashboardTrendPoint.fromJson).toList();
  }

  Future<List<DashboardStatusBreakdown>> _fetchBreakdown(
    String action,
    DateTime? from,
    DateTime? to,
    int? cityId,
  ) async {
    final items = await _fetchList(action, from, to, cityId);
    return items.map(DashboardStatusBreakdown.fromJson).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchList(
    String action,
    DateTime? from,
    DateTime? to,
    int? cityId,
  ) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/Dashboard/$action').replace(
      queryParameters: {
        if (from != null) 'from': _dateParam(from),
        if (to != null) 'to': _dateParam(to),
        if (cityId != null) 'cityId': '$cityId',
      },
    );

    final response = await _send(
      () => _client.get(uri, headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw AdminDashboardException(
        _messageFor(response, 'Statistiku nije moguće učitati'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const AdminDashboardException('Statistika je u neispravnom formatu.');
    }

    return decoded.whereType<Map<String, dynamic>>().toList();
  }

  String _dateParam(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-${two(date.day)}';
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw const AdminDashboardException('Niste prijavljeni.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw AdminDashboardException(
        'Server nije dostupan na ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw const AdminDashboardException('Server nije odgovorio na vrijeme.');
    } on http.ClientException catch (e) {
      throw AdminDashboardException('Greška mreže: ${e.message}');
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
