import 'user_notification_item.dart';

/// Result of the cheap unread probe behind `NotificationBadgeProvider`'s
/// polling (`NotificationService.fetchUnreadSummary`): the total unread count
/// plus the newest unread inbox row, which is what tells a genuinely new
/// notification apart from an unchanged count (one read + one new arrival
/// leaves the count the same).
class UnreadNotificationSummary {
  const UnreadNotificationSummary({
    required this.unreadCount,
    required this.latest,
  });

  final int unreadCount;

  /// Newest unread row by `CreatedAt`, null when nothing is unread.
  final UserNotificationItem? latest;
}
