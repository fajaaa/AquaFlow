import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_collector/l10n/app_localizations.dart';

import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';

/// Email + password login form, pushed on top of [WelcomeScreen]. On success
/// the root `_AuthGate` rebuilds into the authenticated flow, but since this
/// screen was pushed (not the root route), it must explicitly pop itself
/// (and any screens below it) to reveal that rebuilt root.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    final email = await context.read<AuthProvider>().getRememberedEmail();
    if (!mounted || email == null) return;
    setState(() => _emailController.text = email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      email: _emailController.text,
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;

    if (success) {
      // Pop back past the WelcomeScreen (and any other pushed auth screens)
      // to reveal the root route, which _AuthGate has already rebuilt into
      // PlatformGate now that the user is authenticated.
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    final message =
        auth.errorMessage ?? AppLocalizations.of(context).loginFailedError;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = context.select<AuthProvider, bool>((a) => a.isBusy);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Container(
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
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                loc.loginTitle,
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
                        // Logo card on the gradient, above the form card.
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 56,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Text(
                              loc.appTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            loc.loginWelcomeBack,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
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
                                  TextFormField(
                                    controller: _emailController,
                                    enabled: !isBusy,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: loc.fieldEmailLabel,
                                      prefixIcon: const Icon(
                                        Icons.email_outlined,
                                      ),
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
                                    controller: _passwordController,
                                    enabled: !isBusy,
                                    obscureText: _obscurePassword,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) =>
                                        isBusy ? null : _submit(),
                                    decoration: InputDecoration(
                                      labelText: loc.fieldPasswordLabel,
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      border: const OutlineInputBorder(),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                      ),
                                    ),
                                    validator: (value) =>
                                        (value == null || value.isEmpty)
                                        ? loc.passwordRequiredError
                                        : null,
                                  ),
                                  CheckboxListTile(
                                    value: _rememberMe,
                                    onChanged: isBusy
                                        ? null
                                        : (value) => setState(
                                            () => _rememberMe = value ?? true,
                                          ),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    title: Text(loc.loginRememberMe),
                                  ),
                                  const SizedBox(height: 20),
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
                                        disabledBackgroundColor:
                                            Colors.transparent,
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
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : Text(loc.authLoginButton),
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
          const Positioned(
            top: 8,
            right: 8,
            child: SafeArea(child: _LanguageToggle()),
          ),
        ],
      ),
    );
  }
}

/// Small BS/EN switch, independent of any account/login state and with no
/// backend call - the only way to change language before authenticating.
/// Nothing here persists: a fresh app launch defaults back to
/// [LocaleProvider]'s own `Locale('bs')` until a logged-in user's
/// `UserPreference.Language` is fetched in `AuthProvider.bootstrap()`.
class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle();

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<LocaleProvider>().locale.languageCode;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SegmentedButton<String>(
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
        segments: const [
          ButtonSegment(value: 'bs', label: Text('BS')),
          ButtonSegment(value: 'en', label: Text('EN')),
        ],
        selected: {languageCode},
        onSelectionChanged: (selection) =>
            context.read<LocaleProvider>().setLanguageCode(selection.first),
      ),
    );
  }
}
