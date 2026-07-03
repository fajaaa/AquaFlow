import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_desktop/shared/providers/auth_provider.dart';

/// One entry in a [MobileShell]'s bottom navigation: the destination shown in
/// the bar plus the body rendered when it is selected.
class MobileTab {
  const MobileTab({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.body,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget body;
}

/// Reusable bottom-navigation scaffold for the mobile clients (customer and
/// collector). It owns the shared chrome - a centered "AquaFlow" app bar with an
/// info action and a logout action - and the selected-tab state, so each role
/// only has to supply its list of [MobileTab]s.
///
/// Tab bodies render no Scaffold/AppBar of their own; this shell provides them.
class MobileShell extends StatefulWidget {
  const MobileShell({super.key, required this.tabs});

  final List<MobileTab> tabs;

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> {
  int _selectedIndex = 0;

  void _onTabSelected(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final tabs = widget.tabs;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: 'Informacije',
          onPressed: () {
            // TODO: wire up the info/about action.
          },
        ),
        title: const Text('AquaFlow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Odjava',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: tabs[_selectedIndex].body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabSelected,
        destinations: [
          for (final tab in tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

/// Temporary body shown for a tab whose real screen is not built yet. Public so
/// both role shells can reuse it while their features are placeholders.
class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 16),
          Text(label, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
