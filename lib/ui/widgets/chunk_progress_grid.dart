import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Visual grid showing received vs pending chunks during a QR transfer.
class ChunkProgressGrid extends StatelessWidget {
  final int totalChunks;
  final Set<int> receivedIndices;

  const ChunkProgressGrid({
    super.key,
    required this.totalChunks,
    required this.receivedIndices,
  });

  @override
  Widget build(BuildContext context) {
    if (totalChunks <= 0) return const SizedBox.shrink();

    final displayCount = totalChunks > 150 ? 150 : totalChunks;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chunks (${receivedIndices.length}/$totalChunks)',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  _LegendDot(color: AppColors.success),
                  const SizedBox(width: 4),
                  const Text(
                    'Received',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                  ),
                  const SizedBox(width: 10),
                  _LegendDot(color: AppColors.border),
                  const SizedBox(width: 4),
                  const Text(
                    'Pending',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 3,
            runSpacing: 3,
            children: List.generate(displayCount, (index) {
              final isReceived = receivedIndices.contains(index);
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isReceived
                      ? AppColors.success
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: isReceived ? AppColors.success : AppColors.border,
                    width: 0.5,
                  ),
                ),
              );
            }),
          ),
          if (totalChunks > 150)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '+${totalChunks - 150} more chunks',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
