import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/collector/screens/collector_water_meter_requests_screen.dart';
import 'package:aquaflow_desktop/collector/screens/collector_water_meters_screen.dart';
import 'package:aquaflow_desktop/shared/screens/account_screen.dart';
import 'package:aquaflow_desktop/shared/screens/mobile_shell.dart';
import 'package:aquaflow_desktop/shared/screens/notifications_screen.dart';

/// Mobile home for the `collector` (Sakupljač/Inkasant) role.
///
/// Also used by an `admin` signed in on a phone (product decision - see
/// [MobileRoleRouter]). Configures the shared [MobileShell] with the
/// collector-facing tabs; "Obavijesti" and "Nalog" are the shared screens,
/// "Vodomjeri" is [CollectorWaterMetersScreen] (replaces the former
/// "Očitanja"/route tab with a free-text meter search), and "Nalozi" is
/// [CollectorWaterMeterRequestsScreen].
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
          icon: Icons.water_drop_outlined,
          selectedIcon: Icons.water_drop,
          label: 'Vodomjeri',
          body: CollectorWaterMetersScreen(),
        ),
        MobileTab(
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment,
          label: 'Nalozi',
          body: CollectorWaterMeterRequestsScreen(),
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
