import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/notification_image.dart';
import '../models/user_notification_item.dart';
import '../navigation/app_navigation.dart';
import '../providers/notification_badge_provider.dart';
import '../services/notification_exception.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/authenticated_image.dart';

/// Icon + accent color + human label for a notification `type`. The three
/// backend type strings (`Info`/`PlannedWorks`/`Warning`) map here; anything
/// unknown falls back to [_infoMeta].
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

  bool _imagesLoading = true;
  List<NotificationImage> _images = const [];

  /// Tracks the in-flight [_markAsRead] call (if any) so [dispose] can wait
  /// for it before closing [_service] - `http.Client.close()` force-closes
  /// active connections, and closing it while the PATCH is still in flight
  /// (e.g. the user backs out of this screen quickly) silently aborts the
  /// read receipt, which is why "mark as read" could appear to do nothing.
  Future<void>? _markAsReadFuture;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    if (!_item.isRead) {
      _markAsReadFuture = _markAsRead();
    }
    unawaited(_loadImages());
  }

  // Runs alongside (not blocking) the mark-as-read flow above - most notifications carry
  // no images, so this fails silently into an empty gallery rather than surfacing an error
  // for what's a secondary, often-empty section of the screen.
  Future<void> _loadImages() async {
    try {
      final images = await _service.fetchImages(_item.notificationId);
      if (!mounted) return;
      setState(() {
        _images = images;
        _imagesLoading = false;
      });
    } on NotificationException {
      if (!mounted) return;
      setState(() => _imagesLoading = false);
    }
  }

  Future<void> _markAsRead() async {
    // Captured up front so they still fire even if this screen is popped
    // (and thus unmounted) before the PATCH resolves - only the local
    // setState below actually needs `mounted`.
    final onMarkedRead = widget.onMarkedRead;
    final badgeProvider = context.read<NotificationBadgeProvider>();

    try {
      await _service.markAsRead(_item.id);
    } on NotificationException {
      // Best-effort, same as NotificationBadgeProvider.refresh(): keep
      // showing the notification even if the read receipt fails to save.
      return;
    }

    final updated = _item.copyWith(readAt: DateTime.now().toUtc());
    if (mounted) setState(() => _item = updated);
    badgeProvider.decrement();
    onMarkedRead?.call(updated);
  }

  @override
  void dispose() {
    final pending = _markAsReadFuture;
    if (pending != null) {
      unawaited(pending.whenComplete(_service.dispose));
    } else {
      _service.dispose();
    }
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
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
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: accent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _StatusPill(isRead: _item.isRead, color: accent),
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
                    if (!_imagesLoading && _images.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildImagesSection(accent),
                    ],
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
            ],
          ),
        ),
      ),
    );
  }

  // Renders nothing while loading or when there are no images - most notifications carry
  // none, so this stays a lazy-loaded, easy-to-miss-if-absent section rather than a
  // placeholder, same approach as CustomerFaultReportDetailScreen's photo gallery.
  Widget _buildImagesSection(Color accent) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading('Slike (${_images.length})', color: accent),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              // Fixed square tiles so every thumbnail renders at the same
              // size regardless of the source image's own aspect ratio.
              childAspectRatio: 1,
            ),
            itemCount: _images.length,
            itemBuilder: (context, index) {
              final image = _images[index];
              return _ImageThumbnail(
                onTap: () => _openFullscreenImage(image),
                fetcher: () =>
                    _service.fetchImageBytes(_item.notificationId, image.id),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openFullscreenImage(NotificationImage image) {
    final initialIndex = _images.indexOf(image);
    context.pushScreen(
      _FullscreenImageScreen(
        images: _images,
        initialIndex: initialIndex < 0 ? 0 : initialIndex,
        fetcherFor: (image) =>
            _service.fetchImageBytes(_item.notificationId, image.id),
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
          Icons.build_outlined,
          AppColors.success,
        );
      case 'warning':
        return const _TypeMeta(
          'Upozorenje',
          Icons.warning_amber_rounded,
          AppColors.warning,
        );
      case 'info':
      default:
        return _infoMeta;
    }
  }

  /// On the dark theme an accent dark enough to blend into the background
  /// reads as illegible text, so lift it toward white. Light theme and the
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

/// One square gallery tile - fixed 1:1 aspect ratio (enforced by the grid's
/// `childAspectRatio`) so every thumbnail is the same size no matter the
/// source image's own dimensions, with a bordered/shadowed frame matching
/// [_Card] and a small zoom affordance hinting it opens fullscreen.
class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({required this.onTap, required this.fetcher});

  final VoidCallback onTap;
  final Future<Uint8List> Function() fetcher;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Material(
      color: isLight ? Colors.white : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      elevation: isLight ? 1.5 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(
              color: isLight
                  ? const Color(0xFFE1EDF7)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AuthenticatedImage(fetcher: fetcher, fit: BoxFit.cover),
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.zoom_in,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullscreenImageScreen extends StatefulWidget {
  const _FullscreenImageScreen({
    required this.images,
    required this.initialIndex,
    required this.fetcherFor,
  });

  final List<NotificationImage> images;
  final int initialIndex;
  final Future<Uint8List> Function(NotificationImage image) fetcherFor;

  @override
  State<_FullscreenImageScreen> createState() => _FullscreenImageScreenState();
}

class _FullscreenImageScreenState extends State<_FullscreenImageScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final current = images[_index];
    final hasMultiple = images.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          hasMultiple
              ? '${current.fileName} (${_index + 1}/${images.length})'
              : current.fileName,
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: images.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) {
              final image = images[index];
              return InteractiveViewer(
                child: AuthenticatedImage(
                  fetcher: () => widget.fetcherFor(image),
                  fit: BoxFit.contain,
                ),
              );
            },
          ),
          if (hasMultiple) ...[
            Positioned(
              left: 4,
              child: _NavArrow(
                icon: Icons.chevron_left,
                onTap: _index > 0 ? () => _goTo(_index - 1) : null,
              ),
            ),
            Positioned(
              right: 4,
              child: _NavArrow(
                icon: Icons.chevron_right,
                onTap: _index < images.length - 1
                    ? () => _goTo(_index + 1)
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon),
        color: enabled ? Colors.white : Colors.white38,
        onPressed: onTap,
      ),
    );
  }
}
