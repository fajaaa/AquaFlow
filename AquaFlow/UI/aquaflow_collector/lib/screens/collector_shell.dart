import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_collector/l10n/app_localizations.dart';
import 'package:aquaflow_collector/screens/collector_water_meter_requests_screen.dart';
import 'package:aquaflow_collector/screens/collector_water_meters_screen.dart';
import 'package:aquaflow_collector/shared/providers/notification_badge_provider.dart';
import 'package:aquaflow_collector/shared/screens/account_screen.dart';
import 'package:aquaflow_collector/shared/screens/mobile_shell.dart';
import 'package:aquaflow_collector/shared/screens/notifications_screen.dart';

/// Mobile home for the `collector` (Sakupljač/Inkasant) role.
///
/// Also used by an `admin` signed in on a phone (product decision - see
/// [MobileRoleRouter]). Configures the shared [MobileShell] with the
/// collector-facing tabs; "Obavijesti" and "Nalog" are the shared screens,
/// "Vodomjeri" is [CollectorWaterMetersScreen] (replaces the former
/// "Očitanja"/route tab with a free-text meter search), and "Nalozi" is
/// [CollectorWaterMeterRequestsScreen].
///
/// The "Obavijesti" tab is always index 0, i.e. [MobileShell] builds it
/// immediately on mount regardless of which tab the user later selects, so
/// [NotificationsScreen] itself (via `NotificationBadgeProvider.markSeen`)
/// is what keeps the unread badge in sync - this shell doesn't need its own
/// `NotificationBadgeProvider.refresh()` call. It used to have one in
/// `initState`/on every return to this tab, which raced the list's own load
/// (two concurrent `GET /UserNotifications/mine` calls for the same user)
/// and could backfill the same inbox row twice.
class CollectorShell extends StatelessWidget {
  const CollectorShell({super.key});

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
          body: const CollectorWaterMetersScreen(),
        ),
        MobileTab(
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment,
          label: loc.tabWaterMeterRequests,
          body: const CollectorWaterMeterRequestsScreen(),
        ),
        MobileTab(
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: loc.tabAccount,
          body: const AccountScreen(),
        ),
      ],
    );
  }
}
