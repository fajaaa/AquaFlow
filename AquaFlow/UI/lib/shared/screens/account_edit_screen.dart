import 'package:flutter/material.dart';

import '../models/account_details.dart';
import '../services/account_exception.dart';
import '../services/account_service.dart';

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
/// editable; a password change (`PUT /Account/me/password`) is sent only when
/// the password fields are filled in, mirroring the admin "Moj nalog" screen
/// (`AdminAccountEditScreen`) - this is the mobile customer/collector path.
class AccountEditScreen extends StatefulWidget {
  const AccountEditScreen({super.key});

  @override
  State<AccountEditScreen> createState() => _AccountEditScreenState();
}

class _AccountEditScreenState extends State<AccountEditScreen> {
  final AccountService _service = AccountService();
  final _formKey = GlobalKey<FormState>();

  // One controller per editable field; created empty and prefilled once the
  // data loads, so they can be disposed unconditionally.
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  AccountDetails? _details;
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
    try {
      final details = await _service.fetch();
      _details = details;
      _emailCtrl.text = details.email;
      _phoneCtrl.text = details.phone;
      if (mounted) setState(() => _loading = false);
    } on AccountException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = e.message;
        });
      }
    }
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    final current = _details;
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
    _service.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
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
