import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_customer/app/unavailable_screen.dart';
import 'package:aquaflow_customer/screens/customer_shell.dart';
import 'package:aquaflow_customer/shared/providers/auth_provider.dart';

/// This app is customer-only: any other role reaching an authenticated
/// session is blocked with a message instead of being shown a UI that
/// doesn't exist here.
class RoleGate extends StatelessWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context
        .select<AuthProvider, String>((a) => a.session?.userRole ?? '')
        .toLowerCase();

    if (role == 'customer') {
      return const CustomerShell();
    }
    return UnavailableScreen(
      icon: Icons.help_outline,
      title: 'Nepoznata uloga',
      message: 'Vaš nalog nema podržanu ulogu za ovu aplikaciju. '
          'Obratite se administratoru.',
      onLogout: () => context.read<AuthProvider>().logout(),
    );
  }
}
