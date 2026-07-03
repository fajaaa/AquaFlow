import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// Post-login landing screen. Shows who is signed in (decoded from the JWT) and
/// offers logout. Kept intentionally small - it just proves the auth round-trip
/// works and gives later screens a place to hang off.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final session = auth.session;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AquaFlow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: session == null
          ? const SizedBox.shrink()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  shrinkWrap: true,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 56, color: Colors.green),
                    const SizedBox(height: 16),
                    Text(
                      'Signed in',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    _InfoTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: session.email,
                    ),
                    _InfoTile(
                      icon: Icons.badge_outlined,
                      label: 'Role',
                      value: session.userRole,
                    ),
                    _InfoTile(
                      icon: Icons.schedule,
                      label: 'Session expires',
                      value: session.expiresAt.toLocal().toString(),
                    ),
                    const SizedBox(height: 16),
                    if (session.permissions.isNotEmpty) ...[
                      Text(
                        'Permissions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final permission in session.permissions)
                            Chip(label: Text(permission)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value.isEmpty ? '-' : value),
    );
  }
}
