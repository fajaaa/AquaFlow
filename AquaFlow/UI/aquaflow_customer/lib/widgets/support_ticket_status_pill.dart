import 'package:flutter/material.dart';

/// Coloured status pill for a support ticket, covering the backend
/// `SupportTicketStatus` values (Open/Closed). Shared by the ticket cards on
/// `CustomerSupportTicketsScreen` and the detail screen. Same visual shape as
/// `FaultReportStatusPill`.
class SupportTicketStatusPill extends StatelessWidget {
  const SupportTicketStatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status.toLowerCase()) {
      'open' => (
        'Otvoren',
        const Color(0xFF1D4ED8),
        Icons.mark_chat_unread_outlined,
      ),
      'closed' => (
        'Zatvoren',
        const Color(0xFF64748B),
        Icons.lock_outline,
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
