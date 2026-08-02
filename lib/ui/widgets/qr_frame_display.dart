import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/app_theme.dart';

/// Renders the current QR code frame and the header/chunk badge above it.
class QrFrameDisplay extends StatelessWidget {
  /// The encoded string data for the current frame.
  final String payload;

  /// File name shown in the title row.
  final String fileName;

  /// Subtitle below the file name (e.g. "12 chunks · abc12345…").
  final String subtitle;

  /// Label inside the badge (e.g. "Header" or "Chunk 3/12").
  final String badgeLabel;

  /// When true the badge uses the warning colour; otherwise uses primary.
  final bool isHeader;

  const QrFrameDisplay({
    super.key,
    required this.payload,
    required this.fileName,
    required this.subtitle,
    required this.badgeLabel,
    required this.isHeader,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = isHeader ? AppColors.warning : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title + badge row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(
                    color: badgeColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                badgeLabel,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // QR code
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: QrImageView(
              data: payload,
              version: QrVersions.auto,
              size: 260.0,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
