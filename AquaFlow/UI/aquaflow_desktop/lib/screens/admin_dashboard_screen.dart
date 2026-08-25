import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_desktop/l10n/app_localizations.dart';
import 'package:aquaflow_desktop/models/dashboard_stats.dart';
import 'package:aquaflow_desktop/models/dashboard_status_breakdown.dart';
import 'package:aquaflow_desktop/models/dashboard_trend_point.dart';
import 'package:aquaflow_desktop/screens/admin_account_edit_screen.dart';
import 'package:aquaflow_desktop/screens/admin_codebook_screen.dart';
import 'package:aquaflow_desktop/screens/admin_collectors_screen.dart';
import 'package:aquaflow_desktop/screens/admin_consumption_alerts_screen.dart';
import 'package:aquaflow_desktop/screens/admin_fault_reports_screen.dart';
import 'package:aquaflow_desktop/screens/admin_invoices_screen.dart';
import 'package:aquaflow_desktop/screens/admin_notifications_screen.dart';
import 'package:aquaflow_desktop/screens/admin_payments_screen.dart';
import 'package:aquaflow_desktop/screens/admin_support_tickets_screen.dart';
import 'package:aquaflow_desktop/screens/admin_tariffs_screen.dart';
import 'package:aquaflow_desktop/screens/admin_users_screen.dart';
import 'package:aquaflow_desktop/screens/admin_water_meter_requests_screen.dart';
import 'package:aquaflow_desktop/services/admin_dashboard_service.dart';
import 'package:aquaflow_desktop/shared/models/auth_session.dart';
import 'package:aquaflow_desktop/shared/models/city_lookup.dart';
import 'package:aquaflow_desktop/shared/providers/auth_provider.dart';
import 'package:aquaflow_desktop/shared/screens/company_settings_screen.dart';
import 'package:aquaflow_desktop/shared/services/location_lookup_service.dart';
import 'package:aquaflow_desktop/shared/widgets/async_state_view.dart';

/// Desktop home for the `admin` role - the only surface the desktop app exposes.
///
/// Classic admin layout: a fixed left [_Sidebar] (brand on top, a vertical menu
/// below with the active item highlighted in blue and a left indicator bar) and
/// a content area on the right that swaps with the selected menu item. The menu
/// mixes standalone entries ("Dashboard", "Obavijesti", "Moj nalog") with
/// collapsible category groups ("Korisnici", "Finansije", "Podrška",
/// "Sistem"); at most one group is expanded at a time (accordion - see
/// [_SidebarState]). The "Obavijesti", "Šifarnik", "Tarife", "Računi",
/// "Prijave kvarova", "Zahtjevi" (water meter requests, grouped under
/// "Podrška" alongside fault reports rather than under its own "Vodomjeri"
/// category), "Postavke firme", and "Moj nalog" sections embed their
/// existing screens; the rest are placeholders until wired up. There is no
/// "Aktivnosti" section - a user's activity log is reached per-row from
/// "Korisnici"/"Administratori" (see [AdminUserActivityLogsScreen]). "Moj
/// nalog" uses the admin-only [AdminAccountEditScreen] (not the shared
/// `AccountEditScreen` used by the mobile customer/collector "Nalog" tab),
/// since it edits more than contact data here. The nav tree is built
/// per-session (`_buildNavEntries`, not a static const list) because
/// "Podrška" only appears for a caller holding `SupportTickets.Manage` - see
/// [AdminSupportTicketsScreen]. Same reasoning gates the standalone
/// "Upozorenja o potrošnji" leaf behind `ConsumptionAlerts.Manage` - see
/// [AdminConsumptionAlertsScreen]. Selection is tracked as a single flat index
/// into the tree's leaf items in display order (see `_flattenNavItems`), so
/// existing per-session selection/clamping logic didn't need to change shape.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

/// A single leaf entry in the admin sidebar menu. [builder] renders the
/// content area for this item; left null for a section that isn't wired up
/// yet, in which case `_buildContent` falls back to `_SectionPlaceholder`.
class _AdminNavItem {
  const _AdminNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.builder,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final WidgetBuilder? builder;
}

/// One entry in the top-level sidebar tree: either a standalone leaf (e.g.
/// "Dashboard") or a collapsible category group of related leaves. Sealed so
/// `_flattenNavItems` and `_SidebarState` can switch over the two shapes
/// exhaustively.
sealed class _AdminNavEntry {
  const _AdminNavEntry();
}

