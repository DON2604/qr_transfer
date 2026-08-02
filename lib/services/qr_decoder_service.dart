import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../models/transfer_metadata.dart';

enum AssemblyState { idle, receiving, complete, error }

class QrDecoderService {
  TransferMetadata? _metadata;
  final Map<int, String> _receivedChunks = {};
  String? _currentTransferId;
  AssemblyState _state = AssemblyState.idle;
  String? _errorMessage;

  TransferMetadata? get metadata => _metadata;
  Map<int, String> get receivedChunks => Map.unmodifiable(_receivedChunks);
  AssemblyState get state => _state;
  String? get errorMessage => _errorMessage;

  int get totalChunks => _metadata?.totalChunks ?? 0;
  int get countReceived => _receivedChunks.length;
  double get progress => totalChunks > 0 ? (countReceived / totalChunks) : 0.0;
  bool get isComplete => _metadata != null && countReceived == totalChunks;

  /// Resets receiver session
  void reset() {
    _metadata = null;
    _receivedChunks.clear();
    _currentTransferId = null;
    _state = AssemblyState.idle;
    _errorMessage = null;
  }

  /// Processes a single raw scanned string from camera. Returns true if new unique data was ingested.
  bool processScannedPayload(String rawPayload) {
    if (rawPayload.isEmpty) return false;

    // 1. Try parsing Metadata
    if (rawPayload.startsWith('META:')) {
      final meta = TransferMetadata.tryParse(rawPayload);
      if (meta != null) {
        if (_currentTransferId != null && _currentTransferId != meta.id) {
          // New file transfer initiated while another was active -> reset if new file
          _metadata = meta;
          _currentTransferId = meta.id;
          _receivedChunks.clear();
          _state = AssemblyState.receiving;
          return true;
        } else if (_metadata == null) {
          _metadata = meta;
          _currentTransferId = meta.id;
          _state = AssemblyState.receiving;
          return true;
        }
      }
      return false;
    }

    // 2. Try parsing Data Chunk
    if (rawPayload.startsWith('DAT:')) {
      final chunk = DataChunk.tryParse(rawPayload);
      if (chunk != null) {
        // If metadata isn't captured yet, infer totalChunks & transferId from chunk!
        if (_currentTransferId == null) {
          _currentTransferId = chunk.transferId;
          _state = AssemblyState.receiving;
        } else if (_currentTransferId != chunk.transferId) {
          // Ignore chunks from a different transfer ID unless reset
          return false;
        }

        final isNew = !_receivedChunks.containsKey(chunk.chunkIndex);
        if (isNew) {
          _receivedChunks[chunk.chunkIndex] = chunk.base64Payload;
          if (_metadata != null && _receivedChunks.length == _metadata!.totalChunks) {
            _state = AssemblyState.complete;
          }
          return true;
        }
      }
    }

    return false;
  }

  /// Reconstructs the original binary byte array and verifies SHA-256 hash.
  Uint8List assembleFile() {
    if (_metadata == null) {
      throw Exception('Metadata missing. Cannot assemble file.');
    }
    if (_receivedChunks.length < _metadata!.totalChunks) {
      throw Exception('Incomplete chunks (${_receivedChunks.length}/${_metadata!.totalChunks}).');
    }

    final BytesBuilder bytesBuilder = BytesBuilder();

    for (int i = 0; i < _metadata!.totalChunks; i++) {
      final base64Chunk = _receivedChunks[i];
      if (base64Chunk == null) {
        throw Exception('Missing chunk index $i.');
      }
      final chunkBytes = base64Decode(base64Chunk);
      bytesBuilder.add(chunkBytes);
    }

    final fullBytes = bytesBuilder.toBytes();

    // Verify SHA-256 hash
    final digest = sha256.convert(fullBytes);
    final calculatedHash = digest.toString();

    if (_metadata!.hash.isNotEmpty && calculatedHash != _metadata!.hash) {
      _state = AssemblyState.error;
      _errorMessage = 'SHA-256 integrity check failed! Expected ${_metadata!.hash}, got $calculatedHash';
      throw Exception(_errorMessage);
    }

    _state = AssemblyState.complete;
    return fullBytes;
  }

  /// Returns missing chunk indices for live visual feedback
  List<int> getMissingChunkIndices() {
    if (_metadata == null) return [];
    final List<int> missing = [];
    for (int i = 0; i < _metadata!.totalChunks; i++) {
      if (!_receivedChunks.containsKey(i)) {
        missing.add(i);
      }
    }
    return missing;
  }
}
