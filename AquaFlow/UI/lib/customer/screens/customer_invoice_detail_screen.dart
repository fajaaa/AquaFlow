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
/// caller), plus the client-computed paid/remaining totals.
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

  bool _loading = true;
  String? _error;
  List<CustomerPayment> _payments = const [];

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
      final payments = await _service.fetchPayments(widget.invoice.id);
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
    final invoice = widget.invoice;
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
                  onPressed: () => _payInvoice(invoice),
                  icon: const Icon(Icons.payment_outlined),
                  label: const Text('Plati'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _payInvoice(CustomerInvoice invoice) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plaćanje računa uskoro stiže - trenutno nije dostupno.'),
      ),
    );
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
      remaining: invoice.totalAmount - _totalPaid,
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
            value: '${_formatMoney(invoice.subtotal)} KM',
          ),
          const SizedBox(height: 6),
          _KeyValueRow(
            label: 'Porez',
            value: '${_formatMoney(invoice.tax)} KM',
          ),
          const SizedBox(height: 6),
          _KeyValueRow(
            label: 'Ukupno',
            value: '${_formatMoney(invoice.totalAmount)} KM',
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
            value: '${_formatMoney(totalPaid)} KM',
          ),
          const SizedBox(height: 6),
          _KeyValueRow(
            label: 'Preostalo za platiti',
            value: '${_formatMoney(remaining < 0 ? 0 : remaining)} KM',
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
          '${_formatMoney(payment.amount)} KM',
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
