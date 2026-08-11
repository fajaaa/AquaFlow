import 'package:flutter/material.dart';

import 'package:aquaflow_customer/shared/widgets/empty_state_view.dart';

/// "Uskoro" tab body: a reserved placeholder tab, intentionally empty until
/// its real feature is built.
///
/// Rendered inside [MobileShell], so it has no Scaffold/AppBar of its own.
class CustomerComingSoonScreen extends StatelessWidget {
  const CustomerComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EmptyStateView(
                icon: Icons.hourglass_empty,
                message: 'Uskoro dostupno.',
              ),
              const SizedBox(height: 8),
              Text(
                'Ovaj dio aplikacije još nije spreman.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
