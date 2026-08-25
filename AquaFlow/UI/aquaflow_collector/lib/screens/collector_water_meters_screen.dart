import 'dart:async';

import 'package:flutter/material.dart';

import 'package:aquaflow_collector/l10n/app_localizations.dart';
import 'package:aquaflow_collector/models/collector_water_meter.dart';
import 'package:aquaflow_collector/screens/collector_fault_reports_screen.dart';
import 'package:aquaflow_collector/screens/collector_meter_reading_entry_screen.dart';
import 'package:aquaflow_collector/services/collector_water_meter_exception.dart';
import 'package:aquaflow_collector/services/collector_water_meter_service.dart';
import 'package:aquaflow_collector/shared/navigation/app_navigation.dart';
import 'package:aquaflow_collector/shared/widgets/empty_state_view.dart';
import 'package:aquaflow_collector/shared/widgets/error_retry.dart';
import 'package:aquaflow_collector/shared/widgets/list_skeleton.dart';
import 'package:aquaflow_collector/widgets/collector_water_meter_status_pill.dart';

/// "Vodomjeri" tab body: replaces the former "Očitanja" (reading route) tab.
/// A single debounced free-text box (`Term`) searches water meters by owner
/// name, naselje, serial number, or address (`WaterMeterSearchObject.Term`,
/// see `WaterMeterService.ApplyFilters`); tapping a result opens
/// [CollectorMeterReadingEntryScreen] to view the meter and record a reading.
///
/// Card styling mirrors `CustomerWaterMetersScreen`: a branded gradient bar
/// keyed to the meter's status, an accent-tinted status pill, and the same
/// skeleton/empty/error scaffolding (`ListSkeleton`/`EmptyStateView`/
/// `ErrorRetry`). The search-first flow itself (no listing until a term is
/// entered) is unique to this screen and unchanged.
///
/// Rendered inside [MobileShell], so it has no Scaffold/AppBar of its own.
class CollectorWaterMetersScreen extends StatefulWidget {
  const CollectorWaterMetersScreen({super.key});

  @override
  State<CollectorWaterMetersScreen> createState() =>
      _CollectorWaterMetersScreenState();
}

class _CollectorWaterMetersScreenState
    extends State<CollectorWaterMetersScreen> {
  final CollectorWaterMeterService _service = CollectorWaterMeterService();
  final TextEditingController _searchCtrl = TextEditingController();

  Timer? _searchDebounce;
  int _requestSerial = 0;
  bool _loading = false;
  bool _searched = false;
  String? _error;
  List<CollectorWaterMeter> _meters = const [];

  Future<void> _search() async {
    final term = _searchCtrl.text.trim();
    final requestId = ++_requestSerial;

    if (term.isEmpty) {
      setState(() {
        _searched = false;
        _loading = false;
        _error = null;
        _meters = const [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _searched = true;
      _error = null;
    });

    try {
      final meters = await _service.search(term);
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _meters = meters;
        _loading = false;
      });
    } on CollectorWaterMeterException catch (e) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _meters = const [];
        _loading = false;
        _error = e.message;
      });
    }
  }

  void _queueSearch(String _) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), _search);
  }

  void _clearSearch() {
    if (_searchCtrl.text.isEmpty) return;
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    _search();
  }

  Future<void> _openEntry(CollectorWaterMeter meter) async {
    await context.pushScreen(CollectorMeterReadingEntryScreen(meter: meter));
  }

  Future<void> _openFaultReports() async {
    await context.pushScreen(const CollectorFaultReportsScreen());
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
    final loc = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    loc.tabWaterMeters,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: loc.faultReportsTooltip,
                  onPressed: _openFaultReports,
                  icon: const Icon(Icons.report_problem_outlined),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              onChanged: _queueSearch,
              onSubmitted: (_) {
                _searchDebounce?.cancel();
                _search();
              },
              decoration: InputDecoration(
                hintText: loc.collectorMeterSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: loc.commonClear,
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (!_searched) {
      return const _PromptState();
    }

    if (_loading) {
      return ListSkeleton(
        itemBuilder: (context, index) =>
            _WaterMeterCard(meter: _skeletonMeter, onTap: () {}),
      );
    }

    final error = _error;
    if (error != null) {
      return ErrorRetry(message: error, onRetry: _search);
    }

    if (_meters.isEmpty) {
      return EmptyStateView(
        icon: Icons.water_drop_outlined,
        message: AppLocalizations.of(
          context,
        ).collectorMetersEmptyMessage(_searchCtrl.text.trim()),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _meters.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final meter = _meters[index];
        return _WaterMeterCard(meter: meter, onTap: () => _openEntry(meter));
      },
    );
  }
}

final _skeletonMeter = CollectorWaterMeter(
  id: 0,
  serialNumber: 'SN-0000000',
  customerId: 0,
  customerFirstName: 'Ime',
  customerLastName: 'Prezime',
  settlementId: 0,
  settlementName: 'Naselje',
  street: 'Ulica',
  houseNumber: '1',
  status: 'Active',
  lastReading: 0,
);

/// Mirrors `_WaterMeterCard` in `customer_water_meters_screen.dart`: rounded
/// branded card with a gradient status bar keyed to `meta.color`/`meta.icon`
/// and an accent-tinted status pill. Unlike the customer card (which shows
/// only settlement/address, since the meter is always the customer's own),
/// this card also surfaces the owning customer's name, since a collector
/// works across many customers' meters.
class _WaterMeterCard extends StatelessWidget {
  const _WaterMeterCard({required this.meter, required this.onTap});

  final CollectorWaterMeter meter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final loc = AppLocalizations.of(context);

    final meta = CollectorWaterMeterStatusMeta.of(meter.status, loc);
    final accent = _readableAccent(meta.color, theme.brightness);
    final needsAttention = meter.status.toLowerCase() == 'inactive';

    final owner = meter.customerFullName;
    final subtitle = [
      meter.settlementName,
      meter.address,
    ].where((part) => part.trim().isNotEmpty).join(', ');

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
                                meter.serialNumber,
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
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          owner.isEmpty ? '-' : owner,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          subtitle.isEmpty ? '-' : subtitle,
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
                              loc.collectorLastReadingLabel(
                                _formatReading(meter.lastReading),
                              ),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
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

  /// Mirrors `_readableAccent` in `customer_water_meters_screen.dart`: any
  /// accent dark enough to blend into the dark theme's background is lifted
  /// toward white there. Light theme and the brighter accents are returned
  /// unchanged.
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

class _PromptState extends StatelessWidget {
  const _PromptState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 14),
            Text(
              AppLocalizations.of(context).collectorMetersPromptMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatReading(double value) {
  final text = value.toStringAsFixed(2);
  return text.endsWith('.00')
      ? text.substring(0, text.length - 3)
      : text.replaceFirst(RegExp(r'0$'), '');
}
