import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/customer/models/customer_invoice.dart';
import 'package:aquaflow_desktop/customer/models/customer_payment.dart';
import 'package:aquaflow_desktop/customer/services/customer_invoice_exception.dart';
import 'package:aquaflow_desktop/customer/services/customer_invoice_service.dart';
import 'package:aquaflow_desktop/customer/widgets/invoice_status_pill.dart';

/// Detail view of a single invoice belonging to the signed-in customer,
/// pushed from `CustomerInvoicesScreen` as its own Scaffold+AppBar route
/// (same push pattern as `CustomerRequestsScreen`). Shows the readings,
/// amount breakdown, and the Completed payments recorded against it
/// (`CustomerInvoiceService.fetchPayments`, backend pins `CustomerId` to the
/// caller). The "Plaćeno ukupno" total is summed from that payments list;
/// "Preostalo za platiti" comes straight from `invoice.remainingAmount`
/// (`InvoiceResponse.RemainingAmount`) rather than being computed here - a
/// payment provider's charge amount must never originate client-side.
class CustomerInvoiceDetailScreen extends StatefulWidget {
  const CustomerInvoiceDetailScreen({super.key, required this.invoice});

  final CustomerInvoice invoice;

  @override
  State<CustomerInvoiceDetailScreen> createState() =>
      _CustomerInvoiceDetailScreenState();
}

class _CustomerInvoiceDetailScreenState
    extends State<CustomerInvoiceDetailScreen> {
  final CustomerInvoiceService _service = CustomerInvoiceService();

  late CustomerInvoice _invoice = widget.invoice;
  bool _loading = true;
  String? _error;
  List<CustomerPayment> _payments = const [];
  bool _paying = false;

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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final payments = await _service.fetchPayments(_invoice.id);
      if (!mounted) return;
      setState(() {
        _payments = payments;
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

  double get _totalPaid =>
      _payments.fold<double>(0, (sum, payment) => sum + payment.amount);

  @override
  Widget build(BuildContext context) {
    final invoice = _invoice;
    return Scaffold(
      appBar: AppBar(title: Text(invoice.invoiceNumber)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeaderCard(invoice: invoice),
            const SizedBox(height: 12),
            _ReadingsCard(invoice: invoice),
            const SizedBox(height: 12),
            _AmountCard(invoice: invoice),
            const SizedBox(height: 12),
            _buildPaymentsSection(invoice),
            if (invoice.isPayable) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _paying ? null : () => _payInvoice(invoice),
                  icon: _paying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.payment_outlined),
                  label: const Text('Plati'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // There is no real payment provider behind this yet (see AGENTS.md) - the
  // checkout only opens a Pending payment session, it does not complete the
  // payment, so the confirmation must never claim the invoice is paid.
  Future<void> _payInvoice(CustomerInvoice invoice) async {
    setState(() => _paying = true);

    try {
      final session = await _service.checkout(invoice.id);
      if (!mounted) return;

      final amount = _formatMoney(session.amount);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Plaćanje pokrenuto: $amount ${session.currency} '
            '(status: ${_statusLabel(session.status)}).',
          ),
        ),
      );

      await _refreshInvoice();
      await _load();
    } on CustomerInvoiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) {
        setState(() => _paying = false);
      }
    }
  }

  Future<void> _refreshInvoice() async {
    try {
      final refreshed = await _service.fetchById(_invoice.id);
      if (!mounted) return;
      setState(() => _invoice = refreshed);
    } on CustomerInvoiceException {
      // Non-fatal: the checkout itself already succeeded and was reported above,
      // so a failed refresh just leaves the previously shown invoice state.
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Na čekanju';
      case 'completed':
        return 'Završeno';
      case 'failed':
        return 'Neuspješno';
      default:
        return status;
    }
  }

  Widget _buildPaymentsSection(CustomerInvoice invoice) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final error = _error;
    if (error != null) {
      return _ErrorRetry(message: error, onRetry: _load);
    }

    return _PaymentsCard(
      payments: _payments,
      totalPaid: _totalPaid,
      remaining: invoice.remainingAmount,
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.invoice});

  final CustomerInvoice invoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      child: Row(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 22,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              invoice.invoiceNumber,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          InvoiceStatusPill(status: invoice.status),
        ],
      ),
    );
  }
}

class _ReadingsCard extends StatelessWidget {
  const _ReadingsCard({required this.invoice});

  final CustomerInvoice invoice;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Očitanja'),
          const SizedBox(height: 10),
          _KeyValueRow(
            label: 'Period',
            value:
                '${_formatDate(invoice.billingPeriodFrom)} - ${_formatDate(invoice.billingPeriodTo)}',
          ),
          const SizedBox(height: 6),
          _KeyValueRow(
            label: 'Prethodno očitanje',
            value: '${_formatMoney(invoice.previousReading)} m³',
          ),
          const SizedBox(height: 6),
          _KeyValueRow(
            label: 'Novo očitanje',
            value: '${_formatMoney(invoice.currentReading)} m³',
          ),
          const SizedBox(height: 6),
          _KeyValueRow(
            label: 'Potrošnja',
            value: '${_formatMoney(invoice.consumptionM3)} m³',
          ),
        ],
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.invoice});

  final CustomerInvoice invoice;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Iznos'),
          const SizedBox(height: 10),
          _KeyValueRow(
            label: 'Osnovica',
            value: '${_formatMoney(invoice.subtotal)} BAM',
          ),
          const SizedBox(height: 6),
          _KeyValueRow(
            label: 'Ukupno',
            value: '${_formatMoney(invoice.totalAmount)} BAM',
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

class _PaymentsCard extends StatelessWidget {
  const _PaymentsCard({
    required this.payments,
    required this.totalPaid,
    required this.remaining,
  });

  final List<CustomerPayment> payments;
  final double totalPaid;
  final double remaining;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Uplate'),
          const SizedBox(height: 10),
          if (payments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nema evidentiranih uplata.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Column(
              children: [
                for (final payment in payments) ...[
                  _PaymentRow(payment: payment),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          const Divider(height: 24),
          _KeyValueRow(
            label: 'Plaćeno ukupno',
            value: '${_formatMoney(totalPaid)} BAM',
          ),
          const SizedBox(height: 6),
          _KeyValueRow(
            label: 'Preostalo za platiti',
            value: '${_formatMoney(remaining < 0 ? 0 : remaining)} BAM',
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});

  final CustomerPayment payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            payment.paidAt != null ? _formatDate(payment.paidAt!) : '-',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Text(
          '${_formatMoney(payment.amount)} BAM',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

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
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
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
