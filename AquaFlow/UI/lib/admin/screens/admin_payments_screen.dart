import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aquaflow_desktop/admin/models/admin_payment.dart';
import 'package:aquaflow_desktop/admin/services/admin_payment_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_payment_service.dart';
import 'package:aquaflow_desktop/shared/screens/paged_list_controller.dart';
import 'package:aquaflow_desktop/shared/utils/money_format.dart';
import 'package:aquaflow_desktop/shared/widgets/empty_state_view.dart';
import 'package:aquaflow_desktop/shared/widgets/error_retry.dart';
import 'package:aquaflow_desktop/shared/widgets/paged_table_pagination_bar.dart';
import 'package:aquaflow_desktop/shared/widgets/screen_header.dart';

/// Desktop admin table over `/Payments` (`AdminPaymentService`/`AdminPayment`
/// data layer). Purely read-only: uplate arise exclusively through the
/// "Evidentiraj uplatu" action on `AdminInvoicesScreen`
/// (`POST /Invoices/{id}/payments`), so there is no create/edit/delete here -
/// same shared-widget + `PagedListController` template as
/// `AdminTariffsScreen`, minus mutations and the Akcije column.
class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

const _statusOptions = <String, String>{
  'Pending': 'Na čekanju',
  'Completed': 'Završena',
};

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen>
    with PagedListController<AdminPayment, AdminPaymentsScreen> {
  final AdminPaymentService _service = AdminPaymentService();

  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Future<({List<AdminPayment> items, int totalCount})> fetchPage() async {
    final pageData = await _service.fetch(
      page: page,
      pageSize: pageSize,
      invoiceId: int.tryParse(searchController.text.trim()),
      status: _statusFilter,
    );
    return (items: pageData.items, totalCount: pageData.totalCount);
  }

  @override
  String describeError(Object error) {
    return error is AdminPaymentException
        ? error.message
        : 'Došlo je do neočekivane greške.';
  }

  void _setStatusFilter(String value) {
    final selected = value.isEmpty ? null : value;
    if (selected == _statusFilter) return;
    setState(() => _statusFilter = selected);
    load(resetPage: true);
  }

  @override
  void dispose() {
    disposeController();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScreenHeader(
                  title: 'Plaćanja',
                  subtitle:
                      'Pregled evidentiranih uplata. Uplate se evidentiraju isključivo '
                      'putem akcije "Evidentiraj uplatu" na ekranu Računi.',
                  actions: [
                    IconButton(
                      tooltip: 'Osvježi',
                      onPressed: loading ? null : () => load(),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildFilters(),
              ],
            ),
          ),
          if (loading && !isInitialLoad)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildContent()),
          if (!isInitialLoad && error == null)
            PagedTablePaginationBar(
              page: page,
              totalPages: totalPages,
              totalCount: totalCount,
              pageSize: pageSize,
              loading: loading,
              onPageChanged: goToPage,
              onPageSizeChanged: setPageSize,
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final hasSearch = searchController.text.trim().isNotEmpty;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 200,
          child: TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: queueSearch,
            onSubmitted: submitSearch,
            decoration: InputDecoration(
              labelText: 'ID računa',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: hasSearch
                  ? IconButton(
                      tooltip: 'Očisti pretragu',
                      onPressed: clearSearch,
                      icon: const Icon(Icons.clear),
                    )
                  : null,
            ),
          ),
        ),
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String>(
            initialValue: _statusFilter ?? '',
            decoration: const InputDecoration(
              labelText: 'Status',
              prefixIcon: Icon(Icons.filter_alt_outlined),
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('Svi')),
              for (final entry in _statusOptions.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: loading ? null : (value) => _setStatusFilter(value ?? ''),
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Primijeni filtere',
          onPressed: loading ? null : () => load(resetPage: true),
          icon: const Icon(Icons.filter_alt_outlined),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = this.error;
    if (error != null) {
      return ErrorRetry(message: error, onRetry: () => load());
    }

    if (items.isEmpty) {
      return EmptyStateView(
        icon: Icons.payments_outlined,
        message: 'Nema uplata.',
        hasFilters: _hasFilters,
        filteredIcon: Icons.search_off,
        filteredMessage: 'Nema uplata za zadane filtere.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth - 56),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.30),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 68,
                    columns: const [
                      DataColumn(label: Text('Datum uplate')),
                      DataColumn(label: Text('Račun')),
                      DataColumn(label: Text('Kupac')),
                      DataColumn(label: Text('Iznos')),
                      DataColumn(label: Text('Način')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(
                          cells: [
                            DataCell(Text(_formatDate(item.paidAt ?? item.createdAt))),
                            DataCell(Text('#${item.invoiceId}')),
                            DataCell(Text('#${item.customerId}')),
                            DataCell(Text('${formatMoney(item.amount)} KM')),
                            DataCell(Text(_paymentMethodLabel(item.paymentMethod))),
                            DataCell(_PaymentStatusPill(status: item.status)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool get _hasFilters =>
      searchController.text.trim().isNotEmpty || _statusFilter != null;
}

class _PaymentStatusPill extends StatelessWidget {
  const _PaymentStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = status == 'Completed'
        ? ('Završena', const Color(0xFF2E7D32), Icons.check_circle_outline)
        : (
            _statusOptions[status] ?? status,
            const Color(0xFF64748B),
            Icons.hourglass_bottom_outlined,
          );

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

String _paymentMethodLabel(String method) => method == 'Manual' ? 'Ručno' : method;

String _formatDate(DateTime? date) {
  if (date == null) return '—';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}.';
}
