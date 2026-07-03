import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_desktop/shared/providers/auth_provider.dart';
import 'package:aquaflow_desktop/shared/screens/account_edit_screen.dart';
import 'package:aquaflow_desktop/shared/screens/company_settings_screen.dart';

/// Desktop home for the `admin` role - the only surface the desktop app exposes.
///
/// Shown by [PlatformGate] on Windows/macOS/Linux once an admin is signed in.
/// It is a launcher of admin sections: the built ones (company settings, account
/// editing) open their screens; the rest are placeholders until wired up.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final email = context.select<AuthProvider, String>(
      (a) => a.session?.email ?? '',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('AquaFlow — Admin'),
        actions: [
          if (email.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: Text(email)),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Odjava',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Administratorska ploča',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Upravljanje AquaFlow sistemom',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _AdminCard(
                        icon: Icons.business_outlined,
                        title: 'Postavke firme',
                        subtitle: 'Podaci firme, jezik i valuta',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CompanySettingsScreen(),
                          ),
                        ),
                      ),
                      _AdminCard(
                        icon: Icons.manage_accounts_outlined,
                        title: 'Moj nalog',
                        subtitle: 'Izmjena email adrese i telefona',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AccountEditScreen(),
                          ),
                        ),
                      ),
                      _AdminCard(
                        icon: Icons.people_outline,
                        title: 'Korisnici',
                        subtitle: 'Upravljanje korisnicima i ulogama',
                        onTap: () => _notReady(context),
                      ),
                      _AdminCard(
                        icon: Icons.water_drop_outlined,
                        title: 'Vodomjeri',
                        subtitle: 'Pregled i upravljanje vodomjerima',
                        onTap: () => _notReady(context),
                      ),
                      _AdminCard(
                        icon: Icons.receipt_long_outlined,
                        title: 'Računi',
                        subtitle: 'Fakturisanje i naplata',
                        onTap: () => _notReady(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _notReady(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Ova sekcija još nije implementirana.')),
      );
  }
}

/// Single tappable action tile on the admin dashboard.
class _AdminCard extends StatelessWidget {
  const _AdminCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 280,
      child: Card(
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
