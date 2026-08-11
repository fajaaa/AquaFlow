import 'package:flutter/material.dart';

import 'package:aquaflow_customer/models/customer_invoice.dart';
import 'package:aquaflow_customer/models/customer_invoice_page.dart';
import 'package:aquaflow_customer/screens/customer_invoice_detail_screen.dart';
import 'package:aquaflow_customer/services/customer_invoice_exception.dart';
import 'package:aquaflow_customer/services/customer_invoice_service.dart';
import 'package:aquaflow_customer/widgets/invoice_summary_card.dart';
import 'package:aquaflow_customer/shared/navigation/app_navigation.dart';
import 'package:aquaflow_customer/shared/widgets/async_state_view.dart';
import 'package:aquaflow_customer/shared/widgets/empty_state_view.dart';
import 'package:aquaflow_customer/shared/widgets/list_skeleton.dart';

/// "Računi" tab body: lists the signed-in customer's own invoices, every
/// status, newest first. Real server-side pagination via
/// `CustomerInvoiceService.fetchPage` (backend pins `CustomerId` to the
/// caller) - page-number pagination bar at the bottom, same template as
/// `NotificationsScreen`. Tapping a card pushes
/// [CustomerInvoiceDetailScreen].
///
/// Rendered inside [MobileShell], so it has no Scaffold/AppBar of its own.
class CustomerInvoicesScreen extends StatefulWidget {
  const CustomerInvoicesScreen({super.key});

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
      final pageData = await _service.fetchPage(page: _page, pageSize: _pageSize);
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = pageData;
        _loading = false;
      });
    } on CustomerInvoiceException catch (e) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = null;
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

  Future<void> _openDetail(CustomerInvoice invoice) async {
    await context.pushScreen(CustomerInvoiceDetailScreen(invoice: invoice));
  }

  @override
  Widget build(BuildContext context) {
    final pageData = _pageData;
    final totalPages = _totalPages(pageData?.totalCount ?? 0);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Računi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Osvježi',
                  onPressed: _loading ? null : () => _load(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          if (_loading && pageData != null)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildBody()),
          if (pageData != null && _error == null)
            _PaginationBar(
              page: _page,
              totalPages: totalPages,
              totalCount: pageData.totalCount,
              pageSize: _pageSize,
              loading: _loading,
              onPageChanged: _goToPage,
              onPageSizeChanged: _setPageSize,
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return AsyncStateView(
      loading: _loading && _pageData == null,
      error: _error,
      onRetry: () => _load(),
      loadingBuilder: (context) => ListSkeleton(
        itemBuilder: (context, index) => InvoiceSummaryCard(
          invoice: _skeletonInvoice,
          onTap: () {},
        ),
      ),
      builder: (context) {
        final items = _pageData?.items ?? const <CustomerInvoice>[];
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => _load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
                const EmptyStateView(
                  icon: Icons.receipt_long_outlined,
                  message: 'Trenutno nemate evidentiranih računa.',
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _load(),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final invoice = items[index];
              return InvoiceSummaryCard(
                invoice: invoice,
                onTap: () => _openDetail(invoice),
              );
            },
          ),
        );
      },
    );
  }

  int _totalPages(int totalCount) {
    if (totalCount <= 0) return 1;
    return ((totalCount + _pageSize - 1) / _pageSize).floor();
  }
}

final _skeletonInvoice = CustomerInvoice(
  id: 0,
  invoiceNumber: 'INV-000000',
  billingPeriodFrom: DateTime(2024, 1, 1),
  billingPeriodTo: DateTime(2024, 1, 31),
  previousReading: 0,
  currentReading: 0,
  consumptionM3: 0,
  subtotal: 0,
  totalAmount: 0,
  paidAmount: 0,
  remainingAmount: 0,
  status: 'Paid',
  waterMeterSerialNumber: 'SN-0000000',
);

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.pageSize,
    required this.loading,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  final int page;
  final int totalPages;
  final int totalCount;
  final int pageSize;
  final bool loading;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int?> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canGoBack = page > 1 && !loading;
    final canGoForward = page < totalPages && !loading;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.35)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Prethodna stranica',
              onPressed: canGoBack ? () => onPageChanged(page - 1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Stranica $page od $totalPages',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge,
                  ),
                  Text(
                    '$totalCount ukupno',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Sljedeća stranica',
              onPressed: canGoForward ? () => onPageChanged(page + 1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: pageSize,
                onChanged: loading ? null : onPageSizeChanged,
                items: const [
                  DropdownMenuItem(value: 5, child: Text('5')),
                  DropdownMenuItem(value: 10, child: Text('10')),
                  DropdownMenuItem(value: 20, child: Text('20')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

