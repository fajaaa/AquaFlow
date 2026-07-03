import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_desktop/admin/screens/admin_dashboard_screen.dart';
import 'package:aquaflow_desktop/app/mobile_role_router.dart';
import 'package:aquaflow_desktop/app/unavailable_screen.dart';
import 'package:aquaflow_desktop/shared/providers/auth_provider.dart';

/// Splits an authenticated session by device class.
///
/// Desktop (Windows/macOS/Linux) is an admin-only surface: an `admin` lands on
/// the [AdminDashboardScreen], while any other role is blocked with a message -
/// there is deliberately no customer/collector UI on desktop. Mobile/tablet
/// (Android/iOS) defers to [MobileRoleRouter], which picks the shell from the
/// role.
///
/// Web never reaches here: it is short-circuited in `main.dart` before login.
class PlatformGate extends StatelessWidget {
  const PlatformGate({super.key});

  /// Desktop OSes get the admin surface. Uses [defaultTargetPlatform] (not
  /// `dart:io Platform`) so it also compiles for web builds without extra guards.
  static bool get isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  Widget build(BuildContext context) {
    final role = context
        .select<AuthProvider, String>((a) => a.session?.userRole ?? '')
        .toLowerCase();

    if (!isDesktop) {
      // Android / iOS phone or tablet.
      return const MobileRoleRouter();
    }

    // Desktop: admins only.
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