class _AdminNavLeaf extends _AdminNavEntry {
  const _AdminNavLeaf(this.item);

  final _AdminNavItem item;
}

/// A collapsible category header in the sidebar (e.g. "Korisnici") grouping
/// related leaf items under it. At most one group is expanded at a time - see
/// [_SidebarState].
class _AdminNavGroup extends _AdminNavEntry {
  const _AdminNavGroup({
    required this.label,
    required this.icon,
    required this.items,
  });

  final String label;
  final IconData icon;
  final List<_AdminNavItem> items;
}

/// The menu tree, in display order. Built per-session (rather than a static
/// const list) because "Podrška" only appears for a caller holding
/// `SupportTickets.Manage` - everyone else never sees the entry, same
/// "hide what you can't use" precedent as `AccountScreen`'s admin-only
/// "Postavke firme" card.
List<_AdminNavEntry> _buildNavEntries(
  AuthSession? session,
  AppLocalizations loc,
) {
  final canManageSupportTickets =
      session?.hasPermission('SupportTickets.Manage') ?? false;
  final canManageConsumptionAlerts =
      session?.hasPermission('ConsumptionAlerts.Manage') ?? false;

  return [
    _AdminNavLeaf(
      _AdminNavItem(
        icon: Icons.grid_view_outlined,
        selectedIcon: Icons.grid_view,
        label: loc.dashboardLabel,
        builder: (_) => const _DashboardOverview(),
      ),
    ),
    _AdminNavLeaf(
      _AdminNavItem(
        icon: Icons.notifications_outlined,
        selectedIcon: Icons.notifications,
        label: loc.tabNotifications,
        builder: (_) => const AdminNotificationsScreen(),
      ),
    ),
    _AdminNavGroup(
      label: loc.usersLabel,
      icon: Icons.groups_outlined,
      items: [
        _AdminNavItem(
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          label: loc.usersLabel,
          // "Korisnici" and "Administratori" are the same widget type in the
          // same tree position, so they need distinct keys - otherwise
          // switching between them reuses the State and keeps the other
          // tab's loaded rows.
          builder: (_) =>
              const AdminUsersScreen(key: ValueKey('users-customers')),
        ),
        _AdminNavItem(
          icon: Icons.assignment_ind_outlined,
          selectedIcon: Icons.assignment_ind,
          label: loc.collectorsNavLabel,
          builder: (_) => const AdminCollectorsScreen(),
        ),
        _AdminNavItem(
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings,
          label: loc.administratorsLabel,
          builder: (_) => const AdminUsersScreen(
            key: ValueKey('users-admins'),
            mode: AdminUsersScreenMode.admins,
          ),
        ),
      ],
    ),
    _AdminNavGroup(
      label: loc.financeGroupLabel,
      icon: Icons.account_balance_wallet_outlined,
      items: [
        _AdminNavItem(
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          label: loc.invoicesLabel,
          builder: (_) => const AdminInvoicesScreen(),
        ),
        _AdminNavItem(
          icon: Icons.payments_outlined,
          selectedIcon: Icons.payments,
          label: loc.paymentsLabel,
          builder: (_) => const AdminPaymentsScreen(),
        ),
        _AdminNavItem(
          icon: Icons.request_quote_outlined,
          selectedIcon: Icons.request_quote,
          label: loc.tariffsNavLabel,
          builder: (_) => const AdminTariffsScreen(),
        ),
      ],
    ),
    _AdminNavGroup(
      label: loc.supportGroupLabel,
      icon: Icons.headset_mic_outlined,
      items: [
        _AdminNavItem(
          icon: Icons.report_problem_outlined,
          selectedIcon: Icons.report_problem,
          label: loc.faultReportsScreenTitle,
          builder: (_) => const AdminFaultReportsScreen(),
        ),
        _AdminNavItem(
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment,
          label: loc.waterMeterRequestsNavLabel,
          builder: (_) => const AdminWaterMeterRequestsScreen(),
        ),
        if (canManageSupportTickets)
          _AdminNavItem(
            icon: Icons.support_agent_outlined,
            selectedIcon: Icons.support_agent,
            label: loc.supportGroupLabel,
            builder: (_) => const AdminSupportTicketsScreen(),
          ),
      ],
    ),
    if (canManageConsumptionAlerts)
      _AdminNavLeaf(
        _AdminNavItem(
          icon: Icons.warning_amber_outlined,
          selectedIcon: Icons.warning_amber,
          label: loc.consumptionAlertsNavLabel,
          builder: (_) => const AdminConsumptionAlertsScreen(),
        ),
      ),
    _AdminNavGroup(
      label: loc.systemGroupLabel,
      icon: Icons.settings_outlined,
      items: [
        _AdminNavItem(
          icon: Icons.location_city_outlined,
          selectedIcon: Icons.location_city,
          label: loc.codebookLabel,
          builder: (_) => const AdminCodebookScreen(),
        ),
        _AdminNavItem(
          icon: Icons.business_outlined,
          selectedIcon: Icons.business,
          label: loc.companySettingsScreenTitle,
          builder: (_) => const CompanySettingsScreen(),
        ),
      ],
    ),
    _AdminNavLeaf(
      _AdminNavItem(
        icon: Icons.manage_accounts_outlined,
        selectedIcon: Icons.manage_accounts,
        label: loc.myAccountTitle,
        builder: (_) => const AdminAccountEditScreen(),
      ),
    ),
  ];
}

