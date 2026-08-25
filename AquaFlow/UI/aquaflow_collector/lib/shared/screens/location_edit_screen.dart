import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_collector/l10n/app_localizations.dart';

import '../models/city_lookup.dart';
import '../models/customer_profile.dart';
import '../models/municipality_lookup.dart';
import '../models/settlement_lookup.dart';
import '../providers/auth_provider.dart';
import '../services/location_lookup_exception.dart';
import '../services/location_lookup_service.dart';
import '../services/profile_exception.dart';
import '../services/profile_service.dart';
import '../widgets/async_state_view.dart';

/// Screen for editing the signed-in user's address: Grad -> Općina ->
/// Naselje plus Ulica/Broj.
///
/// Reached from the "Nalog" tab (see `AccountScreen`) - split out of the
/// former single "Uredi nalog" screen together with
/// [PersonalDetailsEditScreen] (name/email/phone/theme) and
/// [PasswordResetScreen] (password).
///
/// The address lives on the CustomerProfile (not the `User` entity), so it
/// is loaded/saved through [ProfileService] (`GET`/`POST`/`PATCH
/// /CustomerProfiles`) - the same row [PersonalDetailsEditScreen] edits, so
/// the existing first/last name is sent back unchanged on save (the backend
/// PATCH replaces the whole profile row). Creating a brand new profile
/// requires a name (backend `CustomerProfileInsertValidator`), so a user with
/// no profile yet must fill in [PersonalDetailsEditScreen] first - [_save]
/// blocks with a message pointing there instead of letting the backend call
/// fail.
class LocationEditScreen extends StatefulWidget {
  const LocationEditScreen({super.key});

  @override
  State<LocationEditScreen> createState() => _LocationEditScreenState();
}

class _LocationEditScreenState extends State<LocationEditScreen> {
  final ProfileService _profileService = ProfileService();
  final LocationLookupService _locationService = LocationLookupService();
  final _formKey = GlobalKey<FormState>();

  final _streetCtrl = TextEditingController();
  final _houseNumberCtrl = TextEditingController();

  int? _existingProfileId;
  String _existingFirstName = '';
  String _existingLastName = '';
  bool _loading = true;
  String? _loadError;
  bool _saving = false;

  List<CityLookup> _cities = const [];
  List<MunicipalityLookup> _municipalities = const [];
  List<SettlementLookup> _settlements = const [];
  int? _selectedCityId;
  int? _selectedMunicipalityId;
  int? _selectedSettlementId;

  bool get _hasName =>
      _existingFirstName.trim().isNotEmpty &&
      _existingLastName.trim().isNotEmpty;

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

      _existingProfileId = profile?.id;
      _existingFirstName = profile?.firstName ?? '';
      _existingLastName = profile?.lastName ?? '';
      _streetCtrl.text = profile?.street ?? '';
      _houseNumberCtrl.text = profile?.houseNumber ?? '';
      _applySettlement(profile?.settlementId);
      setState(() => _loading = false);
    } on ProfileException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = e.message;
        });
      }
    } on LocationLookupException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = e.message;
        });
      }
    }
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

  Future<void> _save() async {
    final form = _formKey.currentState;
    final userId = _userId;
    if (form == null || !form.validate() || userId == null) return;

    if (!_hasName) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).locationNameRequiredError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final street = _streetCtrl.text.trim();
    final houseNumber = _houseNumberCtrl.text.trim();

    try {
      await _profileService.saveProfile(
        userId: userId,
        firstName: _existingFirstName,
        lastName: _existingLastName,
        settlementId: _selectedSettlementId,
        street: street.isEmpty ? null : street,
        houseNumber: houseNumber.isEmpty ? null : houseNumber,
        existingProfileId: _existingProfileId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).locationSaveSuccess),
        ),
      );
      await _load();
    } on ProfileException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _profileService.dispose();
    _locationService.dispose();
    _streetCtrl.dispose();
    _houseNumberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).locationTitle)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return AsyncStateView(
      loading: _loading,
      error: _loadError,
      onRetry: _load,
      builder: (context) => _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedCityId ?? 0,
                      decoration: InputDecoration(
                        labelText: loc.locationCityLabel,
                        prefixIcon: const Icon(Icons.location_city_outlined),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 0,
                          child: Text(loc.locationNoCityOption),
                        ),
                        for (final city in _cities)
                          DropdownMenuItem(
                            value: city.id,
                            child: Text(city.name),
                          ),
                      ],
                      onChanged: (value) =>
                          _onCityChanged(value == 0 ? null : value),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedMunicipalityId ?? 0,
                      decoration: InputDecoration(
                        labelText: loc.locationMunicipalityLabel,
                        prefixIcon: const Icon(Icons.map_outlined),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 0,
                          child: Text(loc.locationNoMunicipalityOption),
                        ),
                        for (final municipality
                            in _municipalitiesForSelectedCity)
                          DropdownMenuItem(
                            value: municipality.id,
                            child: Text(municipality.name),
                          ),
                      ],
                      onChanged: _selectedCityId == null
                          ? null
                          : (value) => _onMunicipalityChanged(
                              value == 0 ? null : value,
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedSettlementId ?? 0,
                      decoration: InputDecoration(
                        labelText: loc.locationSettlementLabel,
                        prefixIcon: const Icon(Icons.holiday_village_outlined),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 0,
                          child: Text(loc.locationNoSettlementOption),
                        ),
                        for (final settlement
                            in _settlementsForSelectedMunicipality)
                          DropdownMenuItem(
                            value: settlement.id,
                            child: Text(settlement.name),
                          ),
                      ],
                      onChanged: _selectedMunicipalityId == null
                          ? null
                          : (value) =>
                                _onSettlementChanged(value == 0 ? null : value),
                    ),
                  ),
                  _field(
                    controller: _streetCtrl,
                    label: loc.locationStreetLabel,
                    icon: Icons.signpost_outlined,
                    maxLength: 120,
                  ),
                  _field(
                    controller: _houseNumberCtrl,
                    label: loc.locationHouseNumberLabel,
                    icon: Icons.pin_outlined,
                    maxLength: 20,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? loc.commonSaving : loc.commonSave),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          counterText: '',
        ),
      ),
    );
  }
}
