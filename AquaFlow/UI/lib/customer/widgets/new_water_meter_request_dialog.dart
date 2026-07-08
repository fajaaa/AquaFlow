import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_desktop/customer/services/customer_water_meter_request_exception.dart';
import 'package:aquaflow_desktop/customer/services/customer_water_meter_request_service.dart';
import 'package:aquaflow_desktop/shared/models/city_lookup.dart';
import 'package:aquaflow_desktop/shared/models/customer_profile.dart';
import 'package:aquaflow_desktop/shared/models/municipality_lookup.dart';
import 'package:aquaflow_desktop/shared/models/settlement_lookup.dart';
import 'package:aquaflow_desktop/shared/providers/auth_provider.dart';
import 'package:aquaflow_desktop/shared/services/location_lookup_exception.dart';
import 'package:aquaflow_desktop/shared/services/location_lookup_service.dart';
import 'package:aquaflow_desktop/shared/services/profile_exception.dart';
import 'package:aquaflow_desktop/shared/services/profile_service.dart';

/// Opens the "Zahtjev za novi vodomjer" dialog and resolves to `true` when a
/// request was successfully created. Shared by the "Vodomjeri" tab and
/// `CustomerRequestsScreen`.
Future<bool?> showNewWaterMeterRequestDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (_) => const NewWaterMeterRequestDialog(),
  );
}

/// Modal form for a new water meter request. `WaterMeterRequest` now carries
/// its own full address, so the form collects a cascading
/// Grad -> Općina -> Naselje selection plus required Ulica/Broj (and an
/// optional Napomena) and sends `{ settlementId, street, houseNumber, note? }`.
///
/// Self-contained: it fetches the City/Municipality/Settlement lookups and the
/// caller's own CustomerProfile on open, prefilling every address field from
/// the profile when it has a settlement/street/house, so both entry points open
/// it identically.
class NewWaterMeterRequestDialog extends StatefulWidget {
  const NewWaterMeterRequestDialog({super.key});

  @override
  State<NewWaterMeterRequestDialog> createState() =>
      _NewWaterMeterRequestDialogState();
}

