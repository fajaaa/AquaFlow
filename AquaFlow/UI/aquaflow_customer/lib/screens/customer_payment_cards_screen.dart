import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

import 'package:aquaflow_customer/l10n/app_localizations.dart';
import 'package:aquaflow_customer/models/payment_card.dart';
import 'package:aquaflow_customer/services/customer_payment_card_exception.dart';
import 'package:aquaflow_customer/services/customer_payment_card_service.dart';

/// "Moje kartice": the customer's saved Stripe cards (list, add, delete).
class CustomerPaymentCardsScreen extends StatefulWidget {
  const CustomerPaymentCardsScreen({super.key});

  @override
  State<CustomerPaymentCardsScreen> createState() =>
      _CustomerPaymentCardsScreenState();
}

class _CustomerPaymentCardsScreenState
    extends State<CustomerPaymentCardsScreen> {
  final CustomerPaymentCardService _service = CustomerPaymentCardService();

  PaymentCardList? _data;
  String? _error;
  bool _loading = true;
  bool _busy = false;

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
    try {
      final data = await _service.fetchCards();
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
        _loading = false;
      });
    } on CustomerPaymentCardException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addCard() async {
    if (_busy) return;
    final loc = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final setup = await _service.createSetup();
      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          setupIntentClientSecret: setup.setupIntentClientSecret,
          customerId: setup.stripeCustomerId,
          customerEphemeralKeySecret: setup.ephemeralKeySecret,
          merchantDisplayName: 'AquaFlow',
        ),
      );
      await stripe.Stripe.instance.presentPaymentSheet();
      if (!mounted) return;
      _snack(loc.savedCardsAdded);
      await _load();
    } on stripe.StripeException catch (e) {
      if (!mounted) return;
      // User cancelling the sheet is not an error.
      if (e.error.code != stripe.FailureCode.Canceled) {
        _snack(e.error.localizedMessage ?? e.error.message ?? loc.paymentFailedMessage);
      }
    } on CustomerPaymentCardException catch (e) {
      if (!mounted) return;
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(PaymentCard card) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.savedCardsDeleteTitle),
        content: Text(loc.savedCardsDeleteMessage(_brandName(card.brand), card.last4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await _service.deleteCard(card.id);
      if (!mounted) return;
      _snack(loc.savedCardsDeleted);
      await _load();
    } on CustomerPaymentCardException catch (e) {
      if (!mounted) return;
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _brandName(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return 'Visa';
      case 'mastercard':
        return 'Mastercard';
      case 'amex':
        return 'American Express';
      case 'discover':
        return 'Discover';
      case 'diners':
        return 'Diners Club';
      case 'jcb':
        return 'JCB';
      case 'unionpay':
        return 'UnionPay';
      default:
        return brand.isEmpty
            ? 'Card'
            : brand[0].toUpperCase() + brand.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final supported = _data?.isSupported ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(loc.savedCardsTitle)),
      floatingActionButton: supported
          ? FloatingActionButton.extended(
              onPressed: _busy ? null : _addCard,
              icon: const Icon(Icons.add),
              label: Text(loc.savedCardsAdd),
            )
          : null,
      body: _buildBody(loc),
    );
  }

  Widget _buildBody(AppLocalizations loc) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final data = _data;
    if (data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? '', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  setState(() => _loading = true);
                  _load();
                },
                child: Text(loc.commonRetry),
              ),
            ],
          ),
        ),
      );
    }

    if (!data.isSupported) {
      return _centeredMessage(Icons.info_outline, loc.savedCardsUnsupported);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: data.items.isEmpty
          ? LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: _centeredMessage(Icons.credit_card_off_outlined, loc.savedCardsEmpty),
                ),
              ),
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: data.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _cardTile(data.items[i], loc),
            ),
    );
  }

  Widget _centeredMessage(IconData icon, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _cardTile(PaymentCard card, AppLocalizations loc) {
    final theme = Theme.of(context);
    final expired = card.isExpired;
    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(Icons.credit_card, color: theme.colorScheme.primary),
        title: Text('${_brandName(card.brand)}  •••• ${card.last4}'),
        subtitle: Row(
          children: [
            Text(card.expiryLabel),
            if (expired) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  loc.savedCardsExpired,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: loc.commonDelete,
          onPressed: _busy ? null : () => _delete(card),
        ),
      ),
    );
  }
}
