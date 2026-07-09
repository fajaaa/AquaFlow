import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_desktop/app/platform_gate.dart';
import 'package:aquaflow_desktop/app/unavailable_screen.dart';
import 'package:aquaflow_desktop/shared/providers/auth_provider.dart';
import 'package:aquaflow_desktop/shared/screens/login_screen.dart';
import 'package:aquaflow_desktop/shared/services/push_message_handler.dart';
import 'package:aquaflow_desktop/shared/theme/app_theme.dart';

/// Root navigator/messenger keys, needed so [PushMessageHandler] can push a
/// route and show a SnackBar from FCM's top-level message callbacks, which
/// run outside any screen's own [BuildContext].
final _navigatorKey = GlobalKey<NavigatorState>();
final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Push (FCM) is mobile-only - there is no admin desktop UI for it and the
  // app never ships as a web build (see the kIsWeb block below), so Firebase
  // is only initialized on Android/iOS. Same platform check as [PlatformGate].
  final isMobile = !kIsWeb && !PlatformGate.isDesktop;
  if (isMobile) {
    await Firebase.initializeApp();
  }
  runApp(const AquaFlowApp());
  if (isMobile) {
    // Runs after runApp so `_navigatorKey.currentState` is already attached -
    // a cold start can resolve getInitialMessage() immediately.
    await PushMessageHandler(
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _scaffoldMessengerKey,
    ).init();
  }
}

class AquaFlowApp extends StatelessWidget {
  const AquaFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Restore any saved session as soon as the provider is created.
      create: (_) => AuthProvider()..bootstrap(),
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        scaffoldMessengerKey: _scaffoldMessengerKey,
        title: 'AquaFlow',
        theme: AppTheme.light,
        home: const _AppEntry(),
      ),
    );
  }
}

/// First fork, before any auth work: the app is a desktop (admin) and
/// mobile (customer/collector) product, not a web app, so opening it in a
/// browser short-circuits to an info screen. Every other platform continues to
/// the auth gate.
class _AppEntry extends StatelessWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const UnavailableScreen(
        icon: Icons.desktop_access_disabled,
        title: 'Web verzija nije dostupna',
        message: 'AquaFlow nije dostupan u web pregledniku. Administratori '
            'koriste desktop aplikaciju, a korisnici i inkasanti mobilnu '
            'aplikaciju.',
      );
    }
    return const _AuthGate();
  }
}

/// Chooses the screen based on auth state: a splash while [AuthStatus.unknown]
/// (bootstrap in flight), then login or - once authenticated - the
/// [PlatformGate], which routes by platform and role. Because it watches the
/// provider, login/logout swap the screen with no manual navigation.
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
        return const PlatformGate();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
