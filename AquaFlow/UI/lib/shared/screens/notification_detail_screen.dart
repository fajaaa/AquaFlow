import 'package:flutter/material.dart';

import '../models/user_notification_item.dart';

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key, required this.item});

  final UserNotificationItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notification = item.notification;
    final type = notification?.type ?? '';
    final accent = _typeColor(type, theme.colorScheme);
    final title = _title(item);
    final body = notification?.body.trim() ?? '';
    final createdAt = notification?.createdAt ?? item.createdAt;

    return Scaffold(
      appBar: AppBar(title: const Text('Obavijest')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.28),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(_typeIcon(type), color: accent),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatDate(createdAt),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusPill(isRead: item.isRead, color: accent),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        body.isEmpty ? 'Nema dodatnog sadržaja.' : body,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.45,
                          color: body.isEmpty
                              ? theme.colorScheme.onSurfaceVariant
                              : null,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Divider(color: theme.dividerColor.withValues(alpha: 0.4)),
                      const SizedBox(height: 6),
                      _InfoRow(
                        icon: Icons.category_outlined,
                        label: 'Tip',
                        value: _typeLabel(type),
                      ),
                      _InfoRow(
                        icon: Icons.event_outlined,
                        label: 'Objavljeno',
                        value: _formatDate(createdAt),
                      ),
                      if (notification?.validUntil != null)
                        _InfoRow(
                          icon: Icons.event_available_outlined,
                          label: 'Važi do',
                          value: _formatDate(notification!.validUntil),
                        ),
                      _InfoRow(
                        icon: item.isRead
                            ? Icons.mark_email_read_outlined
                            : Icons.mark_email_unread_outlined,
                        label: 'Status',
                        value: item.isRead
                            ? 'Pročitano ${_formatDate(item.readAt)}'
                            : 'Novo',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _title(UserNotificationItem item) {
    final notification = item.notification;
    final title = notification?.title.trim();
    if (title == null || title.isEmpty) {
      return 'Obavijest #${item.notificationId}';
    }
    return title;
  }

  static IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'plannedworks':
        return Icons.construction_outlined;
      case 'billing':
        return Icons.receipt_long_outlined;
      case 'warning':
      case 'outage':
        return Icons.warning_amber_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  static Color _typeColor(String type, ColorScheme colorScheme) {
    switch (type.toLowerCase()) {
      case 'plannedworks':
        return const Color(0xFF0277BD);
      case 'billing':
        return const Color(0xFF2E7D32);
      case 'warning':
      case 'outage':
        return const Color(0xFFF9A825);
      default:
        return colorScheme.primary;
    }
  }

  static String _typeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'plannedworks':
        return 'Planirani radovi';
      case 'billing':
        return 'Računi';
      case 'warning':
        return 'Upozorenje';
      case 'outage':
        return 'Prekid usluge';
      default:
        return type.isEmpty ? 'Obavijest' : type;
    }
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '-';
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year}. '
        '${two(date.hour)}:${two(date.minute)}';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isRead, required this.color});

  final bool isRead;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = isRead ? theme.colorScheme.onSurfaceVariant : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isRead ? 'Pročitano' : 'Novo',
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
