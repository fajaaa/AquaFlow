import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_desktop/l10n/app_localizations.dart';
import 'package:aquaflow_desktop/services/admin_account_service.dart';
import 'package:aquaflow_desktop/shared/models/account_details.dart';
import 'package:aquaflow_desktop/shared/models/user_preferences.dart';
import 'package:aquaflow_desktop/shared/providers/auth_provider.dart';
import 'package:aquaflow_desktop/shared/providers/locale_provider.dart';
import 'package:aquaflow_desktop/shared/providers/theme_provider.dart';
import 'package:aquaflow_desktop/shared/services/account_exception.dart';
import 'package:aquaflow_desktop/shared/services/account_service.dart';
import 'package:aquaflow_desktop/shared/services/preferences_api_service.dart';
import 'package:aquaflow_desktop/shared/services/preferences_exception.dart';
import 'package:aquaflow_desktop/shared/widgets/screen_header.dart';

/// Admin-only "Moj nalog" screen (embedded directly in
/// [AdminDashboardScreen], not pushed as a route - unlike the shared
/// `PersonalDetailsEditScreen`/`LocationEditScreen`/`PasswordResetScreen`
/// used by the mobile customer/collector "Nalog" tab).
///
/// Edits the signed-in admin's own account with the same fields as the
/// "Administratori" -> "Uredi administratora" editor dialog (email, phone,
/// name, password) - minus role and active status, which stay off-limits for
/// self-editing everywhere in this app to avoid privilege escalation. Like
/// that dialog, there is no Adresa/Jezik section here: the Admin role has no
/// CustomerProfile at all (see `AdminUsersScreenMode.usesCustomerProfile` in
/// `admin_users_screen.dart`), so `firstName`/`lastName` live directly on
/// `User` and are edited through `PUT /Account/me` alongside email/phone.
///
/// App theme ("Izgled") is separate from the profile fields: it reads/writes
/// `UserPreference.Theme` via `GET`/`PUT /Account/preferences`
/// ([PreferencesApiService]) and applies immediately to the shared
/// [ThemeProvider] on change, rather than being part of the deferred-save
/// form below.
///
/// Two independent writes happen on save: `PUT /Account/me`
/// (email/phone/firstName/lastName, via [AccountService]) always, and
/// `PUT /Account/me/password` (via [AdminAccountService]) only when the
/// password fields were filled in - which requires the current password for
/// confirmation, unlike an admin resetting another user's password from the
/// Administratori tab.
class AdminAccountEditScreen extends StatefulWidget {
  const AdminAccountEditScreen({super.key});

  @override
  State<AdminAccountEditScreen> createState() => _AdminAccountEditScreenState();
}

class _AdminAccountEditScreenState extends State<AdminAccountEditScreen> {
  final AccountService _accountService = AccountService();
  final AdminAccountService _passwordService = AdminAccountService();
  final PreferencesApiService _preferencesService = PreferencesApiService();
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  AccountDetails? _details;
  UserPreferences? _preferences;

  bool _loading = true;
  String? _loadError;
  bool _saving = false;

  bool get _hasPasswordInput =>
      _currentPasswordCtrl.text.isNotEmpty ||
      _newPasswordCtrl.text.isNotEmpty ||
      _confirmPasswordCtrl.text.isNotEmpty;

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

    if (context.read<AuthProvider>().session?.id == null) {
      setState(() {
        _loading = false;
        _loadError = AppLocalizations.of(context).notLoggedInError;
      });
      return;
    }

