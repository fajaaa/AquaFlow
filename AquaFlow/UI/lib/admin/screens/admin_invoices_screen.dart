import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aquaflow_desktop/admin/models/admin_invoice.dart';
import 'package:aquaflow_desktop/admin/models/admin_invoice_billing_cycle_option.dart';
import 'package:aquaflow_desktop/admin/models/admin_invoice_page.dart';
import 'package:aquaflow_desktop/admin/services/admin_invoice_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_invoice_service.dart';

/// Desktop admin table over `/Invoices` (`AdminInvoiceService`/`AdminInvoice`
/// data layer). Same `_requestSerial`/450ms-debounce/`_runMutation`/paging
/// template as `AdminTariffsScreen`. Row actions mirror the backend
/// `InvoiceStateMachine` client-side (Draft/Issued/PartiallyPaid/Overdue/
/// Paid/Cancelled) purely to decide which buttons to show - the server
/// remains the source of truth and any rejected transition surfaces via the
/// same error `SnackBar` as other mutation failures.
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

class _AdminInvoicesScreenState extends State<AdminInvoicesScreen> {
  final AdminInvoiceService _service = AdminInvoiceService();
  final TextEditingController _searchCtrl = TextEditingController();

  Timer? _searchDebounce;
  AdminInvoicePage? _pageData;
  bool _loading = true;
  bool _mutating = false;
  String? _error;
  String? _statusFilter;
  int? _billingCycleFilter;
  List<AdminInvoiceBillingCycleOption> _billingCycles = const [];
  int _page = 1;
  int _pageSize = 10;
  int _requestSerial = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _loadBillingCycles();
  }

  Future<void> _load({bool resetPage = false}) async {
    final requestId = ++_requestSerial;

    setState(() {
      if (resetPage) _page = 1;
      _loading = true;
      _error = null;
    });

    try {
      final pageData = await _service.fetch(
        page: _page,
        pageSize: _pageSize,
        invoiceNumber: _searchCtrl.text,
        status: _statusFilter,
        billingCycleId: _billingCycleFilter,
      );
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = pageData;
        _loading = false;
      });
    } on AdminInvoiceException catch (e) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _pageData = null;
        _loading = false;
        _error = e.message;
      });
    }
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

  void _queueSearch(String _) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 450),
      () => _load(resetPage: true),
    );
  }

  void _submitSearch(String _) {
    _searchDebounce?.cancel();
    _load(resetPage: true);
  }

  void _clearSearch() {
    if (_searchCtrl.text.isEmpty) return;
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    setState(() {});
    _load(resetPage: true);
  }

  void _setStatusFilter(String value) {
    final selected = value.isEmpty ? null : value;
    if (selected == _statusFilter) return;
    setState(() => _statusFilter = selected);
    _load(resetPage: true);
  }

  void _setBillingCycleFilter(String value) {
    final selected = value.isEmpty ? null : int.tryParse(value);
    if (selected == _billingCycleFilter) return;
    setState(() => _billingCycleFilter = selected);
    _load(resetPage: true);
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

  Future<void> _issue(AdminInvoice invoice) async {
    final confirmed = await _confirmAction(
      title: 'Izdaj račun',
      message: 'Da li želite izdati račun "${invoice.invoiceNumber}"?',
      confirmLabel: 'Izdaj',
      icon: Icons.send_outlined,
    );
    if (!mounted || confirmed != true) return;

    await _runMutation(() async {
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

    await _runMutation(() async {
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

    await _runMutation(() async {
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

    await _runMutation(() async {
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

  Future<void> _runMutation(
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => _mutating = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
      await _load();
    } on AdminInvoiceException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageData = _pageData;
    final totalPages = _totalPages(pageData?.totalCount ?? 0);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  loading: _loading,
                  mutating: _mutating,
                  onRefresh: () => _load(),
                ),
                const SizedBox(height: 18),
                _buildFilters(),
              ],
            ),
          ),
          if ((_loading && pageData != null) || _mutating)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildContent()),
          if (pageData != null && _error == null)
            _PaginationBar(
              page: _page,
              totalPages: totalPages,
              totalCount: pageData.totalCount,
              pageSize: _pageSize,
              loading: _loading || _mutating,
              onPageChanged: _goToPage,
              onPageSizeChanged: _setPageSize,
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final hasSearch = _searchCtrl.text.trim().isNotEmpty;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 220,
          child: TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            onChanged: _queueSearch,
            onSubmitted: _submitSearch,
            decoration: InputDecoration(
              labelText: 'Broj računa',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: hasSearch
                  ? IconButton(
                      tooltip: 'Očisti pretragu',
                      onPressed: _clearSearch,
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
            onChanged: _loading || _mutating
                ? null
                : (value) => _setStatusFilter(value ?? ''),
          ),
        ),
        SizedBox(
          width: 230,
          child: DropdownButtonFormField<String>(
            initialValue: _billingCycleFilter?.toString() ?? '',
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
            onChanged: _loading || _mutating
                ? null
                : (value) => _setBillingCycleFilter(value ?? ''),
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Primijeni filtere',
          onPressed: _loading || _mutating
              ? null
              : () => _load(resetPage: true),
          icon: const Icon(Icons.filter_alt_outlined),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading && _pageData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _error;
    if (error != null) {
      return _ErrorRetry(message: error, onRetry: () => _load());
    }

    final items = _pageData?.items ?? const <AdminInvoice>[];
    if (items.isEmpty) {
      return _EmptyState(hasFilters: _hasFilters);
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
                            DataCell(Text(_formatMoney(item.consumptionM3))),
                            DataCell(Text('${_formatMoney(item.totalAmount)} KM')),
                            DataCell(_InvoiceStatusPill(status: item.status)),
                            DataCell(
                              _RowActions(
                                invoice: item,
                                disabled: _mutating,
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
      _searchCtrl.text.trim().isNotEmpty ||
      _statusFilter != null ||
      _billingCycleFilter != null;

  int _totalPages(int totalCount) {
    if (totalCount <= 0) return 1;
    return (totalCount / _pageSize).ceil();
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.loading,
    required this.mutating,
    required this.onRefresh,
  });

  final bool loading;
  final bool mutating;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Računi',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pregled računa i upravljanje njihovim statusom.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    final actions = IconButton(
      tooltip: 'Osvježi',
      onPressed: loading || mutating ? null : onRefresh,
      icon: const Icon(Icons.refresh),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 12), actions],
          );
        }

        return Row(
          children: [
            Expanded(child: title),
            actions,
          ],
        );
      },
    );
  }
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

    Navigator.of(context).pop(_parseDecimal(_amountCtrl.text));
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
    final parsed = _parseDecimal(value ?? '');
    if (parsed == null) return 'Unesite ispravan broj.';
    if (parsed <= 0) return 'Iznos mora biti veći od 0.';
    return null;
  }
}

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 500;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.35)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
            child: isSmallScreen
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Prethodna stranica',
                            onPressed: canGoBack ? () => onPageChanged(page - 1) : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Expanded(
                            child: Text(
                              'Str. $page/$totalPages',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Sljedeća stranica',
                            onPressed: canGoForward ? () => onPageChanged(page + 1) : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$totalCount ukupno',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: pageSize,
                                onChanged: loading ? null : onPageSizeChanged,
                                items: const [
                                  DropdownMenuItem(value: 10, child: Text('10')),
                                  DropdownMenuItem(value: 20, child: Text('20')),
                                  DropdownMenuItem(value: 50, child: Text('50')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      IconButton(
                        tooltip: 'Prethodna stranica',
                        onPressed: canGoBack ? () => onPageChanged(page - 1) : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Text(
                          'Stranica $page od $totalPages · $totalCount ukupno',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sljedeća stranica',
                        onPressed: canGoForward ? () => onPageChanged(page + 1) : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                      const SizedBox(width: 12),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: pageSize,
                          onChanged: loading ? null : onPageSizeChanged,
                          items: const [
                            DropdownMenuItem(value: 10, child: Text('10')),
                            DropdownMenuItem(value: 20, child: Text('20')),
                            DropdownMenuItem(value: 50, child: Text('50')),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilters});

  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilters ? Icons.search_off : Icons.receipt_long_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            hasFilters ? 'Nema računa za zadane filtere.' : 'Nema računa.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      ),
    );
  }
}

double? _parseDecimal(String text) {
  final normalized = text.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
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

String _formatDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}.';
}
