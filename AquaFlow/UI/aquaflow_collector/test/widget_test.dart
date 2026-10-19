// Widget test for the login form. Validation fails before any network/plugin
// call, so this runs without a backend or the secure-storage plugin.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_collector/l10n/app_localizations.dart';
import 'package:aquaflow_collector/shared/providers/auth_provider.dart';
import 'package:aquaflow_collector/shared/providers/locale_provider.dart';
import 'package:aquaflow_collector/shared/screens/login_screen.dart';

void main() {
  testWidgets('login form validates required fields', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ],
        // LoginScreen reads AppLocalizations, so the delegates must be wired
        // like in main.dart; English is pinned because the asserts below
        // match the English strings.
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.text('Sign in'), findsOneWidget);

    // Submitting an empty form shows validation errors, not a network call.
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
  });
}
