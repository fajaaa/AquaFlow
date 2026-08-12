import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'package:aquaflow_collector/models/collector_meter_reading.dart';
import 'package:aquaflow_collector/models/collector_water_meter.dart';
import 'package:aquaflow_collector/services/collector_meter_reading_exception.dart';
import 'package:aquaflow_collector/services/collector_meter_reading_service.dart';
import 'package:aquaflow_collector/shared/models/tariff_lookup.dart';
import 'package:aquaflow_collector/shared/services/tariff_lookup_exception.dart';
import 'package:aquaflow_collector/shared/services/tariff_lookup_service.dart';
import 'package:aquaflow_collector/shared/theme/app_theme.dart';
import 'package:aquaflow_collector/widgets/collector_water_meter_status_pill.dart';

/// Meter detail + reading entry, pushed when a collector taps a result on
/// [CollectorWaterMetersScreen]. Submits via
/// `POST /MeterReadings/collector-entry`
/// (`CollectorMeterReadingService.submit`) - the server resolves the
/// collector and previous reading itself, so this form only collects the new
/// reading value, the tariff to bill it under (required - picked from the
/// active tariff list), the "Zamjena vodomjera" (meter replacement) toggle,
/// an optional note (mandatory here on the client - and enforced again by
/// the server - when the toggle is on, since it's the audit trail for why
/// the baseline was reset) and an optional photo URL. A reading below the
/// meter's last recorded value is ONLY ever accepted when the replacement
/// toggle is on; the server rejects it outright otherwise, regardless of any
/// note. The server auto-generates an Issued invoice from the reading and
/// the chosen tariff, so the success message shows its number/total - unless
/// consumption came out to zero, in which case the server creates no invoice
/// at all and the summary just confirms the reading was recorded.
/// On open it fetches the last reading to suggest a tariff and check that
/// at least 15 days have passed since the previous reading.
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
  final TariffLookupService _tariffService = TariffLookupService();
  final _formKey = GlobalKey<FormState>();
  final _readingCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _photoUrlCtrl = TextEditingController();
  final _replacedMeterFinalReadingCtrl = TextEditingController();

  bool _submitting = false;
  String? _error;
  bool _isMeterReplacement = false;

  bool _loadingTariffs = true;
  List<TariffLookup> _tariffs = [];
  int? _selectedTariffId;
  String? _tariffError;

  String? _nextReadingAllowedDate;
  double? _lastCountingReadingValue;

  // Generated once per form open and reused for every retry (timeout/network error) of the same
  // submission, so the server can recognize a resubmit as the same request instead of creating a
  // second reading/invoice (see MeterReadingService.CreateForCollectorAsync). A fresh UUID is only
  // generated the next time this screen is opened.
  late final String _clientUuid;

  @override
  void initState() {
    super.initState();
    _clientUuid = const Uuid().v4();
    _readingCtrl.addListener(_onPricePreviewInputChanged);
    _loadData();
  }

  void _onPricePreviewInputChanged() {
    if (mounted) setState(() {});
  }

  double? get _consumptionPreview {
    final reading = double.tryParse(
      _readingCtrl.text.trim().replaceAll(',', '.'),
    );
    if (reading == null) return null;
    final baseline = _isMeterReplacement
        ? 0.0
        : (_lastCountingReadingValue ?? widget.meter.lastReading);
    final consumption = reading - baseline;
    return consumption >= 0 ? consumption : null;
  }

  TariffLookup? get _selectedTariff {
    for (final tariff in _tariffs) {
      if (tariff.id == _selectedTariffId) return tariff;
    }
    return null;
  }

  @override
  void dispose() {
    _readingCtrl.removeListener(_onPricePreviewInputChanged);
    _readingCtrl.dispose();
    _noteCtrl.dispose();
    _photoUrlCtrl.dispose();
    _replacedMeterFinalReadingCtrl.dispose();
    _service.dispose();
    _tariffService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loadingTariffs = true;
      _tariffError = null;
    });

    try {
      final results = await Future.wait([
        _tariffService.fetchActiveTariffs(),
        _service.fetchLastReading(widget.meter.id),
      ], eagerError: false);

      final tariffs = results[0] as List<TariffLookup>;
      final lastReading = results[1] as CollectorMeterReading?;

      String? nextReadingAllowedDate;
      if (lastReading != null) {
        final minDate = lastReading.readingDate.add(const Duration(days: 15));
        final now = DateTime.now();
        if (now.isBefore(minDate)) {
          String two(int value) => value.toString().padLeft(2, '0');
          nextReadingAllowedDate =
              '${two(minDate.day)}.${two(minDate.month)}.${minDate.year}.';
        }
      }

      if (!mounted) return;
      setState(() {
        _tariffs = tariffs;
        _nextReadingAllowedDate = nextReadingAllowedDate;
        _lastCountingReadingValue = lastReading?.readingValue;
        _selectedTariffId = tariffs.any((t) => t.id == lastReading?.tariffId)
            ? lastReading!.tariffId
            : tariffs.firstOrNull?.id;
        _loadingTariffs = false;
      });
    } on TariffLookupException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingTariffs = false;
        _tariffError = e.message;
      });
    } on CollectorMeterReadingException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingTariffs = false;
        _tariffError = e.message;
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
      final replacedMeterFinalReadingText = _replacedMeterFinalReadingCtrl.text
          .trim();
      final result = await _service.submit(
        waterMeterId: widget.meter.id,
        readingValue: double.parse(
          _readingCtrl.text.trim().replaceAll(',', '.'),
        ),
        tariffId: _selectedTariffId!,
        clientUuid: _clientUuid,
        isMeterReplacement: _isMeterReplacement,
        replacedMeterFinalReading:
            _isMeterReplacement && replacedMeterFinalReadingText.isNotEmpty
            ? double.parse(replacedMeterFinalReadingText.replaceAll(',', '.'))
            : null,
        note: _noteCtrl.text,
        photoUrl: _photoUrlCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.hasInvoice
                ? 'Očitanje je snimljeno. Potrošnja: '
                      '${_formatReading(result.consumptionM3)} m³. '
                      'Račun ${result.invoiceNumber}: '
                      '${_formatReading(result.invoiceTotalAmount!)} BAM.'
                : 'Očitanje je snimljeno. Potrošnja: '
                      '${_formatReading(result.consumptionM3)} m³. '
                      'Račun nije kreiran (potrošnja je 0).',
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

  // A lower reading is only ever accepted server-side when IsMeterReplacement is set, and even then
  // only with a Note explaining it - so the Note is required client-side exactly under that toggle.
  String? _noteValidator(String? value) {
    if (!_isMeterReplacement) return null;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Napomena je obavezna kod zamjene vodomjera.';
    return null;
  }

  String? _replacedMeterFinalReadingValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text.replaceAll(',', '.'));
    if (parsed == null || parsed < 0) return 'Unesite pozitivan broj.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final meter = widget.meter;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final meta = CollectorWaterMeterStatusMeta.of(meter.status);
    final accent = _readableAccent(meta.color, theme.brightness);
    final onAccent =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? Colors.white
        : AppColors.textDark;

    return Scaffold(
      appBar: AppBar(title: Text(meter.serialNumber)),
      body: SafeArea(
        child: Column(
          children: [
            // Status banner - full-width strip across the top, same
            // treatment as `CustomerWaterMeterDetailScreen`.
            Container(
              width: double.infinity,
              color: accent.withValues(alpha: 0.10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                        meter.serialNumber,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        meta.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeading(
                          'Podaci o vodomjeru',
                          icon: Icons.info_outline,
                          color: accent,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          meter.customerFullName.isEmpty
                              ? '-'
                              : meter.customerFullName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
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
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.speed_outlined,
                                color: accent,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ZADNJE STANJE',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.4,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_formatReading(meter.lastReading)} m³',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: accent,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_nextReadingAllowedDate != null) ...[
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
                            Icons.info_outlined,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Sljedeće očitanje je moguće od: $_nextReadingAllowedDate',
                              style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _SectionCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeading(
                            'Novo očitanje',
                            icon: Icons.edit_note_outlined,
                            color: accent,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _readingCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]'),
                              ),
                            ],
                            validator: _readingValidator,
                            decoration: const InputDecoration(
                              labelText: 'Novo stanje (m³)',
                              prefixIcon: Icon(Icons.speed_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedTariffId,
                            decoration: InputDecoration(
                              labelText: 'Tarifa',
                              prefixIcon: const Icon(Icons.sell_outlined),
                              errorText: _tariffError,
                            ),
                            hint: Text(
                              _loadingTariffs
                                  ? 'Učitavanje tarifa...'
                                  : _tariffs.isEmpty
                                  ? 'Nema aktivnih tarifa'
                                  : 'Odaberite tarifu',
                            ),
                            items: [
                              for (final tariff in _tariffs)
                                DropdownMenuItem(
                                  value: tariff.id,
                                  child: Text(tariff.name),
                                ),
                            ],
                            validator: (value) =>
                                value == null ? 'Obavezno polje.' : null,
                            onChanged: _tariffs.isNotEmpty
                                ? (value) =>
                                      setState(() => _selectedTariffId = value)
                                : null,
                          ),
                          _PricePreviewCard(
                            consumption: _consumptionPreview,
                            tariff: _selectedTariff,
                            accent: accent,
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _isMeterReplacement,
                            onChanged: (value) {
                              setState(() {
                                _isMeterReplacement = value;
                                if (!value) {
                                  _replacedMeterFinalReadingCtrl.clear();
                                }
                              });
                              _formKey.currentState?.validate();
                            },
                            title: const Text('Zamjena vodomjera'),
                            subtitle: const Text(
                              'Uključite ako je fizički vodomjer zamijenjen novim. Novo '
                              'stanje se tada računa od 0, a napomena postaje obavezna.',
                            ),
                          ),
                          if (_isMeterReplacement) ...[
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _replacedMeterFinalReadingCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,]'),
                                ),
                              ],
                              validator: _replacedMeterFinalReadingValidator,
                              decoration: const InputDecoration(
                                labelText:
                                    'Staro stanje vodomjera (opcionalno)',
                                prefixIcon: Icon(Icons.history_outlined),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _noteCtrl,
                            maxLines: 2,
                            validator: _noteValidator,
                            decoration: InputDecoration(
                              labelText: _isMeterReplacement
                                  ? 'Napomena (obavezno - razlog zamjene)'
                                  : 'Napomena (opcionalno)',
                              prefixIcon: const Icon(Icons.notes_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _photoUrlCtrl,
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
                              style: FilledButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: onAccent,
                                disabledBackgroundColor: accent.withValues(
                                  alpha: 0.35,
                                ),
                                disabledForegroundColor: onAccent.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              onPressed:
                                  (_submitting ||
                                      _tariffs.isEmpty ||
                                      _nextReadingAllowedDate != null)
                                  ? null
                                  : _submit,
                              icon: _submitting
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: onAccent,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: const Text('Snimi očitanje'),
                            ),
                          ),
                        ],
                      ),
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

  /// Mirrors `_readableAccent` in `customer_water_meter_detail_screen.dart`:
  /// any accent dark enough to blend into the dark theme's background is
  /// lifted toward white there. Light theme and the brighter accents are
  /// returned unchanged.
  static Color _readableAccent(Color base, Brightness brightness) {
    if (brightness == Brightness.dark && base.computeLuminance() < 0.2) {
      return Color.lerp(base, Colors.white, 0.6)!;
    }
    return base;
  }
}

/// Mirrors `_SectionCard` in `customer_water_meter_detail_screen.dart` so
/// this screen's sections use the same rounded/bordered/shadowed card.
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

/// Mirrors `_SectionHeading` in `customer_water_meter_detail_screen.dart`.
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

/// Live preview of the invoice the server will generate for this reading -
/// consumption is the last *counting* reading (fetched via
/// `/MeterReadings/last-counting`, same source the server itself uses as
/// `previousReading`) subtracted from the entered reading, falling back to
/// `meter.lastReading` only when there is no reading history at all (or 0 as
/// the baseline when "Zamjena vodomjera" is on), matching
/// `MeterReadingService.CreateForCollectorAsync` exactly - `meter.lastReading`
/// alone can lag behind reality after a cancelled invoice. Multiplied by the
/// selected tariff's [TariffLookup.pricePerM3]. Purely client-side; the
/// server is still the source of truth for the actual invoice total.
class _PricePreviewCard extends StatelessWidget {
  const _PricePreviewCard({
    required this.consumption,
    required this.tariff,
    required this.accent,
  });

  final double? consumption;
  final TariffLookup? tariff;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = (consumption != null && tariff != null)
        ? consumption! * tariff!.pricePerM3
        : null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate_outlined, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                'PREGLED IZNOSA',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PriceLine(
            label: 'Potrošnja',
            value: consumption != null
                ? '${_formatReading(consumption!)} m³'
                : '-',
          ),
          const SizedBox(height: 4),
          _PriceLine(
            label: 'Cijena po m³',
            value: tariff != null
                ? '${_formatReading(tariff!.pricePerM3)} BAM'
                : '-',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: accent.withValues(alpha: 0.2)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ukupno',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                total != null ? '${_formatReading(total)} BAM' : '-',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
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

String _formatReading(double value) {
  final text = value.toStringAsFixed(2);
  return text.endsWith('.00') ? text.substring(0, text.length - 3) : text;
}
