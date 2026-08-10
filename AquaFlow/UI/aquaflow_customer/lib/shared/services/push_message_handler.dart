import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../screens/notification_detail_screen.dart';
import 'notification_exception.dart';
import 'notification_service.dart';

/// Wires Firebase Cloud Messaging's three delivery states to in-app UI:
///
///   * Foreground (`onMessage`) - Android/iOS never show a system banner while
///     the app is open, so this shows an in-app SnackBar with the
///     notification's title instead.
///   * Background tap (`onMessageOpenedApp`) - the OS already showed the
///     system notification; tapping it resumes the app and delivers the same
///     message here.
///   * Terminated/cold start (`getInitialMessage`) - the app was launched by
///     tapping a notification; there is no in-memory state yet.
///
/// Both tap paths read `notificationId` from the push's data payload (set by
/// `NotificationService.SendPushNotificationAsync` on the backend) and open
/// [NotificationDetailScreen], fetching the row from the backend since a cold
/// start has nothing cached.
///
/// Lives in its own file rather than `main.dart` so the app entry point stays
/// small; kept in `shared/services` alongside the notification services it
/// depends on.
class PushMessageHandler {
  PushMessageHandler({
    required this._navigatorKey,
    required this._scaffoldMessengerKey,
    this.onForegroundMessage,
    NotificationService? notificationService,
  }) : _notificationService = notificationService ?? NotificationService();

  final GlobalKey<NavigatorState> _navigatorKey;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;
  final NotificationService _notificationService;

  /// Called for every foreground push (`onMessage`) so callers can bump an
  /// unread-count badge without a full refetch. Not called for the two tap
  /// paths (`onMessageOpenedApp`/cold start) - those resume an already-open
  /// notification rather than deliver a new unread one.
  final VoidCallback? onForegroundMessage;

  /// Call once at mobile app startup, AFTER `runApp` so [_navigatorKey] is
  /// already attached to a live [NavigatorState] (needed because a cold start
  /// can resolve [FirebaseMessaging.getInitialMessage] immediately).
  Future<void> init() async {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_openFromMessage);

    final initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      await _openFromMessage(initialMessage);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    onForegroundMessage?.call();

    final title = message.notification?.title;
    if (title == null || title.isEmpty) return;

    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(title),
        action: SnackBarAction(
          label: 'Otvori',
          onPressed: () => _openFromMessage(message),
        ),
      ),
    );
  }

  Future<void> _openFromMessage(RemoteMessage message) async {
    final notificationId = int.tryParse(message.data['notificationId'] ?? '');
    if (notificationId == null) return;

    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    try {
      final item = await _notificationService.fetchByNotificationId(
        notificationId,
      );
      if (item == null) return;
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => NotificationDetailScreen(item: item),
        ),
      );
    } on NotificationException {
      // Best-effort deep link: if the fetch fails (offline, signed out, the
      // row no longer exists...) just drop it instead of showing a broken
      // screen.
    }
  }
}
