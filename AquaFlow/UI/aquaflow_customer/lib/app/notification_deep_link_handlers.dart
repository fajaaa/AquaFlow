import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:aquaflow_customer/screens/customer_fault_report_detail_screen.dart';
import 'package:aquaflow_customer/screens/customer_invoice_detail_screen.dart';
import 'package:aquaflow_customer/screens/customer_requests_screen.dart';
import 'package:aquaflow_customer/screens/customer_support_ticket_detail_screen.dart';
import 'package:aquaflow_customer/services/customer_fault_report_service.dart';
import 'package:aquaflow_customer/services/customer_invoice_service.dart';
import 'package:aquaflow_customer/services/customer_support_ticket_service.dart';
import 'package:aquaflow_customer/shared/navigation/app_navigation.dart';
import 'package:aquaflow_customer/shared/navigation/notification_deep_links.dart';

/// What a customer's system notification can open, keyed by the backend's
/// `RelatedEntityTypes`. Registered into [NotificationDeepLinks.instance] by
/// `CustomerShell`. Each handler loads the record first (the backend pins it
/// to the caller, so a foreign/deleted id is a 404 and throws - the caller
/// shows a SnackBar), then pushes its screen on top of the notification
/// without awaiting the route.
final Map<String, NotificationDeepLinkHandler> customerNotificationDeepLinks = {
  'Invoice': _openInvoice,
  'FaultReport': _openFaultReport,
  'WaterMeterRequest': _openWaterMeterRequests,
  'SupportTicket': _openSupportTicket,
};

Future<void> _openInvoice(BuildContext context, int id) async {
  final service = CustomerInvoiceService();
  try {
    final invoice = await service.fetchById(id);
    if (!context.mounted) return;
    unawaited(
      context.pushScreen(CustomerInvoiceDetailScreen(invoice: invoice)),
    );
  } finally {
    service.dispose();
  }
}

Future<void> _openFaultReport(BuildContext context, int id) async {
  final service = CustomerFaultReportService();
  try {
    final report = await service.fetchById(id);
    if (!context.mounted) return;
    unawaited(
      context.pushScreen(CustomerFaultReportDetailScreen(report: report)),
    );
  } finally {
    service.dispose();
  }
}

/// There is no single-request screen - the request list shows every request
/// of the customer with its current status, so that is where this lands.
Future<void> _openWaterMeterRequests(BuildContext context, int id) async {
  unawaited(context.pushScreen(const CustomerRequestsScreen()));
}

Future<void> _openSupportTicket(BuildContext context, int id) async {
  final service = CustomerSupportTicketService();
  try {
    // The detail screen loads the ticket itself; fetching it here first is
    // what turns a gone/foreign ticket into the SnackBar instead of an
    // error page.
    await service.fetchById(id);
    if (!context.mounted) return;
    unawaited(
      context.pushScreen(CustomerSupportTicketDetailScreen(ticketId: id)),
    );
  } finally {
    service.dispose();
  }
}