/// Flattens [entries] into their leaf items, in the same display order used
/// to index `_selectedIndex` - a group contributes all of its items in place,
/// a standalone leaf contributes itself.
List<_AdminNavItem> _flattenNavItems(List<_AdminNavEntry> entries) {
  final result = <_AdminNavItem>[];
  for (final entry in entries) {
    switch (entry) {
      case _AdminNavLeaf(:final item):
        result.add(item);
      case _AdminNavGroup(:final items):
        result.addAll(items);
    }
  }
  return result;
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  void _select(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthProvider>().session;
    final loc = AppLocalizations.of(context);
    final entries = _buildNavEntries(session, loc);
    final items = _flattenNavItems(entries);
    // The item count only changes when SupportTickets.Manage flips (a full
    // re-login), but guard anyway so a stale index can never run off the end.
    final selectedIndex = _selectedIndex.clamp(0, items.length - 1);

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Sidebar(
            entries: entries,
            selectedIndex: selectedIndex,
            onSelect: _select,
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey(selectedIndex),
                child: _buildContent(items[selectedIndex]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(_AdminNavItem item) {
    final builder = item.builder;
    return builder == null ? _SectionPlaceholder(item: item) : builder(context);
  }
}

/// Fixed left navigation column: brand, scrollable menu (standalone items and
/// collapsible category groups), and a footer with the signed-in admin's
/// email and a logout action.
class _Sidebar extends StatefulWidget {
  const _Sidebar({
    required this.entries,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<_AdminNavEntry> entries;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  State<_Sidebar> createState() => _SidebarState();
}

/// Accordion state for the category groups: at most one is expanded at a
/// time, so opening a group auto-collapses whichever was open before. Starts
/// expanded on whichever group (if any) contains the initial selection, so a
/// pre-selected item is never hidden inside a collapsed group on first paint.
class _SidebarState extends State<_Sidebar> {
  late String? _expandedGroup = _groupContaining(
    widget.entries,
    widget.selectedIndex,
  );

  static String? _groupContaining(
    List<_AdminNavEntry> entries,
    int selectedIndex,
  ) {
    var index = 0;
    for (final entry in entries) {
      switch (entry) {
        case _AdminNavLeaf():
          index++;
        case _AdminNavGroup(:final label, :final items):
          if (selectedIndex >= index && selectedIndex < index + items.length) {
            return label;
          }
          index += items.length;
      }
    }
    return null;
  }

  void _toggleGroup(String label) {
    setState(() => _expandedGroup = _expandedGroup == label ? null : label);
  }

  /// Builds the scrollable menu tiles for every entry except the trailing
  /// "Moj nalog" leaf, which is rendered in the footer instead (see `build`),
  /// directly above the logout tile.
  List<Widget> _buildMenuChildren() {
    final children = <Widget>[];
    var flatIndex = 0;
    final entries = widget.entries;
    for (var e = 0; e < entries.length; e++) {
      final entry = entries[e];
      final isTrailingAccountLeaf = e == entries.length - 1;
      switch (entry) {
        case _AdminNavLeaf(:final item):
          if (isTrailingAccountLeaf) {
            break;
          }
          final index = flatIndex;
          children.add(
            _AdminNavTile(
              item: item,
              selected: index == widget.selectedIndex,
              onTap: () => widget.onSelect(index),
            ),
          );
          flatIndex++;
        case _AdminNavGroup(:final label, :final icon, :final items):
          final startIndex = flatIndex;
          final expanded = _expandedGroup == label;
          final containsSelection =
              widget.selectedIndex >= startIndex &&
              widget.selectedIndex < startIndex + items.length;
          children.add(
            _AdminNavGroupHeader(
              label: label,
              icon: icon,
              expanded: expanded,
              containsSelection: containsSelection,
              onTap: () => _toggleGroup(label),
            ),
          );
          children.add(
            _AdminNavGroupBody(
              expanded: expanded,
              children: [
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: _AdminNavTile(
                      item: items[i],
                      selected: startIndex + i == widget.selectedIndex,
                      onTap: () => widget.onSelect(startIndex + i),
                    ),
                  ),
              ],
            ),
          );
          flatIndex += items.length;
      }
    }
    return children;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final email = context.select<AuthProvider, String>(
      (a) => a.session?.email ?? '',
    );
    // "Moj nalog" is always the trailing leaf in `_buildNavEntries` - pulled
    // out here so it can render in the footer, right above logout, instead
    // of inside the scrollable menu.
    final flatItems = _flattenNavItems(widget.entries);
    final accountIndex = flatItems.length - 1;
    final accountItem = flatItems[accountIndex];

    return Container(
      width: 248,
      color: Colors.white,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Brand.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
              child: Image.asset(
                'assets/images/logo.png',
                height: 32,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
                errorBuilder: (context, error, stackTrace) => Row(
                  children: [
                    Icon(
                      Icons.water_drop,
                      color: theme.colorScheme.primary,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      loc.appTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Menu (scrolls if the window is short).
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(children: _buildMenuChildren()),
              ),
            ),
            const Divider(height: 1),
            if (email.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 2),
                child: Text(
                  email,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: _AdminNavTile(
                item: accountItem,
                selected: accountIndex == widget.selectedIndex,
                onTap: () => widget.onSelect(accountIndex),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _AdminNavTile(
                item: _AdminNavItem(
                  icon: Icons.logout,
                  selectedIcon: Icons.logout,
                  label: loc.logoutLabel,
                ),
                selected: false,
                danger: true,
                onTap: () => context.read<AuthProvider>().logout(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One menu row. Inactive rows are slate gray; the active row turns blue, swaps
/// to the filled icon, gets a faint tinted background and a rounded indicator
/// bar on its left edge. [danger] renders the row in red (used for logout).
class _AdminNavTile extends StatelessWidget {
  const _AdminNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
    this.danger = false,
  });

  final _AdminNavItem item;
  final bool selected;
  final bool danger;
  final VoidCallback onTap;

  static const Color _inactive = Color(0xFF64748B);
  static const Color _danger = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final accent = danger ? _danger : primary;
    final color = selected ? accent : (danger ? _danger : _inactive);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected ? primary.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            height: 46,
            child: Row(
              children: [
                // Left active-indicator bar (zero height when inactive, so the
                // icons stay aligned across rows).
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 4,
                  height: selected ? 22 : 0,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 20,
                  color: color,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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
}

/// A collapsible category header in the sidebar menu ("Korisnici",
/// "Finansije", ...). Tapping toggles which group is expanded - see
/// [_SidebarState]. Recolors to the accent when [containsSelection], even
/// while collapsed, so the active section is never fully hidden from view.
class _AdminNavGroupHeader extends StatelessWidget {
  const _AdminNavGroupHeader({
    required this.label,
    required this.icon,
    required this.expanded,
    required this.containsSelection,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool expanded;
  final bool containsSelection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final color = containsSelection ? primary : _AdminNavTile._inactive;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: containsSelection
            ? primary.withValues(alpha: 0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            height: 42,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(icon, size: 19, color: color),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: color,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 150),
                  turns: expanded ? 0.5 : 0,
                  child: Icon(Icons.expand_more, size: 18, color: color),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animates a group's sub-items open/closed as [expanded] toggles, using the
/// standard `Align(heightFactor:)` + `AnimatedSize` trick so no explicit
/// height computation is needed.
class _AdminNavGroupBody extends StatelessWidget {
  const _AdminNavGroupBody({required this.expanded, required this.children});

  final bool expanded;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: expanded ? 1 : 0,
          child: Column(children: children),
        ),
      ),
    );
  }
}

/// Landing content (menu index 0): a header, a shared date-range/city filter
/// bar, and 6 chart cards backed by `GET /Dashboard/*` (see
/// [AdminDashboardService]). Every chart shares the same filter selection -
/// changing either control reloads all 6 at once via [_loadStats].
class _DashboardOverview extends StatefulWidget {
  const _DashboardOverview();

  @override
  State<_DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<_DashboardOverview> {
  late DateTimeRange _range = _defaultRange();
  int? _cityId;
  List<CityLookup> _cities = [];
  DashboardStats? _stats;
  bool _loading = true;
  String? _error;

  final _dashboardService = AdminDashboardService();
  final _locationService = LocationLookupService();

  // Rolling last-12-months window ending today, matching the backend's own
  // default (DashboardService.ResolveMonthRange) so the first paint and an
  // explicit reset always show the same range.
  static DateTimeRange _defaultRange() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    final start = DateTime(now.year, now.month - 11, 1);
    return DateTimeRange(start: start, end: end);
  }

  @override
  void initState() {
    super.initState();
    _loadCities();
    _loadStats();
  }

  @override
  void dispose() {
    _dashboardService.dispose();
    _locationService.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    try {
      final cities = await _locationService.fetchCities();
      if (!mounted) return;
      setState(() => _cities = cities);
    } catch (_) {
      // Non-fatal: the city filter just stays empty ("Svi gradovi" only) -
      // the charts themselves still load fine with no city filter applied.
    }
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await _dashboardService.fetchStats(
        from: _range.start,
        to: _range.end,
        cityId: _cityId,
      );
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  void _onRangeChanged(DateTimeRange range) {
    setState(() => _range = range);
    _loadStats();
  }

  void _onCityChanged(int? cityId) {
    setState(() => _cityId = cityId);
    _loadStats();
  }

  void _onReset() {
    setState(() {
      _range = _defaultRange();
      _cityId = null;
    });
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.dashboardLabel,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            loc.dashboardOverviewSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 20),
          _DashboardFilterBar(
            range: _range,
            cityId: _cityId,
            cities: _cities,
            onRangeChanged: _onRangeChanged,
            onCityChanged: _onCityChanged,
            onReset: _onReset,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 420,
            child: AsyncStateView(
              loading: _loading,
              error: _error,
              onRetry: _loadStats,
              builder: (context) => _buildCharts(context, _stats!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts(BuildContext context, DashboardStats stats) {
    final loc = AppLocalizations.of(context);
    final cards = [
      _ChartCard(
        title: loc.dashboardRevenueTrendChartTitle,
        child: _TrendLineView(points: stats.revenueTrend),
      ),
      _ChartCard(
        title: loc.dashboardInvoiceStatusChartTitle,
        child: _StatusDonutView(
          data: stats.invoiceStatus,
          labelFor: (status) => _invoiceStatusLabel(status, loc),
        ),
      ),
      _ChartCard(
        title: loc.dashboardConsumptionTrendChartTitle,
        child: _TrendLineView(points: stats.consumptionTrend),
      ),
      _ChartCard(
        title: loc.dashboardFaultReportStatusChartTitle,
        child: _StatusBarView(
          data: stats.faultReportStatus,
          labelFor: (status) => _faultReportStatusLabel(status, loc),
        ),
      ),
      _ChartCard(
        title: loc.dashboardUserGrowthChartTitle,
        child: _TrendLineView(points: stats.userGrowthTrend),
      ),
      _ChartCard(
        title: loc.dashboardWaterMeterRequestStatusChartTitle,
        child: _StatusBarView(
          data: stats.waterMeterRequestStatus,
          labelFor: (status) => _requestStatusLabel(status, loc),
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1180
            ? 3
            : (constraints.maxWidth >= 760 ? 2 : 1);
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final card in cards)
              SizedBox(
                width:
                    (constraints.maxWidth - (columns - 1) * 16) / columns,
                child: card,
              ),
          ],
        );
      },
    );
  }
}

/// Shared filter bar above the 6 dashboard charts: a date-range picker button
/// and a city dropdown ("Svi gradovi" clears it), plus a reset action back to
/// the default last-12-months / no-city selection.
class _DashboardFilterBar extends StatelessWidget {
  const _DashboardFilterBar({
    required this.range,
    required this.cityId,
    required this.cities,
    required this.onRangeChanged,
    required this.onCityChanged,
    required this.onReset,
  });

  final DateTimeRange range;
  final int? cityId;
  final List<CityLookup> cities;
  final ValueChanged<DateTimeRange> onRangeChanged;
  final ValueChanged<int?> onCityChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Tooltip(
          message: loc.dashboardFilterDateRangeTooltip,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today_outlined, size: 16),
            label: Text(_formatRange(range)),
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 5),
                lastDate: DateTime(now.year, now.month, now.day),
                initialDateRange: range,
              );
              if (picked != null) onRangeChanged(picked);
            },
          ),
        ),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<int?>(
            initialValue: cityId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: loc.dashboardFilterCityLabel,
              prefixIcon: const Icon(Icons.location_city_outlined),
            ),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(loc.dashboardFilterAllCities),
              ),
              for (final city in cities)
                DropdownMenuItem(value: city.id, child: Text(city.name)),
            ],
            onChanged: onCityChanged,
          ),
        ),
        TextButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.restart_alt, size: 18),
          label: Text(loc.dashboardFilterReset),
        ),
      ],
    );
  }

  String _formatRange(DateTimeRange range) {
    String fmt(DateTime d) {
      String two(int v) => v.toString().padLeft(2, '0');
      return '${two(d.day)}.${two(d.month)}.${d.year}.';
    }

    return '${fmt(range.start)} – ${fmt(range.end)}';
  }
}

