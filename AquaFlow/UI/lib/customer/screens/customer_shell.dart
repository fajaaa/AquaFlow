import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/shared/screens/account_screen.dart';
import 'package:aquaflow_desktop/shared/screens/mobile_shell.dart';

/// Mobile home for the `customer` (Kupac) role.
///
/// Configures the shared [MobileShell] with the customer-facing tabs. The first
/// three are placeholders until their real screens are built; the last is the
/// shared [AccountScreen] ("Nalog").
class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const MobileShell(
      tabs: [
        MobileTab(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          label: 'Početna',
          body: PlaceholderTab(icon: Icons.home, label: 'Početna'),
        ),
        MobileTab(
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          label: 'Računi',
          body: PlaceholderTab(icon: Icons.receipt_long, label: 'Računi'),
        ),
        MobileTab(
          icon: Icons.report_problem_outlined,
          selectedIcon: Icons.report_problem,
          label: 'Prijave',
          body: PlaceholderTab(
            icon: Icons.report_problem,
            label: 'Prijave kvarova',
          ),
        ),
        MobileTab(
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: 'Nalog',
          body: AccountScreen(),
        ),
      ],
    );
  }
}
