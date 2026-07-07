import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/account_details.dart';
import '../models/city_lookup.dart';
import '../models/customer_profile.dart';
import '../models/municipality_lookup.dart';
import '../models/settlement_lookup.dart';
import '../providers/auth_provider.dart';
import '../services/account_exception.dart';
import '../services/account_service.dart';
import '../services/location_lookup_exception.dart';
import '../services/location_lookup_service.dart';
import '../services/profile_exception.dart';
import '../services/profile_service.dart';

/// Screen for viewing and editing the signed-in user's own account data.
///
/// Reached from the "Nalog" tab (see [AccountScreen]) by any user, regardless of
/// role - the backend `/Account/me` endpoint derives the user from the JWT, so a
/// caller can only ever edit their own record. Unlike the tab bodies inside
/// [MasterScreen], this screen is pushed as its own route, so it renders its own
/// Scaffold/AppBar.
///
/// The data is loaded on open; the form is prefilled and saved with
/// `PUT /Account/me` through [AccountService]. Email and phone are always
/// editable. First/last name and address (cascading Grad -> Općina -> Naselje
/// + Ulica/Broj) live on the CustomerProfile instead (not the `User` entity),
/// so they are loaded/saved separately through [ProfileService]
/// (`GET`/`POST`/`PATCH /CustomerProfiles`), only when a name was actually
/// entered - mirrors the admin "Moj nalog" screen (`AdminAccountEditScreen`).
/// A password change (`PUT /Account/me/password`) is sent only when the
/// password fields are filled in - this is the mobile customer/collector path.
class AccountEditScreen extends StatefulWidget {
  const AccountEditScreen({super.key});

  @override
  State<AccountEditScreen> createState() => _AccountEditScreenState();
}

class _AccountEditScreenState extends State<AccountEditScreen> {
  final AccountService _service = AccountService();
  final ProfileService _profileService = ProfileService();
  final LocationLookupService _locationService = LocationLookupService();
  final _formKey = GlobalKey<FormState>();

  // One controller per editable field; created empty and prefilled once the
  // data loads, so they can be disposed unconditionally.
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _houseNumberCtrl = TextEditingController();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  AccountDetails? _details;
  int? _existingProfileId;
  bool _loading = true;
  String? _loadError;
  bool _saving = false;

  List<CityLookup> _cities = const [];
  List<MunicipalityLookup> _municipalities = const [];
  List<SettlementLookup> _settlements = const [];
  int? _selectedCityId;
  int? _selectedMunicipalityId;
  int? _selectedSettlementId;

  bool get _hasNameInput =>
      _firstNameCtrl.text.trim().isNotEmpty || _lastNameCtrl.text.trim().isNotEmpty;

