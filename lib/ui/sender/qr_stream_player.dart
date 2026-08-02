import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/qr_encoder_service.dart';
import '../sender/file_selector_card.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class QrStreamPlayer extends StatefulWidget {
  final SelectedFileInfo fileInfo;

  const QrStreamPlayer({
    super.key,
    required this.fileInfo,
  });

  @override
  State<QrStreamPlayer> createState() => _QrStreamPlayerState();
}

class _QrStreamPlayerState extends State<QrStreamPlayer> {
  late QrStreamPackage _package;
  Timer? _timer;
  int _currentFrame = 0;
  bool _isPlaying = true;
  int _fps = 8;
  int _chunkSize = 350;

  @override
  void initState() {
    super.initState();
    _encodeAndStart();
  }

  @override
  void didUpdateWidget(covariant QrStreamPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileInfo.bytes != widget.fileInfo.bytes) {
      _encodeAndStart();
    }
  }

  void _encodeAndStart() {
    _package = QrEncoderService.encodeFile(
      fileBytes: widget.fileInfo.bytes,
      fileName: widget.fileInfo.name,
      rawChunkSize: _chunkSize,
    );
    _currentFrame = 0;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (!_isPlaying) return;

    final intervalMs = (1000 / _fps).round();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (mounted) {
        setState(() {
          _currentFrame = (_currentFrame + 1) % _package.totalFrames;
        });
      }
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    if (_isPlaying) {
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  void _nextFrame() {
    setState(() {
      _isPlaying = false;
    });
    _timer?.cancel();
    _currentFrame = (_currentFrame + 1) % _package.totalFrames;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payload = _package.getFramePayload(_currentFrame);
    final isHeader = _currentFrame == 0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.fileInfo.name,
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
                      '${_package.chunks.length} chunks · ${_package.metadata.hash.substring(0, 8)}…',
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isHeader ? AppColors.warning : AppColors.primary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                    color: (isHeader ? AppColors.warning : AppColors.primary)
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  isHeader
                      ? 'Header'
                      : 'Chunk $_currentFrame/${_package.chunks.length}',
                  style: TextStyle(
                    color: isHeader ? AppColors.warning : AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

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

          const SizedBox(height: 20),

          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _package.totalFrames > 0
                  ? (_currentFrame + 1) / _package.totalFrames
                  : 0,
              minHeight: 3,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.outlined(
                onPressed: () {
                  setState(() {
                    _currentFrame = 0;
                  });
                },
                icon: const Icon(Icons.replay, size: 20),
                tooltip: 'Restart',
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _togglePlayPause,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              IconButton.outlined(
                onPressed: _nextFrame,
                icon: const Icon(Icons.skip_next, size: 20),
                tooltip: 'Next frame',
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),

          Row(
            children: [
              const Text(
                'Speed',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$_fps FPS',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _fps.toDouble(),
                  min: 2,
                  max: 15,
                  divisions: 13,
                  onChanged: (val) {
                    setState(() {
                      _fps = val.toInt();
                    });
                    if (_isPlaying) _startTimer();
                  },
                ),
              ),
            ],
          ),

          Row(
            children: [
              const Text(
                'Chunk size',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              ...[200, 350, 500].map((size) {
                final selected = _chunkSize == size;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${size}B'),
                    selected: selected,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    onSelected: (sel) {
                      if (sel) {
                        setState(() {
                          _chunkSize = size;
                        });
                        _encodeAndStart();
                      }
                    },
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
