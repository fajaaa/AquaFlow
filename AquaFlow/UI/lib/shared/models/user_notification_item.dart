import 'app_notification.dart';

class UserNotificationItem {
  const UserNotificationItem({
    required this.id,
    required this.userId,
    required this.notificationId,
    required this.notification,
    required this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int userId;
  final int notificationId;
  final AppNotification? notification;
  final DateTime? readAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isRead => readAt != null;

  factory UserNotificationItem.fromJson(Map<String, dynamic> json) {
    final notificationJson = json['notification'];

    return UserNotificationItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      notificationId: (json['notificationId'] as num?)?.toInt() ?? 0,
      notification: notificationJson is Map<String, dynamic>
          ? AppNotification.fromJson(notificationJson)
          : null,
      readAt: _date(json['readAt']),
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
