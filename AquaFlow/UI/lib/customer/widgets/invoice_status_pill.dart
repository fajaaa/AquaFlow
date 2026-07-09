import 'package:flutter/material.dart';

/// Coloured status pill for a customer's invoice, covering every backend
/// `InvoiceStatus` (Draft/Issued/PartiallyPaid/Overdue/Paid/Cancelled). Same
/// colour tokens as the admin `_InvoiceStatusPill`. Shared by the invoice
/// cards on `CustomerInvoicesScreen` and the header of
/// `CustomerInvoiceDetailScreen`.
class InvoiceStatusPill extends StatelessWidget {
  const InvoiceStatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status.toLowerCase()) {
      'draft' => ('U pripremi', const Color(0xFF64748B), Icons.edit_outlined),
      'issued' => ('Izdat', const Color(0xFF1D4ED8), Icons.send_outlined),
      'partiallypaid' => (
        'Djelimično plaćen',
        const Color(0xFFB45309),
        Icons.hourglass_top_outlined,
      ),
      'overdue' => (
        'Dospio',
        const Color(0xFFB91C1C),
        Icons.warning_amber_outlined,
      ),
      'paid' => ('Plaćen', const Color(0xFF2E7D32), Icons.check_circle_outline),
      'cancelled' => (
        'Storniran',
        const Color(0xFF64748B),
        Icons.block_outlined,
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
