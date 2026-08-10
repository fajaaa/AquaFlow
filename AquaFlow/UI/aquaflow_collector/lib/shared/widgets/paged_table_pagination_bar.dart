import 'package:flutter/material.dart';

/// Shared pagination footer for admin desktop tables: prev/next controls,
/// a page/count summary, and a 10/20/50 page-size dropdown. Switches to a
/// stacked layout under 500px so it stays usable in narrower panes.
class PagedTablePaginationBar extends StatelessWidget {
  const PagedTablePaginationBar({
    super.key,
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
