import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_desktop/admin/models/admin_customer_profile_draft.dart';
import 'package:aquaflow_desktop/admin/services/admin_account_service.dart';
import 'package:aquaflow_desktop/shared/models/account_details.dart';
import 'package:aquaflow_desktop/shared/providers/auth_provider.dart';
import 'package:aquaflow_desktop/shared/services/account_exception.dart';
import 'package:aquaflow_desktop/shared/services/account_service.dart';

/// Admin-only "Moj nalog" screen (embedded directly in
/// [AdminDashboardScreen], not pushed as a route - unlike the shared
/// `AccountEditScreen` used by the mobile customer/collector "Nalog" tab).
///
/// Edits the signed-in admin's own account with the same depth as the
/// "Korisnici" editor dialog (email, phone, profile name/language/theme,
/// password) - minus role and active status, which stay off-limits for
/// self-editing everywhere in this app to avoid privilege escalation.
///
/// Three independent writes happen on save, each only when relevant data
/// changed: `PUT /Account/me` (email/phone, via [AccountService]), a
/// create-or-update of the caller's own CustomerProfile (name/language/theme,
/// via [AdminAccountService]) only when a name was entered, and
/// `PUT /Account/me/password` (via [AdminAccountService]) only when the
/// password fields were filled in - which requires the current password for
/// confirmation, unlike an admin resetting another user's password from the
/// Korisnici tab.
class AdminAccountEditScreen extends StatefulWidget {
  const AdminAccountEditScreen({super.key});

  @override
  State<AdminAccountEditScreen> createState() => _AdminAccountEditScreenState();
}

class _AdminAccountEditScreenState extends State<AdminAccountEditScreen> {
  final AccountService _accountService = AccountService();
  final AdminAccountService _profileService = AdminAccountService();
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  AccountDetails? _details;
  int? _existingProfileId;
  String? _customerCode;
  String _defaultLanguage = 'bs';
  String _theme = 'light';

  bool _loading = true;
  String? _loadError;
  bool _saving = false;

  bool get _hasProfileInput =>
      _firstNameCtrl.text.trim().isNotEmpty || _lastNameCtrl.text.trim().isNotEmpty;

  bool get _hasPasswordInput =>
      _currentPasswordCtrl.text.isNotEmpty ||
      _newPasswordCtrl.text.isNotEmpty ||
      _confirmPasswordCtrl.text.isNotEmpty;

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
    if (userId == null) {
      setState(() {
        _loading = false;
        _loadError = 'Niste prijavljeni.';
      });
      return;
    }

    try {
      final details = await _accountService.fetch();
      final profile = await _profileService.fetchProfile(userId);
      if (!mounted) return;

      _details = details;
      _emailCtrl.text = details.email;
      _phoneCtrl.text = details.phone;
      _existingProfileId = profile?.id;
      _customerCode = profile?.customerCode;
      _firstNameCtrl.text = profile?.firstName ?? '';
      _lastNameCtrl.text = profile?.lastName ?? '';
      _defaultLanguage = profile?.defaultLanguage ?? 'bs';
      _theme = profile?.theme ?? 'light';
      setState(() => _loading = false);
    } on AccountException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.message;
      });
    }
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    final current = _details;
    final userId = _userId;
    if (form == null || !form.validate() || current == null || userId == null) {
      return;
    }

    setState(() => _saving = true);
    try {
      await _accountService.update(AccountDetails(
        id: current.id,
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        userRole: current.userRole,
        isActive: current.isActive,
      ));

      if (_hasProfileInput) {
        await _profileService.saveProfile(
          userId,
          AdminCustomerProfileDraft(
            firstName: _firstNameCtrl.text.trim(),
            lastName: _lastNameCtrl.text.trim(),
            defaultLanguage: _defaultLanguage,
            theme: _theme,
          ),
          existingProfileId: _existingProfileId,
        );
      }

      if (_hasPasswordInput) {
        await _profileService.changePassword(
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
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _accountService.dispose();
    _profileService.dispose();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Moj nalog')),
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
                  const _SectionLabel('Podaci naloga'),
                  _field(
                    controller: _emailCtrl,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: _emailValidator,
                    maxLength: 150,
                  ),
                  _field(
                    controller: _phoneCtrl,
                    label: 'Telefon',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: _phoneValidator,
                    maxLength: 30,
                  ),
                  const SizedBox(height: 8),
                  const _SectionLabel('Profil'),
                  if (_customerCode != null) ...[
                    TextFormField(
                      key: ValueKey(_customerCode),
                      initialValue: _customerCode,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Šifra korisnika (automatski dodijeljena)',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
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
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _defaultLanguage,
                          decoration: const InputDecoration(
                            labelText: 'Jezik',
                            prefixIcon: Icon(Icons.language_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'bs', child: Text('Bosanski')),
                            DropdownMenuItem(value: 'en', child: Text('Engleski')),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _defaultLanguage = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _theme,
                          decoration: const InputDecoration(
                            labelText: 'Tema',
                            prefixIcon: Icon(Icons.palette_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'light', child: Text('Svijetla')),
                            DropdownMenuItem(value: 'dark', child: Text('Tamna')),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _theme = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel('Promjena lozinke'),
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

  String? _emailValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Obavezno polje.';
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(text)) return 'Unesite ispravan email.';
    return null;
  }

  String? _phoneValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final phonePattern = RegExp(r'^[0-9+\-\s()]+$');
    if (!phonePattern.hasMatch(text) ||
        text.replaceAll(RegExp(r'[^0-9]'), '').length < 6) {
      return 'Unesite ispravan broj telefona.';
    }
    return null;
  }

  // Ime/Prezime are optional, but if either is filled in, both are required -
  // CustomerProfile needs both (mirrors the Korisnici editor dialog).
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

/// Small muted heading that separates the form into sections.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
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
              label: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      ),
    );
  }
}
