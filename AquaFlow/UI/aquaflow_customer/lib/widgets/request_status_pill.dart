import 'package:flutter/material.dart';

import 'package:aquaflow_customer/l10n/app_localizations.dart';

/// Coloured status pill for a customer's water meter request, covering every
/// backend `WaterMeterRequestStatus` (Na čekanju / Dodijeljen / Registrovan /
/// Odbijen / Otkazan). Shared by the request cards on the new
/// `CustomerRequestsScreen`.
class RequestStatusPill extends StatelessWidget {
  const RequestStatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final (label, color, icon) = switch (status.toLowerCase()) {
      'pending' => (
        loc.requestStatusPending,
        const Color(0xFFB45309),
        Icons.hourglass_top_outlined,
      ),
      'assigned' => (
        loc.requestStatusAssigned,
        const Color(0xFF1D4ED8),
        Icons.engineering_outlined,
      ),
      'registered' => (
        loc.requestStatusRegistered,
        const Color(0xFF2E7D32),
        Icons.check_circle_outline,
      ),
      'rejected' => (
        loc.requestStatusRejected,
        const Color(0xFFB91C1C),
        Icons.block_outlined,
      ),
      'cancelled' => (
        loc.requestStatusCancelled,
        const Color(0xFF64748B),
        Icons.cancel_outlined,
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
