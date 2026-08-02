import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_transfer/services/qr_decoder_service.dart';
import 'package:qr_transfer/services/qr_encoder_service.dart';

void main() {
  group('Optical QR Air-Gapped Transfer Protocol Tests', () {
    test('Encodes raw bytes to chunked QR stream package correctly', () {
      final sampleBytes = Uint8List.fromList(List.generate(1000, (i) => i % 256));
      final fileName = 'test_song.mp3';

      final package = QrEncoderService.encodeFile(
        fileBytes: sampleBytes,
        fileName: fileName,
        rawChunkSize: 300,
      );

      expect(package.metadata.fileName, equals('test_song.mp3'));
      expect(package.metadata.fileSize, equals(1000));
      expect(package.metadata.totalChunks, equals(4)); // 1000 / 300 = 3.33 -> 4 chunks
      expect(package.chunks.length, equals(4));
      expect(package.metadata.hash, isNotEmpty);

      // Check metadata string
      final metaQr = package.getFramePayload(0);
      expect(metaQr.startsWith('META:'), isTrue);

      // Check chunk strings
      final chunk0Qr = package.getFramePayload(1);
      expect(chunk0Qr.startsWith('DAT:'), isTrue);
    });

    test('Decodes and reassembles out-of-order scanned QR stream accurately', () {
      final originalData = 'Hello World! Air-Gapped Optical QR Transfer protocol test bytes.' * 20;
      final originalBytes = Uint8List.fromList(utf8.encode(originalData));
      final fileName = 'test_photo.png';

      // 1. Encode file
      final package = QrEncoderService.encodeFile(
        fileBytes: originalBytes,
        fileName: fileName,
        rawChunkSize: 200,
      );

      final totalChunks = package.chunks.length;
      final decoder = QrDecoderService();

      // 2. Feed Metadata first
      decoder.processScannedPayload(package.getFramePayload(0));
      expect(decoder.metadata, isNotNull);
      expect(decoder.metadata!.fileName, equals('test_photo.png'));
      expect(decoder.metadata!.totalChunks, equals(totalChunks));

      // 3. Feed data frames in reverse/out-of-order sequence (e.g. totalChunks..1)
      final frameIndices = List.generate(totalChunks, (i) => i + 1).reversed.toList();
      for (final frameIdx in frameIndices) {
        final payload = package.getFramePayload(frameIdx);
        decoder.processScannedPayload(payload);
      }

      // 4. Verify complete & SHA-256 integrity check
      expect(decoder.isComplete, isTrue);

      final assembledBytes = decoder.assembleFile();
      expect(assembledBytes, equals(originalBytes));
      expect(utf8.decode(assembledBytes), equals(originalData));
    });

    test('Fails assembly if SHA-256 hash checksum is corrupted', () {
      final sampleBytes = Uint8List.fromList(utf8.encode('Corrupted data test'));
      final package = QrEncoderService.encodeFile(
        fileBytes: sampleBytes,
        fileName: 'file.txt',
        rawChunkSize: 50,
      );

      final decoder = QrDecoderService();
      decoder.processScannedPayload(package.getFramePayload(0)); // Meta

      for (int i = 1; i <= package.chunks.length; i++) {
        var payload = package.getFramePayload(i);
        if (i == 1) {
          // Tamper with payload
          payload = 'DAT:${package.metadata.id}:0:${package.chunks.length}:${base64Encode(utf8.encode("TAMPERED"))}';
        }
        decoder.processScannedPayload(payload);
      }

      expect(decoder.isComplete, isTrue);
      expect(() => decoder.assembleFile(), throwsException);
    });
  });
}
