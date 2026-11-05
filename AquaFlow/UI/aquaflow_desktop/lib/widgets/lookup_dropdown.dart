import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/l10n/app_localizations.dart';
import 'package:aquaflow_desktop/models/lookup_item.dart';
import 'package:aquaflow_desktop/services/admin_lookup_service.dart';

/// Dropdown fed by a status/type codebook endpoint. The selected value is the
/// item's Code string ('' = "all" when [includeAllOption] is set).
class LookupDropdown extends StatefulWidget {
  const LookupDropdown({
    super.key,
    required this.route,
    required this.value,
    required this.onChanged,
    this.includeAllOption = false,
    this.label,
    this.icon,
    this.isExpanded = true,
  });

  final String route;
  final String? value;

  /// Null disables the dropdown. Receives '' for the "all" option.
  final ValueChanged<String?>? onChanged;
  final bool includeAllOption;
  final String? label;
  final IconData? icon;
  final bool isExpanded;

  @override
  State<LookupDropdown> createState() => _LookupDropdownState();
}

class _LookupDropdownState extends State<LookupDropdown> {
  final AdminLookupService _service = AdminLookupService();
  late Future<List<LookupItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchActive(widget.route);
  }

  @override
  void didUpdateWidget(covariant LookupDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route != widget.route) {
      _future = _service.fetchActive(widget.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final decoration = InputDecoration(
      labelText: widget.label,
      prefixIcon: widget.icon == null ? null : Icon(widget.icon),
    );

    return FutureBuilder<List<LookupItem>>(
      future: _future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <LookupItem>[];
        final current = widget.value ?? (widget.includeAllOption ? '' : null);
        final known = items.any((i) => i.code == current);
        final selected = current == '' && widget.includeAllOption
            ? ''
            : (known ? current : null);

        return DropdownButtonFormField<String>(
          key: ValueKey('${widget.route}|$selected|${items.length}'),
          initialValue: selected,
          isExpanded: widget.isExpanded,
          decoration: decoration,
          items: [
            if (widget.includeAllOption)
              DropdownMenuItem(value: '', child: Text(loc.allOption)),
            for (final item in items)
              DropdownMenuItem(
                value: item.code,
                child: Text(
                  item.localizedName(language),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: snapshot.hasData ? widget.onChanged : null,
        );
      },
    );
  }
}
