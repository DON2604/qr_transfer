import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Chunk count label + percentage + animated progress bar shown below the
/// camera preview in [QrScannerView].
class ScanProgressRow extends StatelessWidget {
  final int countReceived;
  final int totalChunks;
  final double progress;
  final bool isComplete;

  const ScanProgressRow({
    super.key,
    required this.countReceived,
    required this.totalChunks,
    required this.progress,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    final color = isComplete ? AppColors.success : AppColors.primary;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$countReceived / ${totalChunks > 0 ? totalChunks : "?"} chunks',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            color: color,
          ),
        ),
      ],
    );
  }
}
