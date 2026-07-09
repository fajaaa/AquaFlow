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
    this.badgeCount,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget body;

  /// Unread-style count shown as a small red badge over the tab's icon when
  /// greater than 0. Null/0 renders no badge.
  final int? badgeCount;
}

/// Reusable bottom-navigation scaffold for the mobile clients (customer and
/// collector). It owns the shared chrome - a centered "AquaFlow" app bar with an
/// info action and a logout action - and the selected-tab state, so each role
/// only has to supply its list of [MobileTab]s.
///
/// Tab bodies render no Scaffold/AppBar of their own; this shell provides them.
class MobileShell extends StatefulWidget {
  const MobileShell({super.key, required this.tabs, this.onTabChanged});

  final List<MobileTab> tabs;

  /// Called with the newly-selected tab index whenever the user switches
  /// tabs, in addition to the shell's own selection state. Lets a role shell
  /// react to a specific tab being opened (e.g. refreshing the "Obavijesti"
  /// unread badge).
  final ValueChanged<int>? onTabChanged;

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> {
  int _selectedIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
    widget.onTabChanged?.call(index);
  }

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
              icon: _BadgedIcon(icon: tab.icon, count: tab.badgeCount),
              selectedIcon: _BadgedIcon(
                icon: tab.selectedIcon,
                count: tab.badgeCount,
              ),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

/// Standard Flutter badge-over-icon pattern: a small red circle pinned to the
/// top-right corner of the icon via [Stack]/[Positioned], shown only when
/// [count] is a positive number. Counts above 99 collapse to "99+" so the
/// badge never grows wider than the icon it sits on.
class _BadgedIcon extends StatelessWidget {
  const _BadgedIcon({required this.icon, required this.count});

  final IconData icon;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon);
    final badgeCount = count;
    if (badgeCount == null || badgeCount <= 0) return iconWidget;

    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        iconWidget,
        Positioned(
          top: -4,
          right: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            decoration: BoxDecoration(
              color: colorScheme.error,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badgeCount > 99 ? '99+' : '$badgeCount',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onError,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ),
      ],
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
