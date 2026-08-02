import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../models/transfer_metadata.dart';

class QrStreamPackage {
  final TransferMetadata metadata;
  final List<DataChunk> chunks;

  QrStreamPackage({
    required this.metadata,
    required this.chunks,
  });

  /// Returns total frames in loop (1 metadata frame + N data frames)
  int get totalFrames => 1 + chunks.length;

  /// Retrieves the payload string at index [frameIndex] (0 is metadata, 1..N are data chunks)
  String getFramePayload(int frameIndex) {
    if (frameIndex <= 0 || frameIndex > chunks.length) {
      return metadata.toQrString();
    }
    return chunks[frameIndex - 1].toQrString();
  }
}

class QrEncoderService {
  /// Encodes binary file bytes into a chunked QR stream package
  static QrStreamPackage encodeFile({
    required Uint8List fileBytes,
    required String fileName,
    int rawChunkSize = 300, // bytes per chunk before base64 encoding
  }) {
    // 1. Calculate SHA-256 Hash
    final digest = sha256.convert(fileBytes);
    final fileHash = digest.toString();

    // 2. Generate unique transfer ID
    final transferId = DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase();

    // 3. Slice file into chunks
    final List<DataChunk> chunks = [];
    final totalSize = fileBytes.length;
    final totalChunks = (totalSize / rawChunkSize).ceil();

    for (int i = 0; i < totalChunks; i++) {
      final start = i * rawChunkSize;
      final end = (start + rawChunkSize > totalSize) ? totalSize : start + rawChunkSize;
      final chunkBytes = fileBytes.sublist(start, end);
      final base64Payload = base64Encode(chunkBytes);

      chunks.add(DataChunk(
        transferId: transferId,
        chunkIndex: i,
        totalChunks: totalChunks,
        base64Payload: base64Payload,
      ));
    }

    // 4. Build Metadata Header
    final metadata = TransferMetadata(
      id: transferId,
      fileName: fileName,
      fileSize: totalSize,
      totalChunks: totalChunks,
      chunkSize: rawChunkSize,
      hash: fileHash,
    );

    return QrStreamPackage(
      metadata: metadata,
      chunks: chunks,
    );
  }
}
