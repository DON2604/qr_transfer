import 'package:flutter/material.dart';

class ChunkProgressGrid extends StatelessWidget {
  final int totalChunks;
  final Set<int> receivedIndices;

  static const Color emeraldColor = Color(0xFF10B981);

  const ChunkProgressGrid({
    super.key,
    required this.totalChunks,
    required this.receivedIndices,
  });

  @override
  Widget build(BuildContext context) {
    if (totalChunks <= 0) return const SizedBox.shrink();

    // Limit grid rendering for extremely large chunk counts so UI remains fast
    final displayCount = totalChunks > 150 ? 150 : totalChunks;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chunk Matrix (${receivedIndices.length} / $totalChunks Received)',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: emeraldColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Captured', style: TextStyle(color: Colors.white54, fontSize: 10)),
                  const SizedBox(width: 10),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Missing', style: TextStyle(color: Colors.white54, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(displayCount, (index) {
              final isReceived = receivedIndices.contains(index);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isReceived ? emeraldColor : Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: isReceived
                      ? [
                          BoxShadow(
                            color: emeraldColor.withValues(alpha: 0.6),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),
          if (totalChunks > 150)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '+${totalChunks - 150} more chunks...',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}
