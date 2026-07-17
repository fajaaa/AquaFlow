import 'package:flutter/material.dart';

/// Shared admin desktop table row actions: edit + delete icon buttons,
/// disabled together while a mutation is in flight. [extraActions], if
/// supplied, render before edit/delete for screens that need a row action
/// beyond the standard pair.
class TableRowActions extends StatelessWidget {
  const TableRowActions({
    super.key,
    required this.disabled,
    required this.onEdit,
    required this.onDelete,
    this.extraActions,
  });

  final bool disabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final List<Widget>? extraActions;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...?extraActions,
        IconButton(
          tooltip: 'Uredi',
          onPressed: disabled ? null : onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Obriši',
          onPressed: disabled ? null : onDelete,
          icon: const Icon(Icons.delete_outline),
          color: Theme.of(context).colorScheme.error,
        ),
      ],
    );
  }
}
