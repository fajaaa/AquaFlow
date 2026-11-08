import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:aquaflow_collector/screens/collector_fault_report_detail_screen.dart';
import 'package:aquaflow_collector/services/collector_fault_report_service.dart';
import 'package:aquaflow_collector/services/collector_water_meter_request_exception.dart';
import 'package:aquaflow_collector/services/collector_water_meter_request_service.dart';
import 'package:aquaflow_collector/shared/navigation/app_navigation.dart';
import 'package:aquaflow_collector/shared/navigation/notification_deep_links.dart';
import 'package:aquaflow_collector/shared/screens/mobile_shell.dart';

/// Index of the "Nalozi" tab in `CollectorShell`.
const int collectorRequestsTabIndex = 2;

/// What a collector's system notification can open, keyed by the backend's
/// `RelatedEntityTypes`. Built and registered into
/// [NotificationDeepLinks.instance] by `CollectorShell`, which passes its own
/// [shellKey] so a water meter request can switch to the "Nalozi" tab.
/// A record no longer assigned to this collector throws (the caller shows a
/// SnackBar) instead of opening.
Map<String, NotificationDeepLinkHandler> collectorNotificationDeepLinks(
  GlobalKey<MobileShellState> shellKey,
) {
  return {
    'WaterMeterRequest': (context, id) =>
        _openWaterMeterRequest(context, id, shellKey),
    'FaultReport': _openFaultReport,
  };
}

/// "Nalozi" is a tab (the assigned-request list), not a pushed screen, so
/// this pops back to the shell and selects it - but only if the request is
/// still in that list (assigned to this collector, not yet registered).
Future<void> _openWaterMeterRequest(
  BuildContext context,
  int id,
  GlobalKey<MobileShellState> shellKey,
) async {
  final service = CollectorWaterMeterRequestService();
  try {
    final assigned = await service.fetchAssigned();
    if (!assigned.any((request) => request.id == id)) {
      throw const CollectorWaterMeterRequestException(
        'Nalog više nije dodijeljen.',
      );
    }
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    shellKey.currentState?.selectTab(collectorRequestsTabIndex);
  } finally {
    service.dispose();
  }
}

Future<void> _openFaultReport(BuildContext context, int id) async {
  final service = CollectorFaultReportService();
  try {
    final report = await service.fetchById(id);
    if (!context.mounted) return;
    unawaited(
      context.pushScreen(CollectorFaultReportDetailScreen(report: report)),
    );
  } finally {
    service.dispose();
  }
}
