import 'package:flutter/material.dart';

import 'package:aquaflow_customer/models/customer_invoice.dart';
import 'package:aquaflow_customer/shared/theme/app_theme.dart';
import 'package:aquaflow_customer/shared/utils/money_format.dart';
import 'package:aquaflow_customer/widgets/invoice_status_pill.dart';

/// Reusable invoice card: branded gradient status bar (colored via
/// `InvoiceStatusMeta.of(invoice.status)`), invoice number, billing period,
/// and status pill - shared by `CustomerWaterMeterDetailScreen`'s per-meter
/// "Računi" section. The
/// amount row is where a payable (Issued) invoice diverges from a settled
/// one: Issued shows its outstanding `remainingAmount` in the warning accent
/// so it reads as "needs attention", while Paid/Cancelled show the flat
/// `totalAmount` in a neutral color.
class InvoiceSummaryCard extends StatelessWidget {
  const InvoiceSummaryCard({
    super.key,
    required this.invoice,
    required this.onTap,
  });

  final CustomerInvoice invoice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    final meta = InvoiceStatusMeta.of(invoice.status);
    final accent = _readableAccent(meta.color, theme.brightness);
    // Issued (still unpaid) is the invoice's "needs attention" state, same
    // role `!isRead` plays for a notification card.
    final needsAttention = invoice.isPayable;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isLight ? Colors.white : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: needsAttention
                  ? accent.withValues(alpha: 0.35)
                  : (isLight
                        ? const Color(0x121F2937)
                        : colorScheme.outlineVariant.withValues(alpha: 0.5)),
              width: needsAttention ? 1.5 : 1,
            ),
            boxShadow: isLight
                ? const [
                    BoxShadow(
                      color: Color(0x14062845),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          // A ListView gives each row unbounded height, so a bare stretched
          // Row would force an infinite-height constraint on its children and
          // crash. IntrinsicHeight bounds the row to its tallest child, letting
          // the color bar stretch to the card's height.
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Colored status bar - branded gradient with a white glyph.
                Container(
                  width: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _shade(meta.color, 0.16),
                        _shade(meta.color, -0.20),
                      ],
                    ),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(18),
                    ),
                  ),
                  child: Center(
                    child: Icon(meta.icon, color: Colors.white, size: 20),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      invoice.invoiceNumber,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: needsAttention
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (needsAttention) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: accent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_formatDate(invoice.billingPeriodFrom)} - ${_formatDate(invoice.billingPeriodTo)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                meta.label,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                            Text(
                              invoice.isPayable
                                  ? 'Preostalo: ${formatMoney(invoice.remainingAmount)} KM'
                                  : '${formatMoney(invoice.totalAmount)} KM',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: invoice.isPayable
                                    ? AppColors.warning
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Mirrors `_readableAccent` in notifications_screen.dart: any accent dark
  /// enough to blend into the dark theme's background is lifted toward white
  /// there. Light theme and the brighter accents are returned unchanged.
  static Color _readableAccent(Color base, Brightness brightness) {
    if (brightness == Brightness.dark && base.computeLuminance() < 0.2) {
      return Color.lerp(base, Colors.white, 0.6)!;
    }
    return base;
  }

  /// Tints [c] toward white for a positive [percent] or toward black for a
  /// negative one - used to build the two-stop gradient on the status bar.
  static Color _shade(Color c, double percent) {
    if (percent >= 0) return Color.lerp(c, Colors.white, percent)!;
    return Color.lerp(c, Colors.black, -percent)!;
  }
}

String _formatDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}.';
}
