import 'package:flutter/material.dart';

import '../../models/transfer_file_info.dart';
import '../../services/file_storage_service.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

/// Green card displayed when a file transfer has completed successfully.
class TransferSuccessCard extends StatelessWidget {
  final TransferFileInfo fileInfo;
  final String formattedSize;
  final VoidCallback onScanAnother;

  const TransferSuccessCard({
    super.key,
    required this.fileInfo,
    required this.formattedSize,
    required this.onScanAnother,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.success.withValues(alpha: 0.4),
      backgroundColor: AppColors.success.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_outline,
                  color: AppColors.success, size: 22),
              SizedBox(width: 10),
              Text(
                'Transfer complete',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            fileInfo.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$formattedSize · SHA-256 verified',
            style: const TextStyle(color: AppColors.success, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      FileStorageService.openFile(fileInfo.filePath),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Open file'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      FileStorageService.shareFile(fileInfo.filePath),
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onScanAnother,
            child: const Text('Scan another file'),
          ),
        ],
      ),
    );
  }
}

/// Red card displayed when assembly or integrity check fails.
class TransferErrorCard extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const TransferErrorCard({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.error.withValues(alpha: 0.4),
      backgroundColor: AppColors.error.withValues(alpha: 0.06),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 32),
          const SizedBox(height: 8),
          const Text(
            'Transfer failed',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            errorMessage,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
