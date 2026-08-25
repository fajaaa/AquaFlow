import 'package:flutter/material.dart';

import 'package:aquaflow_customer/l10n/app_localizations.dart';
import 'package:aquaflow_customer/shared/theme/app_theme.dart';

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

  static WaterMeterStatusMeta of(String status, AppLocalizations loc) {
    return switch (status.toLowerCase()) {
      'active' => WaterMeterStatusMeta(
        loc.waterMeterStatusActive,
        AppColors.success,
        Icons.check_circle_outline,
      ),
      'inactive' => WaterMeterStatusMeta(
        loc.waterMeterStatusInactive,
        AppColors.warning,
        Icons.pause_circle_outline,
      ),
      'removed' => WaterMeterStatusMeta(
        loc.waterMeterStatusRemoved,
        const Color(0xFF64748B),
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
