import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shows the name, size, and category of the currently selected file,
/// with a clear button. Used inside [FileSelectorCard].
class SelectedFileRow extends StatelessWidget {
  final String name;
  final String formattedSize;
  final String category;
  final IconData icon;
  final Color color;
  final VoidCallback onClear;

  const SelectedFileRow({
    super.key,
    required this.name,
    required this.formattedSize,
    required this.category,
    required this.icon,
    required this.color,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$formattedSize · $category',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
