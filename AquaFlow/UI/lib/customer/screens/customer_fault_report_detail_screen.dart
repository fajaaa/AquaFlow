import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/customer/models/customer_fault_report.dart';
import 'package:aquaflow_desktop/customer/models/customer_fault_report_photo.dart';
import 'package:aquaflow_desktop/customer/services/customer_fault_report_exception.dart';
import 'package:aquaflow_desktop/customer/services/customer_fault_report_service.dart';
import 'package:aquaflow_desktop/customer/widgets/fault_report_status_pill.dart';
import 'package:aquaflow_desktop/shared/navigation/app_navigation.dart';
import 'package:aquaflow_desktop/shared/widgets/authenticated_image.dart';

/// Detail view of a single fault report belonging to the signed-in customer,
/// pushed from `CustomerFaultReportsScreen` as its own Scaffold+AppBar route
/// (same push pattern as `CustomerInvoiceDetailScreen`). Shows the full
/// description plus a grid of every attached photo
/// (`CustomerFaultReportService.fetchPhotos`, backend pins ownership to the
/// caller); tapping a thumbnail opens a fullscreen preview.
class CustomerFaultReportDetailScreen extends StatefulWidget {
  const CustomerFaultReportDetailScreen({super.key, required this.report});

  final CustomerFaultReport report;

  @override
  State<CustomerFaultReportDetailScreen> createState() =>
      _CustomerFaultReportDetailScreenState();
}

class _CustomerFaultReportDetailScreenState
    extends State<CustomerFaultReportDetailScreen> {
  final CustomerFaultReportService _service = CustomerFaultReportService();

  bool _loading = true;
  String? _error;
  List<CustomerFaultReportPhoto> _photos = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final photos = await _service.fetchPhotos(widget.report.id);
      if (!mounted) return;
      setState(() {
        _photos = photos;
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

  void _openFullscreen(CustomerFaultReportPhoto photo) {
    context.pushScreen(
      _FullscreenPhotoScreen(
        fileName: photo.fileName,
        fetcher: () => _service.fetchPhotoBytes(widget.report.id, photo.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    return Scaffold(
      appBar: AppBar(title: Text(report.title.isEmpty ? '-' : report.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeaderCard(report: report),
            const SizedBox(height: 12),
            _DescriptionCard(report: report),
            const SizedBox(height: 12),
            _buildPhotosSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final error = _error;
    if (error != null) {
      return _ErrorRetry(message: error, onRetry: _load);
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
                        _service.fetchPhotoBytes(widget.report.id, photo.id),
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

  final CustomerFaultReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            label: 'Naselje',
            value: report.settlementName.trim().isEmpty
                ? '-'
                : report.settlementName.trim(),
          ),
          if (report.address.isNotEmpty) ...[
            const SizedBox(height: 6),
            _KeyValueRow(label: 'Adresa', value: report.address),
          ],
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

  final CustomerFaultReport report;

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