    try {
      final details = await _accountService.fetch();
      if (!mounted) return;

      _details = details;
      _emailCtrl.text = details.email;
      _phoneCtrl.text = details.phone;
      _firstNameCtrl.text = details.firstName;
      _lastNameCtrl.text = details.lastName;
      setState(() => _loading = false);
      _loadPreferences();
    } on AccountException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.message;
      });
    }
  }

  /// Fetches `GET /Account/preferences` separately from [_load]: a failure
  /// here (e.g. offline) must not block editing the rest of the account, so
  /// it just leaves [_preferences] null and the theme switch defaults to
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
  /// admin), but a snackbar reports that the choice wasn't saved.
  Future<void> _setTheme(bool isDark) async {
    final current =
        _preferences ??
        const UserPreferences(
          theme: 'light',
          language: 'bs',
          receiveEmailNotifications: true,
          receivePushNotifications: true,
        );
    final updated = current.copyWith(theme: isDark ? 'dark' : 'light');

    setState(() => _preferences = updated);
    context.read<ThemeProvider>().setThemeMode(
      isDark ? ThemeMode.dark : ThemeMode.light,
    );

    try {
      final saved = await _preferencesService.updatePreferences(updated);
      if (mounted) setState(() => _preferences = saved);
    } on PreferencesException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).themeSaveFailedError(e.message),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Applies [code] ('bs'/'en') to the shared [LocaleProvider] immediately,
  /// then persists it via `PUT /Account/preferences` in the background. On
  /// save failure the app language stays changed (better than reverting under
  /// the admin), but a snackbar reports that the choice wasn't saved.
  Future<void> _setLanguage(String code) async {
    final current =
        _preferences ??
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
    if (form == null || !form.validate() || current == null) {
      return;
    }

    setState(() => _saving = true);
    try {
      await _accountService.update(
        AccountDetails(
          id: current.id,
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          userRole: current.userRole,
          isActive: current.isActive,
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
        ),
      );

      if (_hasPasswordInput) {
        await _passwordService.changePassword(
          currentPassword: _currentPasswordCtrl.text,
          newPassword: _newPasswordCtrl.text,
        );
        _currentPasswordCtrl.clear();
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).accountDetailsSaveSuccess),
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
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _accountService.dispose();
    _passwordService.dispose();
    _preferencesService.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: _buildBody());
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return _ErrorRetry(message: _loadError!, onRetry: _load);
    }
    final loc = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              title: loc.myAccountTitle,
              subtitle: loc.myAccountSubtitle,
              actions: const [],
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(loc.profileSectionLabel),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _field(
                          controller: _firstNameCtrl,
                          label: loc.fieldFirstNameLabel,
                          validator: _firstNameValidator,
                          onChanged: () => setState(() {}),
                          maxLength: 80,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          controller: _lastNameCtrl,
                          label: loc.fieldLastNameLabel,
                          validator: _lastNameValidator,
                          onChanged: () => setState(() {}),
                          maxLength: 80,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  _SectionLabel(loc.contactSectionLabel),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _field(
                          controller: _emailCtrl,
                          label: loc.fieldEmailLabel,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: _emailValidator,
                          maxLength: 150,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          controller: _phoneCtrl,
                          label: loc.fieldPhoneLabel,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: _phoneValidator,
                          maxLength: 30,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  _SectionLabel(loc.personalDetailsAppearanceSectionTitle),
                  SegmentedButton<bool>(
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
                  const SizedBox(height: 14),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'bs', label: Text('Bosanski')),
                      ButtonSegment(value: 'en', label: Text('English')),
                    ],
                    selected: {_preferences?.language ?? 'bs'},
                    onSelectionChanged: (selection) =>
                        _setLanguage(selection.first),
                  ),
                  const SizedBox(height: 22),

                  _SectionLabel(loc.passwordResetTitle),
                  Text(
                    loc.passwordOptionalHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: _currentPasswordCtrl,
                    label: loc.passwordResetCurrentLabel,
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: _currentPasswordValidator,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _field(
                          controller: _newPasswordCtrl,
                          label: loc.passwordResetNewLabel,
                          icon: Icons.lock_outline,
                          obscureText: true,
                          validator: _newPasswordValidator,
                          onChanged: () => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          controller: _confirmPasswordCtrl,
                          label: loc.passwordResetConfirmLabel,
                          icon: Icons.lock_outline,
                          obscureText: true,
                          validator: _confirmPasswordValidator,
                          onChanged: () => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _saving ? null : _load,
                        child: Text(loc.dialogDismissButton),
                      ),
                      const SizedBox(width: 12),
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
                        label: Text(
                          _saving ? loc.commonSaving : loc.commonSave,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLength,
    bool obscureText = false,
    VoidCallback? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLength: maxLength,
      obscureText: obscureText,
      onChanged: onChanged == null ? null : (_) => onChanged(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
        counterText: '',
      ),
    );
  }

  String? _emailValidator(String? value) {
    final text = value?.trim() ?? '';
    final loc = AppLocalizations.of(context);
    if (text.isEmpty) return loc.fieldRequiredError;
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(text)) return loc.emailInvalidError;
    return null;
  }

  String? _phoneValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final phonePattern = RegExp(r'^[0-9+\-\s()]+$');
    if (!phonePattern.hasMatch(text) ||
        text.replaceAll(RegExp(r'[^0-9]'), '').length < 6) {
      return AppLocalizations.of(context).phoneInvalidNumberError;
    }
    return null;
  }

  // Ime/Prezime are optional, but if either is filled in, both are required -
  // mirrors the "Uredi administratora" editor dialog's validators.
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

  // The three password fields form one optional group: touch any one of them
  // and all three become required, so the backend always gets a current
  // password to verify alongside the new one.
  String? _currentPasswordValidator(String? value) {
    if ((value ?? '').isEmpty && _hasPasswordInput) {
      return AppLocalizations.of(context).passwordResetCurrentRequiredError;
    }
    return null;
  }

  String? _newPasswordValidator(String? value) {
    final text = value ?? '';
    final loc = AppLocalizations.of(context);
    if (text.isEmpty) {
      return _hasPasswordInput ? loc.passwordResetNewRequiredError : null;
    }
    if (text.length < 6) return loc.passwordTooShortError;
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if (_newPasswordCtrl.text.isEmpty) return null;
    if (value != _newPasswordCtrl.text) {
      return AppLocalizations.of(context).passwordMismatchError;
    }
    return null;
  }
}

/// Small uppercase-weight heading that separates the form into sections -
/// mirrors `_FormSectionHeader` in `admin_users_screen.dart`'s "Uredi
/// administratora" dialog so this screen reads consistently with it.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: Color(0xFF64748B),
        ),
      ),
    );
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
              label: Text(AppLocalizations.of(context).commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}
