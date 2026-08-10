import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/activity_log_item.dart';
import '../models/activity_log_page.dart';
import '../providers/auth_provider.dart';
import '../services/activity_log_exception.dart';
import '../services/activity_log_service.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/error_retry.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  final ActivityLogService _service = ActivityLogService();

  ActivityLogPage? _pageData;
  bool _loading = true;
  String? _error;
  int _page = 1;
  final int _pageSize = 10;
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
      final pageData = await _service.fetchMine(page: _page, pageSize: _pageSize);
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = pageData;
        _loading = false;
      });
    } on ActivityLogException catch (e) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = null;
        _loading = false;
        _error = e.message;
      });
    }
  }

  void _goToPage(int page) {
    if (page == _page || _loading) return;
    setState(() => _page = page);
    _load();
  }

  int _totalPages(int totalCount) {
    if (totalCount <= 0) return 1;
    return ((totalCount + _pageSize - 1) / _pageSize).floor();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje aktivnosti'),
        actions: [
          IconButton(
            tooltip: 'Osvježi',
            onPressed: _loading ? null : () => _load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_loading && pageData != null)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _buildContent()),
            if (pageData != null && _error == null)
              _PaginationBar(
                page: _page,
                totalPages: totalPages,
                totalCount: pageData.totalCount,
                loading: _loading,
                onPageChanged: _goToPage,
              ),
          ],
        ),
      ),
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

    final items = _pageData?.items ?? const <ActivityLogItem>[];
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
            const EmptyStateView(
              icon: Icons.history_toggle_off,
              message: 'Nema zabilježenih aktivnosti.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _ActivityCard(item: items[index]),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item});

  final ActivityLogItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _typeColor(item.eventType, theme.colorScheme);
    final description = item.description?.trim();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_typeIcon(item.eventType), color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _typeLabel(item.eventType),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(item.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(description, style: theme.textTheme.bodyMedium),
                  ],
                  if (item.ipAddress != null && item.ipAddress!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.ipAddress!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Same event types as AquaFlow.Model.ActivityEventTypes / the admin activity
  // logs screen - keep both mappings in sync if a type is added.
  // UserRoleChanged/UserActivated/UserDeactivated/UserDeleted are admin actions
  // performed on this user's account (UsersController), logged under this
  // user's own id, so they do appear here even though this user didn't act.
  static IconData _typeIcon(String type) {
    switch (type) {
      case 'LoginSuccess':
        return Icons.login;
      case 'LoginFailed':
        return Icons.block_outlined;
      case 'TokenRefreshed':
        return Icons.autorenew;
      case 'Registered':
        return Icons.person_add_alt_outlined;
      case 'PasswordChanged':
        return Icons.lock_reset;
      case 'AccountUpdated':
        return Icons.manage_accounts_outlined;
      case 'UserRoleChanged':
        return Icons.admin_panel_settings_outlined;
      case 'UserActivated':
        return Icons.check_circle_outline;
      case 'UserDeactivated':
        return Icons.remove_circle_outline;
      case 'UserDeleted':
        return Icons.person_remove_outlined;
      default:
        return Icons.history;
    }
  }

  static Color _typeColor(String type, ColorScheme colorScheme) {
    switch (type) {
      case 'LoginSuccess':
        return const Color(0xFF2E7D32);
      case 'LoginFailed':
        return colorScheme.error;
      case 'TokenRefreshed':
        return const Color(0xFF0277BD);
      case 'Registered':
        return const Color(0xFF0277BD);
      case 'PasswordChanged':
        return const Color(0xFFF9A825);
      case 'AccountUpdated':
        return const Color(0xFF00838F);
      case 'UserRoleChanged':
        return const Color(0xFF6A1B9A);
      case 'UserActivated':
        return const Color(0xFF2E7D32);
      case 'UserDeactivated':
        return const Color(0xFFEF6C00);
      case 'UserDeleted':
        return const Color(0xFFC62828);
      default:
        return colorScheme.primary;
    }
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'LoginSuccess':
        return 'Uspješna prijava';
      case 'LoginFailed':
        return 'Neuspješna prijava';
      case 'TokenRefreshed':
        return 'Obnova sesije';
      case 'Registered':
        return 'Registracija';
      case 'PasswordChanged':
        return 'Promjena lozinke';
      case 'AccountUpdated':
        return 'Izmjena naloga';
      case 'UserRoleChanged':
        return 'Promjena role';
      case 'UserActivated':
        return 'Korisnik aktiviran';
      case 'UserDeactivated':
        return 'Korisnik deaktiviran';
      case 'UserDeleted':
        return 'Korisnik obrisan';
      default:
        return type.isEmpty ? 'Aktivnost' : type;
    }
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '-';
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year}. '
        '${two(date.hour)}:${two(date.minute)}';
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.loading,
    required this.onPageChanged,
  });

  final int page;
  final int totalPages;
  final int totalCount;
  final bool loading;
  final ValueChanged<int> onPageChanged;

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
          ],
        ),
      ),
    );
  }
}

