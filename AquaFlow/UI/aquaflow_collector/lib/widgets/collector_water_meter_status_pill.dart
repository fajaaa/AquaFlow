import 'package:flutter/material.dart';

import 'package:aquaflow_collector/l10n/app_localizations.dart';
import 'package:aquaflow_collector/shared/theme/app_theme.dart';

/// Icon + accent color + label for a water meter `status`, covering every
/// backend `WaterMeterStatus` (Active/Inactive/Removed). Mirrors
/// `WaterMeterStatusMeta` in the customer app so both apps render the same
/// status semantics - single source of truth for the collector meter list
/// card and reading-entry screen. Inactive is the meter's "needs attention"
/// state.
class CollectorWaterMeterStatusMeta {
  const CollectorWaterMeterStatusMeta(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;

  static CollectorWaterMeterStatusMeta of(String status, AppLocalizations loc) {
    return switch (status.toLowerCase()) {
      'active' => CollectorWaterMeterStatusMeta(
        loc.waterMeterStatusActive,
        AppColors.success,
        Icons.check_circle_outline,
      ),
      'inactive' => CollectorWaterMeterStatusMeta(
        loc.waterMeterStatusInactive,
        AppColors.warning,
        Icons.pause_circle_outline,
      ),
      'removed' => CollectorWaterMeterStatusMeta(
        loc.waterMeterStatusRemoved,
        const Color(0xFF64748B),
        Icons.block_outlined,
      ),
      _ => CollectorWaterMeterStatusMeta(
        status.isEmpty ? '-' : status,
        const Color(0xFF64748B),
        Icons.help_outline,
      ),
    };
  }
}
