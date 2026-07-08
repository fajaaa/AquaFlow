import 'dart:async';

import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/collector/models/collector_water_meter.dart';
import 'package:aquaflow_desktop/collector/screens/collector_meter_reading_entry_screen.dart';
import 'package:aquaflow_desktop/collector/services/collector_water_meter_exception.dart';
import 'package:aquaflow_desktop/collector/services/collector_water_meter_service.dart';

/// "Vodomjeri" tab body: replaces the former "Očitanja" (reading route) tab.
/// A single debounced free-text box (`Term`) searches water meters by owner
/// name, naselje, serial number, or address (`WaterMeterSearchObject.Term`,
/// see `WaterMeterService.ApplyFilters`); tapping a result opens
/// [CollectorMeterReadingEntryScreen] to view the meter and record a reading.
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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CollectorMeterReadingEntryScreen(meter: meter),
      ),
    );
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
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Vodomjeri',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
                hintText: 'Ime vlasnika, naselje, serijski broj ili adresa',
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
      return const Center(child: CircularProgressIndicator());
    }

    final error = _error;
    if (error != null) {
      return _ErrorRetry(message: error, onRetry: _search);
    }

    if (_meters.isEmpty) {
      return _EmptyState(term: _searchCtrl.text.trim());
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _meters.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final meter = _meters[index];
        return _WaterMeterCard(
          meter: meter,
          onTap: () => _openEntry(meter),
        );
      },
    );
  }
}

class _WaterMeterCard extends StatelessWidget {
  const _WaterMeterCard({required this.meter, required this.onTap});

  final CollectorWaterMeter meter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final owner = meter.customerFullName;
    final address = meter.address;

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
                    Icons.water_drop_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      meter.serialNumber,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.person_outline,
                label: owner.isEmpty ? '-' : owner,
              ),
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: meter.settlementName.isEmpty
                    ? '-'
                    : meter.settlementName,
              ),
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.home_outlined,
                label: address.isEmpty ? '-' : address,
              ),
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.speed_outlined,
                label: 'Zadnje stanje: ${_formatReading(meter.lastReading)} m³',
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
              'Unesite ime vlasnika, naselje, serijski broj ili adresu.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.term});

  final String term;

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
              Icons.water_drop_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 14),
            Text(
              'Nema vodomjera za "$term".',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
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

String _formatReading(double value) {
  final text = value.toStringAsFixed(2);
  return text.endsWith('.00')
      ? text.substring(0, text.length - 3)
      : text.replaceFirst(RegExp(r'0$'), '');
}