String _invoiceStatusLabel(String status, AppLocalizations loc) =>
    switch (status) {
      'Issued' => loc.invoiceStatusIssued,
      'Paid' => loc.invoiceStatusPaid,
      'Cancelled' => loc.invoiceStatusCancelled,
      _ => status,
    };

String _faultReportStatusLabel(String status, AppLocalizations loc) =>
    switch (status) {
      'New' => loc.faultReportStatusNew,
      'Assigned' => loc.faultReportStatusAssigned,
      'InProgress' => loc.faultReportStatusInProgress,
      'Resolved' => loc.faultReportStatusResolved,
      _ => status,
    };

String _requestStatusLabel(String status, AppLocalizations loc) =>
    switch (status) {
      'Pending' => loc.requestStatusPending,
      'Assigned' => loc.requestStatusAwaitingRegistration,
      'Registered' => loc.requestStatusRegistered,
      'Rejected' => loc.requestStatusRejected,
      'Cancelled' => loc.requestStatusCancelled,
      _ => status,
    };

// ---------------------------------------------------------------------------
// Charts, backed by real /Dashboard data. Colours come from the validated
// categorical palette (dataviz skill): slot 1 blue, slot 2 aqua, slot 3
// yellow, slot 4 green, slot 5 orange (added here for the 5-status water
// meter request breakdown). Axis chrome uses the muted/grid/baseline ink
// tokens, never a series colour.
// ---------------------------------------------------------------------------

