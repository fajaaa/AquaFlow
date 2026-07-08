import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aquaflow_desktop/collector/models/collector_billing_cycle.dart';
import 'package:aquaflow_desktop/collector/models/collector_water_meter.dart';
import 'package:aquaflow_desktop/collector/services/collector_meter_reading_exception.dart';
import 'package:aquaflow_desktop/collector/services/collector_meter_reading_service.dart';

/// Meter detail + reading entry, pushed when a collector taps a result on
/// [CollectorWaterMetersScreen]. Submits via
/// `POST /MeterReadings/collector-entry`
/// (`CollectorMeterReadingService.submit`) - the server resolves the
/// collector, the billing cycle, and the previous reading itself, so this
/// form only collects the new reading value, an optional note (required when
/// the value is lower than the meter's last reading, e.g. a meter
/// replacement/reset) and an optional photo URL. On open it looks up the
/// current Open billing period and whether this meter already has a reading
/// in it, so a duplicate is flagged before the collector fills anything in -
/// the server still rejects a duplicate/missing-period submit independently,
/// this is just an upfront heads-up.
class CollectorMeterReadingEntryScreen extends StatefulWidget {
  const CollectorMeterReadingEntryScreen({super.key, required this.meter});

  final CollectorWaterMeter meter;

  @override
  State<CollectorMeterReadingEntryScreen> createState() =>
      _CollectorMeterReadingEntryScreenState();
}

class _CollectorMeterReadingEntryScreenState
    extends State<CollectorMeterReadingEntryScreen> {
  final CollectorMeterReadingService _service = CollectorMeterReadingService();
  final _formKey = GlobalKey<FormState>();
  final _readingCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _photoUrlCtrl = TextEditingController();

  bool _submitting = false;
  String? _error;

  bool _loadingPeriod = true;
  CollectorBillingCycle? _currentCycle;
  bool _alreadyRead = false;
  String? _periodError;

  @override
  void initState() {
    super.initState();
    _loadPeriodStatus();
  }

  @override
  void dispose() {
    _readingCtrl.dispose();
    _noteCtrl.dispose();
    _photoUrlCtrl.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadPeriodStatus() async {
    setState(() {
      _loadingPeriod = true;
      _periodError = null;
    });

    try {
      final cycle = await _service.fetchCurrentCycle();
      final alreadyRead = cycle == null
          ? false
          : await _service.hasReadingForCycle(
              waterMeterId: widget.meter.id,
              billingCycleId: cycle.id,
            );
      if (!mounted) return;
      setState(() {
        _currentCycle = cycle;
        _alreadyRead = alreadyRead;
        _loadingPeriod = false;
      });
    } on CollectorMeterReadingException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPeriod = false;
        _periodError = e.message;
      });
    }
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await _service.submit(
        waterMeterId: widget.meter.id,
        readingValue: double.parse(_readingCtrl.text.trim().replaceAll(',', '.')),
        note: _noteCtrl.text,
        photoUrl: _photoUrlCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Očitanje je snimljeno. Potrošnja: '
            '${_formatReading(result.consumptionM3)} m³.',
          ),
        ),
      );
    } on CollectorMeterReadingException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    }
  }

  String? _readingValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Obavezno polje.';
    final parsed = double.tryParse(text.replaceAll(',', '.'));
    if (parsed == null || parsed < 0) return 'Unesite pozitivan broj.';
    return null;
  }

  String get _periodLabel {
    if (_loadingPeriod) return 'učitavanje...';
    if (_periodError != null) return 'greška pri učitavanju';
    final cycle = _currentCycle;
    if (cycle == null) return 'nema otvorenog perioda';
    return '${cycle.name} (${_formatDate(cycle.periodFrom)} - '
        '${_formatDate(cycle.periodTo)})';
  }

  @override
  Widget build(BuildContext context) {
    final meter = widget.meter;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(meter.serialNumber)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      icon: Icons.person_outline,
                      label: meter.customerFullName.isEmpty
                          ? '-'
                          : meter.customerFullName,
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: meter.settlementName.isEmpty
                          ? '-'
                          : meter.settlementName,
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.home_outlined,
                      label: meter.address.isEmpty ? '-' : meter.address,
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.speed_outlined,
                      label:
                          'Zadnje stanje: ${_formatReading(meter.lastReading)} m³',
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.event_outlined,
                      label: 'Tekući period: $_periodLabel',
                    ),
                  ],
                ),
              ),
            ),
            if (_alreadyRead) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ovaj vodomjer je već očitan u tekućem periodu. '
                        'Novo očitanje za isti period nije moguće.',
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'Novo očitanje',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _readingCtrl,
                    enabled: !_alreadyRead,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    validator: _readingValidator,
                    decoration: const InputDecoration(
                      labelText: 'Novo stanje (m³)',
                      prefixIcon: Icon(Icons.speed_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _noteCtrl,
                    enabled: !_alreadyRead,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Napomena (obavezno ako je stanje niže)',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _photoUrlCtrl,
                    enabled: !_alreadyRead,
                    decoration: const InputDecoration(
                      labelText: 'Foto (URL, opcionalno)',
                      prefixIcon: Icon(Icons.photo_camera_outlined),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: (_submitting || _alreadyRead)
                          ? null
                          : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Snimi očitanje'),
                    ),
                  ),
                ],
              ),
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

String _formatReading(double value) {
  final text = value.toStringAsFixed(2);
  return text.endsWith('.00') ? text.substring(0, text.length - 3) : text;
}

String _formatDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}.';
}
