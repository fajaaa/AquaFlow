import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/shared/theme/app_theme.dart';

/// Icon + accent color + label for a customer invoice `status`, covering
/// every backend `InvoiceStatus` (Issued/Paid/Cancelled). Single source of
/// truth shared by the invoice list card and the invoice detail screen's
/// status banner, so both stay in sync - same role as `_metaFor`/
/// `_typeColor` play for notifications. Issued (still unpaid) uses the
/// warning accent to flag it as needing the customer's attention, same
/// semantic as a Warning-type notification.
class InvoiceStatusMeta {
  const InvoiceStatusMeta(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;

  static InvoiceStatusMeta of(String status) {
    return switch (status.toLowerCase()) {
      'issued' => const InvoiceStatusMeta(
        'Izdat',
        AppColors.warning,
        Icons.send_outlined,
      ),
      'paid' => const InvoiceStatusMeta(
        'Plaćen',
        AppColors.success,
        Icons.check_circle_outline,
      ),
      'cancelled' => const InvoiceStatusMeta(
        'Storniran',
        Color(0xFF64748B),
        Icons.block_outlined,
      ),
      _ => InvoiceStatusMeta(status, const Color(0xFF64748B), Icons.help_outline),
    };
  }
}
