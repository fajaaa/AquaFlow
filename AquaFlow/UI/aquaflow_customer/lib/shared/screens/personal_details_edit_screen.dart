import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_customer/l10n/app_localizations.dart';

import '../models/account_details.dart';
import '../models/customer_profile.dart';
import '../models/user_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../services/account_exception.dart';
import '../services/account_service.dart';
import '../services/preferences_api_service.dart';
import '../services/preferences_exception.dart';
import '../services/profile_exception.dart';
import '../services/profile_service.dart';
import '../widgets/async_state_view.dart';

/// Screen for editing the signed-in user's personal details: email, phone,
/// first/last name and the app theme.
///
/// Reached from the "Nalog" tab (see `AccountScreen`) by any user, regardless
/// of role - split out of the former single "Uredi nalog" screen together
/// with [LocationEditScreen] (address) and [PasswordResetScreen] (password),
/// so each concern gets its own focused form.
///
/// Email/phone are saved through `PUT /Account/me` ([AccountService]).
/// First/last name live on the CustomerProfile instead (not the `User`
/// entity), so they are loaded/saved separately through [ProfileService]
/// (`GET`/`POST`/`PATCH /CustomerProfiles`), only when a name was actually
/// entered - the existing address fields (settlement/street/house number)
/// are sent back unchanged, since the backend PATCH replaces the whole
/// profile row. Admins/collectors have no customer profile, so the name
/// fields simply stay blank and are skipped on save for them.
///
/// The "Izgled" theme switch is separate from the rest of the form: it reads/
/// writes `UserPreference.Theme` via `GET`/`PUT /Account/preferences`
/// ([PreferencesApiService]) and applies immediately to the shared
/// [ThemeProvider] on change, rather than waiting for "Sačuvaj".
class PersonalDetailsEditScreen extends StatefulWidget {
  const PersonalDetailsEditScreen({super.key});

  @override
  State<PersonalDetailsEditScreen> createState() =>
      _PersonalDetailsEditScreenState();
}

class _PersonalDetailsEditScreenState extends State<PersonalDetailsEditScreen> {
  final AccountService _service = AccountService();
  final ProfileService _profileService = ProfileService();
  final PreferencesApiService _preferencesService = PreferencesApiService();
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();

  AccountDetails? _details;
  int? _existingProfileId;
  int? _existingSettlementId;
  String? _existingStreet;
  String? _existingHouseNumber;
  UserPreferences? _preferences;
  bool _loading = true;
  String? _loadError;
  bool _saving = false;

  bool get _hasNameInput =>
      _firstNameCtrl.text.trim().isNotEmpty ||
      _lastNameCtrl.text.trim().isNotEmpty;

