import 'package:flutter/material.dart';

/// Shared admin desktop screen header: a title/subtitle block plus trailing
/// action widgets, wrapping to a stacked layout under 620px so it stays
/// usable in narrower panes.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    final actionsRow = Row(mainAxisSize: MainAxisSize.min, children: actions);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [titleColumn, const SizedBox(height: 12), actionsRow],
          );
        }

        return Row(
          children: [
            Expanded(child: titleColumn),
            actionsRow,
          ],
        );
      },
    );
  }
}