  bool get _hasPasswordInput =>
      _currentPasswordCtrl.text.isNotEmpty ||
      _newPasswordCtrl.text.isNotEmpty ||
      _confirmPasswordCtrl.text.isNotEmpty;

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
        _service.fetch(),
        userId == null
            ? Future.value(null)
            : _profileService.fetchCustomerProfile(userId),
        _locationService.fetchCities(),
        _locationService.fetchMunicipalities(),
        _locationService.fetchSettlements(),
      ]);
      if (!mounted) return;

      final details = results[0] as AccountDetails;
      final profile = results[1] as CustomerProfile?;
      _cities = results[2] as List<CityLookup>;
      _municipalities = results[3] as List<MunicipalityLookup>;
      _settlements = results[4] as List<SettlementLookup>;

      _details = details;
      _emailCtrl.text = details.email;
      _phoneCtrl.text = details.phone;
      _existingProfileId = profile?.id;
      _firstNameCtrl.text = profile?.firstName ?? '';
      _lastNameCtrl.text = profile?.lastName ?? '';
      _streetCtrl.text = profile?.street ?? '';
      _houseNumberCtrl.text = profile?.houseNumber ?? '';
      _applySettlement(profile?.settlementId);
      setState(() => _loading = false);
    } on AccountException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = e.message;
        });
      }
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
          !_municipalitiesForSelectedCity.any((m) => m.id == _selectedMunicipalityId)) {
        _selectedMunicipalityId = null;
        _selectedSettlementId = null;
      }
    });
  }

  void _onMunicipalityChanged(int? municipalityId) {
    setState(() {
      _selectedMunicipalityId = municipalityId;
      if (_selectedSettlementId != null &&
          !_settlementsForSelectedMunicipality.any((s) => s.id == _selectedSettlementId)) {
        _selectedSettlementId = null;
      }
    });
  }

  void _onSettlementChanged(int? settlementId) {
    setState(() => _selectedSettlementId = settlementId);
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    final current = _details;
    final userId = _userId;
    if (form == null || !form.validate() || current == null) return;

    setState(() => _saving = true);
    final updated = AccountDetails(
      id: current.id,
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      userRole: current.userRole,
      isActive: current.isActive,
    );

    try {
      _details = await _service.update(updated);

      if (_hasNameInput && userId != null) {
        final street = _streetCtrl.text.trim();
        final houseNumber = _houseNumberCtrl.text.trim();
        await _profileService.saveProfile(
          userId: userId,
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          settlementId: _selectedSettlementId,
          street: street.isEmpty ? null : street,
          houseNumber: houseNumber.isEmpty ? null : houseNumber,
          existingProfileId: _existingProfileId,
        );
      }

      if (_hasPasswordInput) {
        await _service.changePassword(
          currentPassword: _currentPasswordCtrl.text,
          newPassword: _newPasswordCtrl.text,
        );
        _currentPasswordCtrl.clear();
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Podaci naloga su sačuvani.')),
      );
      await _load();
    } on AccountException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
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
    _service.dispose();
    _profileService.dispose();
    _locationService.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _streetCtrl.dispose();
    _houseNumberCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Uredi nalog')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return _ErrorRetry(message: _loadError!, onRetry: _load);
    }
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
                  _field(
                    controller: _emailCtrl,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: _email,
                    maxLength: 150,
                  ),
                  _field(
                    controller: _phoneCtrl,
                    label: 'Telefon',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    maxLength: 30,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ime i prezime',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: _firstNameCtrl,
                    label: 'Ime',
                    icon: Icons.person_outline,
                    validator: _firstNameValidator,
                    onChanged: () => setState(() {}),
                    maxLength: 80,
                  ),
                  _field(
                    controller: _lastNameCtrl,
                    label: 'Prezime',
                    icon: Icons.person_outline,
                    validator: _lastNameValidator,
                    onChanged: () => setState(() {}),
                    maxLength: 80,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Adresa',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedCityId ?? 0,
                      decoration: const InputDecoration(
                        labelText: 'Grad',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                      items: [
                        const DropdownMenuItem(value: 0, child: Text('Bez grada')),
                        for (final city in _cities)
                          DropdownMenuItem(value: city.id, child: Text(city.name)),
                      ],
                      onChanged: (value) => _onCityChanged(value == 0 ? null : value),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedMunicipalityId ?? 0,
                      decoration: const InputDecoration(
                        labelText: 'Općina',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                      items: [
                        const DropdownMenuItem(value: 0, child: Text('Bez općine')),
                        for (final municipality in _municipalitiesForSelectedCity)
                          DropdownMenuItem(
                            value: municipality.id,
                            child: Text(municipality.name),
                          ),
                      ],
                      onChanged: _selectedCityId == null
                          ? null
                          : (value) => _onMunicipalityChanged(value == 0 ? null : value),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedSettlementId ?? 0,
                      decoration: const InputDecoration(
                        labelText: 'Naselje',
                        prefixIcon: Icon(Icons.holiday_village_outlined),
                      ),
                      items: [
                        const DropdownMenuItem(value: 0, child: Text('Bez naselja')),
                        for (final settlement in _settlementsForSelectedMunicipality)
                          DropdownMenuItem(
                            value: settlement.id,
                            child: Text(settlement.name),
                          ),
                      ],
                      validator: _settlementValidator,
                      onChanged: _selectedMunicipalityId == null
                          ? null
                          : (value) => _onSettlementChanged(value == 0 ? null : value),
                    ),
                  ),
                  _field(
                    controller: _streetCtrl,
                    label: 'Ulica',
                    icon: Icons.signpost_outlined,
                    maxLength: 120,
                  ),
                  _field(
                    controller: _houseNumberCtrl,
                    label: 'Broj',
                    icon: Icons.pin_outlined,
                    maxLength: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Promjena lozinke',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ostavite prazno ako ne mijenjate lozinku.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: _currentPasswordCtrl,
                    label: 'Trenutna lozinka',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: _currentPasswordValidator,
                    onChanged: () => setState(() {}),
                  ),
                  _field(
                    controller: _newPasswordCtrl,
                    label: 'Nova lozinka',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: _newPasswordValidator,
                    onChanged: () => setState(() {}),
                  ),
                  _field(
                    controller: _confirmPasswordCtrl,
                    label: 'Potvrda nove lozinke',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: _confirmPasswordValidator,
                    onChanged: () => setState(() {}),
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
                    label: Text(_saving ? 'Spašavanje...' : 'Sačuvaj'),
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
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLength,
    bool obscureText = false,
    VoidCallback? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLength: maxLength,
        obscureText: obscureText,
        onChanged: onChanged == null ? null : (_) => onChanged(),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          counterText: '',
        ),
      ),
    );
  }

  String? _email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Obavezno polje.';
    // Mirrors the backend EmailAddress() rule loosely: must contain "@" with
    // something on both sides. The backend is the authority on validity.
    final at = text.indexOf('@');
    if (at <= 0 || at == text.length - 1) return 'Unesite ispravan email.';
    return null;
  }

  // Ime/Prezime are optional, but if either is filled in, both are required -
  // CustomerProfile needs both (mirrors the admin "Moj nalog" screen).
  String? _firstNameValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty && _lastNameCtrl.text.trim().isNotEmpty) {
      return 'Obavezno ako unosite ime i prezime.';
    }
    return null;
  }

  String? _lastNameValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty && _firstNameCtrl.text.trim().isNotEmpty) {
      return 'Obavezno ako unosite ime i prezime.';
    }
    return null;
  }

  // Creating a brand new CustomerProfile requires a name (backend
  // CustomerProfileInsertValidator), so address input alone can't be saved
  // for a user who doesn't have a profile yet.
  String? _settlementValidator(int? _) {
    final hasAddressInput = _selectedSettlementId != null ||
        _streetCtrl.text.trim().isNotEmpty ||
        _houseNumberCtrl.text.trim().isNotEmpty;
    if (hasAddressInput && !_hasNameInput) {
      return 'Unesite ime i prezime da biste sačuvali adresu.';
    }
    return null;
  }

  // The three password fields form one optional group: touch any one of them
  // and all three become required, so the backend always gets a current
  // password to verify alongside the new one.
  String? _currentPasswordValidator(String? value) {
    if ((value ?? '').isEmpty && _hasPasswordInput) {
      return 'Unesite trenutnu lozinku.';
    }
    return null;
  }

  String? _newPasswordValidator(String? value) {
    final text = value ?? '';
    if (text.isEmpty) {
      return _hasPasswordInput ? 'Unesite novu lozinku.' : null;
    }
    if (text.length < 6) return 'Lozinka mora imati najmanje 6 znakova.';
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if (_newPasswordCtrl.text.isEmpty) return null;
    if (value != _newPasswordCtrl.text) return 'Lozinke se ne podudaraju.';
    return null;
  }
}

/// Full-screen error state with a retry button, shown when the initial load
/// fails.
class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
