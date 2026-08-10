import 'package:flutter/material.dart';

/// Generic full-screen info state used for the platform/role dead-ends the app
/// can reach: opened in a web browser, a non-admin signed in on desktop, or an
/// unrecognised role on mobile.
///
/// Shows an icon, a title and an explanatory message. When [onLogout] is
/// provided a single "Odjava" button is rendered so the user can sign out and
/// try a different account; it is omitted for states with no active session
/// (e.g. the web block, which is shown before login).
class UnavailableScreen extends StatelessWidget {
  const UnavailableScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.onLogout,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 56,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (onLogout != null) ...[
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Odjava'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
