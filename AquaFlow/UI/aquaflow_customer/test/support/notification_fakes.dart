// Test doubles shared by the notification tests: an in-memory
// NotificationService, a signed-in AuthProvider, and the app wrapper the
// shared notification screens need (providers + localizations).

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_customer/l10n/app_localizations.dart';
import 'package:aquaflow_customer/shared/models/app_notification.dart';
import 'package:aquaflow_customer/shared/models/auth_session.dart';
import 'package:aquaflow_customer/shared/models/notification_image.dart';
import 'package:aquaflow_customer/shared/models/notification_page.dart';
import 'package:aquaflow_customer/shared/models/unread_notification_summary.dart';
import 'package:aquaflow_customer/shared/models/user_notification_item.dart';
import 'package:aquaflow_customer/shared/providers/auth_provider.dart';
import 'package:aquaflow_customer/shared/providers/notification_badge_provider.dart';
import 'package:aquaflow_customer/shared/services/notification_service.dart';

final DateTime baseTime = DateTime(2026, 10, 19, 12);

UserNotificationItem inboxItem(
  int id, {
  DateTime? createdAt,
  bool read = false,
  String? title,
  String? relatedEntityType,
  int? relatedEntityId,
}) {
  final created = createdAt ?? baseTime.add(Duration(minutes: id));
  return UserNotificationItem(
    id: id,
    userId: 1,
    notificationId: id,
    notification: AppNotification(
      id: id,
      title: title ?? 'Notification $id',
      body: 'Body $id',
      type: 'Info',
      audience: 'Direct',
      createdById: 1,
      createdAt: created,
      updatedAt: null,
      isSystem: relatedEntityType != null,
      relatedEntityType: relatedEntityType,
      relatedEntityId: relatedEntityId,
    ),
    readAt: read ? created : null,
    createdAt: created,
    updatedAt: null,
  );
}

UnreadNotificationSummary unreadSummary(
  int count,
  UserNotificationItem? latest,
) => UnreadNotificationSummary(unreadCount: count, latest: latest);

/// In-memory [NotificationService]; never touches the network (the
/// underlying client fails every request, so an un-faked call shows up).
class FakeNotificationService extends NotificationService {
  FakeNotificationService()
    : super(client: MockClient((_) async => http.Response('', 500)));

  // --- fetchUnreadSummary ---
  UnreadNotificationSummary summary = unreadSummary(0, null);
  int summaryCalls = 0;
  int maxConcurrentSummaries = 0;
  int _activeSummaries = 0;

  /// While set, every summary request waits for it to complete.
  Completer<void>? summaryGate;

  @override
  Future<UnreadNotificationSummary> fetchUnreadSummary() async {
    summaryCalls++;
    _activeSummaries++;
    maxConcurrentSummaries = math.max(maxConcurrentSummaries, _activeSummaries);
    try {
      final gate = summaryGate;
      if (gate != null) await gate.future;
      return summary;
    } finally {
      _activeSummaries--;
    }
  }

  // --- fetchMine ---
  /// Returns the page for a 1-based page number.
  NotificationPage Function(int page) pages = (_) =>
      const NotificationPage(items: [], totalCount: 0);
  final List<int> fetchMinePages = [];

  /// While set, every page request waits for it to complete.
  Completer<void>? fetchMineGate;

  @override
  Future<NotificationPage> fetchMine({
    required int page,
    required int pageSize,
    String? type,
  }) async {
    fetchMinePages.add(page);
    final gate = fetchMineGate;
    if (gate != null) await gate.future;
    return pages(page);
  }

  @override
  Future<List<NotificationImage>> fetchImages(int notificationId) async =>
      const [];
}

/// An [AuthProvider] that is already signed in, without tokens or network.
class SignedInAuthProvider extends AuthProvider {
  @override
  AuthSession? get session => AuthSession(
    id: 1,
    email: 'user@example.com',
    userRole: 'Customer',
    isActive: true,
    permissions: const [],
    expiresAt: DateTime(2100),
  );
}

/// [child] inside the providers and localizations the shared notification
/// screens read (English pinned, so finders can match English strings).
Widget notificationTestApp({
  required Widget child,
  required NotificationBadgeProvider badge,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => SignedInAuthProvider(),
      ),
      ChangeNotifierProvider.value(value: badge),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    ),
  );
}
