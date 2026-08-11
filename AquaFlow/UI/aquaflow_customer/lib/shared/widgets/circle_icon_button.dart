import 'package:flutter/material.dart';

/// Small circular icon button (outlined surface circle) used for compact
/// chrome actions - theme toggle, logout - that sit outside the main AppBar
/// title. Colors come from [Theme] so it matches both light and dark mode.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 36,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final button = Material(
      color: colorScheme.surface,
      shape: CircleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.45, color: colorScheme.onSurfaceVariant),
        ),
      ),
    );

    final tooltipText = tooltip;
    if (tooltipText == null) return button;
    return Tooltip(message: tooltipText, child: button);
  }
}
