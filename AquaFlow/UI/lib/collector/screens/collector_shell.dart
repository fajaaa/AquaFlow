import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/shared/screens/account_screen.dart';
import 'package:aquaflow_desktop/shared/screens/mobile_shell.dart';
import 'package:aquaflow_desktop/shared/screens/notifications_screen.dart';

/// Mobile home for the `collector` (Sakupljač/Inkasant) role.
///
/// Also used by an `admin` signed in on a phone (product decision - see
/// [MobileRoleRouter]). Configures the shared [MobileShell] with the
/// collector-facing tabs; the first three are placeholders until their real
/// screens are built, and the last is the shared [AccountScreen] ("Nalog").
class CollectorShell extends StatelessWidget {
  const CollectorShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const MobileShell(
      tabs: [
        MobileTab(
          icon: Icons.notifications_outlined,
          selectedIcon: Icons.notifications,
          label: 'Obavijesti',
          body: NotificationsScreen(),
        ),
        MobileTab(
          icon: Icons.speed_outlined,
          selectedIcon: Icons.speed,
          label: 'Očitanja',
          body: PlaceholderTab(icon: Icons.speed, label: 'Očitanja vodomjera'),
        ),
        MobileTab(
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment,
          label: 'Nalozi',
          body: PlaceholderTab(icon: Icons.assignment, label: 'Radni nalozi'),
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
