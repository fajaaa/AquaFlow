import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/l10n/app_localizations.dart';

/// Shared admin desktop table row actions: edit + delete icon buttons,
/// disabled together while a mutation is in flight. [extraActions], if
/// supplied, render before edit/delete for screens that need a row action
/// beyond the standard pair. [onEdit]/[onDelete] are optional - omit either
/// (or both) for screens whose row actions don't map onto that pair at all;
/// only [extraActions] renders in that case.
class TableRowActions extends StatelessWidget {
  const TableRowActions({
    super.key,
    required this.disabled,
    this.onEdit,
    this.onDelete,
    this.extraActions,
  });

  final bool disabled;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final List<Widget>? extraActions;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...?extraActions,
        if (onEdit != null)
          IconButton(
            tooltip: loc.commonEdit,
            onPressed: disabled ? null : onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        if (onDelete != null)
          IconButton(
            tooltip: loc.commonDelete,
            onPressed: disabled ? null : onDelete,
            icon: const Icon(Icons.delete_outline),
            color: Theme.of(context).colorScheme.error,
          ),
      ],
    );
  }
}