  int? get _userId => context.read<AuthProvider>().session?.id;

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
      ]);
      if (!mounted) return;

      final details = results[0] as AccountDetails;
      final profile = results[1] as CustomerProfile?;

      _details = details;
      _emailCtrl.text = details.email;
      _phoneCtrl.text = details.phone;
      _existingProfileId = profile?.id;
      _existingSettlementId = profile?.settlementId;
      _existingStreet = profile?.street;
      _existingHouseNumber = profile?.houseNumber;
      _firstNameCtrl.text = profile?.firstName ?? '';
      _lastNameCtrl.text = profile?.lastName ?? '';
      setState(() => _loading = false);
      _loadPreferences();
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
    }
  }

  /// Fetches `GET /Account/preferences` separately from [_load]: a failure
  /// here (e.g. offline) must not block editing email/phone/name, so it
  /// just leaves [_preferences] null and the theme switch defaults to
  /// whatever [ThemeProvider] is already showing.
  Future<void> _loadPreferences() async {
    try {
      final preferences = await _preferencesService.getPreferences();
      if (!mounted) return;
      setState(() => _preferences = preferences);
    } on PreferencesException {
      // Silently ignored - see the method doc above.
    }
  }

  /// Applies [isDark] to the shared [ThemeProvider] immediately, then
  /// persists it via `PUT /Account/preferences` in the background. On save
  /// failure the app theme stays changed (better than reverting under the
  /// user), but a snackbar reports that the choice wasn't saved.
  Future<void> _setTheme(bool isDark) async {
    final current = _preferences ??
        const UserPreferences(
          theme: 'light',
          language: 'bs',
          receiveEmailNotifications: true,
          receivePushNotifications: true,
        );
    final updated = current.copyWith(theme: isDark ? 'dark' : 'light');

    setState(() => _preferences = updated);
    context
        .read<ThemeProvider>()
        .setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);

    try {
      final saved = await _preferencesService.updatePreferences(updated);
      if (mounted) setState(() => _preferences = saved);
    } on PreferencesException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context).themeSaveFailedError(e.message)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Applies [code] ('bs'/'en') to the shared [LocaleProvider] immediately,
  /// then persists it via `PUT /Account/preferences` in the background. On
  /// save failure the app language stays changed (better than reverting under
  /// the user), but a snackbar reports that the choice wasn't saved.
  Future<void> _setLanguage(String code) async {
    final current = _preferences ??
        const UserPreferences(
          theme: 'light',
          language: 'bs',
          receiveEmailNotifications: true,
          receivePushNotifications: true,
        );
    final updated = current.copyWith(language: code);

    setState(() => _preferences = updated);
    context.read<LocaleProvider>().setLanguageCode(code);

    try {
      final saved = await _preferencesService.updatePreferences(updated);
      if (mounted) setState(() => _preferences = saved);
    } on PreferencesException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).languageSaveFailedError(e.message),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
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
        await _profileService.saveProfile(
          userId: userId,
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          settlementId: _existingSettlementId,
          street: _existingStreet,
          houseNumber: _existingHouseNumber,
          existingProfileId: _existingProfileId,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).personalDetailsSaveSuccess),
        ),
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
    _preferencesService.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).personalDetailsTitle)),
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
                  Text(
                    loc.personalDetailsNameSectionTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: _firstNameCtrl,
                    label: loc.fieldFirstNameLabel,
                    icon: Icons.person_outline,
                    validator: _firstNameValidator,
                    onChanged: () => setState(() {}),
                    maxLength: 80,
                  ),
                  _field(
                    controller: _lastNameCtrl,
                    label: loc.fieldLastNameLabel,
                    icon: Icons.person_outline,
                    validator: _lastNameValidator,
                    onChanged: () => setState(() {}),
                    maxLength: 80,
                  ),
                  _field(
                    controller: _emailCtrl,
                    label: loc.fieldEmailLabel,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: _email,
                    maxLength: 150,
                  ),
                  _field(
                    controller: _phoneCtrl,
                    label: loc.fieldPhoneLabel,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    maxLength: 30,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.personalDetailsAppearanceSectionTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                          value: false,
                          label: Text(loc.themeLightOption),
                          icon: const Icon(Icons.light_mode_outlined),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text(loc.themeDarkOption),
                          icon: const Icon(Icons.dark_mode_outlined),
                        ),
                      ],
                      selected: {_preferences?.isDarkTheme ?? false},
                      onSelectionChanged: (selection) =>
                          _setTheme(selection.first),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'bs', label: Text('Bosanski')),
                        ButtonSegment(value: 'en', label: Text('English')),
                      ],
                      selected: {_preferences?.language ?? 'bs'},
                      onSelectionChanged: (selection) =>
                          _setLanguage(selection.first),
                    ),
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
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLength,
    VoidCallback? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLength: maxLength,
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
    if (text.isEmpty) return AppLocalizations.of(context).fieldRequiredError;
    // Mirrors the backend EmailAddress() rule loosely: must contain "@" with
    // something on both sides. The backend is the authority on validity.
    final at = text.indexOf('@');
    if (at <= 0 || at == text.length - 1) {
      return AppLocalizations.of(context).emailInvalidError;
    }
    return null;
  }

  // Ime/Prezime are optional, but if either is filled in, both are required -
  // CustomerProfile needs both (mirrors the admin "Moj nalog" screen).
  String? _firstNameValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty && _lastNameCtrl.text.trim().isNotEmpty) {
      return AppLocalizations.of(context).nameRequiredTogetherError;
    }
    return null;
  }

  String? _lastNameValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty && _firstNameCtrl.text.trim().isNotEmpty) {
      return AppLocalizations.of(context).nameRequiredTogetherError;
    }
    return null;
  }
}
