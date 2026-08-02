import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/category_button.dart';
import '../widgets/selected_file_row.dart';
import '../widgets/glass_card.dart';

class SelectedFileInfo {
  final String name;
  final int size;
  final String path;
  final Uint8List bytes;
  final String category; // image | video | audio | doc

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

  const FileSelectorCard({super.key, required this.onFileSelected});

  @override
  State<FileSelectorCard> createState() => _FileSelectorCardState();
}

class _FileSelectorCardState extends State<FileSelectorCard> {
  SelectedFileInfo? _selectedFile;
  bool _isLoading = false;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  static String _categoryFromExt(String ext) {
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) {
      return 'image';
    }
    if (['mp3', 'wav', 'aac', 'm4a', 'flac', 'ogg'].contains(ext)) {
      return 'audio';
    }
    if (['mp4', 'mkv', 'avi', 'mov', 'webm'].contains(ext)) {
      return 'video';
    }
    return 'doc';
  }

  static IconData _iconForCategory(String cat) {
    switch (cat) {
      case 'image':
        return Icons.image_outlined;
      case 'audio':
        return Icons.audiotrack_outlined;
      case 'video':
        return Icons.videocam_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  static Color _colorForCategory(String cat) {
    switch (cat) {
      case 'image':
        return AppColors.categoryImage;
      case 'audio':
        return AppColors.categoryAudio;
      case 'video':
        return AppColors.categoryVideo;
      default:
        return AppColors.categoryDoc;
    }
  }

  // ---------------------------------------------------------------------------
  // File picking
  // ---------------------------------------------------------------------------

  Future<void> _pickFile({FileType type = FileType.any}) async {
    setState(() => _isLoading = true);
    try {
      final result = await FilePicker.pickFiles(type: type);

      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.first;
        Uint8List? bytes;

        try {
          bytes = await platformFile.readAsBytes();
        } catch (_) {
          if (platformFile.path != null) {
            final file = File(platformFile.path!);
            if (await file.exists()) bytes = await file.readAsBytes();
          }
        }

        if (bytes != null) {
          final ext = platformFile.extension?.toLowerCase() ?? '';
          final info = SelectedFileInfo(
            name: platformFile.name,
            size: bytes.length,
            path: platformFile.path ?? '',
            bytes: bytes,
            category: _categoryFromExt(ext),
          );
          setState(() => _selectedFile = info);
          widget.onFileSelected(info);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Select file to transfer',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose a file type or browse any file',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CategoryButton(
                  label: 'Image',
                  icon: Icons.photo_library_outlined,
                  color: AppColors.categoryImage,
                  onTap: () => _pickFile(type: FileType.image),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CategoryButton(
                  label: 'Audio',
                  icon: Icons.music_note_outlined,
                  color: AppColors.categoryAudio,
                  onTap: () => _pickFile(type: FileType.audio),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CategoryButton(
                  label: 'Video',
                  icon: Icons.movie_outlined,
                  color: AppColors.categoryVideo,
                  onTap: () => _pickFile(type: FileType.video),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CategoryButton(
                  label: 'File',
                  icon: Icons.folder_open_outlined,
                  color: AppColors.categoryDoc,
                  onTap: () => _pickFile(type: FileType.any),
                ),
              ),
            ],
          ),
          if (_isLoading) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ] else if (_selectedFile != null) ...[
            const SizedBox(height: 16),
            SelectedFileRow(
              name: _selectedFile!.name,
              formattedSize: _formatSize(_selectedFile!.size),
              category: _selectedFile!.category,
              icon: _iconForCategory(_selectedFile!.category),
              color: _colorForCategory(_selectedFile!.category),
              onClear: () => setState(() => _selectedFile = null),
            ),
          ],
        ],
      ),
    );
  }
}
