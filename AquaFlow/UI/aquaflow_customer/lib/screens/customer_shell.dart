import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_customer/screens/customer_invoices_screen.dart';
import 'package:aquaflow_customer/screens/customer_support_tickets_screen.dart';
import 'package:aquaflow_customer/screens/customer_water_meters_screen.dart';
import 'package:aquaflow_customer/shared/navigation/app_navigation.dart';
import 'package:aquaflow_customer/shared/providers/notification_badge_provider.dart';
import 'package:aquaflow_customer/shared/screens/account_screen.dart';
import 'package:aquaflow_customer/shared/screens/mobile_shell.dart';
import 'package:aquaflow_customer/shared/screens/notifications_screen.dart';

/// Mobile home for the `customer` (Kupac) role.
///
/// Configures the shared [MobileShell] with the customer-facing tabs. The
/// last tab is the shared [AccountScreen] ("Nalog").
///
/// The "Obavijesti" tab is always index 0, i.e. [MobileShell] builds it
/// immediately on mount regardless of which tab the user later selects, so
/// [NotificationsScreen] itself (via `NotificationBadgeProvider.markSeen`)
/// is what keeps the unread badge in sync - this shell doesn't need its own
/// `NotificationBadgeProvider.refresh()` call. It used to have one in
/// `initState`/on every return to this tab, which raced the list's own load
/// (two concurrent `GET /UserNotifications/mine` calls for the same user)
/// and could backfill the same inbox row twice.
class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key});

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationBadgeProvider>().unreadCount;

    return MobileShell(
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
