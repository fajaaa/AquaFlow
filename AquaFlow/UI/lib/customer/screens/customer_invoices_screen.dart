import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/customer/models/customer_invoice.dart';
import 'package:aquaflow_desktop/customer/screens/customer_invoice_detail_screen.dart';
import 'package:aquaflow_desktop/customer/services/customer_invoice_exception.dart';
import 'package:aquaflow_desktop/customer/services/customer_invoice_service.dart';
import 'package:aquaflow_desktop/customer/widgets/invoice_status_pill.dart';
import 'package:aquaflow_desktop/shared/navigation/app_navigation.dart';
import 'package:aquaflow_desktop/shared/widgets/async_state_view.dart';
import 'package:aquaflow_desktop/shared/widgets/list_skeleton.dart';

/// "Računi" tab body: lists the signed-in customer's own invoices, every
/// status, newest first. Real server-side pagination via
/// `CustomerInvoiceService.fetchPage` (backend pins `CustomerId` to the
/// caller): infinite scroll loads the next page near the bottom and stops
/// when a short page arrives or the total count is reached, and
/// pull-to-refresh resets to page 1 - same template as
/// `CustomerRequestsScreen`. Tapping a card pushes
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
  static const int _pageSize = 20;

  final CustomerInvoiceService _service = CustomerInvoiceService();
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;
  int _nextPage = 1;
  List<CustomerInvoice> _items = const [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _service.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.fetchPage(page: 1, pageSize: _pageSize);
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _nextPage = 2;
        _hasMore = result.items.length >= _pageSize &&
            _items.length < result.totalCount;
        _loading = false;
      });
    } on CustomerInvoiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    setState(() => _loadingMore = true);

    try {
      final result = await _service.fetchPage(
        page: _nextPage,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...result.items];
        _nextPage += 1;
        final reachedEnd = result.items.length < _pageSize ||
            _items.length >= result.totalCount;
        _hasMore = !reachedEnd;
        _loadingMore = false;
      });
    } on CustomerInvoiceException catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _openDetail(CustomerInvoice invoice) async {
    await context.pushScreen(CustomerInvoiceDetailScreen(invoice: invoice));
  }

  @override
  Widget build(BuildContext context) {
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
                  onPressed: _loading ? null : _loadFirstPage,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return AsyncStateView(
      loading: _loading,
      error: _error,
      onRetry: _loadFirstPage,
      loadingBuilder: (context) => ListSkeleton(
        itemBuilder: (context, index) => _InvoiceCard(
          invoice: _skeletonInvoice,
          onTap: () {},
        ),
      ),
      builder: (context) {
        if (_items.isEmpty) {
          return RefreshIndicator(
            onRefresh: _loadFirstPage,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
                const _EmptyState(),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadFirstPage,
          child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: _items.length + (_hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index >= _items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final invoice = _items[index];
              return _InvoiceCard(
                invoice: invoice,
                onTap: () => _openDetail(invoice),
              );
            },
          ),
        );
      },
    );
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
  tax: 0,
  totalAmount: 0,
  status: 'Paid',
  waterMeterSerialNumber: 'SN-0000000',
);

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice, required this.onTap});

  final CustomerInvoice invoice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.30)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      invoice.invoiceNumber,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  InvoiceStatusPill(status: invoice.status),
                ],
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.date_range_outlined,
                label:
                    '${_formatDate(invoice.billingPeriodFrom)} - ${_formatDate(invoice.billingPeriodTo)}',
              ),
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.speed_outlined,
                label: invoice.waterMeterSerialNumber.isEmpty
                    ? '-'
                    : invoice.waterMeterSerialNumber,
              ),
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.water_drop_outlined,
                label: '${_formatMoney(invoice.consumptionM3)} m³',
              ),
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.payments_outlined,
                label: '${_formatMoney(invoice.totalAmount)} KM',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            'Trenutno nemate evidentiranih računa.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}.';
}

String _formatMoney(double value) {
  final text = value.toStringAsFixed(4);
  final dotIndex = text.indexOf('.');
  var end = text.length;
  while (end > dotIndex + 3 && text[end - 1] == '0') {
    end--;
  }
  return text.substring(0, end);
}
