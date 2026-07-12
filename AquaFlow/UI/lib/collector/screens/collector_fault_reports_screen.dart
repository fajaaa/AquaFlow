import 'dart:async';

import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/collector/models/collector_fault_report.dart';
import 'package:aquaflow_desktop/collector/screens/collector_fault_report_detail_screen.dart';
import 'package:aquaflow_desktop/collector/services/collector_fault_report_exception.dart';
import 'package:aquaflow_desktop/collector/services/collector_fault_report_service.dart';
import 'package:aquaflow_desktop/collector/widgets/fault_report_status_pill.dart';
import 'package:aquaflow_desktop/shared/navigation/app_navigation.dart';

// No 'New' option: a New report is by definition not yet assigned, so the
// pinned listing below can never contain one.
const _statusOptions = <String, String>{
  '': 'Svi statusi',
  'Assigned': 'Dodijeljena',
  'InProgress': 'U toku',
  'Resolved': 'Riješena',
};

/// Pushed as its own Scaffold+AppBar route (from a header action on one of
/// the collector's mobile tabs) rather than added as a 5th `MobileShell` tab -
/// same precedent as `CustomerFaultReportsScreen` on the customer side, which
/// keeps the fixed 4-tab bottom nav intact.
///
/// Lists only the reports assigned to the signed-in collector: the backend
/// pins `AssignedCollectorId` to the caller's own `CollectorProfile` (same
/// model as `WaterMeterRequest`'s "assigned to me" - the query here sends
/// nothing extra). A debounced `Term` search plus a status filter both
/// re-query the backend, same template as `CollectorWaterMetersScreen`'s
/// search box; tap a card to open the detail screen.
class CollectorFaultReportsScreen extends StatefulWidget {
  const CollectorFaultReportsScreen({super.key});

  @override
  State<CollectorFaultReportsScreen> createState() =>
      _CollectorFaultReportsScreenState();
}

class _CollectorFaultReportsScreenState
    extends State<CollectorFaultReportsScreen> {
  final CollectorFaultReportService _service = CollectorFaultReportService();
  final TextEditingController _searchCtrl = TextEditingController();

  Timer? _searchDebounce;
  int _requestSerial = 0;
  bool _loading = true;
  String? _error;
  String _status = '';
  List<CollectorFaultReport> _reports = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final requestId = ++_requestSerial;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final page = await _service.fetch(
        page: 1,
        pageSize: 100,
        term: _searchCtrl.text.trim(),
        status: _status,
      );
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _reports = page.items;
        _loading = false;
      });
    } on CollectorFaultReportException catch (e) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _reports = const [];
        _loading = false;
        _error = e.message;
      });
    }
  }

  void _queueSearch(String _) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), _load);
  }

  void _clearSearch() {
    if (_searchCtrl.text.isEmpty) return;
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    _load();
  }

  void _onStatusChanged(String? value) {
    if (value == null || value == _status) return;
    setState(() => _status = value);
    _load();
  }

  Future<void> _openDetail(CollectorFaultReport report) async {
    final updated = await context.pushScreen<CollectorFaultReport>(
      CollectorFaultReportDetailScreen(report: report),
    );
    if (!mounted || updated == null) return;
    setState(() {
      _reports = [
        for (final r in _reports)
          if (r.id == updated.id) updated else r,
      ];
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prijave kvarova')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                onChanged: _queueSearch,
                onSubmitted: (_) {
                  _searchDebounce?.cancel();
                  _load();
                },
                decoration: InputDecoration(
                  hintText: 'Naslov ili ime kupca',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Obriši',
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: DropdownButton<String>(
                  value: _status,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final entry in _statusOptions.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                  ],
                  onChanged: _onStatusChanged,
                ),
              ),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _error;
    if (error != null) {
      return _ErrorRetry(message: error, onRetry: _load);
    }

    if (_reports.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
            const _EmptyState(),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: _reports.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final report = _reports[index];
          return _FaultReportCard(
            report: report,
            onTap: () => _openDetail(report),
          );
        },
      ),
    );
  }
}

class _FaultReportCard extends StatelessWidget {
  const _FaultReportCard({required this.report, required this.onTap});

  final CollectorFaultReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customer = report.customerFullName;
    final location = [
      report.settlementName.trim(),
      report.address,
    ].where((part) => part.isNotEmpty).join(', ');

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
                    ),
                  ),
                  FaultReportStatusPill(status: report.status),
                ],
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.person_outline,
                // customerId is null when the reporter had no CustomerProfile.
                label: customer.isNotEmpty
                    ? customer
                    : report.customerId == null
                        ? '-'
                        : 'Korisnik #${report.customerId}',
              ),
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: location.isEmpty ? '-' : location,
              ),
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.event_outlined,
                label: 'Prijavljeno: ${_formatDate(report.createdAt)}',
              ),
            ],
          ),
        ),
      ),
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
            'Nema prijava kvarova.',
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
