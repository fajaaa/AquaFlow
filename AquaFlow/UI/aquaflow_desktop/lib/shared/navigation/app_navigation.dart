import 'package:flutter/material.dart';

/// Pushes [screen] with a consistent fade + slight upward slide transition,
/// used app-wide instead of the default [MaterialPageRoute] transition.
extension AppNavigation on BuildContext {
  Future<T?> pushScreen<T>(Widget screen) {
    return Navigator.of(this).push<T>(_fadeSlideRoute<T>(screen));
  }
}

PageRouteBuilder<T> _fadeSlideRoute<T>(Widget screen) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => screen,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 220),
  );
}
