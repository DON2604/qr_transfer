import 'dart:async';
import 'package:flutter/material.dart';

import '../../services/qr_encoder_service.dart';
import '../sender/file_selector_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/playback_controls.dart';
import '../widgets/qr_frame_display.dart';

class QrStreamPlayer extends StatefulWidget {
  final SelectedFileInfo fileInfo;

  const QrStreamPlayer({super.key, required this.fileInfo});

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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Playback logic
  // ---------------------------------------------------------------------------

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
    final interval = Duration(milliseconds: (1000 / _fps).round());
    _timer = Timer.periodic(interval, (_) {
      if (mounted) {
        setState(() {
          _currentFrame = (_currentFrame + 1) % _package.totalFrames;
        });
      }
    });
  }

  void _togglePlayPause() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  void _restart() {
    setState(() => _currentFrame = 0);
  }

  void _nextFrame() {
    setState(() => _isPlaying = false);
    _timer?.cancel();
    setState(() {
      _currentFrame = (_currentFrame + 1) % _package.totalFrames;
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isHeader = _currentFrame == 0;
    final badgeLabel = isHeader
        ? 'Header'
        : 'Chunk $_currentFrame/${_package.chunks.length}';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // QR code + header/chunk badge
          QrFrameDisplay(
            payload: _package.getFramePayload(_currentFrame),
            fileName: widget.fileInfo.name,
            subtitle:
                '${_package.chunks.length} chunks · ${_package.metadata.hash.substring(0, 8)}…',
            badgeLabel: badgeLabel,
            isHeader: isHeader,
          ),

          const SizedBox(height: 20),

          // Frame progress bar
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

          // Transport controls
          PlaybackControls(
            isPlaying: _isPlaying,
            onRestart: _restart,
            onTogglePlayPause: _togglePlayPause,
            onNextFrame: _nextFrame,
          ),

          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Settings
          FpsSlider(
            fps: _fps,
            onChanged: (val) {
              setState(() => _fps = val);
              if (_isPlaying) _startTimer();
            },
          ),

          ChunkSizeSelector(
            chunkSize: _chunkSize,
            onChanged: (size) {
              setState(() => _chunkSize = size);
              _encodeAndStart();
            },
          ),
        ],
      ),
    );
  }
}