const Color _series1 = Color(0xFF2A78D6); // blue
const Color _series2 = Color(0xFF1BAF7A); // aqua
const Color _series3 = Color(0xFFEDA100); // yellow
const Color _series4 = Color(0xFF008300); // green
const Color _series5 = Color(0xFFDD6B20); // orange
const Color _grid = Color(0xFFE1E0D9);
const Color _axis = Color(0xFFC3C2B7);
const Color _muted = Color(0xFF898781);
const List<Color> _statusPalette = [
  _series1,
  _series2,
  _series3,
  _series4,
  _series5,
];

/// Draws a single line of text anchored at [pos]. [anchor] places which point of
/// the text box sits on [pos] (e.g. centerRight = right-align, topCenter =
/// centered below).
void _drawChartText(
  Canvas canvas,
  String text,
  Offset pos, {
  required Color color,
  double size = 11,
  FontWeight weight = FontWeight.w500,
  Alignment anchor = Alignment.centerLeft,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: size, fontWeight: weight),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final dx = pos.dx - tp.width * ((anchor.x + 1) / 2);
  final dy = pos.dy - tp.height * ((anchor.y + 1) / 2);
  tp.paint(canvas, Offset(dx, dy));
}

/// White, rounded, hairline-bordered card that titles a chart and gives it a
/// fixed drawing height.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1A0B0B0B)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF52514E),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(height: 200, child: child),
        ],
      ),
    );
  }
}

