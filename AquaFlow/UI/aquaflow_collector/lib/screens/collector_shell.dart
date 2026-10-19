import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_collector/app/notification_deep_link_handlers.dart';
import 'package:aquaflow_collector/l10n/app_localizations.dart';
import 'package:aquaflow_collector/screens/collector_water_meter_requests_screen.dart';
import 'package:aquaflow_collector/screens/collector_water_meters_screen.dart';
import 'package:aquaflow_collector/shared/navigation/notification_deep_links.dart';
import 'package:aquaflow_collector/shared/providers/notification_badge_provider.dart';
import 'package:aquaflow_collector/shared/screens/account_screen.dart';
import 'package:aquaflow_collector/shared/screens/mobile_shell.dart';
import 'package:aquaflow_collector/shared/screens/notifications_screen.dart';

/// Mobile home for the `collector` (Sakupljač/Inkasant) role.
///
/// Also used by an `admin` signed in on a phone (product decision - see
/// `RoleGate`). Configures the shared [MobileShell] with the
/// collector-facing tabs; "Obavijesti" and "Nalog" are the shared screens,
/// "Vodomjeri" is [CollectorWaterMetersScreen] (replaces the former
/// "Očitanja"/route tab with a free-text meter search), and "Nalozi" is
/// [CollectorWaterMeterRequestsScreen].
///
/// Mounted exactly while the user is signed in, so it is what starts
/// [NotificationBadgeProvider]'s polling (and stops it again on logout) and
/// registers the collector's notification deep links
/// ([collectorNotificationDeepLinks] - a water meter request switches to the
/// "Nalozi" tab through [_shellKey]). [NotificationsScreen] itself (via
/// `NotificationBadgeProvider.markSeen`) clears the badge whenever the inbox
/// list loads.
class CollectorShell extends StatefulWidget {
  const CollectorShell({super.key});

  @override
  State<CollectorShell> createState() => _CollectorShellState();
}

class _CollectorShellState extends State<CollectorShell> {
  final _shellKey = GlobalKey<MobileShellState>();
  late final NotificationBadgeProvider _badge;
  late final Map<String, NotificationDeepLinkHandler> _deepLinks =
      collectorNotificationDeepLinks(_shellKey);

  @override
  void initState() {
    super.initState();
    _badge = context.read<NotificationBadgeProvider>()..start();
    NotificationDeepLinks.instance.registerAll(_deepLinks);
  }

  @override
  void dispose() {
    NotificationDeepLinks.instance.unregisterAll(_deepLinks);
    _badge.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationBadgeProvider>().unreadCount;
    final loc = AppLocalizations.of(context);

    return MobileShell(
      key: _shellKey,
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
