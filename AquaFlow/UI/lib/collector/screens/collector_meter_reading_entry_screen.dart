import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aquaflow_desktop/collector/models/collector_water_meter.dart';
import 'package:aquaflow_desktop/collector/services/collector_meter_reading_exception.dart';
import 'package:aquaflow_desktop/collector/services/collector_meter_reading_service.dart';

/// Meter detail + reading entry, pushed when a collector taps a result on
/// [CollectorWaterMetersScreen]. Submits via
/// `POST /MeterReadings/collector-entry`
/// (`CollectorMeterReadingService.submit`) - the server resolves the
/// collector, the billing cycle, and the previous reading itself, so this
/// form only collects the new reading value and an optional note (required
/// when the value is lower than the meter's last reading, e.g. a meter
/// replacement/reset).
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

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _readingCtrl.dispose();
    _noteCtrl.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await _service.submit(
        waterMeterId: widget.meter.id,
        readingValue: double.parse(_readingCtrl.text.trim().replaceAll(',', '.')),
        note: _noteCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Očitanje je snimljeno.')));
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
                      label: 'Zadnje stanje: ${meter.lastReading} m³',
                    ),
                  ],
                ),
              ),
            ),
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
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Napomena (obavezno ako je stanje niže)',
                      prefixIcon: Icon(Icons.notes_outlined),
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
                      onPressed: _submitting ? null : _submit,
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
