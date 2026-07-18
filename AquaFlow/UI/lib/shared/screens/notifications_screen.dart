import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/notification_page.dart';
import '../models/user_notification_item.dart';
import '../navigation/app_navigation.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_badge_provider.dart';
import '../services/notification_exception.dart';
import '../services/notification_service.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/error_retry.dart';
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
        _error = 'Niste prijavljeni.';
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
    final totalPages = _totalPages(pageData?.totalCount ?? 0);

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
          if (pageData != null && _error == null)
            _PaginationBar(
              page: _page,
              totalPages: totalPages,
              totalCount: pageData.totalCount,
              pageSize: _pageSize,
              loading: _loading,
              onPageChanged: _goToPage,
              onPageSizeChanged: _setPageSize,
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Obavijesti',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: 'Osvježi',
              onPressed: _loading ? null : () => _load(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _typeFilter ?? '',
          decoration: const InputDecoration(
            labelText: 'Tip obavijesti',
            prefixIcon: Icon(Icons.filter_alt_outlined),
          ),
          items: [
            const DropdownMenuItem(value: '', child: Text('Svi tipovi')),
            for (final option in _notificationTypeOptions)
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
              message: 'Nema obavijesti.',
              hasFilters: _typeFilter != null,
              filteredIcon: Icons.filter_alt_off_outlined,
              filteredMessage: 'Nema obavijesti za odabrani tip.',
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
    final notification = item.notification;
    final type = notification?.type ?? '';
    final accent = _typeColor(type, theme.colorScheme);
    final createdAt = notification?.createdAt ?? item.createdAt;
    final title = notification?.title.trim();
    final body = notification?.body.trim();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_typeIcon(type), color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title == null || title.isEmpty
                              ? 'Obavijest #${item.notificationId}'
                              : title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!item.isRead) ...[
                    const SizedBox(width: 8),
                    _StatusBadge(color: accent),
                  ],
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (body != null && body.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(body, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaChip(
                    icon: Icons.category_outlined,
                    label: _typeLabel(type),
                  ),
                  if (notification?.validUntil != null)
                    _MetaChip(
                      icon: Icons.event_available_outlined,
                      label: 'Važi do ${_formatDate(notification!.validUntil)}',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Novo',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.pageSize,
    required this.loading,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  final int page;
  final int totalPages;
  final int totalCount;
  final int pageSize;
  final bool loading;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int?> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canGoBack = page > 1 && !loading;
    final canGoForward = page < totalPages && !loading;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.35)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Prethodna stranica',
              onPressed: canGoBack ? () => onPageChanged(page - 1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Stranica $page od $totalPages',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge,
                  ),
                  Text(
                    '$totalCount ukupno',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Sljedeća stranica',
              onPressed: canGoForward ? () => onPageChanged(page + 1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: pageSize,
                onChanged: loading ? null : onPageSizeChanged,
                items: const [
                  DropdownMenuItem(value: 5, child: Text('5')),
                  DropdownMenuItem(value: 10, child: Text('10')),
                  DropdownMenuItem(value: 20, child: Text('20')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectOption {
  const _SelectOption({required this.value, required this.label});

  final String value;
  final String label;
}

const List<_SelectOption> _notificationTypeOptions = [
  _SelectOption(value: 'Info', label: 'Info'),
  _SelectOption(value: 'PlannedWorks', label: 'Planirani radovi'),
  _SelectOption(value: 'Billing', label: 'Računi'),
  _SelectOption(value: 'Warning', label: 'Upozorenje'),
  _SelectOption(value: 'Outage', label: 'Prekid usluge'),
];

