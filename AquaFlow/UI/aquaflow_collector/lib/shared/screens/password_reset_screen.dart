import 'package:flutter/material.dart';

import 'package:aquaflow_collector/l10n/app_localizations.dart';

import '../services/account_exception.dart';
import '../services/account_service.dart';

/// Screen for changing the signed-in user's own password
/// (`PUT /Account/me/password`).
///
/// Reached from the "Nalog" tab (see `AccountScreen`) - split out of the
/// former single "Uredi nalog" screen together with
/// `PersonalDetailsEditScreen` and `LocationEditScreen`. Unlike those two,
/// this screen loads nothing from the backend, so it renders the form
/// immediately - no [AsyncStateView] needed.
class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final AccountService _service = AccountService();
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _saving = false;

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _saving = true);
    try {
      await _service.changePassword(
        currentPassword: _currentPasswordCtrl.text,
        newPassword: _newPasswordCtrl.text,
      );
      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).passwordResetSuccess),
        ),
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
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.passwordResetTitle)),
      body: SafeArea(
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
                      loc.passwordResetDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _field(
                      controller: _currentPasswordCtrl,
                      label: loc.passwordResetCurrentLabel,
                      validator: _currentPasswordValidator,
                    ),
                    _field(
                      controller: _newPasswordCtrl,
                      label: loc.passwordResetNewLabel,
                      validator: _newPasswordValidator,
                    ),
                    _field(
                      controller: _confirmPasswordCtrl,
                      label: loc.passwordResetConfirmLabel,
                      validator: _confirmPasswordValidator,
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
                          : const Icon(Icons.lock_reset_outlined),
                      label: Text(
                        _saving
                            ? loc.commonSaving
                            : loc.passwordResetSubmitButton,
                      ),
                    ),
                  ],
                ),
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
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: true,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock_outline),
        ),
      ),
    );
  }

  // Unlike the fields on the old combined screen (optional - blank meant "no
  // change"), this screen exists only to change the password, so all three
  // fields are always required.
  String? _currentPasswordValidator(String? value) {
    if ((value ?? '').isEmpty) {
      return AppLocalizations.of(context).passwordResetCurrentRequiredError;
    }
    return null;
  }

  String? _newPasswordValidator(String? value) {
    final text = value ?? '';
    final loc = AppLocalizations.of(context);
    if (text.isEmpty) return loc.passwordResetNewRequiredError;
    if (text.length < 6) return loc.passwordTooShortError;
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if (value != _newPasswordCtrl.text) {
      return AppLocalizations.of(context).passwordMismatchError;
    }
    return null;
  }
}
