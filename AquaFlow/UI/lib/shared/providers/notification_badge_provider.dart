import 'package:flutter/foundation.dart';

import '../services/notification_exception.dart';
import '../services/notification_service.dart';

/// Backs the unread-count badge on the mobile shells' "Obavijesti" tab
/// (`CustomerShell`/`CollectorShell`). The count is fetched from the backend
/// (`NotificationService.fetchUnreadCount`, `GET /UserNotifications/mine` with
/// `IsRead=false`) when a shell mounts and whenever the tab is reselected, but
/// resets to 0 locally as soon as `NotificationsScreen` finishes loading its
/// list - there is no per-item "mark as read" call from the client yet, so
/// this is a "new since last visit" badge rather than a persisted read count.
class NotificationBadgeProvider extends ChangeNotifier {
  NotificationBadgeProvider({NotificationService? service})
    : _service = service ?? NotificationService();

  final NotificationService _service;
  int _unreadCount = 0;

  int get unreadCount => _unreadCount;

  Future<void> refresh() async {
    try {
      final count = await _service.fetchUnreadCount();
      _unreadCount = count;
      notifyListeners();
    } on NotificationException {
      // Best-effort: keep showing the last known count on a transient error
      // rather than the badge disappearing.
    }
  }

  /// Bumps the badge for a push notification received while the app is in the
  /// foreground, without a full refetch.
  void increment() {
    _unreadCount++;
    notifyListeners();
  }

  /// Called once `NotificationsScreen` has loaded its list, i.e. the user has
  /// just seen their inbox.
  void markSeen() {
    if (_unreadCount == 0) return;
    _unreadCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