class _NewWaterMeterRequestDialogState
    extends State<NewWaterMeterRequestDialog> {
  final CustomerWaterMeterRequestService _requestService =
      CustomerWaterMeterRequestService();
  final ProfileService _profileService = ProfileService();
  final LocationLookupService _locationService = LocationLookupService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _streetCtrl = TextEditingController();
  final TextEditingController _houseNumberCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  bool _loading = true;
  String? _loadError;
  bool _submitting = false;
  String? _error;

  List<CityLookup> _cities = const [];
  List<MunicipalityLookup> _municipalities = const [];
  List<SettlementLookup> _settlements = const [];
  int? _selectedCityId;
  int? _selectedMunicipalityId;
  int? _selectedSettlementId;

  int? get _userId => context.read<AuthProvider>().session?.id;

  List<MunicipalityLookup> get _municipalitiesForSelectedCity =>
      _municipalities.where((m) => m.cityId == _selectedCityId).toList();

  List<SettlementLookup> get _settlementsForSelectedMunicipality => _settlements
      .where((s) => s.municipalityId == _selectedMunicipalityId)
      .toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    final userId = _userId;
    try {
      final results = await Future.wait([
        userId == null
            ? Future.value(null)
            : _profileService.fetchCustomerProfile(userId),
        _locationService.fetchCities(),
        _locationService.fetchMunicipalities(),
        _locationService.fetchSettlements(),
      ]);
      if (!mounted) return;

      final profile = results[0] as CustomerProfile?;
      _cities = results[1] as List<CityLookup>;
      _municipalities = results[2] as List<MunicipalityLookup>;
      _settlements = results[3] as List<SettlementLookup>;

      _streetCtrl.text = profile?.street ?? '';
      _houseNumberCtrl.text = profile?.houseNumber ?? '';
      _applySettlement(profile?.settlementId);
      setState(() => _loading = false);
    } on ProfileException catch (e) {
      _failLoad(e.message);
    } on LocationLookupException catch (e) {
      _failLoad(e.message);
    }
  }

  void _failLoad(String message) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _loadError = message;
    });
  }

  /// Resolves the Grad -> Općina chain for a prefilled [settlementId], so the
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
          !_municipalitiesForSelectedCity
              .any((m) => m.id == _selectedMunicipalityId)) {
        _selectedMunicipalityId = null;
        _selectedSettlementId = null;
      }
    });
  }

  void _onMunicipalityChanged(int? municipalityId) {
    setState(() {
      _selectedMunicipalityId = municipalityId;
      if (_selectedSettlementId != null &&
          !_settlementsForSelectedMunicipality
              .any((s) => s.id == _selectedSettlementId)) {
        _selectedSettlementId = null;
      }
    });
  }

  void _onSettlementChanged(int? settlementId) {
    setState(() => _selectedSettlementId = settlementId);
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    final settlementId = _selectedSettlementId;
    if (form == null || !form.validate() || settlementId == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await _requestService.create(
        settlementId: settlementId,
        street: _streetCtrl.text,
        houseNumber: _houseNumberCtrl.text,
        note: _noteCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on CustomerWaterMeterRequestException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    }
  }

  @override
  void dispose() {
    _requestService.dispose();
    _profileService.dispose();
    _locationService.dispose();
    _streetCtrl.dispose();
    _houseNumberCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Zahtjev za novi vodomjer'),
      content: SizedBox(width: 420, child: _buildContent()),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Odustani'),
        ),
        FilledButton(
          onPressed: _submitting || _loading || _loadError != null
              ? null
              : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Pošalji zahtjev'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);

    if (_loading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final loadError = _loadError;
    if (loadError != null) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(loadError, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Pokušaj ponovo'),
              ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CascadingDropdown(
              label: 'Grad',
              icon: Icons.location_city_outlined,
              emptyLabel: 'Bez grada',
              value: _selectedCityId,
              items: [
                for (final city in _cities) (city.id, city.name),
              ],
              onChanged: (value) => _onCityChanged(value),
            ),
            const SizedBox(height: 16),
            _CascadingDropdown(
              label: 'Općina',
              icon: Icons.map_outlined,
              emptyLabel: 'Bez općine',
              value: _selectedMunicipalityId,
              items: [
                for (final m in _municipalitiesForSelectedCity) (m.id, m.name),
              ],
              onChanged: _selectedCityId == null ? null : _onMunicipalityChanged,
            ),
            const SizedBox(height: 16),
            _CascadingDropdown(
              label: 'Naselje',
              icon: Icons.holiday_village_outlined,
              emptyLabel: 'Bez naselja',
              value: _selectedSettlementId,
              items: [
                for (final s in _settlementsForSelectedMunicipality)
                  (s.id, s.name),
              ],
              validator: _settlementValidator,
              onChanged:
                  _selectedMunicipalityId == null ? null : _onSettlementChanged,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _streetCtrl,
              enabled: !_submitting,
              maxLength: 120,
              validator: _requiredValidator,
              decoration: const InputDecoration(
                labelText: 'Ulica',
                prefixIcon: Icon(Icons.signpost_outlined),
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _houseNumberCtrl,
              enabled: !_submitting,
              maxLength: 20,
              validator: _requiredValidator,
              decoration: const InputDecoration(
                labelText: 'Broj',
                prefixIcon: Icon(Icons.pin_outlined),
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteCtrl,
              enabled: !_submitting,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Napomena (opciono)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _settlementValidator(int? value) {
    if (value == null || value == 0) return 'Odaberite naselje.';
    return null;
  }

  String? _requiredValidator(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Obavezno polje.';
    return null;
  }
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
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
