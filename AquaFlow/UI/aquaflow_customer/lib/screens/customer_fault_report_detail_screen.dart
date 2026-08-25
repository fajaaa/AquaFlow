import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:aquaflow_customer/l10n/app_localizations.dart';
import 'package:aquaflow_customer/models/customer_fault_report.dart';
import 'package:aquaflow_customer/models/customer_fault_report_photo.dart';
import 'package:aquaflow_customer/services/customer_fault_report_exception.dart';
import 'package:aquaflow_customer/services/customer_fault_report_service.dart';
import 'package:aquaflow_customer/shared/navigation/app_navigation.dart';
import 'package:aquaflow_customer/shared/theme/app_theme.dart';
import 'package:aquaflow_customer/shared/widgets/authenticated_image.dart';

/// Icon + accent color + label for a fault report `status`, covering the
/// backend `FaultReport.Status` values (New/Assigned/InProgress/Resolved).
/// Mirrors the status palette used by the report cards on
/// `CustomerFaultReportsScreen` so the banner here and the list stay in sync.
class _StatusMeta {
  const _StatusMeta(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

/// Detail view of a single fault report belonging to the signed-in customer,
/// pushed from `CustomerFaultReportsScreen` as its own Scaffold+AppBar route
/// (same push pattern as `CustomerInvoiceDetailScreen`). Layout mirrors
/// `CustomerWaterMeterDetailScreen`/`NotificationDetailScreen`: a full-width
/// status banner up top, then centered content sections. Shows the full
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);

    final meta = _metaFor(report.status, loc);
    final accent = _readableAccent(meta.color, theme.brightness);
    final onAccent =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? Colors.white
        : AppColors.textDark;

    return Scaffold(
      appBar: AppBar(title: Text(report.title.isEmpty ? '-' : report.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status banner - full-width strip across the top, same
              // treatment as NotificationDetailScreen/CustomerWaterMeterDetailScreen.
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
                          loc.faultReportStatusFieldLabel.toUpperCase(),
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
                    _HeaderCard(report: report, accent: accent),
                    const SizedBox(height: 16),
                    _InfoCard(report: report, accent: accent),
                    const SizedBox(height: 16),
                    _DescriptionCard(report: report, accent: accent),
                    const SizedBox(height: 16),
                    _buildPhotosSection(accent),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotosSection(Color accent) {
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

    final loc = AppLocalizations.of(context);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            loc.photosSectionHeading,
            icon: Icons.photo_library_outlined,
            color: accent,
          ),
          const SizedBox(height: 10),
          if (_photos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                loc.noPhotosMessage,
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
                        _service.fetchPhotoBytes(widget.report.id, photo.id),
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  static _StatusMeta _metaFor(String status, AppLocalizations loc) {
    switch (status.toLowerCase()) {
      case 'new':
        return _StatusMeta(
          loc.faultReportStatusNew,
          Icons.fiber_new_outlined,
          const Color(0xFFB45309),
        );
      case 'assigned':
        return _StatusMeta(
          loc.faultReportStatusAssigned,
          Icons.assignment_ind_outlined,
          const Color(0xFF6D28D9),
        );
      case 'inprogress':
        return _StatusMeta(
          loc.faultReportStatusInProgress,
          Icons.engineering_outlined,
          const Color(0xFF1D4ED8),
        );
      case 'resolved':
        return _StatusMeta(
          loc.faultReportStatusResolved,
          Icons.check_circle_outline,
          const Color(0xFF2E7D32),
        );
      default:
        return _StatusMeta(status, Icons.help_outline, const Color(0xFF64748B));
    }
  }

  /// Mirrors `_readableAccent` in notification_detail_screen.dart: any accent
  /// dark enough to blend into the dark theme's background is lifted toward
  /// white there. Light theme and the brighter accents are returned unchanged.
  static Color _readableAccent(Color base, Brightness brightness) {
    if (brightness == Brightness.dark && base.computeLuminance() < 0.2) {
      return Color.lerp(base, Colors.white, 0.6)!;
    }
    return base;
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.report, required this.accent});

  final CustomerFaultReport report;
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

  final CustomerFaultReport report;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            loc.faultReportInfoSectionHeading,
            icon: Icons.info_outline,
            color: accent,
          ),
          const SizedBox(height: 10),
          _KeyValueRow(
            label: loc.locationSettlementLabel,
            value: report.settlementName.trim().isEmpty
                ? '-'
                : report.settlementName.trim(),
          ),
          if (report.address.isNotEmpty) ...[
            const SizedBox(height: 6),
            _KeyValueRow(label: loc.addressLabel, value: report.address),
          ],
          const SizedBox(height: 6),
          _KeyValueRow(
            label: loc.reportedAtLabel,
            value: _formatDate(report.createdAt),
          ),
          if (report.resolvedAt != null) ...[
            const SizedBox(height: 6),
            _KeyValueRow(
              label: loc.resolvedAtLabel,
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

  final CustomerFaultReport report;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            AppLocalizations.of(context).notificationDetailDescriptionHeading,
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

/// Mirrors `_Card` in notification_detail_screen.dart so a fault report's
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

/// Mirrors `_SectionHeading` in customer_invoice_detail_screen.dart.
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
              label: Text(AppLocalizations.of(context).commonRetry),
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
