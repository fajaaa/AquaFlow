import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

import 'package:aquaflow_customer/models/customer_invoice.dart';
import 'package:aquaflow_customer/models/customer_payment.dart';
import 'package:aquaflow_customer/services/customer_invoice_exception.dart';
import 'package:aquaflow_customer/services/customer_invoice_service.dart';
import 'package:aquaflow_customer/widgets/invoice_status_pill.dart';
import 'package:aquaflow_customer/shared/theme/app_theme.dart';

/// Detail view of a single invoice belonging to the signed-in customer,
/// pushed from `CustomerWaterMeterDetailScreen`'s per-meter "Računi" section
/// as its own Scaffold+AppBar route (same push pattern as
/// `CustomerRequestsScreen`). Shows the readings,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final meta = InvoiceStatusMeta.of(invoice.status);
    final accent = _readableAccent(meta.color, theme.brightness);
    final onAccent =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? Colors.white
        : AppColors.textDark;

    return Scaffold(
      appBar: AppBar(title: Text(invoice.invoiceNumber)),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status banner - full-width strip across the top, same
              // treatment as the type banner on NotificationDetailScreen.
              Container(
                width: double.infinity,
                color: accent.withValues(alpha: 0.10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(meta.icon, color: onAccent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STATUS RAČUNA',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meta.label,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderCard(invoice: invoice, accent: accent),
                    const SizedBox(height: 16),
                    _ReadingsCard(invoice: invoice, accent: accent),
                    const SizedBox(height: 16),
                    _AmountCard(invoice: invoice, accent: accent),
                    const SizedBox(height: 16),
                    _buildPaymentsSection(invoice, accent),
                    if (invoice.isPayable) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _paying
                              ? null
                              : () => _payInvoice(invoice),
                          icon: _paying
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.payment_outlined),
                          label: const Text('Plati'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mirrors `_readableAccent` in notification_detail_screen.dart: any
  /// accent dark enough to blend into the dark theme's background is lifted
  /// toward white there. Light theme and the brighter accents are returned
  /// unchanged.
  static Color _readableAccent(Color base, Brightness brightness) {
    if (brightness == Brightness.dark && base.computeLuminance() < 0.2) {
      return Color.lerp(base, Colors.white, 0.6)!;
    }
    return base;
  }

  // Checkout only opens a payment session - it never completes the payment
  // itself, so nothing along this path may claim the invoice is paid. For the
  // Stripe provider, presentPaymentSheet() returning success only means the
  // customer finished entering card details; the actual charge is confirmed
  // asynchronously by Payments/webhook/stripe (see AGENTS.md), so
  // _refreshInvoiceWithRetry polls for the Paid status for a few seconds
  // instead of assuming it landed immediately.
  Future<void> _payInvoice(CustomerInvoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda plaćanja'),
        content: Text(
          'Da li ste sigurni da želite platiti '
          '${_formatMoney(invoice.remainingAmount)} BAM?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Otkaži'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Plati'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _paying = true);

    try {
      final session = await _service.checkout(invoice.id);
      if (!mounted) return;

      final clientSecret = session.clientSecret;
      if (clientSecret != null && clientSecret.isNotEmpty) {
        final presented = await _presentStripePaymentSheet(clientSecret);
        if (presented) {
          await _refreshInvoiceWithRetry();
        } else {
          // Cancelled or failed in the sheet itself - still refresh once in
          // case an earlier attempt on this invoice already completed.
          await _refreshInvoice();
          await _load();
        }
      } else {
        // No provider client secret (e.g. the Manual provider is active) -
        // the pre-Stripe placeholder flow: nothing to present, just report
        // that a Pending session was opened.
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
      }
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

  // Returns true once presentPaymentSheet() completes without the customer
  // cancelling or the sheet reporting an error - never true-because-paid,
  // just true-because-the-sheet-finished (see the _payInvoice comment above
  // for why that distinction matters).
  Future<bool> _presentStripePaymentSheet(String clientSecret) async {
    try {
      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'AquaFlow',
        ),
      );
      await stripe.Stripe.instance.presentPaymentSheet();

      if (!mounted) return true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Plaćanje u obradi.')));
      return true;
    } on stripe.StripeException catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_stripeErrorMessage(e))));
      return false;
    }
  }

  String _stripeErrorMessage(stripe.StripeException e) {
    if (e.error.code == stripe.FailureCode.Canceled) {
      return 'Plaćanje je otkazano.';
    }
    return e.error.localizedMessage ??
        e.error.message ??
        'Plaćanje nije uspjelo.';
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

  // The webhook confirming a Stripe payment arrives asynchronously, some time
  // after presentPaymentSheet() already returned control to the app, so the
  // first refresh right after can easily still show Issued. A few spaced
  // retries give the webhook a realistic chance to land before giving up and
  // showing whatever the last refresh returned (still not wrong - just not
  // yet caught up).
  Future<void> _refreshInvoiceWithRetry() async {
    const attempts = 3;
    const delay = Duration(seconds: 2);

    for (var attempt = 1; attempt <= attempts; attempt++) {
      await _refreshInvoice();
      await _load();
      if (!mounted) return;
      if (_invoice.status.toLowerCase() == 'paid') return;
      if (attempt < attempts) {
        await Future.delayed(delay);
        if (!mounted) return;
      }
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

  Widget _buildPaymentsSection(CustomerInvoice invoice, Color accent) {
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
      accent: accent,
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.invoice, required this.accent});

  final CustomerInvoice invoice;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      child: Text(
        invoice.invoiceNumber,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: accent,
        ),
      ),
    );
  }
}

class _ReadingsCard extends StatelessWidget {
  const _ReadingsCard({required this.invoice, required this.accent});

  final CustomerInvoice invoice;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            'Očitanja',
            icon: Icons.speed_outlined,
            color: accent,
          ),
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
  const _AmountCard({required this.invoice, required this.accent});

  final CustomerInvoice invoice;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            'Iznos',
            icon: Icons.payments_outlined,
            color: accent,
          ),
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
    required this.accent,
  });

  final List<CustomerPayment> payments;
  final double totalPaid;
  final double remaining;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            'Uplate',
            icon: Icons.receipt_long_outlined,
            color: accent,
          ),
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

/// Mirrors `_Card` in notification_detail_screen.dart so invoice sections
/// use the same rounded/bordered/shadowed card as a notification's.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.white
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE1EDF7)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// Mirrors `_SectionHeading` in notification_detail_screen.dart, plus a
/// small leading icon so each invoice section carries its own glyph.
class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text, {required this.icon, required this.color});

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          text.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: color,
          ),
        ),
      ],
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
