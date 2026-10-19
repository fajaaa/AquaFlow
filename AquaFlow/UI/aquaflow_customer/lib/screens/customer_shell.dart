import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_customer/app/notification_deep_link_handlers.dart';
import 'package:aquaflow_customer/l10n/app_localizations.dart';
import 'package:aquaflow_customer/screens/customer_fault_reports_screen.dart';
import 'package:aquaflow_customer/screens/customer_support_tickets_screen.dart';
import 'package:aquaflow_customer/screens/customer_water_meters_screen.dart';
import 'package:aquaflow_customer/shared/navigation/app_navigation.dart';
import 'package:aquaflow_customer/shared/navigation/notification_deep_links.dart';
import 'package:aquaflow_customer/shared/providers/notification_badge_provider.dart';
import 'package:aquaflow_customer/shared/screens/account_screen.dart';
import 'package:aquaflow_customer/shared/screens/mobile_shell.dart';
import 'package:aquaflow_customer/shared/screens/notifications_screen.dart';

/// Mobile home for the `customer` (Kupac) role.
///
/// Configures the shared [MobileShell] with the customer-facing tabs, in
/// order: "Obavijesti" ([NotificationsScreen]), "Vodomjeri"
/// ([CustomerWaterMetersScreen]), "Prijave kvarova"
/// ([CustomerFaultReportsScreen]), and "Nalog" (the shared [AccountScreen]).
///
/// Mounted exactly while a customer is signed in, so it is what starts
/// [NotificationBadgeProvider]'s polling (and stops it again on logout) and
/// registers the customer's notification deep links
/// ([customerNotificationDeepLinks]) for the shared detail screen.
/// [NotificationsScreen] itself (via `NotificationBadgeProvider.markSeen`)
/// clears the badge whenever the inbox list loads.
class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  late final NotificationBadgeProvider _badge;

  @override
  void initState() {
    super.initState();
    _badge = context.read<NotificationBadgeProvider>()..start();
    NotificationDeepLinks.instance.registerAll(customerNotificationDeepLinks);
  }

  @override
  void dispose() {
    NotificationDeepLinks.instance.unregisterAll(customerNotificationDeepLinks);
    _badge.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationBadgeProvider>().unreadCount;
    final loc = AppLocalizations.of(context);

    return MobileShell(
      tabs: [
        MobileTab(
          icon: Icons.notifications_outlined,
          selectedIcon: Icons.notifications,
          label: loc.tabNotifications,
          badgeCount: unreadCount,
          body: const NotificationsScreen(),
        ),
        MobileTab(
          icon: Icons.water_drop_outlined,
          selectedIcon: Icons.water_drop,
          label: loc.tabWaterMeters,
          body: const CustomerWaterMetersScreen(),
        ),
        MobileTab(
          icon: Icons.report_problem_outlined,
          selectedIcon: Icons.report_problem,
          label: loc.tabFaultReports,
          body: const CustomerFaultReportsScreen(),
        ),
        MobileTab(
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: loc.tabAccount,
          body: AccountScreen(
            extraEntries: [
              AccountEntry(
                icon: Icons.support_agent_outlined,
                title: loc.supportTitle,
                subtitle: loc.supportSubtitle,
                onTap: (context) =>
                    context.pushScreen(const CustomerSupportTicketsScreen()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
