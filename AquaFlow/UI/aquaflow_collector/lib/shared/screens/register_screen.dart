import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_collector/l10n/app_localizations.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

/// Self-registration form for new Customers, pushed on top of either
/// [WelcomeScreen] or [LoginScreen]. On success [AuthProvider] becomes
/// authenticated (the provider auto-logs in right after registering), so
/// this screen pops every pushed auth screen to reveal the root `_AuthGate`,
/// which already renders the authenticated flow underneath.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  ThemeMode _selectedTheme = ThemeMode.light;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      email: _emailController.text,
      password: _passwordController.text,
      phone: _phoneController.text,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      theme: _selectedTheme == ThemeMode.dark ? 'dark' : 'light',
    );

    if (!mounted) return;

    if (success) {
      context.read<ThemeProvider>().setThemeMode(_selectedTheme);
      // Pop back past the WelcomeScreen (and LoginScreen, if that's where
      // registration was opened from) to reveal the root route, which
      // _AuthGate has already rebuilt into PlatformGate.
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    final message =
        auth.errorMessage ??
        AppLocalizations.of(context).registrationFailedError;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = context.select<AuthProvider, bool>((a) => a.isBusy);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.waterGradient,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: isBusy
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            loc.registerTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 8,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _firstNameController,
                                      enabled: !isBusy,
                                      textInputAction: TextInputAction.next,
                                      decoration: InputDecoration(
                                        labelText: loc.fieldFirstNameLabel,
                                        border: const OutlineInputBorder(),
                                      ),
                                      validator: (value) =>
                                          (value == null ||
                                              value.trim().isEmpty)
                                          ? loc.firstNameRequiredError
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _lastNameController,
                                      enabled: !isBusy,
                                      textInputAction: TextInputAction.next,
                                      decoration: InputDecoration(
                                        labelText: loc.fieldLastNameLabel,
                                        border: const OutlineInputBorder(),
                                      ),
                                      validator: (value) =>
                                          (value == null ||
                                              value.trim().isEmpty)
                                          ? loc.lastNameRequiredError
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                enabled: !isBusy,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: loc.fieldEmailLabel,
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  final email = value?.trim() ?? '';
                                  if (email.isEmpty) {
                                    return loc.emailRequiredError;
                                  }
                                  if (!email.contains('@')) {
                                    return loc.emailInvalidError;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _phoneController,
                                enabled: !isBusy,
                                keyboardType: TextInputType.phone,
                                autofillHints: const [
                                  AutofillHints.telephoneNumber,
                                ],
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: loc.fieldPhoneLabel,
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  final phone = value?.trim() ?? '';
                                  if (phone.isEmpty) return null;
                                  final validPattern = RegExp(
                                    r'^[0-9+\-\s()]*$',
                                  );
                                  if (!validPattern.hasMatch(phone)) {
                                    return loc.phoneInvalidError;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                enabled: !isBusy,
                                obscureText: _obscurePassword,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: loc.fieldPasswordLabel,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  final password = value ?? '';
                                  if (password.isEmpty) {
                                    return loc.passwordRequiredError;
                                  }
                                  if (password.length < 6) {
                                    return loc.passwordTooShortError;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                enabled: !isBusy,
                                obscureText: _obscureConfirmPassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) =>
                                    isBusy ? null : _submit(),
                                decoration: InputDecoration(
                                  labelText: loc.fieldConfirmPasswordLabel,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscureConfirmPassword =
                                          !_obscureConfirmPassword,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value != _passwordController.text) {
                                    return loc.passwordMismatchError;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  loc.registerThemeLabel,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SegmentedButton<ThemeMode>(
                                segments: [
                                  ButtonSegment(
                                    value: ThemeMode.light,
                                    label: Text(loc.themeLightOption),
                                    icon: const Icon(Icons.light_mode_outlined),
                                  ),
                                  ButtonSegment(
                                    value: ThemeMode.dark,
                                    label: Text(loc.themeDarkOption),
                                    icon: const Icon(Icons.dark_mode_outlined),
                                  ),
                                ],
                                selected: {_selectedTheme},
                                onSelectionChanged: isBusy
                                    ? null
                                    : (selection) => setState(
                                        () => _selectedTheme = selection.first,
                                      ),
                              ),
                              const SizedBox(height: 24),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isBusy
                                        ? [
                                            AppColors.textDark.withValues(
                                              alpha: 0.45,
                                            ),
                                            AppColors.textDark.withValues(
                                              alpha: 0.3,
                                            ),
                                          ]
                                        : AppColors.buttonGradient,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: FilledButton(
                                  onPressed: isBusy ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    disabledBackgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: isBusy
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(loc.authRegisterButton),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
}