/// Smooth line chart for a monthly trend (revenue / consumption / new users).
/// Zero-filled months (see DashboardService.BuildMonthlyTrend) still render as
/// a real point on the line - a flat stretch at 0 is a meaningful "no
/// activity" signal, not something to hide.
class _TrendLineView extends StatelessWidget {
  const _TrendLineView({required this.points});

  final List<DashboardTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).emptyGeneric,
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
      );
    }
    return CustomPaint(
      size: Size.infinite,
      painter: _TrendLinePainter(points),
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  _TrendLinePainter(this.points);

  final List<DashboardTrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTRB(34, 8, size.width - 8, size.height - 22);
    final maxValue = points.fold<double>(0, (m, p) => math.max(m, p.value));
    final niceMax = _niceCeil(maxValue <= 0 ? 1 : maxValue);
    final ticks = [niceMax * 0.25, niceMax * 0.5, niceMax * 0.75, niceMax];

    final gridPaint = Paint()
      ..color = _grid
      ..strokeWidth = 1;
    for (final t in ticks) {
      final y = chart.bottom - (t / niceMax) * chart.height;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      _drawChartText(
        canvas,
        _formatAxisNumber(t),
        Offset(chart.left - 6, y),
        color: _muted,
        size: 9,
        anchor: Alignment.centerRight,
      );
    }
    canvas.drawLine(
      chart.bottomLeft,
      chart.bottomRight,
      Paint()
        ..color = _axis
        ..strokeWidth = 1,
    );

    final pts = <Offset>[
      for (var i = 0; i < points.length; i++)
        Offset(
          chart.left +
              (points.length == 1
                  ? chart.width / 2
                  : (i / (points.length - 1)) * chart.width),
          chart.bottom - (points[i].value / niceMax) * chart.height,
        ),
    ];

    if (pts.length > 1) {
      // Catmull-Rom -> cubic Bezier for a smooth curve.
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 0; i < pts.length - 1; i++) {
        final p0 = pts[i == 0 ? 0 : i - 1];
        final p1 = pts[i];
        final p2 = pts[i + 1];
        final p3 = pts[i + 2 >= pts.length ? pts.length - 1 : i + 2];
        final c1 = Offset(
          p1.dx + (p2.dx - p0.dx) / 6,
          p1.dy + (p2.dy - p0.dy) / 6,
        );
        final c2 = Offset(
          p2.dx - (p3.dx - p1.dx) / 6,
          p2.dy - (p3.dy - p1.dy) / 6,
        );
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = _series1
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Markers: white core with a 2px series-coloured ring.
    for (final p in pts) {
      canvas.drawCircle(p, 4, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        4,
        Paint()
          ..color = _series1
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Thin out x-axis labels once there are more than ~6 points (a default
    // 12-month window) so month labels never overlap.
    final labelStep = (points.length / 6).ceil().clamp(1, points.length);
    for (var i = 0; i < points.length; i += labelStep) {
      _drawChartText(
        canvas,
        _formatMonthLabel(points[i].periodStart),
        Offset(pts[i].dx, chart.bottom + 6),
        color: _muted,
        size: 9,
        anchor: Alignment.topCenter,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) =>
      !identical(oldDelegate.points, points);
}

/// Donut chart for a status breakdown with a small color-coded legend below
/// (the number of statuses/colours isn't fixed, unlike the old demo chart).
class _StatusDonutView extends StatelessWidget {
  const _StatusDonutView({required this.data, required this.labelFor});

  final List<DashboardStatusBreakdown> data;
  final String Function(String status) labelFor;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final total = data.fold<int>(0, (sum, d) => sum + d.count);
    if (total == 0) {
      return Center(
        child: Text(
          loc.emptyGeneric,
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
      );
    }

    final slices = <(double, Color)>[
      for (var i = 0; i < data.length; i++)
        (data[i].count / total * 100, _statusPalette[i % _statusPalette.length]),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: _StatusDonutPainter(slices),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: [
            for (var i = 0; i < data.length; i++)
              _LegendDot(
                color: _statusPalette[i % _statusPalette.length],
                label: '${labelFor(data[i].status)} (${data[i].count})',
              ),
          ],
        ),
      ],
    );
  }
}

class _StatusDonutPainter extends CustomPainter {
  _StatusDonutPainter(this.slices);

  final List<(double value, Color color)> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final thickness = radius * 0.42;
    final ringRadius = radius - thickness / 2;
    const gap = 0.04; // small white separator between slices

    var start = -math.pi / 2;
    for (final (value, color) in slices) {
      final sweep = (value / 100) * 2 * math.pi;
      if (sweep <= 0) continue;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        start + gap / 2,
        math.max(sweep - gap, 0.001),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness,
      );
      // A very thin slice has no room for a readable label inside it.
      if (value >= 6) {
        final mid = start + sweep / 2;
        final labelPos =
            center + Offset(math.cos(mid), math.sin(mid)) * ringRadius;
        _drawChartText(
          canvas,
          '${value.toStringAsFixed(0)}%',
          labelPos,
          color: Colors.white,
          size: 11,
          weight: FontWeight.w700,
          anchor: Alignment.center,
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _StatusDonutPainter oldDelegate) =>
      !identical(oldDelegate.slices, slices);
}

/// Single-series bar chart for a status breakdown (one bar per status, count
/// labelled above each bar) with a color-coded legend below in the same
/// left-to-right order as the bars.
class _StatusBarView extends StatelessWidget {
  const _StatusBarView({required this.data, required this.labelFor});

  final List<DashboardStatusBreakdown> data;
  final String Function(String status) labelFor;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (data.isEmpty) {
      return Center(
        child: Text(
          loc.emptyGeneric,
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
      );
    }

    final bars = <(int, Color)>[
      for (var i = 0; i < data.length; i++)
        (data[i].count, _statusPalette[i % _statusPalette.length]),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: _StatusBarPainter(bars),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: [
            for (var i = 0; i < data.length; i++)
              _LegendDot(
                color: _statusPalette[i % _statusPalette.length],
                label: labelFor(data[i].status),
              ),
          ],
        ),
      ],
    );
  }
}

class _StatusBarPainter extends CustomPainter {
  _StatusBarPainter(this.bars);

  final List<(int count, Color color)> bars;

  @override
  void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTRB(6, 16, size.width - 6, size.height - 8);
    final maxCount = bars.fold<int>(0, (m, b) => math.max(m, b.$1));
    final safeMax = maxCount <= 0 ? 1 : maxCount;
    final n = bars.length;
    final slot = chart.width / n;
    final barWidth = math.min(slot * 0.5, 44.0);

    for (var i = 0; i < n; i++) {
      final (count, color) = bars[i];
      final h = (count / safeMax) * chart.height;
      final left = chart.left + i * slot + (slot - barWidth) / 2;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(left, chart.bottom - h, barWidth, h),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        ),
        Paint()..color = color,
      );
      _drawChartText(
        canvas,
        '$count',
        Offset(left + barWidth / 2, chart.bottom - h - 4),
        color: _muted,
        size: 10,
        weight: FontWeight.w600,
        anchor: Alignment.bottomCenter,
      );
    }
    canvas.drawLine(
      chart.bottomLeft,
      chart.bottomRight,
      Paint()
        ..color = _axis
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _StatusBarPainter oldDelegate) =>
      !identical(oldDelegate.bars, bars);
}

