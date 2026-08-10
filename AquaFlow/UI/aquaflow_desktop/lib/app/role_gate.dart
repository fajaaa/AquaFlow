import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_desktop/app/unavailable_screen.dart';
import 'package:aquaflow_desktop/screens/admin_dashboard_screen.dart';
import 'package:aquaflow_desktop/shared/providers/auth_provider.dart';

/// This app is admin-only: any other role reaching an authenticated session
/// (there is no admin/customer/collector split within one binary anymore -
/// see the customer/collector projects for those) is blocked with a message
/// instead of being shown a UI that doesn't exist here.
class RoleGate extends StatelessWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context
        .select<AuthProvider, String>((a) => a.session?.userRole ?? '')
        .toLowerCase();

    if (role == 'admin') {
      return const AdminDashboardScreen();
    }
    return UnavailableScreen(
      icon: Icons.phone_iphone,
      title: 'Nedostupno na računaru',
      message: 'Desktop aplikacija je namijenjena samo administratorima. '
          'Za vašu ulogu koristite mobilnu aplikaciju.',
      onLogout: () => context.read<AuthProvider>().logout(),
    );
  }
}
