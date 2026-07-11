import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Renders an image that lives behind a Bearer-authenticated endpoint - no
/// resource in this app serves images over a plain URL `Image.network` could
/// hit directly (see `FaultReportsController.GetPhoto`), so this fetches the
/// raw bytes through the caller-supplied [fetcher] and renders them via
/// `Image.memory`, with loading/error states in between.
///
/// Generalized over the fetch call itself (rather than hard-coding a fault
/// report id/photo id pair) so any future authenticated-image endpoint can
/// reuse it - just pass a closure that returns the bytes.
class AuthenticatedImage extends StatefulWidget {
  const AuthenticatedImage({
    super.key,
    required this.fetcher,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final Future<Uint8List> Function() fetcher;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  State<AuthenticatedImage> createState() => _AuthenticatedImageState();
}

class _AuthenticatedImageState extends State<AuthenticatedImage> {
  late Future<Uint8List> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.fetcher();
  }

  @override
  void didUpdateWidget(covariant AuthenticatedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fetcher != widget.fetcher) {
      _future = widget.fetcher();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snapshot) {
        Widget child;
        if (snapshot.connectionState != ConnectionState.done) {
          child = const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          child = Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        } else {
          child = Image.memory(
            snapshot.data!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          );
        }

        final sized = SizedBox(
          width: widget.width,
          height: widget.height,
          child: child,
        );

        final borderRadius = widget.borderRadius;
        if (borderRadius == null) return sized;
        return ClipRRect(borderRadius: borderRadius, child: sized);
      },
    );
  }
}
