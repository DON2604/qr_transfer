import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/transfer_file_info.dart';
import '../../services/file_storage_service.dart';
import '../../services/qr_decoder_service.dart';
import '../receiver/chunk_progress_grid.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class QrScannerView extends StatefulWidget {
  final VoidCallback? onTransferSuccess;

  const QrScannerView({
    super.key,
    this.onTransferSuccess,
  });

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.unrestricted,
    returnImage: false,
  );

  final QrDecoderService _decoder = QrDecoderService();
  bool _isProcessingSuccess = false;
  TransferFileInfo? _savedFileInfo;
  String? _assemblyError;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessingSuccess) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final rawVal = barcode.rawValue;
      if (rawVal != null && rawVal.isNotEmpty) {
        final didAdd = _decoder.processScannedPayload(rawVal);
        if (didAdd && mounted) {
          setState(() {});

          if (_decoder.isComplete && !_isProcessingSuccess) {
            _handleTransferCompletion();
          }
        }
      }
    }
  }

  Future<void> _handleTransferCompletion() async {
    setState(() {
      _isProcessingSuccess = true;
    });

    try {
      final Uint8List assembledBytes = _decoder.assembleFile();
      final meta = _decoder.metadata!;

      final savedInfo = await FileStorageService.saveReceivedFile(
        bytes: assembledBytes,
        fileName: meta.fileName,
        hash: meta.hash,
      );

      if (mounted) {
        setState(() {
          _savedFileInfo = savedInfo;
        });

        if (widget.onTransferSuccess != null) {
          widget.onTransferSuccess!();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _assemblyError = e.toString();
        });
      }
    }
  }

  void _resetScanner() {
    setState(() {
      _decoder.reset();
      _isProcessingSuccess = false;
      _savedFileInfo = null;
      _assemblyError = null;
    });
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final hasProgress = _decoder.countReceived > 0;
    final frameColor = hasProgress ? AppColors.success : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SizedBox(
                height: 320,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusMd - 1),
                      ),
                      child: MobileScanner(
                        controller: _cameraController,
                        onDetect: _onDetect,
                      ),
                    ),

                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        border: Border.all(color: frameColor, width: 2),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),

                    Positioned(
                      top: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          _decoder.metadata != null
                              ? 'Scanning: ${_decoder.metadata!.fileName}'
                              : 'Align QR code within frame',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: IconButton(
                          onPressed: () => _cameraController.toggleTorch(),
                          icon: ValueListenableBuilder(
                            valueListenable: _cameraController,
                            builder: (context, state, child) {
                              switch (state.torchState) {
                                case TorchState.on:
                                  return const Icon(
                                    Icons.flash_on,
                                    color: AppColors.warning,
                                    size: 20,
                                  );
                                case TorchState.off:
                                default:
                                  return const Icon(
                                    Icons.flash_off,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  );
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_decoder.countReceived} / ${_decoder.totalChunks > 0 ? _decoder.totalChunks : "?"} chunks',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${(_decoder.progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: _decoder.isComplete ? AppColors.success : AppColors.primary,
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
                        value: _decoder.progress,
                        minHeight: 4,
                        color: _decoder.isComplete ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (_decoder.totalChunks > 0)
          ChunkProgressGrid(
            totalChunks: _decoder.totalChunks,
            receivedIndices: _decoder.receivedChunks.keys.toSet(),
          ),

        if (_savedFileInfo != null) ...[
          const SizedBox(height: 16),
          GlassCard(
            borderColor: AppColors.success.withValues(alpha: 0.4),
            backgroundColor: AppColors.success.withValues(alpha: 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: AppColors.success, size: 22),
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
                  _savedFileInfo!.fileName,
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
                  '${_formatSize(_savedFileInfo!.fileSize)} · SHA-256 verified',
                  style: const TextStyle(color: AppColors.success, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => FileStorageService.openFile(_savedFileInfo!.filePath),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Open file'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => FileStorageService.shareFile(_savedFileInfo!.filePath),
                        icon: const Icon(Icons.share_outlined, size: 18),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _resetScanner,
                  child: const Text('Scan another file'),
                ),
              ],
            ),
          ),
        ],

        if (_assemblyError != null) ...[
          const SizedBox(height: 16),
          GlassCard(
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
                  _assemblyError!,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _resetScanner,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
