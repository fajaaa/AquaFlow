import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// App shell for the mobile client: a fixed top bar (info action on the left,
/// centered "AquaFlow" title, logout action on the right) and a 4-tab bottom
/// navigation bar.
///
/// The bottom tabs are placeholders for now - each one's real screen is wired
/// in later by replacing the matching entry in [_tabs] and its
/// [NavigationDestination]. Because this widget owns [_selectedIndex], switching
/// tabs already works; only the tab bodies remain to be built.
class MasterScreen extends StatefulWidget {
  const MasterScreen({super.key});

  @override
  State<MasterScreen> createState() => _MasterScreenState();
}

class _MasterScreenState extends State<MasterScreen> {
  int _selectedIndex = 0;

  // Placeholder tab bodies. Replace each with the real screen as it is built.
  static const List<Widget> _tabs = [
    _PlaceholderTab(icon: Icons.folder, label: 'Stavka 1'),
    _PlaceholderTab(icon: Icons.folder, label: 'Stavka 2'),
    _PlaceholderTab(icon: Icons.folder, label: 'Stavka 3'),
    _PlaceholderTab(icon: Icons.folder, label: 'Stavka 4'),
  ];

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
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
      body: _tabs[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Stavka 1',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Stavka 2',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Stavka 3',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Stavka 4',
          ),
        ],
      ),
    );
  }
}

/// Temporary body shown for a bottom-nav tab until its real screen is built.
class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.icon, required this.label});

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
          Text(
            label,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}
