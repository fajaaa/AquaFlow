import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/admin/models/admin_invoice.dart';
import 'package:aquaflow_desktop/admin/services/admin_invoice_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_invoice_service.dart';
import 'package:aquaflow_desktop/shared/screens/paged_list_controller.dart';
import 'package:aquaflow_desktop/shared/utils/money_format.dart';
import 'package:aquaflow_desktop/shared/widgets/empty_state_view.dart';
import 'package:aquaflow_desktop/shared/widgets/error_retry.dart';
import 'package:aquaflow_desktop/shared/widgets/paged_table_pagination_bar.dart';
import 'package:aquaflow_desktop/shared/widgets/screen_header.dart';

/// Desktop admin table over `/Invoices` (`AdminInvoiceService`/`AdminInvoice`
/// data layer). Same shared-widget + `PagedListController` template as
/// `AdminTariffsScreen`. Row actions mirror the backend `InvoiceStateMachine`
/// client-side (Draft/Issued/PartiallyPaid/Overdue/Paid/Cancelled) purely to
/// decide which buttons to show - the server remains the source of truth and
/// any rejected transition surfaces via the same error `SnackBar` as other
/// mutation failures.
class AdminInvoicesScreen extends StatefulWidget {
  const AdminInvoicesScreen({super.key});

  @override
  State<AdminInvoicesScreen> createState() => _AdminInvoicesScreenState();
}

const _statusOptions = <String, String>{
  'Issued': 'Izdat',
  'Paid': 'Plaćen',
  'Cancelled': 'Storniran',
};

