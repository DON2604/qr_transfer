import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Restart / play-pause / next-frame transport controls used in
/// [QrStreamPlayer].
class PlaybackControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onRestart;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onNextFrame;

  const PlaybackControls({
    super.key,
    required this.isPlaying,
    required this.onRestart,
    required this.onTogglePlayPause,
    required this.onNextFrame,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.outlined(
          onPressed: onRestart,
          icon: const Icon(Icons.replay, size: 20),
          tooltip: 'Restart',
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: onTogglePlayPause,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
          child: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        IconButton.outlined(
          onPressed: onNextFrame,
          icon: const Icon(Icons.skip_next, size: 20),
          tooltip: 'Next frame',
        ),
      ],
    );
  }
}

/// FPS speed slider row.
class FpsSlider extends StatelessWidget {
  final int fps;
  final ValueChanged<int> onChanged;

  const FpsSlider({
    super.key,
    required this.fps,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
          '$fps FPS',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Slider(
            value: fps.toDouble(),
            min: 2,
            max: 15,
            divisions: 13,
            onChanged: (val) => onChanged(val.toInt()),
          ),
        ),
      ],
    );
  }
}

/// Chunk-size selector chips row.
class ChunkSizeSelector extends StatelessWidget {
  final int chunkSize;
  final ValueChanged<int> onChanged;

  static const _sizes = [200, 350, 500];

  const ChunkSizeSelector({
    super.key,
    required this.chunkSize,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
        ..._sizes.map((size) {
          final selected = chunkSize == size;
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
                if (sel) onChanged(size);
              },
            ),
          );
        }),
      ],
    );
  }
}
