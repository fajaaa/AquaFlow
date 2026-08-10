import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// A placeholder list matching the shape of real content, shown while a
/// list screen's first page is loading instead of a bare spinner.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({
    super.key,
    required this.itemBuilder,
    this.itemCount = 6,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 16),
  });

  final Widget Function(BuildContext context, int index) itemBuilder;
  final int itemCount;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: padding,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: itemBuilder,
      ),
    );
  }
}
