import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_desktop/app/unavailable_screen.dart';
import 'package:aquaflow_desktop/collector/screens/collector_shell.dart';
import 'package:aquaflow_desktop/customer/screens/customer_shell.dart';
import 'package:aquaflow_desktop/shared/providers/auth_provider.dart';

/// Mobile/tablet (Android/iOS) routing by role, reached once the user is
/// authenticated. The role comes from the JWT (`session.userRole`) and is
/// matched case-insensitively.
///
/// - `customer` -> [CustomerShell]
/// - `collector` -> [CollectorShell]
/// - `admin`     -> [CollectorShell] (product decision: an admin on a phone has
///   no dedicated admin UI, so they use the same shell as a collector)
/// - anything else -> a blocking [UnavailableScreen] with a logout action
class MobileRoleRouter extends StatelessWidget {
  const MobileRoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context
        .select<AuthProvider, String>((a) => a.session?.userRole ?? '')
        .toLowerCase();

    switch (role) {
      case 'customer':
        return const CustomerShell();
      case 'collector':
      case 'admin':
        return const CollectorShell();
      default:
        return UnavailableScreen(
          icon: Icons.help_outline,
          title: 'Nepoznata uloga',
          message: 'Vaš nalog nema podržanu ulogu za mobilnu aplikaciju. '
              'Obratite se administratoru.',
          onLogout: () => context.read<AuthProvider>().logout(),
        );
    }
  }
}
