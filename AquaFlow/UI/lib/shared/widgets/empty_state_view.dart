import 'package:flutter/material.dart';

/// Shared "nothing here" state for admin desktop tables: a centered icon and
/// message. When [hasFilters] is true and [filteredIcon]/[filteredMessage]
/// are supplied, those replace [icon]/[message] instead - the caller owns
/// all text/icon choices, nothing is hard-coded per screen here.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.message,
    this.hasFilters = false,
    this.filteredIcon,
    this.filteredMessage,
  });

  final IconData icon;
  final String message;
  final bool hasFilters;
  final IconData? filteredIcon;
  final String? filteredMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIcon = hasFilters ? (filteredIcon ?? icon) : icon;
    final effectiveMessage = hasFilters ? (filteredMessage ?? message) : message;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(effectiveIcon, size: 56, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 14),
          Text(
            effectiveMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
