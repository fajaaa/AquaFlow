import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'error_retry.dart';

/// Renders the loading / error / content triad shared by most screens that
/// load data on init: a loading state (spinner or custom [loadingBuilder]),
/// an [ErrorRetry] when [error] is set, or the built content with a subtle
/// fade-in once data is ready.
class AsyncStateView extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.builder,
    this.loadingBuilder,
  });

  final bool loading;
  final String? error;
  final Future<void> Function() onRetry;
  final WidgetBuilder builder;
  final WidgetBuilder? loadingBuilder;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return ErrorRetry(message: error!, onRetry: onRetry);
    }
    return builder(context).animate().fadeIn(duration: 180.ms);
  }
}
