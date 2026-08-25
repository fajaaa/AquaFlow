import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/l10n/app_localizations.dart';

/// Coloured status pill for a support ticket, covering the backend
/// `SupportTicketStatus` values (Open/Closed). Duplicated from
/// `lib/customer/widgets/support_ticket_status_pill.dart` rather than
/// imported - this codebase's per-role widget precedent (no admin/collector
/// file imports across role folders, e.g. `FaultReportStatusPill`).
class SupportTicketStatusPill extends StatelessWidget {
  const SupportTicketStatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final (label, color, icon) = switch (status.toLowerCase()) {
      'open' => (
        loc.supportTicketStatusOpen,
        const Color(0xFF1D4ED8),
        Icons.mark_chat_unread_outlined,
      ),
      'closed' => (
        loc.supportTicketStatusClosed,
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
