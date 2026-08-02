import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/transfer_file_info.dart';
import '../../services/file_storage_service.dart';
import '../../services/qr_decoder_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chunk_progress_grid.dart';
import '../widgets/glass_card.dart';
import '../widgets/scan_progress_row.dart';
import '../widgets/scanner_overlay.dart';
import '../widgets/transfer_result_cards.dart';

class QrScannerView extends StatefulWidget {
  final VoidCallback? onTransferSuccess;

  const QrScannerView({super.key, this.onTransferSuccess});

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

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  // ---------------------------------------------------------------------------
  // Scanning logic
  // ---------------------------------------------------------------------------

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessingSuccess) return;
    for (final barcode in capture.barcodes) {
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
    setState(() => _isProcessingSuccess = true);
    try {
      final Uint8List bytes = _decoder.assembleFile();
      final meta = _decoder.metadata!;
      final saved = await FileStorageService.saveReceivedFile(
        bytes: bytes,
        fileName: meta.fileName,
        hash: meta.hash,
      );
      if (mounted) {
        setState(() => _savedFileInfo = saved);
        widget.onTransferSuccess?.call();
      }
    } catch (e) {
      if (mounted) setState(() => _assemblyError = e.toString());
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

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final hasProgress = _decoder.countReceived > 0;
    final frameColor = hasProgress ? AppColors.success : AppColors.primary;
    final statusText = _decoder.metadata != null
        ? 'Scanning: ${_decoder.metadata!.fileName}'
        : 'Align QR code within frame';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Camera card
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
                    ScannerOverlayFrame(color: frameColor),
                    Positioned(
                      top: 16,
                      child: ScanStatusLabel(text: statusText),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: TorchButton(controller: _cameraController),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ScanProgressRow(
                  countReceived: _decoder.countReceived,
                  totalChunks: _decoder.totalChunks,
                  progress: _decoder.progress,
                  isComplete: _decoder.isComplete,
                ),
              ),
            ],
          ),
        ),

        // Chunk grid
        if (_decoder.totalChunks > 0) ...[
          const SizedBox(height: 16),
          ChunkProgressGrid(
            totalChunks: _decoder.totalChunks,
            receivedIndices: _decoder.receivedChunks.keys.toSet(),
          ),
        ],

        // Success result
        if (_savedFileInfo != null) ...[
          const SizedBox(height: 16),
          TransferSuccessCard(
            fileInfo: _savedFileInfo!,
            formattedSize: _formatSize(_savedFileInfo!.fileSize),
            onScanAnother: _resetScanner,
          ),
        ],

        // Error result
        if (_assemblyError != null) ...[
          const SizedBox(height: 16),
          TransferErrorCard(
            errorMessage: _assemblyError!,
            onRetry: _resetScanner,
          ),
        ],
      ],
    );
  }
}
