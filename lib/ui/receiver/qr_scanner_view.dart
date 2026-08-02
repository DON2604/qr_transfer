import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/transfer_file_info.dart';
import '../../services/file_storage_service.dart';
import '../../services/qr_decoder_service.dart';
import '../receiver/chunk_progress_grid.dart';
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
  static const Color emeraldColor = Color(0xFF10B981);

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

          // Check if completion reached
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Camera View Card
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Camera frame viewport
              SizedBox(
                height: 320,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: MobileScanner(
                        controller: _cameraController,
                        onDetect: _onDetect,
                      ),
                    ),

                    // Target scanning frame overlay
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _decoder.countReceived > 0 ? emeraldColor : Colors.cyanAccent,
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: (_decoder.countReceived > 0 ? emeraldColor : Colors.cyanAccent)
                                .withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),

                    // Top scan instruction chip
                    Positioned(
                      top: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.qr_code_scanner_rounded, color: Colors.cyanAccent, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              _decoder.metadata != null
                                  ? 'Scanning: ${_decoder.metadata!.fileName}'
                                  : 'Align Sender QR Code inside box',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Camera Controls Overlay
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => _cameraController.toggleTorch(),
                          icon: ValueListenableBuilder(
                            valueListenable: _cameraController,
                            builder: (context, state, child) {
                              switch (state.torchState) {
                                case TorchState.on:
                                  return const Icon(Icons.flash_on_rounded, color: Colors.amberAccent);
                                case TorchState.off:
                                default:
                                  return const Icon(Icons.flash_off_rounded, color: Colors.white);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Progress Section below camera
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Captured: ${_decoder.countReceived} / ${_decoder.totalChunks > 0 ? _decoder.totalChunks : "?"} Chunks',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${(_decoder.progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _decoder.progress,
                      backgroundColor: Colors.white10,
                      color: _decoder.isComplete ? emeraldColor : Colors.cyanAccent,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Live Chunk Grid Matrix Visualizer
        if (_decoder.totalChunks > 0)
          ChunkProgressGrid(
            totalChunks: _decoder.totalChunks,
            receivedIndices: _decoder.receivedChunks.keys.toSet(),
          ),

        // Transfer Complete Card / Modal
        if (_savedFileInfo != null) ...[
          const SizedBox(height: 16),
          GlassCard(
            borderColor: emeraldColor,
            backgroundColor: emeraldColor.withValues(alpha: 0.1),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: emeraldColor, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'Transfer Verified & Saved!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _savedFileInfo!.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Size: ${_formatSize(_savedFileInfo!.fileSize)} • SHA-256 Verified',
                  style: const TextStyle(color: emeraldColor, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => FileStorageService.openFile(_savedFileInfo!.filePath),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: emeraldColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('Open File', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => FileStorageService.shareFile(_savedFileInfo!.filePath),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: emeraldColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _resetScanner,
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.cyanAccent),
                  label: const Text('Scan Another File', style: TextStyle(color: Colors.cyanAccent)),
                ),
              ],
            ),
          ),
        ],

        // Error message if assembly/integrity fails
        if (_assemblyError != null) ...[
          const SizedBox(height: 16),
          GlassCard(
            borderColor: Colors.redAccent,
            backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
            child: Column(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 36),
                const SizedBox(height: 8),
                const Text('Transfer Error', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_assemblyError!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _resetScanner,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  child: const Text('Reset & Try Again'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
