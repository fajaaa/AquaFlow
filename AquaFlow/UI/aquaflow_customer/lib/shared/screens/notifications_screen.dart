import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_customer/l10n/app_localizations.dart';

import '../models/notification_page.dart';
import '../models/user_notification_item.dart';
import '../navigation/app_navigation.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_badge_provider.dart';
import '../services/notification_exception.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/error_retry.dart';
import '../widgets/paged_table_pagination_bar.dart';
import '../widgets/refresh_button.dart';
import 'notification_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _service = NotificationService();

  NotificationPage? _pageData;
  bool _loading = true;
  bool _markingAll = false;
  String? _error;
  String? _typeFilter;
  int _page = 1;
  int _pageSize = 10;
  int _requestSerial = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool resetPage = false}) async {
    final session = context.read<AuthProvider>().session;
    if (session == null) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context).notLoggedInError;
      });
      return;
    }

    final requestId = ++_requestSerial;
    setState(() {
      if (resetPage) _page = 1;
      _loading = true;
      _error = null;
    });

    try {
      final pageData = await _service.fetchMine(
        page: _page,
        pageSize: _pageSize,
        type: _typeFilter,
      );
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = pageData;
        _loading = false;
      });
      context.read<NotificationBadgeProvider>().markSeen();
    } on NotificationException catch (e) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = null;
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() => _markingAll = true);
    try {
      await _service.markAllAsRead();
      if (!mounted) return;
      context.read<NotificationBadgeProvider>().markSeen();
      await _load(resetPage: true);
    } on NotificationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  void _setTypeFilter(String value) {
    final selected = value.trim().isEmpty ? null : value;
    if (selected == _typeFilter || _loading) return;
    setState(() => _typeFilter = selected);
    _load(resetPage: true);
  }

  void _setPageSize(int? value) {
    if (value == null || value == _pageSize || _loading) return;
    setState(() {
      _pageSize = value;
      _page = 1;
    });
    _load();
  }

  void _goToPage(int page) {
    if (page == _page || _loading) return;
    setState(() => _page = page);
    _load();
  }

  void _openDetails(UserNotificationItem item) {
    context.pushScreen(
      NotificationDetailScreen(item: item, onMarkedRead: _applyMarkedRead),
    );
  }

  /// Patches the just-opened item in the already-loaded page in place, so the
  /// "Novo" badge on its list card clears without a full reload.
  void _applyMarkedRead(UserNotificationItem updated) {
    final pageData = _pageData;
    if (!mounted || pageData == null) return;
    setState(() {
      _pageData = NotificationPage(
        items: [
          for (final existing in pageData.items)
            if (existing.id == updated.id) updated else existing,
        ],
        totalCount: pageData.totalCount,
      );
    });
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageData = _pageData;

    // Docked below the list rather than as its last scrollable item, so it
    // stays visible at the bottom of the tab regardless of scroll position
    // or how many notifications there are.
    final pagination = pageData != null && _error == null
        ? PagedTablePaginationBar(
            page: _page,
            totalPages: _totalPages(pageData.totalCount),
            totalCount: pageData.totalCount,
            pageSize: _pageSize,
            loading: _loading,
            onPageChanged: _goToPage,
            onPageSizeChanged: _setPageSize,
          )
        : null;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _buildFilters(),
          ),
          if (_loading && pageData != null)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildContent()),
          ?pagination,
        ],
      ),
    );
  }

  Widget _buildFilters() {
    // Badge provider's count reflects the tab icon (zeroed by `markSeen` the
    // moment this screen's list loads), so it can't drive this button -
    // whether individual rows are still unread is read straight from the
    // loaded page instead.
    final hasUnread = (_pageData?.items ?? const <UserNotificationItem>[]).any(
      (item) => !item.isRead,
    );
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                loc.tabNotifications,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (hasUnread)
              IconButton(
                tooltip: loc.notificationsMarkAllReadTooltip,
                onPressed: (_loading || _markingAll) ? null : _markAllAsRead,
                icon: _markingAll
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.done_all),
              ),
            if (hasUnread) const SizedBox(width: 8),
            RefreshButton(
              enabled: !_loading,
              onRefresh: () => _load(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _typeFilter ?? '',
          decoration: InputDecoration(
            labelText: loc.notificationTypeFieldLabel,
            prefixIcon: const Icon(Icons.filter_alt_outlined),
          ),
          items: [
            DropdownMenuItem(value: '', child: Text(loc.notificationsAllTypesOption)),
            for (final option in _notificationTypeOptions(loc))
              DropdownMenuItem(value: option.value, child: Text(option.label)),
          ],
          onChanged: _loading ? null : (value) => _setTypeFilter(value ?? ''),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading && _pageData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _error;
    if (error != null) {
      return ErrorRetry(message: error, onRetry: () => _load());
    }

    final items = _pageData?.items ?? const <UserNotificationItem>[];
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
            EmptyStateView(
              icon: Icons.notifications_none,
              message: AppLocalizations.of(context).notificationsEmptyMessage,
              hasFilters: _typeFilter != null,
              filteredIcon: Icons.filter_alt_off_outlined,
              filteredMessage:
                  AppLocalizations.of(context).notificationsEmptyFilteredMessage,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return _NotificationCard(item: item, onTap: () => _openDetails(item));
        },
      ),
    );
  }

  int _totalPages(int totalCount) {
    if (totalCount <= 0) return 1;
    return ((totalCount + _pageSize - 1) / _pageSize).floor();
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final UserNotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final loc = AppLocalizations.of(context);

    final notification = item.notification;
    final type = notification?.type ?? '';
    // Raw brand color drives the branded side bar (always a white glyph on a
    // colored gradient); the readable variant is used for the tinted accents
    // (pill, unread dot/border) so the two dark accents stay legible on dark.
    final baseColor = _typeColor(type);
    final accent = _readableAccent(baseColor, theme.brightness);
    final unread = !item.isRead;

    final createdAt = notification?.createdAt ?? item.createdAt;
    final rawTitle = notification?.title.trim();
    final title = rawTitle == null || rawTitle.isEmpty
        ? loc.notificationFallbackTitle(item.notificationId)
        : rawTitle;
    final body = _truncate(notification?.body.trim() ?? '', 50);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isLight ? Colors.white : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: unread
                  ? accent.withValues(alpha: 0.35)
                  : (isLight
                        ? const Color(0x121F2937)
                        : colorScheme.outlineVariant.withValues(alpha: 0.5)),
              width: unread ? 1.5 : 1,
            ),
            boxShadow: isLight
                ? const [
                    BoxShadow(
                      color: Color(0x14062845),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          // A ListView gives each row unbounded height, so a bare stretched
          // Row would force an infinite-height constraint on its children and
          // crash. IntrinsicHeight bounds the row to its tallest child, letting
          // the color bar stretch to the card's height.
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Colored type bar - branded gradient with a white glyph.
                Container(
                  width: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _shade(baseColor, 0.16),
                        _shade(baseColor, -0.20),
                      ],
                    ),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(18),
                    ),
                  ),
                  child: Center(
                    child: Icon(_typeIcon(type), color: Colors.white, size: 20),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: unread
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (unread) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: accent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ],
                        ),
                        if (body.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 9),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _typeLabel(type, loc),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                            Text(
                              _formatDate(createdAt),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Keep these icons in sync with `_metaFor` in notification_detail_screen.dart
  // so a notification looks the same in the list and on its detail screen.
  static IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'plannedworks':
        return Icons.build_outlined;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline;
    }
  }

  // Keep these accent colors in sync with `_metaFor` in
  // notification_detail_screen.dart (see also `_typeIcon` above).
  static Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'plannedworks':
        return AppColors.success;
      case 'warning':
        return AppColors.warning;
      default:
        return AppColors.secondary;
    }
  }

  /// Mirrors `_readableAccent` in notification_detail_screen.dart: any accent
  /// dark enough to blend into the dark theme's background is lifted toward
  /// white there. Light theme and the brighter accents are returned unchanged.
  static Color _readableAccent(Color base, Brightness brightness) {
    if (brightness == Brightness.dark && base.computeLuminance() < 0.2) {
      return Color.lerp(base, Colors.white, 0.6)!;
    }
    return base;
  }

  static String _typeLabel(String type, AppLocalizations loc) {
    switch (type.toLowerCase()) {
      case 'plannedworks':
        return loc.notificationTypePlannedWorksLabel;
      case 'warning':
        return loc.notificationTypeWarningLabel;
      default:
        return type.isEmpty ? loc.notificationTypeGenericLabel : type;
    }
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '-';
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year}. '
        '${two(date.hour)}:${two(date.minute)}';
  }

  static String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength).trimRight()}...';
  }

  /// Tints [c] toward white for a positive [percent] or toward black for a
  /// negative one - used to build the two-stop gradient on the type bar.
  static Color _shade(Color c, double percent) {
    if (percent >= 0) return Color.lerp(c, Colors.white, percent)!;
    return Color.lerp(c, Colors.black, -percent)!;
  }
}

class _SelectOption {
  const _SelectOption({required this.value, required this.label});

  final String value;
  final String label;
}

List<_SelectOption> _notificationTypeOptions(AppLocalizations loc) => [
  _SelectOption(value: 'Info', label: loc.notificationTypeInfoLabel),
  _SelectOption(value: 'PlannedWorks', label: loc.notificationTypePlannedWorksLabel),
  _SelectOption(value: 'Warning', label: loc.notificationTypeWarningLabel),
];
