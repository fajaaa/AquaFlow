import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/customer/models/customer_fault_report.dart';
import 'package:aquaflow_desktop/customer/screens/customer_fault_report_detail_screen.dart';
import 'package:aquaflow_desktop/customer/services/customer_fault_report_exception.dart';
import 'package:aquaflow_desktop/customer/services/customer_fault_report_service.dart';
import 'package:aquaflow_desktop/customer/widgets/fault_report_status_pill.dart';
import 'package:aquaflow_desktop/customer/widgets/new_fault_report_dialog.dart';
import 'package:aquaflow_desktop/shared/widgets/authenticated_image.dart';

/// Full-screen list of ALL of the signed-in customer's fault reports, every
/// status. Reached from the "Vodomjeri" tab's "Prijave kvarova" action.
///
/// Uses real server-side pagination
/// (`GET /FaultReports?Page=&PageSize=20&IncludeTotalCount=true&SortBy=CreatedAt&SortDescending=true`;
/// the backend pins `CustomerId` to the caller): infinite scroll loads the next
/// page near the bottom and stops when a short page arrives or the total count
/// is reached, and pull-to-refresh resets to page 1. Same template as
/// `CustomerRequestsScreen`.
class CustomerFaultReportsScreen extends StatefulWidget {
  const CustomerFaultReportsScreen({super.key});

  @override
  State<CustomerFaultReportsScreen> createState() =>
      _CustomerFaultReportsScreenState();
}

class _CustomerFaultReportsScreenState
    extends State<CustomerFaultReportsScreen> {
  static const int _pageSize = 20;

  final CustomerFaultReportService _service = CustomerFaultReportService();
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;
  int _nextPage = 1;
  List<CustomerFaultReport> _items = const [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _service.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.fetchPage(page: 1, pageSize: _pageSize);
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _nextPage = 2;
        _hasMore = result.items.length >= _pageSize &&
            _items.length < result.totalCount;
        _loading = false;
      });
    } on CustomerFaultReportException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    setState(() => _loadingMore = true);

    try {
      final result = await _service.fetchPage(
        page: _nextPage,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...result.items];
        _nextPage += 1;
        final reachedEnd = result.items.length < _pageSize ||
            _items.length >= result.totalCount;
        _hasMore = !reachedEnd;
        _loadingMore = false;
      });
    } on CustomerFaultReportException catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _openNewReportDialog() async {
    final created = await showNewFaultReportDialog(context);
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prijava kvara je poslana.')),
      );
      await _loadFirstPage();
    }
  }

  Future<void> _openDetail(CustomerFaultReport report) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomerFaultReportDetailScreen(report: report),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prijave kvarova'),
        actions: [
          IconButton(
            tooltip: 'Nova prijava',
            onPressed: _loading ? null : _openNewReportDialog,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _error;
    if (error != null) {
      return _ErrorRetry(message: error, onRetry: _loadFirstPage);
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadFirstPage,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
            const _EmptyState(),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final report = _items[index];
          return _ReportCard(
            report: report,
            service: _service,
            onTap: () => _openDetail(report),
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.service,
    required this.onTap,
  });

  final CustomerFaultReport report;
  final CustomerFaultReportService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.30)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.report_problem_outlined,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            report.title.isEmpty ? '-' : report.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FaultReportStatusPill(status: report.status),
                    const SizedBox(height: 6),
                    _InfoRow(
                      icon: Icons.event_outlined,
                      label: _formatDate(report.createdAt),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ThumbnailPreview(reportId: report.id, service: service),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the first attached photo's thumbnail (fetches metadata, then the
/// bytes of the first photo, via [AuthenticatedImage]) or nothing when the
/// report has none.
class _ThumbnailPreview extends StatelessWidget {
  const _ThumbnailPreview({required this.reportId, required this.service});

  final int reportId;
  final CustomerFaultReportService service;

  Future<Uint8List?> _fetchFirstPhotoBytes() async {
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
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.report_problem_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            'Nemate poslanih prijava kvarova.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}. '
      '${two(date.hour)}:${two(date.minute)}';
}
