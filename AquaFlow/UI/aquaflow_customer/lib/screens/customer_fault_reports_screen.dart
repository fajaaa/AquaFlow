import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:aquaflow_customer/models/customer_fault_report.dart';
import 'package:aquaflow_customer/models/customer_fault_report_page.dart';
import 'package:aquaflow_customer/screens/customer_fault_report_detail_screen.dart';
import 'package:aquaflow_customer/services/customer_fault_report_exception.dart';
import 'package:aquaflow_customer/services/customer_fault_report_service.dart';
import 'package:aquaflow_customer/widgets/new_fault_report_dialog.dart';
import 'package:aquaflow_customer/shared/navigation/app_navigation.dart';
import 'package:aquaflow_customer/shared/widgets/async_state_view.dart';
import 'package:aquaflow_customer/shared/widgets/empty_state_view.dart';
import 'package:aquaflow_customer/shared/widgets/list_skeleton.dart';
import 'package:aquaflow_customer/shared/widgets/paged_table_pagination_bar.dart';
import 'package:aquaflow_customer/shared/widgets/refresh_button.dart';

/// "Prijave kvarova" tab body: paginated list of ALL of the signed-in
/// customer's fault reports, every status.
///
/// Uses real server-side pagination
/// (`GET /FaultReports?Page=&PageSize=&IncludeTotalCount=true&SortBy=CreatedAt&SortDescending=true`;
/// the backend pins `ReportedById` to the caller). Card styling and page-bar
/// mirror `NotificationsScreen`/`CustomerWaterMetersScreen`: a branded
/// gradient bar keyed to the report's status, an accent-tinted status tag,
/// and the same loading/empty/error scaffolding (`AsyncStateView`/
/// `ListSkeleton`/`EmptyStateView`). Cards are tappable, pushing
/// [CustomerFaultReportDetailScreen].
///
/// Rendered inside [MobileShell], so it has no Scaffold/AppBar of its own.
class CustomerFaultReportsScreen extends StatefulWidget {
  const CustomerFaultReportsScreen({super.key});

  @override
  State<CustomerFaultReportsScreen> createState() =>
      _CustomerFaultReportsScreenState();
}

class _CustomerFaultReportsScreenState
    extends State<CustomerFaultReportsScreen> {
  final CustomerFaultReportService _service = CustomerFaultReportService();

  CustomerFaultReportPage? _pageData;
  bool _loading = true;
  String? _error;
  int _page = 1;
  int _pageSize = 10;
  int _requestSerial = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool resetPage = false}) async {
    final requestId = ++_requestSerial;
    setState(() {
      if (resetPage) _page = 1;
      _loading = true;
      _error = null;
    });

    try {
      final pageData = await _service.fetchPage(
        page: _page,
        pageSize: _pageSize,
      );
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = pageData;
        _loading = false;
      });
    } on CustomerFaultReportException catch (e) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
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

  Future<void> _openNewReportDialog() async {
    final created = await showNewFaultReportDialog(context);
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prijava kvara je poslana.')),
      );
      await _load(resetPage: true);
    }
  }

  Future<void> _openDetail(CustomerFaultReport report) async {
    await context.pushScreen(
      CustomerFaultReportDetailScreen(report: report),
    );
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
    // or how many reports there are.
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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Prijave kvarova',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Nova prijava',
                  onPressed: _loading ? null : _openNewReportDialog,
                  icon: const Icon(Icons.add),
                ),
                RefreshButton(onRefresh: () => _load(), enabled: !_loading),
              ],
            ),
          ),
          if (_loading && pageData != null)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildBody()),
          ?pagination,
        ],
      ),
    );
  }

  Widget _buildBody() {
    return AsyncStateView(
      loading: _loading && _pageData == null,
      error: _error,
      onRetry: _load,
      loadingBuilder: (context) => ListSkeleton(
        itemBuilder: (context, index) =>
            _ReportCard(report: _skeletonReport, service: _service),
      ),
      builder: (context) {
        final items = _pageData!.items;

        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => _load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
                const EmptyStateView(
                  icon: Icons.report_problem_outlined,
                  message: 'Nemate poslanih prijava kvarova.',
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
              final report = items[index];
              return _ReportCard(
                report: report,
                service: _service,
                onTap: () => _openDetail(report),
              );
            },
          ),
        );
      },
    );
  }

  int _totalPages(int totalCount) {
    if (totalCount <= 0) return 1;
    return ((totalCount + _pageSize - 1) / _pageSize).floor();
  }
}

