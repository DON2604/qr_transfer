import 'dart:io';
import 'dart:typed_data';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transfer_file_info.dart';

class FileStorageService {
  static const String _historyFileName = 'transfer_history.json';

  /// Saves assembled file bytes to local application directory
  static Future<TransferFileInfo> saveReceivedFile({
    required Uint8List bytes,
    required String fileName,
    required String hash,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final qrTransferDir = Directory('${docsDir.path}/QR_Transfers');
    if (!await qrTransferDir.exists()) {
      await qrTransferDir.create(recursive: true);
    }

    // Handle collision by appending timestamp if file exists
    String safeName = fileName;
    File targetFile = File('${qrTransferDir.path}/$safeName');
    if (await targetFile.exists()) {
      final extIndex = fileName.lastIndexOf('.');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      if (extIndex != -1) {
        final name = fileName.substring(0, extIndex);
        final ext = fileName.substring(extIndex);
        safeName = '${name}_$timestamp$ext';
      } else {
        safeName = '${fileName}_$timestamp';
      }
      targetFile = File('${qrTransferDir.path}/$safeName');
    }

    await targetFile.writeAsBytes(bytes);

    final info = TransferFileInfo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: safeName,
      filePath: targetFile.path,
      fileSize: bytes.length,
      receivedAt: DateTime.now(),
      hash: hash,
    );

    await _addToHistory(info);
    return info;
  }

  /// Opens the file using device default app (photo viewer, video player, audio player, etc.)
  static Future<void> openFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await OpenFilex.open(filePath);
    }
  }

  /// Shares file using device share sheet
  static Future<void> shareFile(String filePath, {String? text}) async {
    final file = File(filePath);
    if (await file.exists()) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text: text ?? 'Transferred via Air-Gapped QR Transfer',
        ),
      );
    }
  }

  /// Returns history of saved transfers
  static Future<List<TransferFileInfo>> getHistory() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final historyFile = File('${docsDir.path}/$_historyFileName');
      if (!await historyFile.exists()) return [];

      final content = await historyFile.readAsString();
      if (content.isEmpty) return [];

      final List<TransferFileInfo> list = [];
      final lines = content.split('\n');
      for (final line in lines) {
        if (line.trim().isNotEmpty) {
          try {
            list.add(TransferFileInfo.deserialize(line.trim()));
          } catch (_) {}
        }
      }
      // Sort newest first
      list.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  static Future<void> _addToHistory(TransferFileInfo info) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final historyFile = File('${docsDir.path}/$_historyFileName');
      await historyFile.writeAsString('${info.serialize()}\n', mode: FileMode.append);
    } catch (_) {}
  }

  /// Deletes a file from disk and history
  static Future<void> deleteFile(TransferFileInfo info) async {
    try {
      final file = File(info.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      final history = await getHistory();
      history.removeWhere((item) => item.id == info.id);

      final docsDir = await getApplicationDocumentsDirectory();
      final historyFile = File('${docsDir.path}/$_historyFileName');
      final buffer = StringBuffer();
      for (final item in history) {
        buffer.writeln(item.serialize());
      }
      await historyFile.writeAsString(buffer.toString());
    } catch (_) {}
  }
}
