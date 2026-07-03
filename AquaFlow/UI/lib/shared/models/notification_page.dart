import 'user_notification_item.dart';

class NotificationPage {
  const NotificationPage({required this.items, required this.totalCount});

  final List<UserNotificationItem> items;
  final int totalCount;
}
