import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_desktop/collector/screens/collector_water_meter_requests_screen.dart';
import 'package:aquaflow_desktop/collector/screens/collector_water_meters_screen.dart';
import 'package:aquaflow_desktop/shared/providers/notification_badge_provider.dart';
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
class CollectorShell extends StatefulWidget {
  const CollectorShell({super.key});

  @override
  State<CollectorShell> createState() => _CollectorShellState();
}

class _CollectorShellState extends State<CollectorShell> {
  // Index of the "Obavijesti" tab below - kept in one place so the
  // onTabChanged check can't drift from the tabs list.
  static const _notificationsTabIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<NotificationBadgeProvider>().refresh();
  }

  void _onTabChanged(int index) {
    if (index == _notificationsTabIndex) {
      context.read<NotificationBadgeProvider>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationBadgeProvider>().unreadCount;

    return MobileShell(
      onTabChanged: _onTabChanged,
      tabs: [
        MobileTab(
          icon: Icons.notifications_outlined,
          selectedIcon: Icons.notifications,
          label: 'Obavijesti',
          badgeCount: unreadCount,
          body: const NotificationsScreen(),
        ),
        const MobileTab(
          icon: Icons.water_drop_outlined,
          selectedIcon: Icons.water_drop,
          label: 'Vodomjeri',
          body: CollectorWaterMetersScreen(),
        ),
        const MobileTab(
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment,
          label: 'Nalozi',
          body: CollectorWaterMeterRequestsScreen(),
        ),
        const MobileTab(
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: 'Nalog',
          body: AccountScreen(),
        ),
      ],
    );
  }
}
