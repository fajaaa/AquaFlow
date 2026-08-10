import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/shared/theme/app_theme.dart';

/// Icon + accent color + label for a customer water meter `status`, covering
/// every backend `WaterMeterStatus` (Active/Inactive/Removed). Single source
/// of truth for the meter list card - same role `InvoiceStatusMeta` plays
/// for invoices and `_metaFor`/`_typeColor` play for notifications. Inactive
/// is the meter's "needs attention" state, same semantic as a Warning-type
/// notification or an unpaid (Issued) invoice.
class WaterMeterStatusMeta {
  const WaterMeterStatusMeta(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;

  static WaterMeterStatusMeta of(String status) {
    return switch (status.toLowerCase()) {
      'active' => const WaterMeterStatusMeta(
        'Aktivan',
        AppColors.success,
        Icons.check_circle_outline,
      ),
      'inactive' => const WaterMeterStatusMeta(
        'Neaktivan',
        AppColors.warning,
        Icons.pause_circle_outline,
      ),
      'removed' => const WaterMeterStatusMeta(
        'Uklonjen',
        Color(0xFF64748B),
        Icons.block_outlined,
      ),
      _ => WaterMeterStatusMeta(
        status.isEmpty ? '-' : status,
        const Color(0xFF64748B),
        Icons.help_outline,
      ),
    };
  }
}
