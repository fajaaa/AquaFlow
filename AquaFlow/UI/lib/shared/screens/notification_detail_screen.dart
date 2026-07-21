import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_notification_item.dart';
import '../providers/notification_badge_provider.dart';
import '../services/notification_exception.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

/// Icon + accent color + human label for a notification `type`. The five
/// backend type strings (`Info`/`PlannedWorks`/`Billing`/`Warning`/`Outage`)
/// map here; anything unknown falls back to [_infoMeta].
class _TypeMeta {
  const _TypeMeta(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

const _TypeMeta _infoMeta = _TypeMeta(
  'Info',
  Icons.info_outline,
  AppColors.secondary,
);

class NotificationDetailScreen extends StatefulWidget {
  const NotificationDetailScreen({
    super.key,
    required this.item,
    this.onMarkedRead,
  });

  final UserNotificationItem item;

  /// Called once [item] has been persisted as read on the backend, with the
  /// updated copy (new `readAt`) - lets a caller (e.g. `NotificationsScreen`)
  /// patch its own in-memory list without a full refetch.
  final ValueChanged<UserNotificationItem>? onMarkedRead;

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  final NotificationService _service = NotificationService();
  late UserNotificationItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    if (!_item.isRead) {
      _markAsRead();
    }
  }

  Future<void> _markAsRead() async {
    try {
      await _service.markAsRead(_item.id);
    } on NotificationException {
      // Best-effort, same as NotificationBadgeProvider.refresh(): keep
      // showing the notification even if the read receipt fails to save.
      return;
    }

    if (!mounted) return;
    final updated = _item.copyWith(readAt: DateTime.now().toUtc());
    setState(() => _item = updated);
    context.read<NotificationBadgeProvider>().decrement();
    widget.onMarkedRead?.call(updated);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final notification = _item.notification;
    final type = notification?.type ?? '';
    final meta = _metaFor(type);
    final accent = _readableAccent(meta.color, theme.brightness);
    final onAccent =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? Colors.white
        : AppColors.textDark;

    final title = _title(_item);
    final body = notification?.body.trim() ?? '';
    final createdAt = notification?.createdAt ?? _item.createdAt;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalji obavijesti')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type banner - full-width strip across the top.
              Container(
                width: double.infinity,
                color: accent.withValues(alpha: 0.10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(meta.icon, color: onAccent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TIP OBAVIJESTI',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meta.label,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Center(
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.9,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header card - title, published date, read status.
                        _Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: accent,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _StatusPill(
                                    isRead: _item.isRead,
                                    color: accent,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Body card - the notification text.
                        _Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeading('Opis', color: accent),
                              const SizedBox(height: 10),
                              Text(
                                body.isEmpty ? 'Nema dodatnog sadržaja.' : body,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  height: 1.55,
                                  color: body.isEmpty
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSurface.withValues(
                                          alpha: 0.85,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Details card - type, dates, status.
                        _Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeading('Detalji', color: accent),
                              const SizedBox(height: 14),
                              _DetailRow(
                                icon: meta.icon,
                                iconColor: accent,
                                label: 'Tip obavijesti',
                                value: meta.label,
                              ),
                              const SizedBox(height: 14),
                              _DetailRow(
                                icon: Icons.calendar_today_outlined,
                                iconColor: accent,
                                label: 'Datum kreiranja',
                                value: _formatDate(createdAt),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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

  static _TypeMeta _metaFor(String type) {
    switch (type.toLowerCase()) {
      case 'plannedworks':
        return const _TypeMeta(
          'Planirani radovi',
          Icons.construction_outlined,
          AppColors.success,
        );
      case 'billing':
        return const _TypeMeta(
          'Računi',
          Icons.receipt_long_outlined,
          AppColors.primary,
        );
      case 'warning':
        return const _TypeMeta(
          'Upozorenje',
          Icons.warning_amber_outlined,
          AppColors.warning,
        );
      case 'outage':
        return const _TypeMeta(
          'Prekid usluge',
          Icons.block_outlined,
          AppColors.textDark,
        );
      case 'info':
      default:
        return _infoMeta;
    }
  }

  /// The brand palette has two very dark accents (navy for `Billing`, dark
  /// gray for `Outage`). On the dark theme those blend into the background and
  /// read as illegible text, so lift them toward white. Light theme and the
  /// already-bright accents (blue/green/orange) are returned unchanged.
  static Color _readableAccent(Color base, Brightness brightness) {
    if (brightness == Brightness.dark && base.computeLuminance() < 0.2) {
      return Color.lerp(base, Colors.white, 0.6)!;
    }
    return base;
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '-';
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year}. '
        '${two(date.hour)}:${two(date.minute)}';
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.white
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE1EDF7)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text, {this.color});

  final String text;

  /// Section headings are tinted with the notification's type color; falls
  /// back to the muted variant when no color is provided.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: color ?? theme.colorScheme.onSurfaceVariant,
      ),
    );
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
