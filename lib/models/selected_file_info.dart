import 'dart:typed_data';

/// Holds the in-memory representation of a file picked by the sender.
class SelectedFileInfo {
  final String name;
  final int size;
  final String path;
  final Uint8List bytes;

  /// Broad category: 'image' | 'audio' | 'video' | 'doc'
  final String category;

  const SelectedFileInfo({
    required this.name,
    required this.size,
    required this.path,
    required this.bytes,
    required this.category,
  });
}
