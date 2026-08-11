import 'package:flutter/material.dart';

import 'package:aquaflow_customer/models/customer_water_meter.dart';
import 'package:aquaflow_customer/screens/customer_fault_reports_screen.dart';
import 'package:aquaflow_customer/screens/customer_requests_screen.dart';
import 'package:aquaflow_customer/screens/customer_water_meter_detail_screen.dart';
import 'package:aquaflow_customer/services/customer_water_meter_exception.dart';
import 'package:aquaflow_customer/services/customer_water_meter_service.dart';
import 'package:aquaflow_customer/widgets/new_water_meter_request_dialog.dart';
import 'package:aquaflow_customer/widgets/water_meter_status_pill.dart';
import 'package:aquaflow_customer/shared/navigation/app_navigation.dart';
import 'package:aquaflow_customer/shared/widgets/async_state_view.dart';
import 'package:aquaflow_customer/shared/widgets/empty_state_view.dart';
import 'package:aquaflow_customer/shared/widgets/list_skeleton.dart';
import 'package:aquaflow_customer/shared/widgets/refresh_button.dart';

/// "Vodomjeri" tab body: lists the signed-in customer's own water meters and
/// lets them file a new-meter request (the "+" action) or open the full
/// [CustomerRequestsScreen] (the "Zahtjevi" action). The requests themselves no
/// longer render inline here - they live on their own screen.
///
/// Card styling mirrors `NotificationsScreen`: a branded gradient bar keyed
/// to the meter's status, an accent-tinted status pill, and the same
/// loading/empty/error scaffolding (`AsyncStateView`/`ListSkeleton`/
/// `EmptyStateView`). Cards are tappable, pushing
/// [CustomerWaterMeterDetailScreen] and reloading on return so the status/
/// last-reading reflect anything that changed there (e.g. a payment).
///
/// Rendered inside [MobileShell], so it has no Scaffold/AppBar of its own.
class CustomerWaterMetersScreen extends StatefulWidget {
  const CustomerWaterMetersScreen({super.key});

  @override
  State<CustomerWaterMetersScreen> createState() =>
      _CustomerWaterMetersScreenState();
}

class _CustomerWaterMetersScreenState extends State<CustomerWaterMetersScreen> {
  final CustomerWaterMeterService _service = CustomerWaterMeterService();

  bool _loading = true;
  String? _error;
  List<CustomerWaterMeter> _meters = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final meters = await _service.fetchMine();
      if (!mounted) return;
      setState(() {
        _meters = meters;
        _loading = false;
      });
    } on CustomerWaterMeterException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _openNewRequestDialog() async {
    final created = await showNewWaterMeterRequestDialog(context);
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zahtjev za novi vodomjer je poslan.')),
      );
      await _load();
    }
  }

  Future<void> _openRequests() async {
    await context.pushScreen(const CustomerRequestsScreen());
  }

  Future<void> _openFaultReports() async {
    await context.pushScreen(const CustomerFaultReportsScreen());
  }

  Future<void> _openMeterDetail(CustomerWaterMeter meter) async {
    await context.pushScreen(CustomerWaterMeterDetailScreen(meter: meter));
    if (!mounted) return;
    await _load();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Vodomjeri',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Zahtjevi',
                  onPressed: _openRequests,
                  icon: const Icon(Icons.receipt_long_outlined),
                ),
                IconButton(
                  tooltip: 'Prijave kvarova',
                  onPressed: _openFaultReports,
                  icon: const Icon(Icons.report_problem_outlined),
                ),
                IconButton(
                  tooltip: 'Dodaj vodomjer',
                  onPressed: _loading ? null : _openNewRequestDialog,
                  icon: const Icon(Icons.add),
                ),
                RefreshButton(onRefresh: _load, enabled: !_loading),
              ],
            ),
          ),
          if (_loading && _meters.isNotEmpty)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return AsyncStateView(
      loading: _loading && _meters.isEmpty,
      error: _error,
      onRetry: _load,
      loadingBuilder: (context) => ListSkeleton(
        itemBuilder: (context, index) => _WaterMeterCard(meter: _skeletonMeter),
      ),
      builder: (context) {
        if (_meters.isEmpty) {
          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
                const EmptyStateView(
                  icon: Icons.water_drop_outlined,
                  message: 'Trenutno nemate evidentiranih vodomjera.',
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: _meters.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _WaterMeterCard(
              meter: _meters[index],
              onTap: () => _openMeterDetail(_meters[index]),
            ),
          ),
        );
      },
    );
  }
}

final _skeletonMeter = CustomerWaterMeter(
  id: 0,
  serialNumber: 'SN-0000000',
  settlementId: 0,
  settlementName: 'Naselje',
  street: 'Ulica',
  houseNumber: '1',
  installedAt: null,
  status: 'Active',
  initialReading: 0,
  lastReading: 0,
);

class _WaterMeterCard extends StatelessWidget {
  const _WaterMeterCard({required this.meter, this.onTap});

  final CustomerWaterMeter meter;

  /// Null for the skeleton placeholder card, which isn't tappable.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    final meta = WaterMeterStatusMeta.of(meter.status);
    final accent = _readableAccent(meta.color, theme.brightness);
    // Inactive is the meter's "needs attention" state, same role
    // `isPayable` plays for an invoice card / `!isRead` plays for a
    // notification card.
    final needsAttention = meter.status.toLowerCase() == 'inactive';

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
                              'Zadnje očitanje: ${meter.lastReading.toStringAsFixed(2)} m³',
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
