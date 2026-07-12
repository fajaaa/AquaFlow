import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/customer_profile.dart';
import '../navigation/app_navigation.dart';
import '../providers/auth_provider.dart';
import '../services/profile_service.dart';
import 'account_edit_screen.dart';
import 'company_settings_screen.dart';

/// "Nalog" tab body: an account/about card for the signed-in user.
///
/// Shows a role-specific avatar icon, the user's first and last name, and the
/// role - but only when the user is not a regular customer. The name lives on
/// the customer profile (not in the JWT), so it is fetched from the backend;
/// admins/collectors have no customer profile, so their name falls back to the
/// email local part.
///
/// This is a tab body inside [MasterScreen], so it renders no Scaffold/AppBar
/// of its own - the shell provides those.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final ProfileService _profileService = ProfileService();
  late final Future<CustomerProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<CustomerProfile?> _loadProfile() {
    final id = context.read<AuthProvider>().session?.id;
    if (id == null) return Future.value(null);
    return _profileService.fetchCustomerProfile(id);
  }

  @override
  void dispose() {
    _profileService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = context.watch<AuthProvider>().session;
    if (session == null) return const SizedBox.shrink();

    final visual = _RoleVisual.forRole(session.userRole);
    final isRegularUser = _isRegularUser(session.userRole);

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RoleAvatar(visual: visual),
                const SizedBox(height: 20),
                FutureBuilder<CustomerProfile?>(
                  future: _profileFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: SizedBox(
                          height: 26,
                          width: 26,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      );
                    }
                    return Text(
                      _resolveName(snapshot.data, session.email),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    );
                  },
                ),
                // Regular customers do not show a role label; every other role
                // (admin, collector, ...) does.
                if (!isRegularUser) ...[
                  const SizedBox(height: 12),
                  _RoleChip(visual: visual),
                ],
                const SizedBox(height: 28),
                Card(
                  elevation: 2,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email'),
                    subtitle: Text(
                      session.email.isEmpty ? '-' : session.email,
                    ),
                  ),
                ),
                // Every user - regardless of role - can edit their own contact
                // data (email/phone) from here.
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.manage_accounts_outlined),
                    title: const Text('Uredi nalog'),
                    subtitle: const Text(
                      'Izmjena email adrese, telefona, imena i prezimena',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.pushScreen(const AccountEditScreen()),
                  ),
                ),
                // Admins can manage the company-wide settings; regular users
                // and collectors never see this entry.
                if (_isAdmin(session.userRole)) ...[
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.business_outlined),
                      title: const Text('Postavke firme'),
                      subtitle: const Text('Upravljanje podacima firme'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          context.pushScreen(const CompanySettingsScreen()),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The customer's full name when available, otherwise a name derived from the
  /// email (used for admins/collectors, who have no customer profile, and as a
  /// fallback if the profile fetch failed).
  String _resolveName(CustomerProfile? profile, String email) {
    final fullName = profile?.fullName ?? '';
    if (fullName.isNotEmpty) return fullName;
    return _nameFromEmail(email);
  }

  String _nameFromEmail(String email) {
    final local = email.split('@').first;
    if (local.isEmpty) return email;
    return local[0].toUpperCase() + local.substring(1);
  }

  static bool _isRegularUser(String role) => role.toLowerCase() == 'customer';

  static bool _isAdmin(String role) => role.toLowerCase() == 'admin';
}

/// Icon + color + label for a user role. Each role gets a distinct icon.
class _RoleVisual {
  const _RoleVisual({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  factory _RoleVisual.forRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const _RoleVisual(
          icon: Icons.admin_panel_settings,
          color: Color(0xFF6A1B9A),
          label: 'Administrator',
        );
      case 'collector':
        return const _RoleVisual(
          icon: Icons.route,
          color: Color(0xFF00838F),
          label: 'Inkasant',
        );
      case 'customer':
        return const _RoleVisual(
          icon: Icons.person,
          color: Color(0xFF0277BD),
          label: 'Korisnik',
        );
      default:
        return _RoleVisual(
          icon: Icons.account_circle,
          color: Colors.blueGrey.shade600,
          label: role.isEmpty ? 'Korisnik' : role,
        );
    }
  }
}

class _RoleAvatar extends StatelessWidget {
  const _RoleAvatar({required this.visual});

  final _RoleVisual visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: visual.color.withValues(alpha: 0.12),
        border: Border.all(color: visual.color, width: 3),
      ),
      child: Icon(visual.icon, size: 60, color: visual.color),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.visual});

  final _RoleVisual visual;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(visual.icon, size: 18, color: visual.color),
      label: Text(visual.label),
      labelStyle: TextStyle(
        color: visual.color,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: visual.color.withValues(alpha: 0.10),
      side: BorderSide(color: visual.color.withValues(alpha: 0.40)),
    );
  }
}
