import 'dart:convert';

class TransferFileInfo {
  final String id;
  final String fileName;
  final String filePath;
  final int fileSize;
  final DateTime receivedAt;
  final String hash;

  TransferFileInfo({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.receivedAt,
    required this.hash,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'filePath': filePath,
        'fileSize': fileSize,
        'receivedAt': receivedAt.toIso8601String(),
        'hash': hash,
      };

  factory TransferFileInfo.fromJson(Map<String, dynamic> json) {
    return TransferFileInfo(
      id: json['id'] as String? ?? '',
      fileName: json['fileName'] as String? ?? 'file',
      filePath: json['filePath'] as String? ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      receivedAt: DateTime.tryParse(json['receivedAt'] as String? ?? '') ?? DateTime.now(),
      hash: json['hash'] as String? ?? '',
    );
  }

  String serialize() => jsonEncode(toJson());

  static TransferFileInfo deserialize(String raw) {
    return TransferFileInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
