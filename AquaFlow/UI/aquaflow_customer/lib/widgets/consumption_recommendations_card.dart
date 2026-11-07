import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:aquaflow_customer/l10n/app_localizations.dart';
import 'package:aquaflow_customer/models/consumption_insight.dart';
import 'package:aquaflow_customer/shared/theme/app_theme.dart';
import 'package:aquaflow_customer/shared/widgets/error_retry.dart';
import 'package:aquaflow_customer/shared/utils/money_format.dart';

/// "Prognoza i preporuke" card of the water meter detail screen: the model's
/// expected consumption for the next period, the open consumption alert (if
/// any) and one tile per recommendation with an expandable "Zašto?" line that
/// states the numbers the recommendation was derived from.
///
/// Stateless on purpose - the owning screen loads [insight] together with its
/// own data; this card only renders its loading / error (with [onRetry]) /
/// loaded states, so a failed forecast never breaks the screen.
class ConsumptionRecommendationsCard extends StatelessWidget {
  const ConsumptionRecommendationsCard({
    super.key,
    required this.loading,
    required this.error,
    required this.insight,
    required this.onRetry,
    required this.onReportFault,
    required this.accent,
  });

  final bool loading;
  final String? error;
  final ConsumptionInsight? insight;
  final Future<void> Function() onRetry;

  /// Opens the new fault report dialog for this meter.
  final VoidCallback onReportFault;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isLight = theme.brightness == Brightness.light;
    final data = insight;

