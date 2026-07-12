import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/customer/models/customer_water_meter.dart';
import 'package:aquaflow_desktop/customer/screens/customer_fault_reports_screen.dart';
import 'package:aquaflow_desktop/customer/screens/customer_requests_screen.dart';
import 'package:aquaflow_desktop/customer/services/customer_water_meter_exception.dart';
import 'package:aquaflow_desktop/customer/services/customer_water_meter_service.dart';
import 'package:aquaflow_desktop/customer/widgets/new_water_meter_request_dialog.dart';

/// "Vodomjeri" tab body: lists the signed-in customer's own water meters and
/// lets them file a new-meter request (the "+" action) or open the full
/// [CustomerRequestsScreen] (the "Zahtjevi" action). The requests themselves no
/// longer render inline here - they live on their own screen.
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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CustomerRequestsScreen(),
      ),
    );
  }

  Future<void> _openFaultReports() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CustomerFaultReportsScreen(),
      ),
    );
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
                IconButton(
                  tooltip: 'Osvježi',
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          Expanded(child: _buildContent()),
        ],
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

    if (_meters.isEmpty) {
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: _meters.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) =>
            _WaterMeterCard(meter: _meters[index]),
      ),
    );
  }
}

class _WaterMeterCard extends StatelessWidget {
  const _WaterMeterCard({required this.meter});

  final CustomerWaterMeter meter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final address = meter.address;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.30)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    meter.serialNumber,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusPill(status: meter.status),
              ],
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: meter.settlementName.isEmpty ? '-' : meter.settlementName,
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.home_outlined,
              label: address.isEmpty ? '-' : address,
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.speed_outlined,
              label:
                  'Zadnje očitanje: ${meter.lastReading.toStringAsFixed(2)} m³',
            ),
          ],
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final isActive = normalized == 'active' || normalized == 'aktivan';
    final color = isActive ? const Color(0xFF2E7D32) : const Color(0xFF64748B);
    final icon = isActive ? Icons.check_circle_outline : Icons.cancel_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            status.isEmpty ? '-' : status,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
            Icons.water_drop_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            'Trenutno nemate evidentiranih vodomjera.',
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
