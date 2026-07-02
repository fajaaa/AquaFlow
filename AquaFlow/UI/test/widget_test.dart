// Widget test for the login form. Validation fails before any network/plugin
// call, so this runs without a backend or the secure-storage plugin.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_desktop/providers/auth_provider.dart';
import 'package:aquaflow_desktop/screens/login_screen.dart';

void main() {
  testWidgets('login form validates required fields', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: LoginScreen()),
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
