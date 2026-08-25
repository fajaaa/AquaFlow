import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_desktop/app/role_gate.dart';
import 'package:aquaflow_desktop/l10n/app_localizations.dart';
import 'package:aquaflow_desktop/shared/providers/auth_provider.dart';
import 'package:aquaflow_desktop/shared/providers/locale_provider.dart';
import 'package:aquaflow_desktop/shared/providers/notification_badge_provider.dart';
import 'package:aquaflow_desktop/shared/providers/theme_provider.dart';
import 'package:aquaflow_desktop/shared/screens/welcome_screen.dart';
import 'package:aquaflow_desktop/shared/theme/app_theme.dart';

/// This app is the admin-only desktop client (Windows/macOS/Linux) - there is
/// no push/checkout wiring here, unlike the customer/collector mobile apps.
final _navigatorKey = GlobalKey<NavigatorState>();
final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

final _notificationBadgeProvider = NotificationBadgeProvider();

/// Created here (not inside [AquaFlowApp]'s `build`) so the same instance can
/// be passed into [AuthProvider], which applies the signed-in user's
/// `UserPreference.Theme` to it after login/session restore.
final _themeProvider = ThemeProvider();

/// Created here (not inside [AquaFlowApp]'s `build`) so the same instance can
/// be passed into [AuthProvider], which applies the signed-in user's
/// `UserPreference.Language` to it after login/session restore.
final _localeProvider = LocaleProvider();

void main() {
  runApp(const AquaFlowApp());
}

class AquaFlowApp extends StatelessWidget {
  const AquaFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            themeProvider: _themeProvider,
            localeProvider: _localeProvider,
          )..bootstrap(),
        ),
        ChangeNotifierProvider.value(value: _notificationBadgeProvider),
        ChangeNotifierProvider.value(value: _themeProvider),
        ChangeNotifierProvider.value(value: _localeProvider),
      ],
      child: Builder(
        builder: (context) {
          final themeMode = context.select<ThemeProvider, ThemeMode>(
            (p) => p.themeMode,
          );
          final locale = context.select<LocaleProvider, Locale>(
            (p) => p.locale,
          );
          return MaterialApp(
            navigatorKey: _navigatorKey,
            scaffoldMessengerKey: _scaffoldMessengerKey,
            title: 'AquaFlow',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const _AuthGate(),
          );
        },
      ),
    );
  }
}

/// Chooses the screen based on auth state: a splash while [AuthStatus.unknown]
/// (bootstrap in flight), then login or - once authenticated - [RoleGate].
/// Because it watches the provider, login/logout swap the screen with no
/// manual navigation.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>((a) => a.status);

    switch (status) {
      case AuthStatus.unknown:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.authenticated:
        return const RoleGate();
      case AuthStatus.unauthenticated:
        return const WelcomeScreen();
    }
  }
}