final _skeletonReport = CustomerFaultReport(
  id: 0,
  title: 'Naslov prijave kvara',
  description: '',
  status: 'New',
  waterMeterId: null,
  settlementId: 0,
  settlementName: 'Naselje',
  street: 'Ulica',
  houseNumber: '1',
  createdAt: null,
  resolvedAt: null,
);

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.service, this.onTap});

  final CustomerFaultReport report;
  final CustomerFaultReportService service;

  /// Null for the skeleton placeholder card, which isn't tappable.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    final meta = _StatusMeta.of(report.status);
    final accent = _readableAccent(meta.color, theme.brightness);
    // A New report hasn't been picked up yet - same "needs attention" role
    // `!isRead` plays for a notification card / `isInactive` for a meter card.
    final needsAttention = report.isNew;

    final subtitle = _locationLabel(report);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: isLight ? Colors.white : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: needsAttention
                  ? accent.withValues(alpha: 0.35)
                  : (isLight
                        ? const Color(0x121F2937)
                        : colorScheme.outlineVariant.withValues(alpha: 0.5)),
              width: needsAttention ? 1.5 : 1,
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
                // Colored status bar - branded gradient with a white glyph.
                Container(
                  width: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _shade(meta.color, 0.16),
                        _shade(meta.color, -0.20),
                      ],
                    ),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(18),
                    ),
                  ),
                  child: Center(
                    child: Icon(meta.icon, color: Colors.white, size: 20),
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
                            Flexible(
                              child: Text(
                                report.title.isEmpty ? '-' : report.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: needsAttention
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (needsAttention) ...[
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
                            const Spacer(),
                            _ThumbnailPreview(reportId: report.id, service: service),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
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
                                meta.label,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                            Text(
                              _formatDate(report.createdAt),
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

  /// Mirrors `_readableAccent` in notifications_screen.dart: any accent dark
  /// enough to blend into the dark theme's background is lifted toward white
  /// there. Light theme and the brighter accents are returned unchanged.
  static Color _readableAccent(Color base, Brightness brightness) {
    if (brightness == Brightness.dark && base.computeLuminance() < 0.2) {
      return Color.lerp(base, Colors.white, 0.6)!;
    }
    return base;
  }

  /// Tints [c] toward white for a positive [percent] or toward black for a
  /// negative one - used to build the two-stop gradient on the status bar.
  static Color _shade(Color c, double percent) {
    if (percent >= 0) return Color.lerp(c, Colors.white, percent)!;
    return Color.lerp(c, Colors.black, -percent)!;
  }
}

/// Icon + accent color + label for a fault report `status`. Kept in sync with
/// `_metaFor` in customer_fault_report_detail_screen.dart so a report looks
/// the same in this list and on its detail screen.
class _StatusMeta {
  const _StatusMeta(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  static _StatusMeta of(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return const _StatusMeta(
          'Nova',
          Icons.fiber_new_outlined,
          Color(0xFFB45309),
        );
      case 'assigned':
        return const _StatusMeta(
          'Dodijeljena',
          Icons.assignment_ind_outlined,
          Color(0xFF6D28D9),
        );
      case 'inprogress':
        return const _StatusMeta(
          'U toku',
          Icons.engineering_outlined,
          Color(0xFF1D4ED8),
        );
      case 'resolved':
        return const _StatusMeta(
          'Riješena',
          Icons.check_circle_outline,
          Color(0xFF2E7D32),
        );
      default:
        return _StatusMeta(status, Icons.help_outline, const Color(0xFF64748B));
    }
  }
}

/// Shows the first attached photo's thumbnail (fetches metadata, then the
/// bytes of the first photo) or nothing when the report has none/is a
/// skeleton placeholder (id 0).
class _ThumbnailPreview extends StatelessWidget {
  const _ThumbnailPreview({required this.reportId, required this.service});

  final int reportId;
  final CustomerFaultReportService service;

  Future<Uint8List?> _fetchFirstPhotoBytes() async {
    if (reportId == 0) return null;
    final photos = await service.fetchPhotos(reportId);
    if (photos.isEmpty) return null;
    return service.fetchPhotoBytes(reportId, photos.first.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _fetchFirstPhotoBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.data == null) {
          return const SizedBox.shrink();
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.memory(
            snapshot.data!,
            width: 32,
            height: 32,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}

/// "Naselje, Ulica Broj" - the report's own location, not the profile address.
String _locationLabel(CustomerFaultReport report) {
  final parts = [
    report.settlementName.trim(),
    report.address,
  ].where((part) => part.isNotEmpty).toList();
  return parts.isEmpty ? '-' : parts.join(', ');
}

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}. '
      '${two(date.hour)}:${two(date.minute)}';
}
