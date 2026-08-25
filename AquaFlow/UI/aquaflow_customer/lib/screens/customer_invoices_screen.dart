import 'package:flutter/material.dart';

import 'package:aquaflow_customer/l10n/app_localizations.dart';
import 'package:aquaflow_customer/models/customer_invoice.dart';
import 'package:aquaflow_customer/models/customer_invoice_page.dart';
import 'package:aquaflow_customer/screens/customer_invoice_detail_screen.dart';
import 'package:aquaflow_customer/services/customer_invoice_exception.dart';
import 'package:aquaflow_customer/services/customer_invoice_service.dart';
import 'package:aquaflow_customer/shared/navigation/app_navigation.dart';
import 'package:aquaflow_customer/shared/widgets/async_state_view.dart';
import 'package:aquaflow_customer/shared/widgets/empty_state_view.dart';
import 'package:aquaflow_customer/shared/widgets/list_skeleton.dart';
import 'package:aquaflow_customer/shared/widgets/paged_table_pagination_bar.dart';
import 'package:aquaflow_customer/shared/widgets/refresh_button.dart';
import 'package:aquaflow_customer/widgets/invoice_summary_card.dart';

/// Full-screen, paginated list of the signed-in customer's invoices, every
/// status. Reached either via the "Svi računi" app bar action on
/// `CustomerInvoiceDetailScreen` (all invoices, every meter) or via the
/// "Prikaži račune" button on `CustomerWaterMeterDetailScreen` (pass
/// [waterMeterId] to scope the list to that one meter's invoices).
///
/// Uses real server-side pagination
/// (`GET /Invoices?Page=&PageSize=&IncludeTotalCount=true&SortBy=CreatedAt&SortDescending=true[&WaterMeterId=]`;
/// the backend pins `CustomerId` to the caller). Tapping a card pushes
/// `CustomerInvoiceDetailScreen`, which already carries the full "Plati"
/// checkout flow - this screen only lists and links to it, same division of
/// responsibility as the per-meter "Računi" section it replaced on
/// `CustomerWaterMeterDetailScreen`.
class CustomerInvoicesScreen extends StatefulWidget {
  const CustomerInvoicesScreen({
    super.key,
    this.waterMeterId,
    this.meterSerialNumber,
  });

  /// Restricts the list to this water meter's invoices when set; otherwise
  /// every invoice the customer has, across all their meters.
  final int? waterMeterId;

  /// Shown in the app bar title alongside "Računi" when [waterMeterId] is
  /// set, so the customer can tell which meter this scoped list belongs to.
  final String? meterSerialNumber;

  @override
  State<CustomerInvoicesScreen> createState() =>
      _CustomerInvoicesScreenState();
}

class _CustomerInvoicesScreenState extends State<CustomerInvoicesScreen> {
  final CustomerInvoiceService _service = CustomerInvoiceService();

  CustomerInvoicePage? _pageData;
  bool _loading = true;
  String? _error;
  int _page = 1;
  int _pageSize = 10;
  int _requestSerial = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _load({bool resetPage = false}) async {
    final requestId = ++_requestSerial;
    setState(() {
      if (resetPage) _page = 1;
      _loading = true;
      _error = null;
    });

    try {
      final pageData = await _service.fetchPage(
        page: _page,
        pageSize: _pageSize,
        waterMeterId: widget.waterMeterId,
      );
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = pageData;
        _loading = false;
      });
    } on CustomerInvoiceException catch (e) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  void _setPageSize(int? value) {
    if (value == null || value == _pageSize || _loading) return;
    setState(() {
      _pageSize = value;
      _page = 1;
    });
    _load();
  }

  void _goToPage(int page) {
    if (page == _page || _loading) return;
    setState(() => _page = page);
    _load();
  }

  int _totalPages(int totalCount) {
    if (totalCount <= 0) return 1;
    return ((totalCount + _pageSize - 1) / _pageSize).floor();
  }

  // CustomerInvoiceDetailScreen never returns a result through pop (payment
  // completion isn't signalled that way), so an unconditional reload here is
  // the only way this screen's cards pick up a payment made on the detail
  // screen - same as CustomerWaterMeterDetailScreen._openInvoices.
  Future<void> _openInvoice(CustomerInvoice invoice) async {
    await context.pushScreen(CustomerInvoiceDetailScreen(invoice: invoice));
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final pageData = _pageData;
    final serial = widget.meterSerialNumber;
    final loc = AppLocalizations.of(context);

    // Docked below the list rather than as its last scrollable item, so it
    // stays visible and reachable at the bottom of the screen on every
    // device regardless of scroll position or item count - same treatment
    // as NotificationsScreen's pagination bar.
    final pagination = pageData != null && _error == null
        ? PagedTablePaginationBar(
            page: _page,
            totalPages: _totalPages(pageData.totalCount),
            totalCount: pageData.totalCount,
            pageSize: _pageSize,
            loading: _loading,
            onPageChanged: _goToPage,
            onPageSizeChanged: _setPageSize,
          )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          serial != null ? loc.invoicesTitleForMeter(serial) : loc.invoicesTitle,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: RefreshButton(
              enabled: !_loading,
              onRefresh: () => _load(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_loading && pageData != null)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _buildContent()),
            ?pagination,
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return AsyncStateView(
      loading: _loading && _pageData == null,
      error: _error,
      onRetry: () => _load(),
      loadingBuilder: (context) => ListSkeleton(
        itemBuilder: (context, index) =>
            InvoiceSummaryCard(invoice: _skeletonInvoice, onTap: () {}),
      ),
      builder: (context) {
        final items = _pageData!.items;

        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => _load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
                EmptyStateView(
                  icon: Icons.receipt_long_outlined,
                  message: widget.waterMeterId != null
                      ? AppLocalizations.of(context).invoicesEmptyForMeterMessage
                      : AppLocalizations.of(context).invoicesEmptyMessage,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _load(),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final invoice = items[index];
              return InvoiceSummaryCard(
                invoice: invoice,
                onTap: () => _openInvoice(invoice),
              );
            },
          ),
        );
      },
    );
  }
}

/// Placeholder card shown by `ListSkeleton` while the first page is loading -
/// shimmered by `Skeletonizer`, so the exact text does not matter, only the
/// layout shape. Mirrors `_skeletonReport` in customer_fault_reports_screen.dart.
final _skeletonInvoice = CustomerInvoice(
  id: 0,
  invoiceNumber: 'RN-000000',
  billingPeriodFrom: DateTime(2024, 1, 1),
  billingPeriodTo: DateTime(2024, 1, 31),
  previousReading: 0,
  currentReading: 0,
  consumptionM3: 0,
  subtotal: 0,
  totalAmount: 0,
  paidAmount: 0,
  remainingAmount: 0,
  status: 'Issued',
  waterMeterSerialNumber: 'SN-000000',
);