/// Rounds [value] up to a "nice" number (1/2/5 x a power of 10) for chart
/// y-axis ticks, e.g. 83 -> 100, 340 -> 500, 4 -> 5.
double _niceCeil(double value) {
  final magnitude = math.pow(10, (math.log(value) / math.ln10).floor())
      .toDouble();
  final residual = value / magnitude;
  final niceResidual = residual <= 1
      ? 1.0
      : (residual <= 2 ? 2.0 : (residual <= 5 ? 5.0 : 10.0));
  return niceResidual * magnitude;
}

/// Formats a y-axis tick value: whole numbers as-is, thousands with a "k"
/// suffix (e.g. 1500 -> "1.5k") to keep the axis column narrow.
String _formatAxisNumber(double value) {
  if (value >= 1000) {
    final thousands = value / 1000;
    return '${thousands % 1 == 0 ? thousands.toStringAsFixed(0) : thousands.toStringAsFixed(1)}k';
  }
  return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}

/// Numeric MM.yy month label (e.g. "06.26") - matches the dd.MM.yyyy numeric
/// date convention used throughout this app instead of a localized month
/// name, so no extra l10n keys are needed for the 12 month names.
String _formatMonthLabel(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final year = (date.year % 100).toString().padLeft(2, '0');
  return '$month.$year';
}

/// Small swatch + label used in a chart legend. Text stays in ink, not the
/// series colour.
class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF52514E),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Placeholder body for a menu section whose real screen is not built yet.
class _SectionPlaceholder extends StatelessWidget {
  const _SectionPlaceholder({required this.item});

  final _AdminNavItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.selectedIcon,
                      size: 48,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(
                      context,
                    ).sectionNotImplementedMessage(item.label),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
