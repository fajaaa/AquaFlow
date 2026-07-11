import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/collector/models/collector_fault_report.dart';
import 'package:aquaflow_desktop/collector/models/collector_fault_report_photo.dart';
import 'package:aquaflow_desktop/collector/services/collector_fault_report_exception.dart';
import 'package:aquaflow_desktop/collector/services/collector_fault_report_service.dart';
import 'package:aquaflow_desktop/collector/widgets/fault_report_status_pill.dart';
import 'package:aquaflow_desktop/shared/widgets/authenticated_image.dart';

const _statusLabels = <String, String>{
  'New': 'Nova',
  'Assigned': 'Dodijeljena',
  'InProgress': 'U toku',
  'Resolved': 'Riješena',
};

/// Detail view of a single fault report, pushed from
/// `CollectorFaultReportsScreen`. Shows the full description plus a grid of
/// every attached photo (same layout as `CustomerFaultReportDetailScreen`),
/// and a status-advance action ("Započni": Assigned -> InProgress, then
/// "Riješi": InProgress -> Resolved; hidden once Resolved - terminal, same
/// precedent as `AdminFaultReportsScreen`'s row action). The backend permits
/// this without `FaultReports.Manage` because the caller resolves to the
/// report's own `AssignedCollectorId`. On pop, the caller receives the
/// updated report (if any status change was made) so the list can be patched
/// in place without a full reload.
class CollectorFaultReportDetailScreen extends StatefulWidget {
  const CollectorFaultReportDetailScreen({super.key, required this.report});

  final CollectorFaultReport report;

  @override
  State<CollectorFaultReportDetailScreen> createState() =>
      _CollectorFaultReportDetailScreenState();
}

class _CollectorFaultReportDetailScreenState
    extends State<CollectorFaultReportDetailScreen> {
  final CollectorFaultReportService _service = CollectorFaultReportService();

  late CollectorFaultReport _report;
  bool _loadingPhotos = true;
  bool _updatingStatus = false;
  String? _photosError;
  List<CollectorFaultReportPhoto> _photos = const [];

  @override
  void initState() {
    super.initState();
    _report = widget.report;
    _loadPhotos();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _loadingPhotos = true;
      _photosError = null;
    });

    try {
      final photos = await _service.fetchPhotos(_report.id);
      if (!mounted) return;
      setState(() {
        _photos = photos;
        _loadingPhotos = false;
      });
    } on CollectorFaultReportException catch (e) {
      if (!mounted) return;
      setState(() {
        _photosError = e.message;
        _loadingPhotos = false;
      });
    }
  }

  Future<void> _advanceStatus() async {
    final next = _report.nextStatus;
    if (next == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Promjena statusa'),
        content: Text(
          'Postaviti status prijave na "${_statusLabels[next] ?? next}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Potvrdi'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _updatingStatus = true);
    try {
      // New/Assigned -> start, InProgress -> resolve; the backend state
      // machine stamps resolvedAt itself, so no date is sent from here.
      final updated = _report.isNew || _report.isAssigned
          ? await _service.start(_report.id)
          : await _service.resolve(_report.id);
      if (!mounted) return;
      setState(() {
        _report = updated;
        _updatingStatus = false;
      });
    } on CollectorFaultReportException catch (e) {
      if (!mounted) return;
      setState(() => _updatingStatus = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _openFullscreen(CollectorFaultReportPhoto photo) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullscreenPhotoScreen(
          fileName: photo.fileName,
          fetcher: () => _service.fetchPhotoBytes(_report.id, photo.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_report);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_report.title.isEmpty ? '-' : _report.title),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(report: _report),
              const SizedBox(height: 12),
              _DescriptionCard(report: _report),
              const SizedBox(height: 12),
              _buildPhotosSection(),
              const SizedBox(height: 12),
              _buildStatusAction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusAction() {
    final next = _report.nextStatus;
    if (next == null) {
      return const SizedBox.shrink();
    }

    final startsWork = next == 'InProgress';

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _updatingStatus ? null : _advanceStatus,
        icon: _updatingStatus
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                startsWork
                    ? Icons.engineering_outlined
                    : Icons.check_circle_outline,
              ),
        label: Text(startsWork ? 'Započni' : 'Riješi'),
      ),
    );
  }

  Widget _buildPhotosSection() {
    if (_loadingPhotos) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final error = _photosError;
    if (error != null) {
      return _ErrorRetry(message: error, onRetry: _loadPhotos);
    }

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Fotografije'),
          const SizedBox(height: 10),
          if (_photos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nema priloženih fotografija.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                final photo = _photos[index];
                return GestureDetector(
                  onTap: () => _openFullscreen(photo),
                  child: AuthenticatedImage(
                    fetcher: () =>
                        _service.fetchPhotoBytes(_report.id, photo.id),
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.report});

  final CollectorFaultReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customer = report.customerFullName;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.report_problem_outlined,
                size: 22,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  report.title.isEmpty ? '-' : report.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FaultReportStatusPill(status: report.status),
            ],
          ),
          const SizedBox(height: 10),
          _KeyValueRow(
            label: 'Kupac',
            value: customer.isEmpty ? 'Korisnik #${report.customerId}' : customer,
          ),
          const SizedBox(height: 6),
          _KeyValueRow(
            label: 'Naselje',
            value: report.settlementName.isEmpty ? '-' : report.settlementName,
          ),
          const SizedBox(height: 6),
          _KeyValueRow(label: 'Prijavljeno', value: _formatDate(report.createdAt)),
          if (report.resolvedAt != null) ...[
            const SizedBox(height: 6),
            _KeyValueRow(
              label: 'Riješeno',
              value: _formatDate(report.resolvedAt),
            ),
          ],
        ],
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.report});

  final CollectorFaultReport report;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Opis'),
          const SizedBox(height: 10),
          Text(
            report.description.isEmpty ? '-' : report.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

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
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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

class _FullscreenPhotoScreen extends StatelessWidget {
  const _FullscreenPhotoScreen({required this.fileName, required this.fetcher});

  final String fileName;
  final Future<Uint8List> Function() fetcher;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(fileName),
      ),
      body: Center(
        child: InteractiveViewer(
          child: AuthenticatedImage(fetcher: fetcher, fit: BoxFit.contain),
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
