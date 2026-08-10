import 'package:flutter/material.dart';

import '../models/company_settings.dart';
import '../services/company_settings_exception.dart';
import '../services/company_settings_service.dart';

/// Admin-only screen for viewing and editing the company settings.
///
/// Reached from the "Nalog" tab (see [AccountScreen]) only when the signed-in
/// user is an admin. Unlike the tab bodies inside [MasterScreen], this screen is
/// pushed as its own route, so it renders its own Scaffold/AppBar.
///
/// The single settings row is loaded on open; the form is prefilled with it and
/// saved with `PUT /CompanySettings/{id}` through [CompanySettingsService].
class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  final CompanySettingsService _service = CompanySettingsService();
  final _formKey = GlobalKey<FormState>();

  // One controller per editable field; created empty and prefilled once the
  // settings load, so they can be disposed unconditionally.
  final _companyNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _taxNumberCtrl = TextEditingController();
  final _bankAccountCtrl = TextEditingController();
  final _logoUrlCtrl = TextEditingController();
  final _defaultLanguageCtrl = TextEditingController();
  final _defaultCurrencyCtrl = TextEditingController();

  int? _settingsId;
  bool _loading = true;
  String? _loadError;
  bool _saving = false;

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
      final settings = await _service.fetch();
      _settingsId = settings.id;
      _companyNameCtrl.text = settings.companyName;
      _addressCtrl.text = settings.address;
      _phoneCtrl.text = settings.phone;
      _emailCtrl.text = settings.email;
      _taxNumberCtrl.text = settings.taxNumber;
      _bankAccountCtrl.text = settings.bankAccount;
      _logoUrlCtrl.text = settings.logoUrl ?? '';
      _defaultLanguageCtrl.text = settings.defaultLanguage;
      _defaultCurrencyCtrl.text = settings.defaultCurrency;
      if (mounted) setState(() => _loading = false);
    } on CompanySettingsException catch (e) {
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
    if (form == null || !form.validate() || _settingsId == null) return;

    setState(() => _saving = true);
    final logo = _logoUrlCtrl.text.trim();
    final updated = CompanySettings(
      id: _settingsId!,
      companyName: _companyNameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      taxNumber: _taxNumberCtrl.text.trim(),
      bankAccount: _bankAccountCtrl.text.trim(),
      logoUrl: logo.isEmpty ? null : logo,
      defaultLanguage: _defaultLanguageCtrl.text.trim(),
      defaultCurrency: _defaultCurrencyCtrl.text.trim(),
    );

    try {
      await _service.update(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Postavke firme su sačuvane.')),
      );
    } on CompanySettingsException catch (e) {
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
    _companyNameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _taxNumberCtrl.dispose();
    _bankAccountCtrl.dispose();
    _logoUrlCtrl.dispose();
    _defaultLanguageCtrl.dispose();
    _defaultCurrencyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Postavke firme')),
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
                    controller: _companyNameCtrl,
                    label: 'Naziv firme',
                    icon: Icons.business_outlined,
                    validator: _required,
                    maxLength: 150,
                  ),
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
                  _field(
                    controller: _addressCtrl,
                    label: 'Adresa',
                    icon: Icons.location_on_outlined,
                    maxLength: 200,
                  ),
                  _field(
                    controller: _taxNumberCtrl,
                    label: 'Porezni broj',
                    icon: Icons.badge_outlined,
                    maxLength: 50,
                  ),
                  _field(
                    controller: _bankAccountCtrl,
                    label: 'Bankovni račun',
                    icon: Icons.account_balance_outlined,
                    maxLength: 80,
                  ),
                  _field(
                    controller: _logoUrlCtrl,
                    label: 'URL logotipa (opcionalno)',
                    icon: Icons.image_outlined,
                    keyboardType: TextInputType.url,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          controller: _defaultLanguageCtrl,
                          label: 'Jezik',
                          icon: Icons.language_outlined,
                          validator: _required,
                          maxLength: 10,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          controller: _defaultCurrencyCtrl,
                          label: 'Valuta',
                          icon: Icons.payments_outlined,
                          validator: _required,
                          maxLength: 10,
                        ),
                      ),
                    ],
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          counterText: '',
        ),
      ),
    );
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Obavezno polje.' : null;

  String? _email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Obavezno polje.';
    // Mirrors the backend EmailAddress() rule loosely: must contain "@" with
    // something on both sides. The backend is the authority on validity.
    final at = text.indexOf('@');
    if (at <= 0 || at == text.length - 1) return 'Unesite ispravan email.';
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
