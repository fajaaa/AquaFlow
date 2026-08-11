import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:aquaflow_collector/models/collector_fault_report.dart';
import 'package:aquaflow_collector/models/collector_fault_report_photo.dart';
import 'package:aquaflow_collector/services/collector_fault_report_exception.dart';
import 'package:aquaflow_collector/services/collector_fault_report_service.dart';
import 'package:aquaflow_collector/shared/navigation/app_navigation.dart';
import 'package:aquaflow_collector/shared/theme/app_theme.dart';
import 'package:aquaflow_collector/shared/widgets/authenticated_image.dart';

const _statusLabels = <String, String>{
  'New': 'Nova',
  'Assigned': 'Dodijeljena',
  'InProgress': 'U toku',
  'Resolved': 'Riješena',
};

/// Icon + accent color + label for a fault report `status`, covering the
/// backend `FaultReport.Status` values (New/Assigned/InProgress/Resolved).
/// Mirrors `FaultReportStatusPill`'s palette so the banner here and the pill
/// on `CollectorFaultReportsScreen` stay in sync.
class _StatusMeta {
  const _StatusMeta(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

/// Detail view of a single fault report, pushed from
/// `CollectorFaultReportsScreen`. Layout mirrors the customer app's
/// `CustomerFaultReportDetailScreen`/`CustomerWaterMeterDetailScreen`: a
/// full-width status banner up top, then centered content sections. Shows
/// the full description plus a grid of every attached photo, and a
/// status-advance action ("Započni": Assigned -> InProgress, then "Riješi":
/// InProgress -> Resolved; hidden once Resolved - terminal, same precedent
/// as `AdminFaultReportsScreen`'s row action). The backend permits this
/// without `FaultReports.Manage` because the caller resolves to the report's
/// own `AssignedCollectorId`. On pop, the caller receives the updated report
/// (if any status change was made) so the list can be patched in place
/// without a full reload.
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
    context.pushScreen(
      _FullscreenPhotoScreen(
        fileName: photo.fileName,
        fetcher: () => _service.fetchPhotoBytes(_report.id, photo.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final meta = _metaFor(_report.status);
    final accent = _readableAccent(meta.color, theme.brightness);
    final onAccent =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? Colors.white
        : AppColors.textDark;

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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status banner - full-width strip across the top, same
                // treatment as the customer app's detail screens.
                Container(
                  width: double.infinity,
                  color: accent.withValues(alpha: 0.10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(meta.icon, color: onAccent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STATUS PRIJAVE',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            meta.label,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeaderCard(report: _report, accent: accent),
                      const SizedBox(height: 16),
                      _InfoCard(report: _report, accent: accent),
                      const SizedBox(height: 16),
                      _DescriptionCard(report: _report, accent: accent),
                      const SizedBox(height: 16),
                      _buildPhotosSection(accent),
                      const SizedBox(height: 16),
                      _buildStatusAction(),
                    ],
                  ),
                ),
              ],
            ),
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

  Widget _buildPhotosSection(Color accent) {
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
          _SectionHeading(
            'Fotografije',
            icon: Icons.photo_library_outlined,
            color: accent,
          ),
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
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                final photo = _photos[index];
                return GestureDetector(
                  onTap: () => _openFullscreen(photo),
                  child: AuthenticatedImage(
                    fetcher: () =>
                        _service.fetchPhotoBytes(_report.id, photo.id),
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  static _StatusMeta _metaFor(String status) {
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

  /// Mirrors the customer app's `_readableAccent`: any accent dark enough to
  /// blend into the dark theme's background is lifted toward white there.
  /// Light theme and the brighter accents are returned unchanged.
  static Color _readableAccent(Color base, Brightness brightness) {
    if (brightness == Brightness.dark && base.computeLuminance() < 0.2) {
      return Color.lerp(base, Colors.white, 0.6)!;
    }
    return base;
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.report, required this.accent});

  final CollectorFaultReport report;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      child: Text(
        report.title.isEmpty ? '-' : report.title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: accent,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.report, required this.accent});

  final CollectorFaultReport report;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final customer = report.customerFullName;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            'Podaci o prijavi',
            icon: Icons.info_outline,
            color: accent,
          ),
          const SizedBox(height: 10),
          _KeyValueRow(
            label: 'Kupac',
            // customerId is null when the reporter had no CustomerProfile.
            value: customer.isNotEmpty
                ? customer
                : report.customerId == null
                ? '-'
                : 'Korisnik #${report.customerId}',
          ),
          const SizedBox(height: 6),
          _KeyValueRow(
            label: 'Naselje',
            value: report.settlementName.isEmpty ? '-' : report.settlementName,
          ),
          if (report.address.isNotEmpty) ...[
            const SizedBox(height: 6),
            _KeyValueRow(label: 'Adresa', value: report.address),
          ],
          const SizedBox(height: 6),
          _KeyValueRow(
            label: 'Prijavljeno',
            value: _formatDate(report.createdAt),
          ),
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
  const _DescriptionCard({required this.report, required this.accent});

  final CollectorFaultReport report;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            'Opis',
            icon: Icons.description_outlined,
            color: accent,
          ),
          const SizedBox(height: 10),
          Text(
            report.description.isEmpty ? '-' : report.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.55,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mirrors the customer app's `_SectionCard`/`_Card` so a fault report's
/// sections use the same rounded/bordered/shadowed card.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.white
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE1EDF7)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text, {required this.icon, required this.color});

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          text.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: color,
          ),
        ),
      ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          textAlign: TextAlign.end,
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
