import 'package:flutter/material.dart';

/// Circular refresh button that spins its icon while [onRefresh] is awaited.
/// Drop-in replacement for a bare `IconButton(icon: Icon(Icons.refresh))` -
/// same tap target, but gives visual feedback for the duration of the call
/// instead of relying solely on an external loading indicator.
class RefreshButton extends StatefulWidget {
  const RefreshButton({
    super.key,
    required this.onRefresh,
    this.tooltip = 'Osvježi',
    this.size = 36,
    this.enabled = true,
  });

  final Future<void> Function() onRefresh;
  final String? tooltip;
  final double size;

  /// Set to false to disable taps for an external reason (e.g. a mutation in
  /// progress elsewhere on the screen) even while not mid-spin.
  final bool enabled;

  @override
  State<RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<RefreshButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  bool _loading = false;

  Future<void> _handleTap() async {
    if (_loading) return;
    setState(() => _loading = true);
    _controller.repeat();
    try {
      await widget.onRefresh();
    } finally {
      _controller.stop();
      _controller.value = 0;
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canTap = widget.enabled && !_loading;

    final button = Material(
      color: colorScheme.surface,
      shape: CircleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: canTap ? _handleTap : null,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: RotationTransition(
              turns: _controller,
              child: Icon(
                Icons.refresh,
                size: widget.size * 0.5,
                color: widget.enabled ? colorScheme.onSurfaceVariant : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    );

    final tooltipText = widget.tooltip;
    if (tooltipText == null) return button;
    return Tooltip(message: tooltipText, child: button);
  }
}
