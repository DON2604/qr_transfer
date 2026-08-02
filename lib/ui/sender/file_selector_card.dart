import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../widgets/glass_card.dart';

class SelectedFileInfo {
  final String name;
  final int size;
  final String path;
  final Uint8List bytes;
  final String category; // image, video, audio, doc

  SelectedFileInfo({
    required this.name,
    required this.size,
    required this.path,
    required this.bytes,
    required this.category,
  });
}

class FileSelectorCard extends StatefulWidget {
  final Function(SelectedFileInfo info) onFileSelected;

  const FileSelectorCard({
    super.key,
    required this.onFileSelected,
  });

  @override
  State<FileSelectorCard> createState() => _FileSelectorCardState();
}

class _FileSelectorCardState extends State<FileSelectorCard> {
  SelectedFileInfo? _selectedFile;
  bool _isLoading = false;

  Future<void> _pickFile({FileType type = FileType.any}) async {
    setState(() => _isLoading = true);
    try {
      final result = await FilePicker.pickFiles(
        type: type,
      );

      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.first;
        Uint8List? bytes;

        try {
          bytes = await platformFile.readAsBytes();
        } catch (_) {
          if (platformFile.path != null) {
            final file = File(platformFile.path!);
            if (await file.exists()) {
              bytes = await file.readAsBytes();
            }
          }
        }

        if (bytes != null) {
          final ext = platformFile.extension?.toLowerCase() ?? '';
          String category = 'doc';
          if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) {
            category = 'image';
          } else if (['mp3', 'wav', 'aac', 'm4a', 'flac', 'ogg'].contains(ext)) {
            category = 'audio';
          } else if (['mp4', 'mkv', 'avi', 'mov', 'webm'].contains(ext)) {
            category = 'video';
          }

          final info = SelectedFileInfo(
            name: platformFile.name,
            size: bytes.length,
            path: platformFile.path ?? '',
            bytes: bytes,
            category: category,
          );

          setState(() {
            _selectedFile = info;
          });

          widget.onFileSelected(info);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'image':
        return Icons.image_rounded;
      case 'audio':
        return Icons.audiotrack_rounded;
      case 'video':
        return Icons.videocam_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'image':
        return Colors.pinkAccent;
      case 'audio':
        return Colors.cyanAccent;
      case 'video':
        return Colors.amberAccent;
      default:
        return Colors.purpleAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.upload_file_rounded, color: Colors.cyanAccent, size: 24),
              SizedBox(width: 10),
              Text(
                'Select Media or File to Transfer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Category Selectors
          Row(
            children: [
              Expanded(
                child: _buildCategoryBtn(
                  label: 'Image',
                  icon: Icons.photo_library_rounded,
                  color: Colors.pinkAccent,
                  onTap: () => _pickFile(type: FileType.image),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCategoryBtn(
                  label: 'Audio',
                  icon: Icons.music_note_rounded,
                  color: Colors.cyanAccent,
                  onTap: () => _pickFile(type: FileType.audio),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCategoryBtn(
                  label: 'Video',
                  icon: Icons.movie_rounded,
                  color: Colors.amberAccent,
                  onTap: () => _pickFile(type: FileType.video),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCategoryBtn(
                  label: 'File',
                  icon: Icons.folder_open_rounded,
                  color: Colors.purpleAccent,
                  onTap: () => _pickFile(type: FileType.any),
                ),
              ),
            ],
          ),

          if (_isLoading) ...[
            const SizedBox(height: 20),
            const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            ),
          ] else if (_selectedFile != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _getCategoryColor(_selectedFile!.category).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(_selectedFile!.category).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCategoryIcon(_selectedFile!.category),
                      color: _getCategoryColor(_selectedFile!.category),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFile!.name,
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
                          'Size: ${_formatSize(_selectedFile!.size)} • Type: ${_selectedFile!.category.toUpperCase()}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _selectedFile = null);
                    },
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
