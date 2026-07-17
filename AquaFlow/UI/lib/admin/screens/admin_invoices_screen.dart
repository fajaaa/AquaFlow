import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aquaflow_desktop/admin/models/admin_invoice.dart';
import 'package:aquaflow_desktop/admin/models/admin_invoice_billing_cycle_option.dart';
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
  'Draft': 'Nacrt',
  'Issued': 'Izdat',
  'PartiallyPaid': 'Djelimično plaćen',
  'Overdue': 'Dospio',
  'Paid': 'Plaćen',
  'Cancelled': 'Storniran',
};

class _AdminInvoicesScreenState extends State<AdminInvoicesScreen>
    with PagedListController<AdminInvoice, AdminInvoicesScreen> {
  final AdminInvoiceService _service = AdminInvoiceService();

  String? _statusFilter;
  int? _billingCycleFilter;
  List<AdminInvoiceBillingCycleOption> _billingCycles = const [];

  @override
  void initState() {
    super.initState();
    load();
    _loadBillingCycles();
  }

  @override
  Future<({List<AdminInvoice> items, int totalCount})> fetchPage() async {
    final pageData = await _service.fetch(
      page: page,
      pageSize: pageSize,
      invoiceNumber: searchController.text,
      status: _statusFilter,
      billingCycleId: _billingCycleFilter,
    );
    return (items: pageData.items, totalCount: pageData.totalCount);
  }

  @override
  String describeError(Object error) {
    return error is AdminInvoiceException
        ? error.message
        : 'Došlo je do neočekivane greške.';
  }

  Future<void> _loadBillingCycles() async {
    try {
      final cycles = await _service.fetchBillingCycles();
      if (!mounted) return;
      setState(() => _billingCycles = cycles);
    } on AdminInvoiceException {
      // Non-fatal: the cycle filter simply stays empty.
    }
  }

  void _setStatusFilter(String value) {
    final selected = value.isEmpty ? null : value;
    if (selected == _statusFilter) return;
    setState(() => _statusFilter = selected);
    load(resetPage: true);
  }

  void _setBillingCycleFilter(String value) {
    final selected = value.isEmpty ? null : int.tryParse(value);
    if (selected == _billingCycleFilter) return;
    setState(() => _billingCycleFilter = selected);
    load(resetPage: true);
  }

  Future<void> _issue(AdminInvoice invoice) async {
    final confirmed = await _confirmAction(
      title: 'Izdaj račun',
      message: 'Da li želite izdati račun "${invoice.invoiceNumber}"?',
      confirmLabel: 'Izdaj',
      icon: Icons.send_outlined,
    );
    if (!mounted || confirmed != true) return;

    await runMutation(() async {
      await _service.issue(invoice.id);
    }, 'Račun je izdat.');
  }

  Future<void> _cancel(AdminInvoice invoice) async {
    final confirmed = await _confirmAction(
      title: 'Storniraj račun',
      message: 'Da li želite stornirati račun "${invoice.invoiceNumber}"?',
      confirmLabel: 'Storniraj',
      icon: Icons.block_outlined,
      isDestructive: true,
    );
    if (!mounted || confirmed != true) return;

    await runMutation(() async {
      await _service.cancel(invoice.id);
    }, 'Račun je storniran.');
  }

  Future<void> _markOverdue(AdminInvoice invoice) async {
    final confirmed = await _confirmAction(
      title: 'Označi dospjelim',
      message:
          'Da li želite označiti račun "${invoice.invoiceNumber}" kao dospio?',
      confirmLabel: 'Označi dospjelim',
      icon: Icons.schedule_outlined,
    );
    if (!mounted || confirmed != true) return;

    await runMutation(() async {
      await _service.markOverdue(invoice.id);
    }, 'Račun je označen dospjelim.');
  }

  Future<void> _recordPayment(AdminInvoice invoice) async {
    final amount = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PaymentDialog(invoice: invoice),
    );
    if (!mounted || amount == null) return;

    await runMutation(() async {
      await _service.recordPayment(invoice.id, amount);
    }, 'Uplata je evidentirana.');
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
    required IconData icon,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: Icon(icon),
            label: Text(confirmLabel),
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
          ),
        ],
      ),
    );
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
        SizedBox(
          width: 230,
          child: DropdownButtonFormField<String>(
            initialValue: _billingCycleFilter?.toString() ?? '',
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Ciklus obračuna',
              prefixIcon: Icon(Icons.event_repeat_outlined),
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('Svi ciklusi')),
              for (final cycle in _billingCycles)
                DropdownMenuItem(
                  value: cycle.id.toString(),
                  child: Text(cycle.name),
                ),
            ],
            onChanged: loading || mutating
                ? null
                : (value) => _setBillingCycleFilter(value ?? ''),
          ),
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
                            DataCell(Text('${formatMoney(item.totalAmount)} KM')),
                            DataCell(_InvoiceStatusPill(status: item.status)),
                            DataCell(
                              _RowActions(
                                invoice: item,
                                disabled: mutating,
                                onIssue: () => _issue(item),
                                onCancel: () => _cancel(item),
                                onMarkOverdue: () => _markOverdue(item),
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
      _billingCycleFilter != null;
}

class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.invoice,
    required this.disabled,
    required this.onIssue,
    required this.onCancel,
    required this.onMarkOverdue,
    required this.onRecordPayment,
  });

  final AdminInvoice invoice;
  final bool disabled;
  final VoidCallback onIssue;
  final VoidCallback onCancel;
  final VoidCallback onMarkOverdue;
  final VoidCallback onRecordPayment;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];

    switch (invoice.status) {
      case 'Draft':
        buttons.add(
          IconButton(
            tooltip: 'Izdaj',
            onPressed: disabled ? null : onIssue,
            icon: const Icon(Icons.send_outlined),
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
      case 'Issued':
      case 'PartiallyPaid':
        buttons.add(
          IconButton(
            tooltip: 'Evidentiraj uplatu',
            onPressed: disabled ? null : onRecordPayment,
            icon: const Icon(Icons.payments_outlined),
          ),
        );
        buttons.add(
          IconButton(
            tooltip: 'Označi dospjelim',
            onPressed: disabled ? null : onMarkOverdue,
            icon: const Icon(Icons.schedule_outlined),
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
      case 'Overdue':
        buttons.add(
          IconButton(
            tooltip: 'Evidentiraj uplatu',
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
      default:
        // Paid/Cancelled are terminal - no actions.
        break;
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
      'Draft' => ('Nacrt', const Color(0xFF64748B), Icons.edit_outlined),
      'Issued' => ('Izdat', const Color(0xFF1D4ED8), Icons.send_outlined),
      'PartiallyPaid' => (
        'Djelimično plaćen',
        const Color(0xFFB45309),
        Icons.hourglass_bottom_outlined,
      ),
      'Overdue' => (
        'Dospio',
        const Color(0xFFB91C1C),
        Icons.warning_amber_outlined,
      ),
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

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({required this.invoice});

  final AdminInvoice invoice;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final form = _formKey.currentState;
    final formValid = form != null && form.validate();
    if (!formValid) return;

    Navigator.of(context).pop(parseDecimal(_amountCtrl.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Evidentiraj uplatu — ${widget.invoice.invoiceNumber}'),
      content: SizedBox(
        width: math.min(420, MediaQuery.sizeOf(context).width - 48),
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _amountCtrl,
            autofocus: true,
            textInputAction: TextInputAction.done,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            validator: _amountValidator,
            onFieldSubmitted: (_) => _save(),
            decoration: const InputDecoration(
              labelText: 'Iznos',
              prefixIcon: Icon(Icons.payments_outlined),
              suffixText: 'KM',
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Odustani'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Sačuvaj'),
        ),
      ],
    );
  }

  String? _amountValidator(String? value) {
    final parsed = parseDecimal(value ?? '');
    if (parsed == null) return 'Unesite ispravan broj.';
    if (parsed <= 0) return 'Iznos mora biti veći od 0.';
    return null;
  }
}

String _formatDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}.';
}
