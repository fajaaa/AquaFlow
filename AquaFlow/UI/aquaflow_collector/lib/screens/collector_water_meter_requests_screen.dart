import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:aquaflow_collector/l10n/app_localizations.dart';
import 'package:aquaflow_collector/models/collector_water_meter_request.dart';
import 'package:aquaflow_collector/services/collector_water_meter_request_exception.dart';
import 'package:aquaflow_collector/services/collector_water_meter_request_service.dart';
import 'package:aquaflow_collector/shared/models/city_lookup.dart';
import 'package:aquaflow_collector/shared/models/municipality_lookup.dart';
import 'package:aquaflow_collector/shared/models/settlement_lookup.dart';
import 'package:aquaflow_collector/shared/services/location_lookup_exception.dart';
import 'package:aquaflow_collector/shared/services/location_lookup_service.dart';
import 'package:aquaflow_collector/shared/widgets/refresh_button.dart';

class CollectorWaterMeterRequestsScreen extends StatefulWidget {
  const CollectorWaterMeterRequestsScreen({super.key});

  @override
  State<CollectorWaterMeterRequestsScreen> createState() =>
      _CollectorWaterMeterRequestsScreenState();
}

class _CollectorWaterMeterRequestsScreenState
    extends State<CollectorWaterMeterRequestsScreen> {
  final CollectorWaterMeterRequestService _service =
      CollectorWaterMeterRequestService();

  bool _loading = true;
  bool _mutating = false;
  String? _error;
  List<CollectorWaterMeterRequest> _requests = const [];

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
      // The request now carries the customer's contact and its own address, so
      // no per-customer profile lookup is needed anymore.
      final requests = await _service.fetchAssigned();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _loading = false;
      });
    } on CollectorWaterMeterRequestException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _openRegisterDialog(CollectorWaterMeterRequest request) async {
    final draft = await showDialog<_WaterMeterRegistrationDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RegisterWaterMeterDialog(request: request),
    );
    if (!mounted || draft == null) return;

    setState(() => _mutating = true);
    try {
      await _service.register(
        requestId: request.id,
        serialNumber: draft.serialNumber,
        installedAt: draft.installedAt,
        initialReading: draft.initialReading,
        settlementId: draft.settlementId,
        street: draft.street,
        houseNumber: draft.houseNumber,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).meterRegisteredSuccess),
        ),
      );
      await _load();
    } on CollectorWaterMeterRequestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
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
                    AppLocalizations.of(context).waterMeterRequestsScreenTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                RefreshButton(
                  onRefresh: _load,
                  enabled: !(_loading || _mutating),
                ),
              ],
            ),
          ),
          if (_mutating) const LinearProgressIndicator(minHeight: 2),
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

    if (_requests.isEmpty) {
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
        itemCount: _requests.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _RequestCard(
          request: _requests[index],
          disabled: _mutating,
          onRegister: () => _openRegisterDialog(_requests[index]),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.disabled,
    required this.onRegister,
  });

  final CollectorWaterMeterRequest request;
  final bool disabled;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final note = request.note?.trim();
    final settlementName = request.settlementName;
    final address = request.address;
    final phone = request.customerPhone?.trim() ?? '';
    final hasPhone = phone.isNotEmpty;
    final customerLabel = request.customerFullName.isNotEmpty
        ? request.customerFullName
        : loc.customerFallbackLabel(request.customerId);

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
                Icon(
                  Icons.assignment_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    loc.requestCardTitle(request.id),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const _AssignedPill(),
              ],
            ),
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.person_outline, label: customerLabel),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: hasPhone ? phone : loc.phoneNotAvailableLabel,
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: settlementName.isEmpty ? '-' : settlementName,
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.home_outlined,
              label: address.isEmpty ? '-' : address,
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.event_outlined,
              label: loc.createdAtInlineLabel(_formatDate(request.createdAt)),
            ),
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 6),
              _InfoRow(icon: Icons.notes_outlined, label: note),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: hasPhone && !disabled
                        ? () => _launchPhone(context, 'tel', phone)
                        : null,
                    icon: const Icon(Icons.call_outlined),
                    label: Text(loc.callButton),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: hasPhone && !disabled
                        ? () => _launchPhone(context, 'sms', phone)
                        : null,
                    icon: const Icon(Icons.sms_outlined),
                    label: const Text('SMS'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: disabled ? null : onRegister,
                icon: const Icon(Icons.water_drop_outlined),
                label: Text(loc.registerWaterMeterTitle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchPhone(
    BuildContext context,
    String scheme,
    String phone,
  ) async {
    final uri = Uri(scheme: scheme, path: phone.replaceAll(' ', ''));
    try {
      final launched = await launchUrl(uri);
      if (!launched && context.mounted) _showLaunchError(context);
    } catch (_) {
      if (context.mounted) _showLaunchError(context);
    }
  }

  void _showLaunchError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).actionNotSupportedError),
      ),
    );
  }
}

