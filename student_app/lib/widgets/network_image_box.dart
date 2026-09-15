import 'package:flutter/material.dart';

import 'package:mysun_app/core/constants/categories.dart';

/// A fixed-ratio image that degrades gracefully: a category-tinted gradient
/// with an icon whenever [url] is null or fails to load.
class NetworkImageBox extends StatelessWidget {
  const NetworkImageBox({
    super.key,
    required this.url,
    required this.category,
    this.height,
    this.aspectRatio = 16 / 9,
    this.borderRadius = BorderRadius.zero,
  });

  final String? url;
  final String category;
  final double? height;
  final double aspectRatio;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final fallback = _Fallback(category: category);

    Widget child;
    if (url == null || url!.isEmpty) {
      child = fallback;
    } else {
      child = Image.network(
        url!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        loadingBuilder: (context, widget, progress) {
          if (progress == null) return widget;
          return _Shimmer(category: category);
        },
        errorBuilder: (context, error, stack) => fallback,
      );
    }

    final clipped = ClipRRect(borderRadius: borderRadius, child: child);

    if (height != null) {
      return SizedBox(height: height, width: double.infinity, child: clipped);
    }
    return AspectRatio(aspectRatio: aspectRatio, child: clipped);
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(category);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.85), color.withValues(alpha: 0.55)],
        ),
      ),
      child: Center(
        child: Icon(categoryIcon(category),
            size: 44, color: Colors.white.withValues(alpha: 0.9)),
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: categoryColor(category).withValues(alpha: 0.15),
    );
  }
}
