import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_customer/app/role_gate.dart';
import 'package:aquaflow_customer/shared/providers/auth_provider.dart';
import 'package:aquaflow_customer/shared/providers/notification_badge_provider.dart';
import 'package:aquaflow_customer/shared/providers/theme_provider.dart';
import 'package:aquaflow_customer/shared/screens/welcome_screen.dart';
import 'package:aquaflow_customer/shared/services/push_message_handler.dart';
import 'package:aquaflow_customer/shared/services/stripe_config_service.dart';
import 'package:aquaflow_customer/shared/theme/app_theme.dart';

/// Root navigator/messenger keys, needed so [PushMessageHandler] can push a
/// route and show a SnackBar from FCM's top-level message callbacks, which
/// run outside any screen's own [BuildContext].
final _navigatorKey = GlobalKey<NavigatorState>();
final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Created here rather than inside [AquaFlowApp]'s `build` so
/// [PushMessageHandler] - which lives outside the widget tree - can bump the
/// "Obavijesti" tab badge directly from FCM's `onMessage` callback.
final _notificationBadgeProvider = NotificationBadgeProvider();

/// Created here (not inside [AquaFlowApp]'s `build`) so the same instance can
/// be passed into [AuthProvider], which applies the signed-in user's
/// `UserPreference.Theme` to it after login/session restore.
final _themeProvider = ThemeProvider();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AquaFlowApp());
  // Runs after runApp so `_navigatorKey.currentState` is already attached -
  // a cold start can resolve getInitialMessage() immediately.
  await PushMessageHandler(
    navigatorKey: _navigatorKey,
    scaffoldMessengerKey: _scaffoldMessengerKey,
    onForegroundMessage: _notificationBadgeProvider.increment,
  ).init();
  await _initStripe();
}

/// Configures the Stripe SDK once at startup, well before the customer can
/// reach `CustomerInvoiceDetailScreen`'s "Plati" button. A null config (no
/// network, or the active provider isn't Stripe) just leaves the SDK
/// unconfigured; checkout still works via the pre-Stripe SnackBar fallback.
Future<void> _initStripe() async {
  final config = await StripeConfigService().fetch();
  if (config == null) return;

  Stripe.publishableKey = config.publishableKey;
  await Stripe.instance.applySettings();
}

class AquaFlowApp extends StatelessWidget {
  const AquaFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Restore any saved session as soon as the provider is created.
        ChangeNotifierProvider(
          create: (_) => AuthProvider(themeProvider: _themeProvider)..bootstrap(),
        ),
        // Shared instance (not `create`) so PushMessageHandler's onMessage
        // callback in `main()`, which runs outside the widget tree, bumps the
        // exact same badge state the shell reads.
        ChangeNotifierProvider.value(value: _notificationBadgeProvider),
        // Shared instance (not `create`) - see the comment on [_themeProvider].
        ChangeNotifierProvider.value(value: _themeProvider),
      ],
      child: Builder(
        builder: (context) {
          final themeMode = context.select<ThemeProvider, ThemeMode>(
            (p) => p.themeMode,
          );
          return MaterialApp(
            navigatorKey: _navigatorKey,
            scaffoldMessengerKey: _scaffoldMessengerKey,
            title: 'AquaFlow',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
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