    Widget body;
    if (loading && data == null) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    } else if (error != null && data == null) {
      body = ErrorRetry(message: error!, onRetry: onRetry);
    } else if (data == null) {
      body = const SizedBox.shrink();
    } else {
      body = _Loaded(
        insight: data,
        accent: accent,
        onReportFault: onReportFault,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : theme.colorScheme.surfaceContainerHighest,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph_outlined, size: 15, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  loc.insightHeading.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          body,
        ],
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.insight,
    required this.accent,
    required this.onReportFault,
  });

  final ConsumptionInsight insight;
  final Color accent;
  final VoidCallback onReportFault;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final alert = insight.openAlert;
    final tiles = [
      for (final r in insight.recommendations)
        if (_knownCodes.contains(r.code))
          _RecommendationTile(
            recommendation: r,
            insight: insight,
            onReportFault: onReportFault,
          ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (insight.hasEnoughData) ...[
          Text(
            loc.insightExpectedConsumption(
              _num(context, insight.predictedNextM3),
              _num(context, insight.predictedLowerM3),
              _num(context, insight.predictedUpperM3),
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (insight.estimatedNextAmount != null) ...[
            const SizedBox(height: 4),
            Text(
              loc.insightEstimatedAmount(
                formatMoney(insight.estimatedNextAmount!),
                insight.currency,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
        if (alert != null) ...[
          const SizedBox(height: 12),
          _AlertBox(alert: alert),
        ],
        for (final tile in tiles) ...[const SizedBox(height: 12), tile],
        const SizedBox(height: 14),
        Text(
          loc.insightFootnote,
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _AlertBox extends StatelessWidget {
  const _AlertBox({required this.alert});

  final ConsumptionInsightAlert alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final color = AppColors.warning;
    final text = alert.hasExpectedInterval
        ? loc.insightAlertBody(
            _num(context, alert.measuredValue),
            _num(context, alert.expectedValue!),
            _num(context, alert.expectedLowerBound!),
            _num(context, alert.expectedUpperBound!),
            _num(context, alert.thresholdValue),
          )
        : loc.insightAlertBodyNoModel(
            _num(context, alert.measuredValue),
            _num(context, alert.thresholdValue),
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.insightAlertTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(text, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const Set<String> _knownCodes = {
  'LeakSuspected',
  'MeterCheckSuggested',
  'ForecastAboveAverage',
  'AboveSettlementAverage',
  'OnTrack',
  'NotEnoughData',
};

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({
    required this.recommendation,
    required this.insight,
    required this.onReportFault,
  });

  final ConsumptionRecommendation recommendation;
  final ConsumptionInsight insight;
  final VoidCallback onReportFault;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final r = recommendation;
    final content = _contentFor(context, loc);
    final color = _colorFor(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Theme(
        // ExpansionTile draws its own divider lines; hide them inside the tile.
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_iconFor(r), color: color, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          content.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(content.body, style: theme.textTheme.bodyMedium),
                        if (content.tip != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            content.tip!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (r.code == 'MeterCheckSuggested') ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: onReportFault,
                            icon: const Icon(Icons.report_problem_outlined),
                            label: Text(loc.insightReportFaultButton),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                dense: true,
                expandedAlignment: Alignment.centerLeft,
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                title: Text(
                  loc.insightWhyLabel,
                  style: theme.textTheme.labelLarge?.copyWith(color: color),
                ),
                children: [Text(content.why, style: theme.textTheme.bodySmall)],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorFor(BuildContext context) {
    if (recommendation.code == 'LeakSuspected') {
      return Theme.of(context).colorScheme.error;
    }
    switch (recommendation.severity) {
      case 'warning':
        return AppColors.warning;
      case 'positive':
        return AppColors.success;
      default:
        return AppColors.secondary;
    }
  }

  IconData _iconFor(ConsumptionRecommendation r) {
    switch (r.code) {
      case 'LeakSuspected':
        return Icons.water_damage_outlined;
      case 'MeterCheckSuggested':
        return Icons.speed_outlined;
      case 'ForecastAboveAverage':
        return Icons.trending_up;
      case 'AboveSettlementAverage':
        return Icons.groups_outlined;
      case 'OnTrack':
        return Icons.check_circle_outline;
      default:
        return Icons.hourglass_empty;
    }
  }

  _TileContent _contentFor(BuildContext context, AppLocalizations loc) {
    final r = recommendation;
    String n(String name, [int decimals = 1]) =>
        _num(context, r.param(name) ?? 0, decimals);
    final percent = _num(context, r.param('percentAbove') ?? 0, 0);

    switch (r.code) {
      case 'LeakSuspected':
        return _TileContent(
          title: loc.insightLeakTitle,
          body: loc.insightLeakBody(n('measured')),
          tip: loc.insightTipLeak,
          why: _withExpected(
            context,
            loc,
            loc.insightLeakWhy(n('measured'), n('baseline')),
          ),
        );
      case 'MeterCheckSuggested':
        return _TileContent(
          title: loc.insightMeterCheckTitle,
          body: loc.insightMeterCheckBody,
          why: _withExpected(
            context,
            loc,
            loc.insightLeakWhy(n('measured'), n('baseline')),
          ),
        );
      case 'ForecastAboveAverage':
        return _TileContent(
          title: loc.insightForecastTitle,
          body: loc.insightForecastBody(percent),
          tip: loc.insightTipSaving,
          why: loc.insightForecastWhy(
            n('predicted'),
            percent,
            n('average'),
            n('lower'),
            n('upper'),
          ),
        );
      case 'AboveSettlementAverage':
        return _TileContent(
          title: loc.insightSettlementTitle,
          body: loc.insightSettlementBody(percent),
          tip: loc.insightTipSaving,
          why: loc.insightSettlementWhy(
            n('average'),
            percent,
            n('settlementAverage'),
          ),
        );
      case 'OnTrack':
        return _TileContent(
          title: loc.insightOnTrackTitle,
          body: loc.insightOnTrackBody,
          why: loc.insightOnTrackWhy(
            _num(context, insight.predictedNextM3),
            _num(context, insight.recentAverageM3),
          ),
        );
      default: // NotEnoughData
        final have = (r.param('readingsCount') ?? insight.readingsCount)
            .round();
        final required = (r.param('required') ?? have).round();
        final missing = (required - have).clamp(1, 1 << 30);
        return _TileContent(
          title: loc.insightNotEnoughTitle,
          body: loc.insightNotEnoughBody('$missing'),
          why: loc.insightNotEnoughWhy('$have', '$required'),
        );
    }
  }

  /// Appends the model's expected interval to a leak/meter-check "why" line
  /// when the recommendation carries one.
  String _withExpected(BuildContext context, AppLocalizations loc, String why) {
    final r = recommendation;
    final expected = r.param('expected');
    final lower = r.param('lower');
    final upper = r.param('upper');
    if (expected == null || lower == null || upper == null) return why;
    return '$why ${loc.insightWhyExpected(_num(context, expected), _num(context, lower), _num(context, upper))}';
  }
}

class _TileContent {
  const _TileContent({
    required this.title,
    required this.body,
    required this.why,
    this.tip,
  });

  final String title;
  final String body;
  final String why;
  final String? tip;
}

/// Locale-aware number with [decimals] fraction digits (e.g. `14,2` in bs/de,
/// `14.2` in en).
String _num(BuildContext context, double value, [int decimals = 1]) {
  final locale = Localizations.localeOf(context).toString();
  return NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: decimals,
  ).format(value);
}
