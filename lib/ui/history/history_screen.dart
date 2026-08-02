import 'package:flutter/material.dart';
import '../../models/transfer_file_info.dart';
import '../../services/file_storage_service.dart';
import '../widgets/glass_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const Color emeraldColor = Color(0xFF10B981);
  List<TransferFileInfo> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final items = await FileStorageService.getHistory();
    if (mounted) {
      setState(() {
        _history = items;
        _isLoading = false;
      });
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) return Icons.image_rounded;
    if (['mp3', 'wav', 'm4a', 'flac'].contains(ext)) return Icons.audiotrack_rounded;
    if (['mp4', 'mkv', 'avi', 'mov'].contains(ext)) return Icons.movie_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _getFileColor(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) return Colors.pinkAccent;
    if (['mp3', 'wav', 'm4a', 'flac'].contains(ext)) return Colors.cyanAccent;
    if (['mp4', 'mkv', 'avi', 'mov'].contains(ext)) return Colors.amberAccent;
    return Colors.purpleAccent;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
    }

    if (_history.isEmpty) {
      return Center(
        child: GlassCard(
          margin: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 64, color: Colors.white.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              const Text(
                'No Transferred Files Yet',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Files received via Optical QR scanner will be listed here automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: Colors.cyanAccent,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _history.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _history[index];
          final color = _getFileColor(item.fileName);
          final icon = _getFileIcon(item.fileName);

          return GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Size: ${_formatSize(item.fileSize)} • ${item.receivedAt.day}/${item.receivedAt.month} ${item.receivedAt.hour}:${item.receivedAt.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
                  color: const Color(0xFF1E293B),
                  onSelected: (val) async {
                    if (val == 'open') {
                      await FileStorageService.openFile(item.filePath);
                    } else if (val == 'share') {
                      await FileStorageService.shareFile(item.filePath);
                    } else if (val == 'delete') {
                      await FileStorageService.deleteFile(item);
                      _loadHistory();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'open',
                      child: Row(
                        children: [
                          Icon(Icons.open_in_new_rounded, color: Colors.cyanAccent, size: 18),
                          SizedBox(width: 8),
                          Text('Open File', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share_rounded, color: emeraldColor, size: 18),
                          SizedBox(width: 8),
                          Text('Share', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded, color: Colors.redAccent, size: 18),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
