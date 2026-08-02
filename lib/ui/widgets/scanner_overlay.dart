import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme/app_theme.dart';

/// Rounded viewfinder rectangle drawn over the camera preview.
class ScannerOverlayFrame extends StatelessWidget {
  final Color color;

  const ScannerOverlayFrame({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
    );
  }
}

/// Status label shown at the top of the camera preview.
class ScanStatusLabel extends StatelessWidget {
  final String text;

  const ScanStatusLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Circular torch-toggle button overlaid on the camera preview.
class TorchButton extends StatelessWidget {
  final MobileScannerController controller;

  const TorchButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.7),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        onPressed: controller.toggleTorch,
        icon: ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, state, _) {
            final isOn = state.torchState == TorchState.on;
            return Icon(
              isOn ? Icons.flash_on : Icons.flash_off,
              color: isOn ? AppColors.warning : AppColors.textSecondary,
              size: 20,
            );
          },
        ),
      ),
    );
  }
}
