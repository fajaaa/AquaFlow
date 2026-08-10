import 'package:flutter/material.dart';

/// Coloured status pill for a customer's fault report, covering the backend
/// `FaultReport.Status` values (New/Assigned/InProgress/Resolved). Shared by
/// the report cards on `CustomerFaultReportsScreen` and the detail screen.
/// Assigned is violet rather than blue because blue already means "U toku"
/// in this pill (unlike the admin `_StatusPill`, where InProgress is amber).
class FaultReportStatusPill extends StatelessWidget {
  const FaultReportStatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status.toLowerCase()) {
      'new' => ('Nova', const Color(0xFFB45309), Icons.fiber_new_outlined),
      'assigned' => (
        'Dodijeljena',
        const Color(0xFF6D28D9),
        Icons.assignment_ind_outlined,
      ),
      'inprogress' => (
        'U toku',
        const Color(0xFF1D4ED8),
        Icons.engineering_outlined,
      ),
      'resolved' => (
        'Riješena',
        const Color(0xFF2E7D32),
        Icons.check_circle_outline,
      ),
      _ => (status, const Color(0xFF64748B), Icons.help_outline),
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
