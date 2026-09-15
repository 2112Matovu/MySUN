import 'package:flutter/material.dart';

import 'package:mysun_app/core/constants/categories.dart';

/// Small pill showing a category with its accent colour and icon.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge(this.category, {super.key, this.compact = false});

  final String category;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(category);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(categoryIcon(category), size: compact ? 12 : 14, color: color),
          const SizedBox(width: 5),
          Text(
            category,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
