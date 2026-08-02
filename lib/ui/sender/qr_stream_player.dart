import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/qr_encoder_service.dart';
import '../sender/file_selector_card.dart';
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
  int _fps = 8; // Default 8 frames per second
  int _chunkSize = 350; // Default 350 bytes per chunk

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
      _timer?.cancel();
      _currentFrame = (_currentFrame + 1) % _package.totalFrames;
    });
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
        children: [
          // Header info & Status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.fileInfo.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_package.chunks.length} Chunks • Hash: ${_package.metadata.hash.substring(0, 8)}...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isHeader
                      ? Colors.amberAccent.withValues(alpha: 0.2)
                      : Colors.cyanAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isHeader ? Colors.amberAccent : Colors.cyanAccent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isHeader ? Icons.subtitles_rounded : Icons.numbers_rounded,
                      size: 14,
                      color: isHeader ? Colors.amberAccent : Colors.cyanAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isHeader
                          ? 'HEADER'
                          : 'CHUNK $_currentFrame/${_package.chunks.length}',
                      style: TextStyle(
                        color: isHeader ? Colors.amberAccent : Colors.cyanAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Animated Glowing QR Container
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isHeader
                        ? Colors.amberAccent.withValues(alpha: 0.6)
                        : Colors.cyanAccent.withValues(alpha: 0.6),
                    blurRadius: 25,
                    spreadRadius: 2,
                  ),
                ],
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

          // Frame Progress Bar
          LinearProgressIndicator(
            value: _package.totalFrames > 0
                ? (_currentFrame + 1) / _package.totalFrames
                : 0,
            backgroundColor: Colors.white10,
            color: isHeader ? Colors.amberAccent : Colors.cyanAccent,
            minHeight: 4,
            borderRadius: BorderRadius.circular(4),
          ),

          const SizedBox(height: 20),

          // Control Buttons (Play, Pause, Step)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: () {
                  setState(() {
                    _currentFrame = 0;
                  });
                },
                icon: const Icon(Icons.replay_rounded),
                tooltip: 'Restart Stream',
              ),
              const SizedBox(width: 16),
              FloatingActionButton.large(
                onPressed: _togglePlayPause,
                backgroundColor: _isPlaying ? Colors.pinkAccent : Colors.cyanAccent,
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 40,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 16),
              IconButton.filledTonal(
                onPressed: _nextFrame,
                icon: const Icon(Icons.skip_next_rounded),
                tooltip: 'Next Frame',
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),

          // Stream Speed & Chunk Settings
          Row(
            children: [
              const Icon(Icons.speed_rounded, color: Colors.cyanAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Speed: $_fps FPS',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              Expanded(
                child: Slider(
                  value: _fps.toDouble(),
                  min: 2,
                  max: 15,
                  divisions: 13,
                  activeColor: Colors.cyanAccent,
                  inactiveColor: Colors.white12,
                  label: '$_fps FPS',
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
              const Icon(Icons.data_array_rounded, color: Colors.amberAccent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Chunk Density:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                children: [200, 350, 500].map((size) {
                  final selected = _chunkSize == size;
                  return ChoiceChip(
                    label: Text('${size}B'),
                    selected: selected,
                    selectedColor: Colors.amberAccent,
                    labelStyle: TextStyle(
                      color: selected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (sel) {
                      if (sel) {
                        setState(() {
                          _chunkSize = size;
                        });
                        _encodeAndStart();
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