/// Registration form. Besides the meter details (serial, initial reading,
/// install date) it now carries an EDITABLE address block - a cascading
/// Grad -> Općina -> Naselje picker plus Ulica/Broj, prefilled from the
/// request's stored address - so the collector can correct the location on
/// site. The corrected `settlementId`/`street`/`houseNumber` are sent on
/// register and become the new meter's address.
class _RegisterWaterMeterDialog extends StatefulWidget {
  const _RegisterWaterMeterDialog({required this.request});

  final CollectorWaterMeterRequest request;

  @override
  State<_RegisterWaterMeterDialog> createState() =>
      _RegisterWaterMeterDialogState();
}

class _RegisterWaterMeterDialogState extends State<_RegisterWaterMeterDialog> {
  final LocationLookupService _locationService = LocationLookupService();
  final _formKey = GlobalKey<FormState>();
  final _serialCtrl = TextEditingController();
  final _readingCtrl = TextEditingController(text: '0');
  final _streetCtrl = TextEditingController();
  final _houseNumberCtrl = TextEditingController();

  late DateTime _installedAt;

  bool _loading = true;
  String? _loadError;

  List<CityLookup> _cities = const [];
  List<MunicipalityLookup> _municipalities = const [];
  List<SettlementLookup> _settlements = const [];
  int? _selectedCityId;
  int? _selectedMunicipalityId;
  int? _selectedSettlementId;

  List<MunicipalityLookup> get _municipalitiesForSelectedCity =>
      _municipalities.where((m) => m.cityId == _selectedCityId).toList();

  List<SettlementLookup> get _settlementsForSelectedMunicipality => _settlements
      .where((s) => s.municipalityId == _selectedMunicipalityId)
      .toList();

