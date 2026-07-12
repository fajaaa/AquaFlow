import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_desktop/admin/screens/admin_account_edit_screen.dart';
import 'package:aquaflow_desktop/admin/screens/admin_codebook_screen.dart';
import 'package:aquaflow_desktop/admin/screens/admin_collectors_screen.dart';
import 'package:aquaflow_desktop/admin/screens/admin_fault_reports_screen.dart';
import 'package:aquaflow_desktop/admin/screens/admin_invoices_screen.dart';
import 'package:aquaflow_desktop/admin/screens/admin_notifications_screen.dart';
import 'package:aquaflow_desktop/admin/screens/admin_payments_screen.dart';
import 'package:aquaflow_desktop/admin/screens/admin_tariffs_screen.dart';
import 'package:aquaflow_desktop/admin/screens/admin_users_screen.dart';
import 'package:aquaflow_desktop/admin/screens/admin_water_meter_requests_screen.dart';
import 'package:aquaflow_desktop/shared/providers/auth_provider.dart';
import 'package:aquaflow_desktop/shared/screens/company_settings_screen.dart';

/// Desktop home for the `admin` role - the only surface the desktop app exposes.
///
/// Classic admin layout: a fixed left [_Sidebar] (brand on top, a vertical menu
/// below with the active item highlighted in blue and a left indicator bar) and
/// a content area on the right that swaps with the selected menu item. The
/// "Obavijesti", "Šifarnik", "Tarife", "Računi", "Prijave kvarova", "Postavke firme",
/// and "Moj nalog" sections embed their existing screens; the rest are placeholders
/// until wired up. "Moj nalog" uses
/// the admin-only [AdminAccountEditScreen] (not the shared `AccountEditScreen`
/// used by the mobile customer/collector "Nalog" tab), since it edits more than
/// contact data here.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

/// A single entry in the admin sidebar menu.
class _AdminNavItem {
  const _AdminNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// The menu, in display order. Indexes are referenced by the content switch and
/// by the overview shortcuts, so keep them in sync when reordering.
const List<_AdminNavItem> _navItems = [
  _AdminNavItem(
    icon: Icons.grid_view_outlined,
    selectedIcon: Icons.grid_view,
    label: 'Dashboard',
  ),
  _AdminNavItem(
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications,
    label: 'Obavijesti',
  ),
  _AdminNavItem(
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
    label: 'Korisnici',
  ),
  _AdminNavItem(
    icon: Icons.assignment_ind_outlined,
    selectedIcon: Icons.assignment_ind,
    label: 'Inkasanti',
  ),
  _AdminNavItem(
    icon: Icons.water_drop_outlined,
    selectedIcon: Icons.water_drop,
    label: 'Vodomjeri',
  ),
  _AdminNavItem(
    icon: Icons.speed_outlined,
    selectedIcon: Icons.speed,
    label: 'Očitanja',
  ),
  _AdminNavItem(
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    label: 'Računi',
  ),
  _AdminNavItem(
    icon: Icons.payments_outlined,
    selectedIcon: Icons.payments,
    label: 'Plaćanja',
  ),
  _AdminNavItem(
    icon: Icons.report_problem_outlined,
    selectedIcon: Icons.report_problem,
    label: 'Prijave kvarova',
  ),
  _AdminNavItem(
    icon: Icons.admin_panel_settings_outlined,
    selectedIcon: Icons.admin_panel_settings,
    label: 'Administratori',
  ),
  _AdminNavItem(
    icon: Icons.location_city_outlined,
    selectedIcon: Icons.location_city,
    label: 'Šifarnik',
  ),
  _AdminNavItem(
    icon: Icons.request_quote_outlined,
    selectedIcon: Icons.request_quote,
    label: 'Tarife',
  ),
  _AdminNavItem(
    icon: Icons.business_outlined,
    selectedIcon: Icons.business,
    label: 'Postavke firme',
  ),
  _AdminNavItem(
    icon: Icons.manage_accounts_outlined,
    selectedIcon: Icons.manage_accounts,
    label: 'Moj nalog',
  ),
  _AdminNavItem(
    icon: Icons.assignment_outlined,
    selectedIcon: Icons.assignment,
    label: 'Zahtjevi',
  ),
];

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  void _select(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Sidebar(
            items: _navItems,
            selectedIndex: _selectedIndex,
            onSelect: _select,
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const _DashboardOverview();
      case 1:
        return const AdminNotificationsScreen();
      // "Korisnici" and "Administratori" are the same widget type in the same
      // tree position, so they need distinct keys - otherwise switching between
      // them reuses the State and keeps the other tab's loaded rows.
      case 2:
        return const AdminUsersScreen(key: ValueKey('users-customers'));
      case 3:
        return const AdminCollectorsScreen();
      case 6:
        return const AdminInvoicesScreen();
      case 7:
        return const AdminPaymentsScreen();
      case 8:
        return const AdminFaultReportsScreen();
      case 9:
        return const AdminUsersScreen(
          key: ValueKey('users-admins'),
          mode: AdminUsersScreenMode.admins,
        );
      case 10:
        return const AdminCodebookScreen();
      case 11:
        return const AdminTariffsScreen();
      case 12:
        return const CompanySettingsScreen();
      case 13:
        return const AdminAccountEditScreen();
      case 14:
        return const AdminWaterMeterRequestsScreen();
      default:
        return _SectionPlaceholder(item: _navItems[_selectedIndex]);
    }
  }
}

