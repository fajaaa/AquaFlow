import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_collector/app/unavailable_screen.dart';
import 'package:aquaflow_collector/screens/collector_shell.dart';
import 'package:aquaflow_collector/shared/providers/auth_provider.dart';

/// This app is collector-only, with one exception carried over from the
/// combined app: an `admin` account has no dedicated UI here either, so by
/// product decision it also reuses [CollectorShell]. Any other role is
/// blocked with a message.
class RoleGate extends StatelessWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context
        .select<AuthProvider, String>((a) => a.session?.userRole ?? '')
        .toLowerCase();

    switch (role) {
      case 'collector':
      case 'admin':
        return const CollectorShell();
      default:
        return UnavailableScreen(
          icon: Icons.help_outline,
          title: 'Nepoznata uloga',
          message: 'Vaš nalog nema podržanu ulogu za ovu aplikaciju. '
              'Obratite se administratoru.',
          onLogout: () => context.read<AuthProvider>().logout(),
        );
    }
  }
}
