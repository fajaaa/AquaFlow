import 'package:flutter/material.dart';

/// Status pill for a [AdminReadingRoute]/route detail header. Shared between
/// `AdminReadingRoutesScreen`'s table and `AdminReadingRouteItemsScreen`'s
/// header, so it lives here instead of being duplicated in both files.
class ReadingRouteStatusPill extends StatelessWidget {
  const ReadingRouteStatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      'Planned' => (
        'Planned',
        const Color(0xFF64748B),
        Icons.schedule_outlined,
      ),
      'Assigned' => (
        'Assigned',
        const Color(0xFF1D4ED8),
        Icons.engineering_outlined,
      ),
      'Cancelled' => ('Cancelled', const Color(0xFFB91C1C), Icons.block_outlined),
      _ => (status.isEmpty ? '-' : status, const Color(0xFF64748B), Icons.help_outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
