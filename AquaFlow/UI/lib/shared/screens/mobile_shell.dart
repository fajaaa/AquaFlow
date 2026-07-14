import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_desktop/shared/models/user_preferences.dart';
import 'package:aquaflow_desktop/shared/providers/auth_provider.dart';
import 'package:aquaflow_desktop/shared/providers/theme_provider.dart';
import 'package:aquaflow_desktop/shared/services/preferences_api_service.dart';
import 'package:aquaflow_desktop/shared/services/preferences_exception.dart';

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

  final PreferencesApiService _preferencesService = PreferencesApiService();
  UserPreferences? _preferences;
  Timer? _themeSaveDebounce;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _themeSaveDebounce?.cancel();
    _preferencesService.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
    widget.onTabChanged?.call(index);
  }

  /// Fetches `GET /Account/preferences` just to have a base object (language/
  /// notification flags) for the `PUT` in [_saveTheme] - a failure here (e.g.
  /// offline) is silently ignored, same as [AccountEditScreen]; the theme
  /// toggle still works locally via [ThemeProvider], it just won't have the
  /// user's other saved preferences to echo back until this succeeds.
  Future<void> _loadPreferences() async {
    try {
      final preferences = await _preferencesService.getPreferences();
      if (!mounted) return;
      setState(() => _preferences = preferences);
    } on PreferencesException {
      // Silently ignored - see the method doc above.
    }
  }

  /// Toggles [ThemeProvider] immediately so the app reacts without delay,
  /// then debounces the `PUT /Account/preferences` call by 3 seconds so
  /// rapid taps only trigger a single save of the final theme.
  void _onThemeToggle() {
    final themeProvider = context.read<ThemeProvider>();
    final newMode =
        themeProvider.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    themeProvider.setThemeMode(newMode);

    _themeSaveDebounce?.cancel();
    _themeSaveDebounce = Timer(const Duration(seconds: 3), () => _saveTheme(newMode));
  }

  Future<void> _saveTheme(ThemeMode mode) async {
    final current = _preferences ??
        const UserPreferences(
          theme: 'light',
          language: 'bs',
          receiveEmailNotifications: true,
          receivePushNotifications: true,
        );
    final updated = current.copyWith(theme: mode == ThemeMode.dark ? 'dark' : 'light');

    try {
      final saved = await _preferencesService.updatePreferences(updated);
      if (mounted) setState(() => _preferences = saved);
    } on PreferencesException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tema nije sačuvana: ${e.message}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = widget.tabs;
    final themeMode = context.select<ThemeProvider, ThemeMode>((p) => p.themeMode);
    final isDark = themeMode == ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
          tooltip: 'Promijeni temu',
          onPressed: _onThemeToggle,
        ),
        title: Image.asset(
          'assets/images/logo.png',
          height: 32,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Text('AquaFlow'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Odjava',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: tabs[_selectedIndex].body,
        ),
      ),
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