class _AdminInvoicesScreenState extends State<AdminInvoicesScreen>
    with PagedListController<AdminInvoice, AdminInvoicesScreen> {
  final AdminInvoiceService _service = AdminInvoiceService();

  String? _statusFilter;
  DateTime? _billingPeriodFilter;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Future<({List<AdminInvoice> items, int totalCount})> fetchPage() async {
    final pageData = await _service.fetch(
      page: page,
      pageSize: pageSize,
      invoiceNumber: searchController.text,
      status: _statusFilter,
      billingPeriodFrom: _billingPeriodFilter,
    );
    return (items: pageData.items, totalCount: pageData.totalCount);
  }

  @override
  String describeError(Object error) {
    return error is AdminInvoiceException
        ? error.message
        : 'Došlo je do neočekivane greške.';
  }

  void _setStatusFilter(String value) {
    final selected = value.isEmpty ? null : value;
    if (selected == _statusFilter) return;
    setState(() => _statusFilter = selected);
    load(resetPage: true);
  }

  Future<void> _selectBillingMonth(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _billingPeriodFilter ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (!mounted || selected == null) return;
    setState(
      () => _billingPeriodFilter = DateTime(selected.year, selected.month, 1),
    );
    load(resetPage: true);
  }

  Future<void> _recordPayment(AdminInvoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Označi kao plaćeno'),
        content: Text(
          'Da li želite označiti račun "${invoice.invoiceNumber}" kao '
          'plaćen (${formatMoney(invoice.remainingAmount)} BAM)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Označi kao plaćeno'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    await runMutation(() async {
      await _service.recordPayment(invoice.id);
    }, 'Račun je označen kao plaćen.');
  }

  Future<void> _cancel(AdminInvoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storniraj račun'),
        content: Text(
          'Da li želite stornirati račun "${invoice.invoiceNumber}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.block_outlined),
            label: const Text('Storniraj'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    await runMutation(() async {
      await _service.cancel(invoice.id);
    }, 'Račun je storniran.');
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
                  title: 'Računi',
                  subtitle: 'Pregled računa i upravljanje njihovim statusom.',
                  actions: [
                    IconButton(
                      tooltip: 'Osvježi',
                      onPressed: loading || mutating ? null : () => load(),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildFilters(),
              ],
            ),
          ),
          if ((loading && !isInitialLoad) || mutating)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildContent()),
          if (!isInitialLoad && error == null)
            PagedTablePaginationBar(
              page: page,
              totalPages: totalPages,
              totalCount: totalCount,
              pageSize: pageSize,
              loading: loading || mutating,
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
          width: 220,
          child: TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onChanged: queueSearch,
            onSubmitted: submitSearch,
            decoration: InputDecoration(
              labelText: 'Broj računa',
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
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Status',
              prefixIcon: Icon(Icons.filter_alt_outlined),
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('Svi')),
              for (final entry in _statusOptions.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: loading || mutating
                ? null
                : (value) => _setStatusFilter(value ?? ''),
          ),
        ),
        Wrap(
          spacing: 4,
          children: [
            InputChip(
              label: Text(
                _billingPeriodFilter != null
                    ? '${_billingPeriodFilter!.month}/${_billingPeriodFilter!.year}'
                    : 'Mjesec',
              ),
              avatar: const Icon(Icons.calendar_month_outlined, size: 18),
              onPressed: loading || mutating
                  ? null
                  : () => _selectBillingMonth(context),
              onDeleted: _billingPeriodFilter != null && !loading && !mutating
                  ? () {
                      setState(() => _billingPeriodFilter = null);
                      load(resetPage: true);
                    }
                  : null,
            ),
          ],
        ),
        IconButton.filledTonal(
          tooltip: 'Primijeni filtere',
          onPressed: loading || mutating ? null : () => load(resetPage: true),
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
        icon: Icons.receipt_long_outlined,
        message: 'Nema računa.',
        hasFilters: _hasFilters,
        filteredIcon: Icons.search_off,
        filteredMessage: 'Nema računa za zadane filtere.',
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
                      DataColumn(label: Text('Broj računa')),
                      DataColumn(label: Text('Kupac')),
                      DataColumn(label: Text('Vodomjer')),
                      DataColumn(label: Text('Period')),
                      DataColumn(label: Text('Potrošnja m³')),
                      DataColumn(label: Text('Iznos')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Akcije')),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(
                          cells: [
                            DataCell(Text(item.invoiceNumber)),
                            DataCell(Text(item.customerFullName)),
                            DataCell(Text(item.waterMeterSerialNumber)),
                            DataCell(
                              Text(
                                '${_formatDate(item.billingPeriodFrom)} – '
                                '${_formatDate(item.billingPeriodTo)}',
                              ),
                            ),
                            DataCell(Text(formatMoney(item.consumptionM3))),
                            DataCell(Text('${formatMoney(item.totalAmount)} BAM')),
                            DataCell(_InvoiceStatusPill(status: item.status)),
                            DataCell(
                              _RowActions(
                                invoice: item,
                                disabled: mutating,
                                onCancel: () => _cancel(item),
                                onRecordPayment: () => _recordPayment(item),
                              ),
                            ),
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
      searchController.text.trim().isNotEmpty ||
      _statusFilter != null ||
      _billingPeriodFilter != null;
}

class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.invoice,
    required this.disabled,
    required this.onCancel,
    required this.onRecordPayment,
  });

  final AdminInvoice invoice;
  final bool disabled;
  final VoidCallback onCancel;
  final VoidCallback onRecordPayment;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];

    if (invoice.status == 'Issued') {
      buttons.add(
        IconButton(
          tooltip: 'Označi kao plaćeno',
          onPressed: disabled ? null : onRecordPayment,
          icon: const Icon(Icons.payments_outlined),
        ),
      );
      buttons.add(
        IconButton(
          tooltip: 'Storniraj',
          onPressed: disabled ? null : onCancel,
          icon: const Icon(Icons.block_outlined),
          color: Theme.of(context).colorScheme.error,
        ),
      );
    }

    if (buttons.isEmpty) {
      return Text(
        '—',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: buttons);
  }
}

class _InvoiceStatusPill extends StatelessWidget {
  const _InvoiceStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      'Issued' => ('Izdat', const Color(0xFF1D4ED8), Icons.send_outlined),
      'Paid' => (
        'Plaćen',
        const Color(0xFF2E7D32),
        Icons.check_circle_outline,
      ),
      'Cancelled' => (
        'Storniran',
        const Color(0xFF64748B),
        Icons.block_outlined,
      ),
      _ => (status, const Color(0xFF64748B), Icons.help_outline),
    };

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

String _formatDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}.';
}
