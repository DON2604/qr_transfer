import 'dart:convert';

/// Represents the handshake metadata frame for a file transfer
class TransferMetadata {
  final String id;
  final String fileName;
  final int fileSize;
  final int totalChunks;
  final int chunkSize;
  final String hash;

  TransferMetadata({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.totalChunks,
    required this.chunkSize,
    required this.hash,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': fileName,
        'size': fileSize,
        'total': totalChunks,
        'cSize': chunkSize,
        'hash': hash,
      };

  factory TransferMetadata.fromJson(Map<String, dynamic> json) {
    return TransferMetadata(
      id: json['id'] as String? ?? '',
      fileName: json['name'] as String? ?? 'file.bin',
      fileSize: (json['size'] as num?)?.toInt() ?? 0,
      totalChunks: (json['total'] as num?)?.toInt() ?? 0,
      chunkSize: (json['cSize'] as num?)?.toInt() ?? 350,
      hash: json['hash'] as String? ?? '',
    );
  }

  /// Encodes metadata as a compact string payload for QR representation
  String toQrString() {
    return 'META:${jsonEncode(toJson())}';
  }

  /// Tries to parse a metadata object from raw QR string
  static TransferMetadata? tryParse(String rawPayload) {
    if (!rawPayload.startsWith('META:')) return null;
    try {
      final jsonStr = rawPayload.substring(5);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return TransferMetadata.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}

/// Represents an individual data chunk frame within the animated stream
class DataChunk {
  final String transferId;
  final int chunkIndex;
  final int totalChunks;
  final String base64Payload;

  DataChunk({
    required this.transferId,
    required this.chunkIndex,
    required this.totalChunks,
    required this.base64Payload,
  });

  /// Encodes chunk into a compact text format: `DAT:<transferId>:<chunkIndex>:<totalChunks>:<base64>`
  String toQrString() {
    return 'DAT:$transferId:$chunkIndex:$totalChunks:$base64Payload';
  }

  /// Tries to parse a DataChunk from a raw QR string payload
  static DataChunk? tryParse(String rawPayload) {
    if (!rawPayload.startsWith('DAT:')) return null;
    try {
      // Split into 5 parts: DAT, transferId, chunkIndex, totalChunks, base64Payload
      final parts = rawPayload.split(':');
      if (parts.length < 5) return null;

      final transferId = parts[1];
      final chunkIndex = int.parse(parts[2]);
      final totalChunks = int.parse(parts[3]);

      // In case base64 payload itself contains ':' (unlikely in standard base64), join remaining
      final base64Payload = parts.sublist(4).join(':');

      return DataChunk(
        transferId: transferId,
        chunkIndex: chunkIndex,
        totalChunks: totalChunks,
        base64Payload: base64Payload,
      );
    } catch (_) {
      return null;
    }
  }
}