/// Fixed left navigation column: brand, scrollable menu, and a footer with the
/// signed-in admin's email and a logout action.
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<_AdminNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email =
        context.select<AuthProvider, String>((a) => a.session?.email ?? '');

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
              child: Row(
                children: [
                  Icon(Icons.water_drop,
                      color: theme.colorScheme.primary, size: 26),
                  const SizedBox(width: 10),
                  Text(
                    'AquaFlow',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
            // Menu (scrolls if the window is short).
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      _AdminNavTile(
                        item: items[i],
                        selected: i == selectedIndex,
                        onTap: () => onSelect(i),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            if (email.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 2),
                child: Text(
                  email,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: const Color(0xFF94A3B8)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: _AdminNavTile(
                item: const _AdminNavItem(
                  icon: Icons.logout,
                  selectedIcon: Icons.logout,
                  label: 'Odjava',
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
                Icon(selected ? item.selectedIcon : item.icon,
                    size: 20, color: color),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
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

/// Landing content (menu index 0): a header and three demo charts (line, donut,
/// bar) with hard-coded values. Placeholder until the real dashboard is built.
class _DashboardOverview extends StatelessWidget {
  const _DashboardOverview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Pregled ključnih pokazatelja (demo podaci)',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              const cards = [
                _ChartCard(title: 'Line Chart', child: _LineChartView()),
                _ChartCard(title: 'Donut Chart', child: _DonutChartView()),
                _ChartCard(title: 'Bar Chart', child: _BarChartView()),
              ];
              // Side by side when there is room, otherwise stacked.
              if (constraints.maxWidth >= 900) {
                return Row(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: 16),
                      Expanded(child: cards[i]),
                    ],
                  ],
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    cards[i],
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Charts (demo data). Colours come from the validated categorical palette
// (dataviz skill): slot 1 blue, slot 2 aqua, slot 3 yellow, slot 4 green. Axis
// chrome uses the muted/grid/baseline ink tokens, never a series colour.
// ---------------------------------------------------------------------------

const Color _series1 = Color(0xFF2A78D6); // blue
const Color _series2 = Color(0xFF1BAF7A); // aqua
const Color _series3 = Color(0xFFEDA100); // yellow
const Color _series4 = Color(0xFF008300); // green
const Color _grid = Color(0xFFE1E0D9);
const Color _axis = Color(0xFFC3C2B7);
const Color _muted = Color(0xFF898781);

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

/// Single-series smooth line chart (no legend needed - the title names it).
class _LineChartView extends StatelessWidget {
  const _LineChartView();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.infinite, painter: _LineChartPainter());
}

class _LineChartPainter extends CustomPainter {
  static const List<int> _years = [2016, 2017, 2018, 2019, 2020, 2021];
  static const List<double> _values = [2, 1, 8, 3, 17, 4.5];
  static const double _maxY = 18;
  static const List<double> _ticks = [5, 10, 15];

  @override
  void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTRB(26, 8, size.width - 8, size.height - 22);
    final gridPaint = Paint()
      ..color = _grid
      ..strokeWidth = 1;

    for (final t in _ticks) {
      final y = chart.bottom - (t / _maxY) * chart.height;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      _drawChartText(canvas, t.toInt().toString(),
          Offset(chart.left - 6, y), color: _muted, size: 10,
          anchor: Alignment.centerRight);
    }
    canvas.drawLine(chart.bottomLeft, chart.bottomRight,
        Paint()..color = _axis..strokeWidth = 1);

    final pts = <Offset>[
      for (var i = 0; i < _values.length; i++)
        Offset(
          chart.left + (i / (_values.length - 1)) * chart.width,
          chart.bottom - (_values[i] / _maxY) * chart.height,
        ),
    ];

    // Catmull-Rom -> cubic Bezier for a smooth curve.
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = pts[i == 0 ? 0 : i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = pts[i + 2 >= pts.length ? pts.length - 1 : i + 2];
      final c1 = Offset(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
      final c2 = Offset(p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);
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

    // Markers: white core with a 2px series-coloured ring.
    for (final p in pts) {
      canvas.drawCircle(p, 4.5, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        4.5,
        Paint()
          ..color = _series1
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    for (var i = 0; i < _years.length; i++) {
      _drawChartText(canvas, '${_years[i]}',
          Offset(pts[i].dx, chart.bottom + 6), color: _muted, size: 10,
          anchor: Alignment.topCenter);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Four-segment donut with percentage labels inside each slice.
class _DonutChartView extends StatelessWidget {
  const _DonutChartView();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.infinite, painter: _DonutChartPainter());
}

class _DonutChartPainter extends CustomPainter {
  static const List<(double, Color)> _data = [
    (40, _series1),
    (30, _series2),
    (15, _series3),
    (15, _series4),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final thickness = radius * 0.42;
    final ringRadius = radius - thickness / 2;
    const gap = 0.04; // small white separator between slices

    var start = -math.pi / 2;
    for (final (value, color) in _data) {
      final sweep = (value / 100) * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        start + gap / 2,
        sweep - gap,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness,
      );
      final mid = start + sweep / 2;
      final labelPos =
          center + Offset(math.cos(mid), math.sin(mid)) * ringRadius;
      _drawChartText(canvas, '${value.toInt()}%', labelPos,
          color: Colors.white, size: 12, weight: FontWeight.w700,
          anchor: Alignment.center);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Grouped bar chart, two series per year, with a legend (>= 2 series).
class _BarChartView extends StatelessWidget {
  const _BarChartView();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomPaint(size: Size.infinite, painter: _BarChartPainter()),
        ),
        const SizedBox(height: 8),
        Row(
          children: const [
            _LegendDot(color: _series1, label: 'Serija A'),
            SizedBox(width: 16),
            _LegendDot(color: _series2, label: 'Serija B'),
          ],
        ),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  static const List<int> _years = [2016, 2017, 2018, 2019, 2020, 2021, 2022];
  static const List<List<double>> _series = [
    [25, 60],
    [80, 60],
    [90, 25],
    [100, 80],
    [85, 30],
    [10, 70],
    [50, 8],
  ];
  static const double _maxY = 100;
  static const List<double> _ticks = [0, 25, 50, 75, 100];
  static const List<Color> _colors = [_series1, _series2];

  @override
  void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTRB(26, 8, size.width - 6, size.height - 20);
    final gridPaint = Paint()
      ..color = _grid
      ..strokeWidth = 1;

    for (final t in _ticks) {
      final y = chart.bottom - (t / _maxY) * chart.height;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      _drawChartText(canvas, t.toInt().toString(),
          Offset(chart.left - 6, y), color: _muted, size: 10,
          anchor: Alignment.centerRight);
    }

    final groups = _years.length;
    final groupWidth = chart.width / groups;
    const barGap = 2.0;
    final innerPad = groupWidth * 0.22;
    final barWidth = (groupWidth - innerPad * 2 - barGap) / 2;

    for (var g = 0; g < groups; g++) {
      final gx = chart.left + g * groupWidth + innerPad;
      for (var s = 0; s < 2; s++) {
        final h = (_series[g][s] / _maxY) * chart.height;
        final left = gx + s * (barWidth + barGap);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(left, chart.bottom - h, barWidth, h),
            topLeft: const Radius.circular(4),
            topRight: const Radius.circular(4),
          ),
          Paint()..color = _colors[s],
        );
      }
      _drawChartText(canvas, '${_years[g]}',
          Offset(chart.left + g * groupWidth + groupWidth / 2, chart.bottom + 5),
          color: _muted, size: 9, anchor: Alignment.topCenter);
    }
    canvas.drawLine(chart.bottomLeft, chart.bottomRight,
        Paint()..color = _axis..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600),
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
                    child: Icon(item.selectedIcon,
                        size: 48, color: theme.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sekcija "${item.label}" još nije implementirana.',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.outline),
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