  @override
  void initState() {
    super.initState();
    _installedAt = DateTime.now();
    _streetCtrl.text = widget.request.street ?? '';
    _houseNumberCtrl.text = widget.request.houseNumber ?? '';
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait([
        _locationService.fetchCities(),
        _locationService.fetchMunicipalities(),
        _locationService.fetchSettlements(),
      ]);
      if (!mounted) return;

      _cities = results[0] as List<CityLookup>;
      _municipalities = results[1] as List<MunicipalityLookup>;
      _settlements = results[2] as List<SettlementLookup>;
      _applySettlement(widget.request.settlementId);
      setState(() => _loading = false);
    } on LocationLookupException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.message;
      });
    }
  }

  /// Resolves the Grad -> Općina chain for the prefilled [settlementId], so the
  /// two parent dropdowns start selected too, not just the leaf Naselje.
  void _applySettlement(int? settlementId) {
    if (settlementId == null) return;
    SettlementLookup? settlement;
    for (final s in _settlements) {
      if (s.id == settlementId) {
        settlement = s;
        break;
      }
    }
    if (settlement == null) return;

    _selectedSettlementId = settlement.id;
    _selectedMunicipalityId = settlement.municipalityId;
    for (final m in _municipalities) {
      if (m.id == settlement.municipalityId) {
        _selectedCityId = m.cityId;
        break;
      }
    }
  }

  void _onCityChanged(int? cityId) {
    setState(() {
      _selectedCityId = cityId;
      if (_selectedMunicipalityId != null &&
          !_municipalitiesForSelectedCity.any(
            (m) => m.id == _selectedMunicipalityId,
          )) {
        _selectedMunicipalityId = null;
        _selectedSettlementId = null;
      }
    });
  }

  void _onMunicipalityChanged(int? municipalityId) {
    setState(() {
      _selectedMunicipalityId = municipalityId;
      if (_selectedSettlementId != null &&
          !_settlementsForSelectedMunicipality.any(
            (s) => s.id == _selectedSettlementId,
          )) {
        _selectedSettlementId = null;
      }
    });
  }

  void _onSettlementChanged(int? settlementId) {
    setState(() => _selectedSettlementId = settlementId);
  }

  @override
  void dispose() {
    _locationService.dispose();
    _serialCtrl.dispose();
    _readingCtrl.dispose();
    _streetCtrl.dispose();
    _houseNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickInstalledAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _installedAt,
      firstDate: DateTime(DateTime.now().year - 10),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (!mounted || date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_installedAt),
    );
    if (!mounted || time == null) return;

    setState(() {
      _installedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _submit() {
    final form = _formKey.currentState;
    final settlementId = _selectedSettlementId;
    if (form == null || !form.validate() || settlementId == null) return;

    Navigator.of(context).pop(
      _WaterMeterRegistrationDraft(
        serialNumber: _serialCtrl.text.trim(),
        initialReading: double.parse(_readingCtrl.text.trim()),
        installedAt: _installedAt,
        settlementId: settlementId,
        street: _streetCtrl.text.trim(),
        houseNumber: _houseNumberCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(loc.registerWaterMeterTitle),
      content: SizedBox(width: 420, child: _buildContent()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.dialogDismissButton),
        ),
        FilledButton.icon(
          onPressed: _loading || _loadError != null ? null : _submit,
          icon: const Icon(Icons.save_outlined),
          label: Text(loc.registerButton),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    if (_loading) {
      return const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final loadError = _loadError;
    if (loadError != null) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 40,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(loadError, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: Text(loc.commonRetry),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CascadingDropdown(
              label: loc.locationCityLabel,
              icon: Icons.location_city_outlined,
              emptyLabel: loc.locationNoCityOption,
              value: _selectedCityId,
              items: [for (final city in _cities) (city.id, city.name)],
              onChanged: _onCityChanged,
            ),
            const SizedBox(height: 14),
            _CascadingDropdown(
              label: loc.locationMunicipalityLabel,
              icon: Icons.map_outlined,
              emptyLabel: loc.locationNoMunicipalityOption,
              value: _selectedMunicipalityId,
              items: [
                for (final m in _municipalitiesForSelectedCity) (m.id, m.name),
              ],
              onChanged: _selectedCityId == null
                  ? null
                  : _onMunicipalityChanged,
            ),
            const SizedBox(height: 14),
            _CascadingDropdown(
              label: loc.locationSettlementLabel,
              icon: Icons.holiday_village_outlined,
              emptyLabel: loc.locationNoSettlementOption,
              value: _selectedSettlementId,
              items: [
                for (final s in _settlementsForSelectedMunicipality)
                  (s.id, s.name),
              ],
              validator: _settlementValidator,
              onChanged: _selectedMunicipalityId == null
                  ? null
                  : _onSettlementChanged,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _streetCtrl,
              textInputAction: TextInputAction.next,
              maxLength: 200,
              validator: _required,
              decoration: InputDecoration(
                labelText: loc.locationStreetLabel,
                prefixIcon: const Icon(Icons.signpost_outlined),
                counterText: '',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _houseNumberCtrl,
              textInputAction: TextInputAction.next,
              maxLength: 30,
              validator: _required,
              decoration: InputDecoration(
                labelText: loc.locationHouseNumberLabel,
                prefixIcon: const Icon(Icons.pin_outlined),
                counterText: '',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _serialCtrl,
              textInputAction: TextInputAction.next,
              validator: _required,
              decoration: InputDecoration(
                labelText: loc.serialNumberLabel,
                prefixIcon: const Icon(Icons.confirmation_number_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _readingCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              validator: _readingValidator,
              decoration: InputDecoration(
                labelText: loc.initialReadingLabel,
                prefixIcon: const Icon(Icons.speed_outlined),
              ),
            ),
            const SizedBox(height: 14),
            _InstalledAtField(value: _installedAt, onPick: _pickInstalledAt),
          ],
        ),
      ),
    );
  }

  String? _settlementValidator(int? value) {
    if (value == null || value == 0) {
      return AppLocalizations.of(context).settlementRequiredError;
    }
    return null;
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty
        ? AppLocalizations.of(context).fieldRequiredError
        : null;
  }

  String? _readingValidator(String? value) {
    final text = value?.trim() ?? '';
    final loc = AppLocalizations.of(context);
    if (text.isEmpty) return loc.fieldRequiredError;
    final parsed = double.tryParse(text);
    if (parsed == null || parsed < 0) return loc.positiveNumberRequiredError;
    return null;
  }
}

class _WaterMeterRegistrationDraft {
  const _WaterMeterRegistrationDraft({
    required this.serialNumber,
    required this.initialReading,
    required this.installedAt,
    required this.settlementId,
    required this.street,
    required this.houseNumber,
  });

  final String serialNumber;
  final double initialReading;
  final DateTime installedAt;
  final int settlementId;
  final String street;
  final String houseNumber;
}

/// A single dropdown in the cascading Grad -> Općina -> Naselje picker. Uses a
/// `0` sentinel for "none selected" so the field can render an empty option and
/// still validate; a `null` [onChanged] disables the field until its parent is
/// picked.
class _CascadingDropdown extends StatelessWidget {
  const _CascadingDropdown({
    required this.label,
    required this.icon,
    required this.emptyLabel,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final IconData icon;
  final String emptyLabel;
  final int? value;
  final List<(int, String)> items;
  final ValueChanged<int?>? onChanged;
  final String? Function(int?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value ?? 0,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: [
        DropdownMenuItem(value: 0, child: Text(emptyLabel)),
        for (final (id, name) in items)
          DropdownMenuItem(value: id, child: Text(name)),
      ],
      validator: validator,
      onChanged: onChanged == null
          ? null
          : (value) => onChanged!(value == 0 ? null : value),
    );
  }
}

class _InstalledAtField extends StatelessWidget {
  const _InstalledAtField({required this.value, required this.onPick});

  final DateTime value;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE6ED)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_available_outlined,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.installedAtFieldLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(_formatDate(value), style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          IconButton(
            tooltip: loc.pickDateTooltip,
            onPressed: onPick,
            icon: const Icon(Icons.calendar_month_outlined),
          ),
        ],
      ),
    );
  }
}

class _AssignedPill extends StatelessWidget {
  const _AssignedPill();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF1D4ED8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.engineering_outlined, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            AppLocalizations.of(context).requestStatusAssigned,
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
            Icons.assignment_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            AppLocalizations.of(context).waterMeterRequestsEmptyMessage,
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
              label: Text(AppLocalizations.of(context).commonRetry),
            ),
          ],
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
