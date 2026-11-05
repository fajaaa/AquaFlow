import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'package:aquaflow_desktop/l10n/app_localizations.dart';
import 'package:aquaflow_desktop/services/admin_report_exception.dart';
import 'package:aquaflow_desktop/services/admin_report_service.dart';
import 'package:aquaflow_desktop/shared/models/city_lookup.dart';
import 'package:aquaflow_desktop/shared/services/location_lookup_service.dart';
import 'package:aquaflow_desktop/shared/widgets/screen_header.dart';

/// Admin "Izvještaji" screen: shared date range + city filters and one card
/// per backend PDF report, each with download and print actions.
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

enum _Report { consumption, billing }

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  late DateTimeRange _range = _defaultRange();
  int? _cityId;
  List<CityLookup> _cities = [];
  _Report? _loading;

  final _service = AdminReportService();
  final _locationService = LocationLookupService();

  static DateTimeRange _defaultRange() {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month, now.day),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  @override
  void dispose() {
    _service.dispose();
    _locationService.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    try {
      final cities = await _locationService.fetchCities();
      if (!mounted) return;
      setState(() => _cities = cities);
    } catch (_) {
      // Non-fatal: only "Svi gradovi" stays available.
    }
  }

  String _two(int v) => v.toString().padLeft(2, '0');
  String _iso(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
  String _display(DateTime d) => '${_two(d.day)}.${_two(d.month)}.${d.year}.';

  Future<Uint8List?> _fetch(_Report report) async {
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (_range.start.isAfter(_range.end)) {
      messenger.showSnackBar(SnackBar(content: Text(loc.reportsInvalidRange)));
      return null;
    }
    setState(() => _loading = report);
    try {
      return report == _Report.consumption
          ? await _service.fetchConsumptionPdf(
              _range.start,
              _range.end,
              _cityId,
            )
          : await _service.fetchBillingPdf(_range.start, _range.end, _cityId);
    } on AdminReportException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return null;
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
      return null;
    } finally {
      if (mounted) setState(() => _loading = null);
    }
  }

  String _fileName(_Report report) {
    final prefix = report == _Report.consumption ? 'potrosnja' : 'naplata';
    return 'izvjestaj-$prefix-${_iso(_range.start)}_${_iso(_range.end)}.pdf';
  }

  Future<void> _download(_Report report) async {
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final bytes = await _fetch(report);
    if (bytes == null || !mounted) return;
    try {
      final location = await getSaveLocation(
        suggestedName: _fileName(report),
        acceptedTypeGroups: const [
          XTypeGroup(label: 'PDF', extensions: ['pdf']),
        ],
      );
      if (location == null) return;
      await File(location.path).writeAsBytes(bytes);
      messenger.showSnackBar(
        SnackBar(content: Text(loc.reportsSavedTo(location.path))),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _print(_Report report) async {
    final messenger = ScaffoldMessenger.of(context);
    final bytes = await _fetch(report);
    if (bytes == null || !mounted) return;
    try {
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: _fileName(report),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(
            title: loc.reportsScreenTitle,
            subtitle: loc.reportsScreenSubtitle,
            actions: const [],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(
                  '${_display(_range.start)} – ${_display(_range.end)}',
                ),
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(now.year - 5),
                    lastDate: DateTime(now.year, now.month, now.day),
                    initialDateRange: _range,
                  );
                  if (picked != null) setState(() => _range = picked);
                },
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<int?>(
                  initialValue: _cityId,
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
                    for (final city in _cities)
                      DropdownMenuItem(value: city.id, child: Text(city.name)),
                  ],
                  onChanged: (v) => setState(() => _cityId = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _ReportCard(
                title: loc.reportsConsumptionTitle,
                description: loc.reportsConsumptionDescription,
                busy: _loading == _Report.consumption,
                onDownload: () => _download(_Report.consumption),
                onPrint: () => _print(_Report.consumption),
              ),
              _ReportCard(
                title: loc.reportsBillingTitle,
                description: loc.reportsBillingDescription,
                busy: _loading == _Report.billing,
                onDownload: () => _download(_Report.billing),
                onPrint: () => _print(_Report.billing),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.title,
    required this.description,
    required this.busy,
    required this.onDownload,
    required this.onPrint,
  });

  final String title;
  final String description;
  final bool busy;
  final VoidCallback onDownload;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    return SizedBox(
      width: 420,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: busy ? null : onDownload,
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(loc.reportsDownloadPdf),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: busy ? null : onPrint,
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: Text(loc.reportsPrint),
                  ),
                  if (busy) ...[
                    const SizedBox(width: 12),
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
