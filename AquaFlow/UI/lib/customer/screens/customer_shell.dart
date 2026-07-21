import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_desktop/customer/screens/customer_invoices_screen.dart';
import 'package:aquaflow_desktop/customer/screens/customer_support_tickets_screen.dart';
import 'package:aquaflow_desktop/customer/screens/customer_water_meters_screen.dart';
import 'package:aquaflow_desktop/shared/navigation/app_navigation.dart';
import 'package:aquaflow_desktop/shared/providers/notification_badge_provider.dart';
import 'package:aquaflow_desktop/shared/screens/account_screen.dart';
import 'package:aquaflow_desktop/shared/screens/mobile_shell.dart';
import 'package:aquaflow_desktop/shared/screens/notifications_screen.dart';

/// Mobile home for the `customer` (Kupac) role.
///
/// Configures the shared [MobileShell] with the customer-facing tabs. The
/// last tab is the shared [AccountScreen] ("Nalog").
class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
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
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          label: 'Računi',
          body: CustomerInvoicesScreen(),
        ),
        const MobileTab(
          icon: Icons.water_drop_outlined,
          selectedIcon: Icons.water_drop,
          label: 'Vodomjeri',
          body: CustomerWaterMetersScreen(),
        ),
        MobileTab(
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: 'Nalog',
          body: AccountScreen(
            extraEntries: [
              AccountEntry(
                icon: Icons.support_agent_outlined,
                title: 'Podrška',
                subtitle: 'Vaši tiketi i poruke podršci',
                onTap: (context) => context.pushScreen(
                  const CustomerSupportTicketsScreen(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
